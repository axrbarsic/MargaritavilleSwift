import SwiftUI

/// Единая точка отрисовки всех шейдерных обоев: один `TimelineView` с бюджетом
/// кадров из `ShaderWallpaperFramePolicy`, без собственных display link.
struct ShaderWallpaperView: View {
    let kind: ShaderWallpaperKind

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startDate = Date()
    @State private var isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled

    private static let reducedMotionTime: Float = 20

    var body: some View {
        let policy = ShaderWallpaperFramePolicy(
            isSceneActive: scenePhase == .active,
            isLowPowerModeEnabled: isLowPowerModeEnabled,
            reduceMotion: reduceMotion
        )
        GeometryReader { proxy in
            TimelineView(.animation(minimumInterval: policy.minimumInterval, paused: policy.isPaused)) { context in
                Rectangle()
                    .colorEffect(shader(size: proxy.size, time: time(at: context.date)))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)) { _ in
            isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
    }

    private func time(at date: Date) -> Float {
        guard !reduceMotion else { return Self.reducedMotionTime }
        return Float(date.timeIntervalSince(startDate))
    }

    private func shader(size: CGSize, time: Float) -> Shader {
        ShaderLibrary.default[dynamicMember: kind.shaderFunctionName](
            .float2(Float(size.width), Float(size.height)),
            .float(time)
        )
    }
}

#Preview {
    ShaderWallpaperView(kind: .synthwave)
        .ignoresSafeArea()
}
