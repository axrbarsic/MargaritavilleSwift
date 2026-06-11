import SwiftUI

struct SettingsWorkSection: View {
    @Bindable var appSettings: AppSettingsStore
    @Bindable var workSession: WorkSessionStore
    let activeHotel: HotelProfile
    let appleSyncStatus: AppleSyncStatus
    let onPendingHotelSelection: (HotelProfile) -> Void
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

            hotelPicker

            if activeHotel.id == HotelProfile.margaritaville.id {
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

    private var hotelPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            SettingsInfoRow(
                title: "Отель",
                value: activeHotel.name,
                systemName: "building.2.fill",
                subtitle: "Переключение открывает отдельную рабочую базу выбранного отеля."
            )

            HStack(spacing: 10) {
                ForEach(HotelProfile.all) { profile in
                    Button {
                        guard profile.id != activeHotel.id else { return }
                        feedback.confirm()
                        onPendingHotelSelection(profile)
                    } label: {
                        Text(profile.name)
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .foregroundStyle(profile.id == activeHotel.id ? OceanKeyTheme.roomForeground : .white)
                            .background(profile.id == activeHotel.id ? OceanKeyTheme.accent : .black.opacity(0.20))
                            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
