import BrooklynBackgroundKit
import SwiftUI

struct AppBackgroundView: View {
    @Environment(\.appBackgroundMode) private var appBackgroundMode
    @Environment(\.appBackgroundVideoURL) private var appBackgroundVideoURL
    @Environment(\.appBackgroundVideoBlur) private var appBackgroundVideoBlur
    @Environment(\.appBackgroundVideoBrightness) private var appBackgroundVideoBrightness
    @Environment(\.appBackgroundVideoGreenTint) private var appBackgroundVideoGreenTint
    @Environment(\.appBackgroundVideoGridIntensity) private var appBackgroundVideoGridIntensity
    @Environment(\.tvStaticNoiseConfiguration) private var tvStaticNoiseConfiguration
    @Environment(\.brooklynSurfaceStyle) private var brooklynSurfaceStyle
    @Environment(\.brooklynAppearance) private var brooklynAppearance
    @AppStorage(CameraBackgroundEffect.storageKey) private var cameraEffect: CameraBackgroundEffect = .normal
    @AppStorage(CameraBackgroundPosition.storageKey) private var cameraPosition: CameraBackgroundPosition = .back
    @AppStorage(CameraEffectTuning.Keys.amount) private var cameraAmount = CameraEffectTuning.default.amount
    @AppStorage(CameraEffectTuning.Keys.brightness) private var cameraBrightness = CameraEffectTuning.default.brightness
    @AppStorage(CameraEffectTuning.Keys.reliefDepth) private var cameraReliefDepth = CameraEffectTuning.default.reliefDepth
    @AppStorage(CameraEffectTuning.Keys.lightAngle) private var cameraLightAngle = CameraEffectTuning.default.lightAngle
    @AppStorage(CameraEffectTuning.Keys.edgeSensitivity) private var cameraEdgeSensitivity = CameraEffectTuning.default.edgeSensitivity
    @AppStorage(CameraEffectTuning.Keys.detailScale) private var cameraDetailScale = CameraEffectTuning.default.detailScale
    @AppStorage(CameraEffectTuning.Keys.metalHue) private var cameraMetalHue = CameraEffectTuning.default.metalHue
    @AppStorage(CameraEffectTuning.Keys.metalSaturation) private var cameraMetalSaturation = CameraEffectTuning.default.metalSaturation
    @AppStorage(CameraEffectTuning.Keys.liveLight) private var cameraLiveLight = CameraEffectTuning.default.liveLight
    @AppStorage(CameraEffectTuning.Keys.glowAmount) private var cameraGlowAmount = CameraEffectTuning.default.glowAmount
    @State private var presenceID = UUID()
    private let presence = AppBackgroundPresence.shared

    var body: some View {
        let isActive = presence.isActive(presenceID)
        ZStack {
            Color.black
            if appBackgroundMode == .matrixRain {
                SpriteKitEffectView(.matrixRain, isActive: isActive)
            } else if appBackgroundMode == .tvStaticNoise {
                TVStaticNoiseBackgroundView(configuration: tvStaticNoiseConfiguration, isActive: isActive)
            } else if appBackgroundMode == .video, let appBackgroundVideoURL {
                LoopingVideoBackgroundView(
                    url: appBackgroundVideoURL,
                    isActive: isActive,
                    tuning: VideoBackgroundTuning(
                        blur: appBackgroundVideoBlur,
                        brightness: appBackgroundVideoBrightness,
                        greenTint: appBackgroundVideoGreenTint,
                        gridIntensity: appBackgroundVideoGridIntensity
                    )
                )
            } else if appBackgroundMode == .brooklyn {
                BrooklynBackgroundView(
                    configuration: .init(style: brooklynSurfaceStyle, appearance: brooklynAppearance),
                    isActive: isActive
                )
            } else if appBackgroundMode == .camera {
                CameraBackgroundView(
                    isActive: isActive,
                    effect: cameraEffect,
                    position: cameraPosition,
                    tuning: CameraEffectTuning(
                        amount: cameraAmount,
                        brightness: cameraBrightness,
                        reliefDepth: cameraReliefDepth,
                        lightAngle: cameraLightAngle,
                        edgeSensitivity: cameraEdgeSensitivity,
                        detailScale: cameraDetailScale,
                        metalHue: cameraMetalHue,
                        metalSaturation: cameraMetalSaturation,
                        liveLight: cameraLiveLight,
                        glowAmount: cameraGlowAmount
                    )
                )
            }
        }
        .ignoresSafeArea()
        .onAppear { presence.register(presenceID) }
        .onDisappear { presence.unregister(presenceID) }
    }
}

#Preview {
    AppBackgroundView()
        .environment(\.appBackgroundMode, .matrixRain)
        .environment(\.matrixRainConfiguration, .default)
}
