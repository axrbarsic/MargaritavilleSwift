import SwiftUI

struct SavedCellTypographyPresetPanel: View {
    let preset: SavedCellTypographyPreset
    let copied: Bool
    let onCopy: () -> Void
    let onDelete: () -> Void

    var body: some View {
        SettingsPanel(
            title: "Сохранённый пресет",
            subtitle: "Сохранено \(Self.timestampFormatter.string(from: preset.savedAt))"
        ) {
            valueGroup(
                title: "Основной номер",
                size: preset.typography.roomNumberSize,
                weight: preset.typography.roomNumberWeight,
                offset: preset.typography.roomNumberVerticalOffset
            )
            valueGroup(
                title: "Время активации",
                size: preset.typography.activationTimeSize,
                weight: preset.typography.activationTimeWeight,
                offset: preset.typography.activationTimeVerticalOffset
            )

            Button(action: onCopy) {
                Label(copied ? "Пресет скопирован" : "Скопировать пресет", systemImage: copied ? "checkmark" : "doc.on.doc.fill")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .foregroundStyle(.white)
                    .background(OceanKeyTheme.surface.opacity(0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("cellTypographyLab.copy")

            Button(role: .destructive, action: onDelete) {
                Label("Удалить сохранённый пресет", systemImage: "trash.fill")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity, minHeight: 46)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("cellTypographyLab.delete")
        }
    }

    private func valueGroup(
        title: String,
        size: Double,
        weight: RoomCellTypographyWeight,
        offset: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
            valueRow("Размер", value: "\(Int(size.rounded())) pt")
            valueRow("Толщина", value: weight.title)
            valueRow("Смещение Y", value: signedPoints(offset))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OceanKeyTheme.surface.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func valueRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(OceanKeyTheme.secondaryText)
            Spacer(minLength: 10)
            Text(value).fontWeight(.bold)
        }
        .font(.system(size: 14, design: .rounded))
    }

    private func signedPoints(_ value: Double) -> String {
        let rounded = Int(value.rounded())
        return rounded > 0 ? "+\(rounded) pt" : "\(rounded) pt"
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "dd.MM.yyyy HH:mm:ss zzz"
        return formatter
    }()
}
