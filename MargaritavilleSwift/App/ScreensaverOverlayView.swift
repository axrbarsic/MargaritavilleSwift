import SwiftUI

struct ScreensaverOverlayView: View {
    let mode: IdleScreensaverMode
    @Bindable var appSettings: AppSettingsStore
    let onDismiss: () -> Void

    @State private var currentTime = Date()
    @State private var logoPulse = false
    private let timeTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black

            if mode == .matrixRain {
                SpriteKitEffectView(.matrixRain)
                    .environment(\.matrixRainConfiguration, MatrixRainConfiguration(speed: appSettings.matrixSpeed * 0.8))
            } else if mode == .video, let videoURL = appSettings.backgroundVideoURL {
                LoopingVideoBackgroundView(
                    url: videoURL,
                    tuning: VideoBackgroundTuning(
                        blur: 0,
                        brightness: 0.1,
                        greenTint: 0.15,
                        gridIntensity: 0.05
                    )
                )
            }

            RadialGradient(
                gradient: Gradient(colors: [.clear, .black.opacity(0.4), .black.opacity(0.85)]),
                center: .center,
                startRadius: 100,
                endRadius: 600
            )

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 8) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 44))
                        .foregroundColor(themeColor)
                        .shadow(color: glowColor, radius: logoPulse ? 12 : 4)
                        .shadow(color: glowColor, radius: logoPulse ? 24 : 8)
                        .scaleEffect(logoPulse ? 1.05 : 0.98)

                    Text("MARGARITAVILLE")
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .tracking(8)
                        .foregroundColor(.white)
                        .shadow(color: glowColor, radius: logoPulse ? 8 : 3)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        logoPulse = true
                    }
                }

                Spacer().frame(height: 40)

                Text(timeString)
                    .font(.system(size: 76, weight: .thin, design: .monospaced))
                    .foregroundColor(.white)
                    .shadow(color: glowColor, radius: 8)
                    .shadow(color: glowColor, radius: 20)

                Text(dateString)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .tracking(2)
                    .shadow(color: .black, radius: 3)

                Spacer()

                Text("Коснитесь экрана, чтобы продолжить")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.45))
                    .tracking(1)
                    .padding(.bottom, 40)
            }
            .padding()
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture {
            onDismiss()
        }
        .onReceive(timeTimer) { input in
            currentTime = input
        }
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: currentTime)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter.string(from: currentTime).capitalized
    }

    private var glowColor: Color {
        mode == .matrixRain ? Color(red: 0.0, green: 1.0, blue: 0.4) : Color(red: 0.0, green: 0.9, blue: 1.0)
    }

    private var themeColor: Color {
        mode == .matrixRain ? Color(red: 0.0, green: 1.0, blue: 0.4) : Color(red: 0.0, green: 0.9, blue: 1.0)
    }
}
