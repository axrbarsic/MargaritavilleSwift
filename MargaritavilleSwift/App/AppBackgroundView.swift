import BrooklynBackgroundKit
import BrooklynWebBackgroundKit
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
    @Environment(\.brooklynWebConfiguration) private var brooklynWebConfiguration

    var body: some View {
        ZStack {
            Color.black
            if appBackgroundMode == .matrixRain {
                SpriteKitEffectView(.matrixRain)
            } else if appBackgroundMode == .tvStaticNoise {
                TVStaticNoiseBackgroundView(configuration: tvStaticNoiseConfiguration)
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
            } else if appBackgroundMode == .brooklyn {
                BrooklynBackgroundView(configuration: .init(style: brooklynSurfaceStyle))
            } else if appBackgroundMode == .brooklynWeb {
                BrooklynWebBackgroundView(configuration: brooklynWebConfiguration)
            } else if let shaderWallpaper = appBackgroundMode.shaderWallpaper {
                ShaderWallpaperView(kind: shaderWallpaper)
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
