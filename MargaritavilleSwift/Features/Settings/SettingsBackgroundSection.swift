import BrooklynBackgroundKit
import PhotosUI
import SwiftUI

struct SettingsBackgroundSection: View {
    @Bindable var appSettings: AppSettingsStore
    @Environment(\.interactionFeedback) private var feedback
    @State private var selectedBackgroundVideoItem: PhotosPickerItem?
    @AppStorage(CameraBackgroundEffect.storageKey) private var cameraEffect: CameraBackgroundEffect = .normal

    var body: some View {
        SettingsPanel(
            title: "Фон приложения",
            subtitle: "Живые Matrix, TV, Video, Brooklyn и камера как фон для всех экранов приложения."
        ) {
            Picker("Заставка", selection: $appSettings.appBackgroundMode) {
                ForEach(AppBackgroundMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.menu)
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
            if appSettings.appBackgroundMode == .brooklyn {
                brooklynControls
                BrooklynAppearanceControls(appSettings: appSettings)
            }
            if appSettings.appBackgroundMode == .camera {
                cameraControls
            }
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

    private var cameraControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Эффект камеры", selection: $cameraEffect) {
                ForEach(CameraBackgroundEffect.allCases) { effect in
                    Text(effect.title).tag(effect)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: cameraEffect) { _, _ in feedback.confirm() }

            SettingsInfoRow(
                title: "Эффект камеры",
                value: cameraEffect.title,
                systemName: "camera.filters",
                subtitle: cameraEffect.subtitle
            )
        }
    }

    private var backgroundModeSubtitle: String {
        switch appSettings.appBackgroundMode {
        case .off: "Фон отключён, основной экран остаётся чёрным."
        case .matrixRain: "Matrix Rain как основной живой фон."
        case .tvStaticNoise: "ShaderKit Dynamic Gray Noise: аналоговый телевизионный снег как основной фон."
        case .video: "Видео хранится только локально на устройстве."
        case .brooklyn: "Нативная Swift/Metal сцена Brooklyn с точной геометрией, материалом и анимацией исходника."
        case .camera: CameraBackgroundSession.isDenied
            ? "Нет доступа к камере. Разрешите его: Настройки iOS → Margaritaville → Камера."
            : "Вместо обоев видно изображение задней камеры. Камера выключается, когда приложение свёрнуто или поверх открыт другой экран."
        }
    }

    private var brooklynControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Материал", selection: $appSettings.brooklynSurfaceStyle) {
                Text("Оригинал").tag(BrooklynSurfaceStyle.donorExact)
                Text("Блики+").tag(BrooklynSurfaceStyle.enhanced)
            }
            .pickerStyle(.segmented)
            .onChange(of: appSettings.brooklynSurfaceStyle) { _, _ in feedback.confirm() }

            SettingsInfoRow(
                title: "Материал Brooklyn",
                value: appSettings.brooklynSurfaceStyle == .donorExact ? "Оригинал" : "Блики+",
                systemName: "cube.transparent",
                subtitle: appSettings.brooklynSurfaceStyle == .donorExact
                    ? "Точный материал donor с оригинальными текстурами и city HDR."
                    : "Та же сцена и анимация с усиленными отражательными бликами."
            )
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
