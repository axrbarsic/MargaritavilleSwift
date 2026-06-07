import SwiftUI

struct AppBackgroundView: View {
    @Environment(\.appBackgroundMode) private var appBackgroundMode
    @Environment(\.appBackgroundVideoURL) private var appBackgroundVideoURL
    @Environment(\.appBackgroundVideoBlur) private var appBackgroundVideoBlur

    var body: some View {
        ZStack {
            Color.black
            if appBackgroundMode == .matrixRain {
                SpriteKitEffectView(.matrixRain)
            }
            if appBackgroundMode == .video, let appBackgroundVideoURL {
                LoopingVideoBackgroundView(url: appBackgroundVideoURL)
                    .overlay {
                        BackgroundMaterialView(alpha: CGFloat(appBackgroundVideoBlur))
                    }
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
