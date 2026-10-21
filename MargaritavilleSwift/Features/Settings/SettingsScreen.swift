import SwiftUI

struct SettingsScreen: View {
    @Bindable var workSession: WorkSessionStore
    @Bindable var appSettings: AppSettingsStore
    @Bindable var aiVisualPresetStore: AIVisualPresetStore
    let activeHotel: HotelProfile
    let onSelectHotel: (HotelProfile) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.interactionFeedback) private var feedback
    @Environment(\.appleSyncStatus) private var appleSyncStatus
    @State private var selectedCategory: SettingsCategory = .appearance
    @State private var isChangelogPresented = false
    @State private var isResetConfirmationPresented = false
    @State private var isCellTypographyLabPresented = false

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
        .fullScreenCover(isPresented: $isCellTypographyLabPresented) {
            CellTypographyLabScreen(
                geometry: appSettings.roomCellGeometry,
                gridColumnCount: appSettings.margaritavilleGridColumnCount,
                statusPaletteSaturation: appSettings.statusPaletteSaturation
            )
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
            SettingsSoundSection(appSettings: appSettings)
            settingsSection
        case .background:
            SettingsBackgroundSection(appSettings: appSettings)
        case .workflow:
            SettingsWorkSection(
                appSettings: appSettings,
                workSession: workSession,
                activeHotel: activeHotel,
                appleSyncStatus: appleSyncStatus
            )
        case .developer:
            experimentalSection
            SettingsTestDataSection(
                workSession: workSession,
                housekeepers: appSettings.housekeepers
            )
            deepSeekLabSection
            developerSection
        }
    }

    private var experimentalSection: some View {
        SettingsPanel(
            title: "Экспериментальное",
            subtitle: "Только активные режимы, которые можно реально оценить на основном экране."
        ) {
            Toggle(isOn: $appSettings.developerLive3DCellsEnabled) {
                SettingsInfoRow(
                    title: "Живые 3D-ячейки",
                    value: appSettings.developerLive3DCellsEnabled ? "Вкл" : "Выкл",
                    systemName: "cube.transparent.fill",
                    subtitle: "Экспериментальный Metal-рендер тела ячеек. Текст и все действия остаются обычным интерфейсом."
                )
            }
            .tint(OceanKeyTheme.accent)
            .onChange(of: appSettings.developerLive3DCellsEnabled) { _, _ in
                feedback.confirm()
            }
            .accessibilityIdentifier("settings.experimental.live3DCells")

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

            Button(action: openCellTypographyLab) {
                SettingsInfoRow(
                    title: "Типографика ячеек",
                    value: "Стенд",
                    systemName: "textformat.size",
                    subtitle: "Живой preview production-ячеек с отдельными настройками номера и времени."
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("settings.experimental.cellTypographyLab")

            Toggle(isOn: $appSettings.developerVIPJellyEnabled) {
                SettingsInfoRow(
                    title: "VIP-желе",
                    value: appSettings.developerVIPJellyEnabled ? "Вкл" : "Выкл",
                    systemName: "water.waves",
                    subtitle: "Живая форма VIP-ячейки: двигается сам контур, а не внутренняя линия."
                )
            }
            .tint(OceanKeyTheme.accent)
            .onChange(of: appSettings.developerVIPJellyEnabled) { _, _ in
                feedback.confirm()
            }

            if appSettings.developerVIPJellyEnabled {
                SettingsSliderRow(
                    title: "Скорость желе",
                    valueLabel: "\(String(format: "%.2f", appSettings.developerVIPJellySpeed))x",
                    systemName: "speedometer",
                    range: 0.2...2.5,
                    defaultValue: 0.75,
                    value: $appSettings.developerVIPJellySpeed
                )
            }

            Toggle(isOn: $appSettings.developerVIPHDREnabled) {
                SettingsInfoRow(
                    title: "VIP HDR-свет",
                    value: appSettings.developerVIPHDREnabled ? "Вкл" : "Выкл",
                    systemName: "sun.max.fill",
                    subtitle: "VIP-ячейка просит EDR/HDR headroom и светится отдельно от общей яркости интерфейса."
                )
            }
            .tint(OceanKeyTheme.accent)
            .onChange(of: appSettings.developerVIPHDREnabled) { _, _ in
                feedback.confirm()
            }

            Toggle(isOn: $appSettings.developerStatusHDRPulseEnabled) {
                SettingsInfoRow(
                    title: "HDR-всплеск статуса",
                    value: appSettings.developerStatusHDRPulseEnabled ? "Вкл" : "Выкл",
                    systemName: "bolt.fill",
                    subtitle: "После смены статуса ячейка разгорается и две секунды плавно остывает из максимальной HDR-яркости нового цвета."
                )
            }
            .tint(OceanKeyTheme.accent)
            .onChange(of: appSettings.developerStatusHDRPulseEnabled) { _, _ in
                feedback.confirm()
            }
        }
    }

    private var deepSeekLabSection: some View {
        DeepSeekLabSection(
            presetStore: aiVisualPresetStore,
            appSettings: appSettings,
            modelTier: $appSettings.deepSeekModelTier
        )
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
                    subtitle: "Стандартный режим меняет статус удержанием, расширенный увеличивает комнату почти на весь экран."
                )

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Ячеек в ряду")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                        Spacer()
                        Text("\(appSettings.margaritavilleGridColumnCount.rawValue)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(OceanKeyTheme.secondaryText)
                    }

                    Picker("Ячеек в ряду", selection: $appSettings.margaritavilleGridColumnCount) {
                        ForEach(MargaritavilleGridColumnCount.allCases) { count in
                            Text(count.title).tag(count)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text("Меняет только число production-ячеек в строке главного экрана и стенда.")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(OceanKeyTheme.secondaryText.opacity(0.82))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(OceanKeyTheme.surface.opacity(0.84))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .onChange(of: appSettings.margaritavilleGridColumnCount) { _, _ in
                    feedback.confirm()
                }

                Toggle(isOn: $appSettings.transparentSurfacesEnabled) {
                    SettingsInfoRow(
                        title: "Прозрачные панели",
                        value: appSettings.transparentSurfacesEnabled ? "AWS26" : "Обычные",
                        systemName: "square.3.layers.3d.down.right",
                        subtitle: "Ослабляет плотный чёрный фон у общих панелей, карточек и окон поверх живого фона."
                    )
                }
                .tint(OceanKeyTheme.accent)
                .onChange(of: appSettings.transparentSurfacesEnabled) { _, _ in
                    feedback.confirm()
                }

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

    private func openCellTypographyLab() {
        feedback.tap()
        isCellTypographyLabPresented = true
    }

    private func confirmResetSettings() {
        feedback.tap()
        isResetConfirmationPresented = true
    }

    private func resetSettings() {
        feedback.confirm()
        appSettings.resetToDefaults()
    }

}

#Preview {
    SettingsScreen(
        workSession: .preview(),
        appSettings: AppSettingsStore(),
        aiVisualPresetStore: try! AIVisualPresetStore(inMemory: true),
        activeHotel: .current,
        onSelectHotel: { _ in }
    )
        .preferredColorScheme(.dark)
}
