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
    @State private var pendingHotelSelection: HotelProfile?

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
        .confirmationDialog(
            "Переключить отель?",
            isPresented: hotelSwitchConfirmationBinding,
            titleVisibility: .visible,
            presenting: pendingHotelSelection
        ) { profile in
            Button("Открыть \(profile.name)", role: .destructive) {
                applyHotelSelection(profile)
            }
            Button("Отмена", role: .cancel) {
                pendingHotelSelection = nil
            }
        } message: { profile in
            Text("Текущая рабочая база будет закрыта, а данные \(profile.name) откроются из отдельного хранилища.")
        }
    }

    private var hotelSwitchConfirmationBinding: Binding<Bool> {
        Binding(
            get: { pendingHotelSelection != nil },
            set: { isPresented in
                if !isPresented {
                    pendingHotelSelection = nil
                }
            }
        )
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
            SettingsBackgroundSection(appSettings: appSettings)
        case .workflow:
            SettingsWorkSection(
                appSettings: appSettings,
                workSession: workSession,
                activeHotel: activeHotel,
                appleSyncStatus: appleSyncStatus,
                onPendingHotelSelection: { pendingHotelSelection = $0 }
            )
        case .developer:
            experimentalSection
            deepSeekLabSection
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

    private func applyHotelSelection(_ profile: HotelProfile) {
        feedback.confirm()
        onSelectHotel(profile)
        pendingHotelSelection = nil
        dismiss()
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
