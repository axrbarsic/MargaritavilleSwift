import SwiftUI

struct AppBackgroundView: View {
    @Environment(\.appBackgroundMode) private var appBackgroundMode
    @Environment(\.appBackgroundVideoURL) private var appBackgroundVideoURL
    @Environment(\.appBackgroundVideoBlur) private var appBackgroundVideoBlur
    @Environment(\.experimentalMetalAuroraEnabled) private var experimentalMetalAuroraEnabled

    var body: some View {
        ZStack {
            Color.black
            if experimentalMetalAuroraEnabled {
                MetalAuroraBackgroundView()
                    .opacity(0.92)
                    .transition(.opacity)
            }
            if appBackgroundMode == .matrixRain {
                SpriteKitEffectView(.matrixRain)
            }
            if appBackgroundMode == .video, let appBackgroundVideoURL {
                LoopingVideoBackgroundView(
                    url: appBackgroundVideoURL,
                    matteStrength: appBackgroundVideoBlur
                )
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    AppBackgroundView()
        .environment(\.appBackgroundMode, .matrixRain)
        .environment(\.matrixRainConfiguration, .default)
}
