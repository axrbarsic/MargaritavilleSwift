import PhotosUI
import SwiftUI

struct SettingsScreen: View {
    @Bindable var appSettings: AppSettingsStore

    @Environment(\.dismiss) private var dismiss
    @Environment(\.interactionFeedback) private var feedback
    @Environment(\.appleSyncStatus) private var appleSyncStatus
    @State private var selectedCategory: SettingsCategory = .appearance
    @State private var isChangelogPresented = false
    @State private var isResetConfirmationPresented = false
    @State private var selectedBackgroundVideoItem: PhotosPickerItem?

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    SettingsCategorySelector(selectedCategory: $selectedCategory)
                        .onChange(of: selectedCategory) { _, _ in
                            feedback.tap()
                        }
                    selectedCategoryContent
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
        }
        .sheet(isPresented: $isChangelogPresented) {
            BuildChangelogScreen()
                .preferredColorScheme(.dark)
        }
        .confirmationDialog(
            "Сбросить настройки?",
            isPresented: $isResetConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Сбросить", role: .destructive, action: resetSettings)
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Размер ячеек, режимы меню, палитра и Matrix-настройки вернутся к значениям по умолчанию.")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .black))
                    .frame(width: 48, height: 48)
                    .foregroundStyle(OceanKeyTheme.secondaryText)
                    .background(OceanKeyTheme.surface.opacity(0.82))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            Text("Настройки")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.74)
        }
    }

    @ViewBuilder
    private var selectedCategoryContent: some View {
        switch selectedCategory {
        case .appearance:
            appearanceSection
            settingsSection
        case .background:
            backgroundSection
        case .workflow:
            workSection
        case .developer:
            experimentalSection
            developerSection
        }
    }

    private var experimentalSection: some View {
        SettingsPanel(
            title: "Экспериментальное",
            subtitle: "Только активные режимы, которые можно реально оценить на основном экране."
        ) {
            Toggle(isOn: $appSettings.developerCellPhysicsEnabled) {
                SettingsInfoRow(
                    title: "Живые ячейки",
                    value: appSettings.developerCellPhysicsEnabled ? "Вкл" : "Выкл",
                    systemName: "waveform.path",
                    subtitle: "Пружинящий отклик ячеек на изменения статуса, задач и VIP."
                )
            }
            .tint(OceanKeyTheme.accent)
            .onChange(of: appSettings.developerCellPhysicsEnabled) { _, _ in
                feedback.confirm()
            }

            if appSettings.developerCellPhysicsEnabled {
                SettingsSliderRow(
                    title: "Сила пружины",
                    valueLabel: "\(Int((appSettings.developerCellSpringIntensity * 100).rounded()))%",
                    systemName: "arrow.up.and.down.and.arrow.left.and.right",
                    range: 0...1,
                    defaultValue: 0.72,
                    value: $appSettings.developerCellSpringIntensity
                )
                SettingsSliderRow(
                    title: "Скорость пружины",
                    valueLabel: "\(String(format: "%.2f", appSettings.developerCellSpringSpeed))x",
                    systemName: "speedometer",
                    range: 0.2...1.6,
                    defaultValue: 0.82,
                    value: $appSettings.developerCellSpringSpeed
                )
            }

            Toggle(isOn: $appSettings.developerCellTVStaticEnabled) {
                SettingsInfoRow(
                    title: "TV-шум в ячейках",
                    value: appSettings.developerCellTVStaticEnabled ? "Вкл" : "Выкл",
                    systemName: "tv.fill",
                    subtitle: "Цветной шум сломанного телевизора внутри каждой ячейки по её статусу."
                )
            }
            .tint(OceanKeyTheme.accent)
            .onChange(of: appSettings.developerCellTVStaticEnabled) { _, _ in
                feedback.confirm()
            }

            SettingsSliderRow(
                title: "VIP-зебра",
                valueLabel: "\(Int((appSettings.developerVIPZebraIntensity * 100).rounded()))%",
                systemName: "line.3.horizontal.decrease.circle.fill",
                range: 0...1,
                defaultValue: 0.86,
                value: $appSettings.developerVIPZebraIntensity
            )
            SettingsSliderRow(
                title: "Скорость VIP",
                valueLabel: "\(String(format: "%.2f", appSettings.developerVIPZebraSpeed))x",
                systemName: "speedometer",
                range: 0.2...1.8,
                defaultValue: 0.78,
                value: $appSettings.developerVIPZebraSpeed
            )
            SettingsSliderRow(
                title: "Резкость VIP",
                valueLabel: "\(Int((appSettings.developerVIPZebraSharpness * 100).rounded()))%",
                systemName: "slider.horizontal.2.square.on.square",
                range: 0...1,
                defaultValue: 0.62,
                value: $appSettings.developerVIPZebraSharpness
            )
        }
    }

    private var developerSection: some View {
        SettingsPanel(
            title: "Разработчик",
            subtitle: "Только служебный build changelog. Остальная диагностика не смешивается с настройками."
        ) {
            Button(action: openChangelog) {
                SettingsInfoRow(
                    title: "Версия \(AppBuildInfo.versionLabel)",
                    value: "Изменения",
                    systemName: "list.bullet.clipboard.fill",
                    subtitle: "Короткая выжимка по последним билдам."
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var appearanceSection: some View {
        SettingsPanel(
            title: "Внешний вид",
            subtitle: "Размер ячеек, палитра статусов и жесты задач на основном экране."
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Picker("Размер ячеек", selection: $appSettings.roomCellGeometry) {
                    ForEach(RoomCellGeometry.allCases) { geometry in
                        Text(geometry.title).tag(geometry)
                    }
                }
                .pickerStyle(.segmented)

                SettingsInfoRow(
                    title: "Ячейки",
                    value: appSettings.roomCellGeometry.description,
                    systemName: "rectangle.roundedtop.fill",
                    subtitle: "Можно оставить просторный размер или вернуться ближе к компактному виду."
                )

                Toggle(isOn: $appSettings.vividStatusPaletteEnabled) {
                    SettingsInfoRow(
                        title: "Сочная палитра",
                        value: appSettings.vividStatusPaletteEnabled ? "Скриншот" : "Обычная",
                        systemName: "paintpalette.fill",
                        subtitle: "Второй режим фиксирует яркие цвета ячеек как на твоём скриншоте."
                    )
                }
                .tint(OceanKeyTheme.accent)
                .onChange(of: appSettings.vividStatusPaletteEnabled) { _, _ in
                    feedback.confirm()
                }

                Toggle(isOn: $appSettings.roomTaskLongPress) {
                    SettingsInfoRow(
                        title: "Долгий тап",
                        value: appSettings.roomTaskLongPress ? "Включен" : "Быстрый",
                        systemName: "hand.tap.fill",
                        subtitle: "Защищает S, L, B от случайных касаний во время скролла."
                    )
                }
                .tint(OceanKeyTheme.accent)
                .onChange(of: appSettings.roomTaskLongPress) { _, _ in
                    feedback.confirm()
                }
            }
        }
    }

    private var backgroundSection: some View {
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
            .onChange(of: appSettings.appBackgroundMode) { _, _ in
                feedback.confirm()
            }

            SettingsInfoRow(
                title: "Заставка",
                value: appSettings.appBackgroundMode.description,
                systemName: "grid",
                subtitle: backgroundModeSubtitle
            )
            if appSettings.appBackgroundMode == .matrixRain {
                SettingsSliderRow(
                    title: "Скорость",
                    valueLabel: "\(String(format: "%.2f", appSettings.matrixSpeed))x",
                    systemName: "speedometer",
                    range: 0.08...3.0,
                    defaultValue: MatrixRainConfiguration.default.speed,
                    value: $appSettings.matrixSpeed
                )
            }
            if appSettings.appBackgroundMode == .video {
                videoBackgroundControls
            }
        }
    }

    private var backgroundModeSubtitle: String {
        switch appSettings.appBackgroundMode {
        case .off:
            "Фон отключён, основной экран остаётся чёрным."
        case .matrixRain:
            "Matrix Rain как основной живой фон."
        case .tvStaticNoise:
            "ShaderKit Dynamic Gray Noise: аналоговый телевизионный снег как основной фон."
        case .video:
            "Видео хранится только локально на устройстве."
        }
    }

    private var videoBackgroundControls: some View {
        let videoStatus = appSettings.backgroundVideoRelativePath == nil ? "Выбрать" : "Выбрано"

        return VStack(alignment: .leading, spacing: 12) {
            PhotosPicker(
                selection: $selectedBackgroundVideoItem,
                matching: .videos,
                photoLibrary: .shared()
            ) {
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

    private var workSection: some View {
        SettingsPanel(
            title: "Работа",
            subtitle: "Поведение раздвижного меню ячейки и рабочие жесты на основном экране."
        ) {
            SettingsInfoRow(
                title: "Синхронизация Apple",
                value: appleSyncStatus.statusLabel,
                systemName: appleSyncStatus.isCloudActive ? "icloud.fill" : "externaldrive.fill",
                subtitle: appleSyncStatus.detailsLabel
            )

            Toggle(isOn: $appSettings.summaryActionMenuAllowsMultiple) {
                SettingsInfoRow(
                    title: "Мульти-меню",
                    value: appSettings.summaryActionMenuAllowsMultiple ? "Несколько" : "Одно",
                    systemName: "rectangle.stack.fill",
                    subtitle: "По умолчанию открыто только одно меню ячейки; этот режим разрешает несколько."
                )
            }
            .tint(OceanKeyTheme.accent)
            .onChange(of: appSettings.summaryActionMenuAllowsMultiple) { _, _ in
                feedback.confirm()
            }
        }
    }

    private var settingsSection: some View {
        SettingsPanel(
            title: "Сброс",
            subtitle: "Вернуть визуальные и рабочие параметры к значениям по умолчанию."
        ) {
            Button(action: confirmResetSettings) {
                SettingsInfoRow(
                    title: "Сброс настроек",
                    value: "По умолчанию",
                    systemName: "arrow.counterclockwise.circle.fill",
                    subtitle: "Не удаляет рабочую смену, но сбрасывает внешний вид и режимы."
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func openChangelog() {
        feedback.tap()
        isChangelogPresented = true
    }

    private func confirmResetSettings() {
        feedback.tap()
        isResetConfirmationPresented = true
    }

    private func resetSettings() {
        feedback.confirm()
        appSettings.resetToDefaults()
    }

    @MainActor
    private func importBackgroundVideo(_ item: PhotosPickerItem) async {
        do {
            guard let pickedVideo = try await item.loadTransferable(type: PickedBackgroundVideo.self) else { return }
            let relativePath = try BackgroundVideoFileStore().saveVideo(from: pickedVideo.url)
            appSettings.backgroundVideoRelativePath = relativePath
            appSettings.appBackgroundMode = .video
            feedback.confirm()
        } catch {
            feedback.holdWarning()
        }
    }
}

#Preview {
    SettingsScreen(
        appSettings: AppSettingsStore()
    )
        .preferredColorScheme(.dark)
}
