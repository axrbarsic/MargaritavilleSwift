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
