import SwiftUI

struct AppBackgroundView: View {
    @Environment(\.appBackgroundMode) private var appBackgroundMode
    @Environment(\.appBackgroundVideoURL) private var appBackgroundVideoURL
    @Environment(\.appBackgroundVideoBlur) private var appBackgroundVideoBlur
    @Environment(\.appBackgroundVideoBrightness) private var appBackgroundVideoBrightness
    @Environment(\.appBackgroundVideoGreenTint) private var appBackgroundVideoGreenTint
    @Environment(\.appBackgroundVideoGridIntensity) private var appBackgroundVideoGridIntensity

    var body: some View {
        ZStack {
            Color.black
            if appBackgroundMode == .matrixRain {
                SpriteKitEffectView(.matrixRain)
            } else if appBackgroundMode == .tvStaticNoise {
                TVStaticNoiseBackgroundView()
            } else if appBackgroundMode == .video, let appBackgroundVideoURL {
                LoopingVideoBackgroundView(
                    url: appBackgroundVideoURL,
                    tuning: VideoBackgroundTuning(
                        blur: appBackgroundVideoBlur,
                        brightness: appBackgroundVideoBrightness,
                        greenTint: appBackgroundVideoGreenTint,
                        gridIntensity: appBackgroundVideoGridIntensity
                    )
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
