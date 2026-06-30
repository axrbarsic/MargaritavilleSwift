import SwiftUI

struct SettingsSoundSection: View {
    @Bindable var appSettings: AppSettingsStore
    @Environment(\.interactionFeedback) private var feedback

    var body: some View {
        SettingsPanel(
            title: "Звуки",
            subtitle: "Три назначения: общий интерфейс, ячейка и финальная зелёная ячейка."
        ) {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(InteractionSoundEvent.settingsVisibleCases) { event in
                    soundRow(for: event)
                }
            }
        }
    }

    private func soundRow(for event: InteractionSoundEvent) -> some View {
        let asset = appSettings.interactionSoundAssignments.asset(for: event)
        return HStack(spacing: 10) {
            Menu {
                ForEach(InteractionSoundAsset.settingsPickerAssets(current: asset)) { candidate in
                    Button {
                        select(candidate, for: event)
                    } label: {
                        Label(candidate.title, systemImage: candidate == asset ? "checkmark" : "speaker.wave.2.fill")
                    }
                }
            } label: {
                SettingsInfoRow(
                    title: event.title,
                    value: asset.title,
                    systemName: "speaker.wave.2.fill",
                    subtitle: event.settingsSubtitle
                )
            }
            .buttonStyle(.plain)

            Button {
                feedback.previewSound(asset)
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 16, weight: .black))
                    .frame(width: 44, height: 44)
                    .foregroundStyle(OceanKeyTheme.accent)
                    .background(OceanKeyTheme.surface.opacity(0.84))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(OceanKeyTheme.accent.opacity(0.18), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Прослушать \(asset.title)")
        }
    }

    private func select(_ asset: InteractionSoundAsset, for event: InteractionSoundEvent) {
        var assignments = appSettings.interactionSoundAssignments
        assignments.set(asset, for: event)
        appSettings.interactionSoundAssignments = assignments
        feedback.previewSound(asset)
    }
}
