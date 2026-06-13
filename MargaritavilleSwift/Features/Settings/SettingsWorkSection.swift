import SwiftUI

struct SettingsWorkSection: View {
    @Bindable var appSettings: AppSettingsStore
    @Bindable var workSession: WorkSessionStore
    let activeHotel: HotelProfile
    let appleSyncStatus: AppleSyncStatus
    @Environment(\.interactionFeedback) private var feedback

    var body: some View {
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

            if activeHotel.id == HotelProfile.margaritaville.id {
                VStack(alignment: .leading, spacing: 8) {
                    SettingsInfoRow(
                        title: "Меню уборщицы",
                        value: appSettings.housekeeperDetailsGestureMode.settingsValue,
                        systemName: "hand.tap.fill",
                        subtitle: "Как открывать голос, медиа и расходники по имени на основном экране."
                    )
                    Picker("Меню уборщицы", selection: $appSettings.housekeeperDetailsGestureMode) {
                        ForEach(HousekeeperDetailsGestureMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: appSettings.housekeeperDetailsGestureMode) { _, _ in
                        feedback.confirm()
                    }
                }

                HousekeeperCatalogEditorSection(
                    appSettings: appSettings,
                    workSession: workSession
                )
                CartConsumableCatalogEditorSection(appSettings: appSettings)
                MargaritavilleCatalogEditorSection(workSession: workSession)
            }

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
}
