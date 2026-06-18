import PhotosUI
import SwiftUI

struct SettingsBackgroundSection: View {
    @Bindable var appSettings: AppSettingsStore
    @Environment(\.interactionFeedback) private var feedback
    @State private var selectedBackgroundVideoItem: PhotosPickerItem?

    var body: some View {
        SettingsPanel(
            title: "Фон приложения",
            subtitle: "Matrix Rain или локальное видео как живая заставка основного экрана."
        ) {
            Picker("Заставка", selection: $appSettings.appBackgroundMode) {
                ForEach(AppBackgroundMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: appSettings.appBackgroundMode) { _, _ in feedback.confirm() }

            SettingsInfoRow(
                title: "Заставка",
                value: appSettings.appBackgroundMode.description,
                systemName: "grid",
                subtitle: backgroundModeSubtitle
            )
            if appSettings.appBackgroundMode == .matrixRain {
                matrixControls
            }
            if appSettings.appBackgroundMode == .tvStaticNoise {
                tvStaticControls
            }
            if appSettings.appBackgroundMode == .video {
                videoControls
            }
        }

        SettingsPanel(
            title: "Автозаставка при бездействии",
            subtitle: "Полноэкранные часы и эффект при неактивности пользователя."
        ) {
            Toggle("Включить автозаставку", isOn: $appSettings.idleScreensaverEnabled)
                .onChange(of: appSettings.idleScreensaverEnabled) { _, _ in feedback.confirm() }

            if appSettings.idleScreensaverEnabled {
                Picker("Эффект заставки", selection: $appSettings.idleScreensaverMode) {
                    ForEach(IdleScreensaverMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: appSettings.idleScreensaverMode) { _, _ in feedback.confirm() }

                SettingsInfoRow(
                    title: "Режим",
                    value: appSettings.idleScreensaverMode.description,
                    systemName: "clock.fill",
                    subtitle: idleModeSubtitle
                )

                Picker("Время бездействия", selection: $appSettings.idleScreensaverTimeout) {
                    Text("15 секунд").tag(15)
                    Text("30 секунд").tag(30)
                    Text("1 минута").tag(60)
                    Text("2 минуты").tag(120)
                }
                .onChange(of: appSettings.idleScreensaverTimeout) { _, _ in feedback.confirm() }
            }
        }
    }

    private var idleModeSubtitle: String {
        switch appSettings.idleScreensaverMode {
        case .matrixRain: "Матричный дождь с неоновыми часами во весь экран."
        case .video: "Локальная видеозаставка с неоновыми часами во весь экран."
        }
    }

    private var matrixControls: some View {
        SettingsSliderRow(
            title: "Скорость",
            valueLabel: "\(String(format: "%.2f", appSettings.matrixSpeed))x",
            systemName: "speedometer",
            range: 0.08...3.0,
            defaultValue: MatrixRainConfiguration.default.speed,
            value: $appSettings.matrixSpeed
        )
    }

    private var backgroundModeSubtitle: String {
        switch appSettings.appBackgroundMode {
        case .off: "Фон отключён, основной экран остаётся чёрным."
        case .matrixRain: "Matrix Rain как основной живой фон."
        case .tvStaticNoise: "ShaderKit Dynamic Gray Noise: аналоговый телевизионный снег как основной фон."
        case .video: "Видео хранится только локально на устройстве."
        }
    }

    private var videoControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            let videoStatus = appSettings.backgroundVideoRelativePath == nil ? "Выбрать" : "Выбрано"
            PhotosPicker(selection: $selectedBackgroundVideoItem, matching: .videos, photoLibrary: .shared()) {
                BackgroundVideoPickerLabel(videoStatus: videoStatus)
            }
            .buttonStyle(.plain)
            .onChange(of: selectedBackgroundVideoItem) { _, item in
                guard let item else { return }
                Task { await importBackgroundVideo(item) }
            }

            SettingsSliderRow(
                title: "Матовость",
                valueLabel: "\(Int((appSettings.backgroundVideoBlur * 100).rounded()))%",
                systemName: "aqi.medium",
                range: 0...1,
                defaultValue: 0.28,
                value: $appSettings.backgroundVideoBlur
            )
            SettingsSliderRow(
                title: "Яркость",
                valueLabel: "\(Int((appSettings.backgroundVideoBrightness * 100).rounded()))%",
                systemName: "sun.max.fill",
                range: -0.85...0.85,
                defaultValue: 0.08,
                value: $appSettings.backgroundVideoBrightness
            )
            SettingsSliderRow(
                title: "Зелёный",
                valueLabel: "\(Int((appSettings.backgroundVideoGreenTint * 100).rounded()))%",
                systemName: "leaf.fill",
                range: 0...1,
                defaultValue: 0.34,
                value: $appSettings.backgroundVideoGreenTint
            )
            SettingsSliderRow(
                title: "Сетка",
                valueLabel: "\(Int((appSettings.backgroundVideoGridIntensity * 100).rounded()))%",
                systemName: "squareshape.split.3x3",
                range: 0...1,
                defaultValue: 0,
                value: $appSettings.backgroundVideoGridIntensity
            )
        }
    }

    private var tvStaticControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsInfoRow(
                title: "Вариант шума",
                value: appSettings.tvStaticVariant.title,
                systemName: "tv.fill",
                subtitle: appSettings.tvStaticVariant.description
            )
            Picker("Вариант шума", selection: $appSettings.tvStaticVariant) {
                ForEach(TVStaticNoiseVariant.allCases) { variant in
                    Text(variant.title).tag(variant)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: appSettings.tvStaticVariant) { _, _ in feedback.confirm() }

            SettingsSliderRow(
                title: "Яркость",
                valueLabel: "\(Int((appSettings.tvStaticBrightness * 100).rounded()))%",
                systemName: "sun.max.fill",
                range: -1...1,
                defaultValue: TVStaticNoiseConfiguration.default.brightness,
                value: $appSettings.tvStaticBrightness
            )
            SettingsSliderRow(
                title: "Зелёный",
                valueLabel: "\(Int((appSettings.tvStaticGreenTint * 100).rounded()))%",
                systemName: "leaf.fill",
                range: 0...1,
                defaultValue: TVStaticNoiseConfiguration.default.greenTint,
                value: $appSettings.tvStaticGreenTint
            )
        }
    }

    @MainActor
    private func importBackgroundVideo(_ item: PhotosPickerItem) async {
        do {
            guard let pickedVideo = try await item.loadTransferable(type: PickedBackgroundVideo.self) else { return }
            appSettings.backgroundVideoRelativePath = try BackgroundVideoFileStore().saveVideo(from: pickedVideo.url)
            appSettings.appBackgroundMode = .video
            feedback.confirm()
        } catch {
            feedback.holdWarning()
        }
    }
}
