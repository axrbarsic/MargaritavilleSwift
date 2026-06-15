import SwiftUI

struct TerritoryPicker: View {
    let territory: Territory
    let territories: [Territory]
    let onChanged: (Territory) -> Void

    private var buildings: [Building] {
        Array(Set(territories.map(\.building))).sorted { $0.label < $1.label }
    }

    private var floors: [Int] {
        Array(Set(territories.map(\.floor))).sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 10) {
                pickerLabel("Здание")
                ForEach(buildings, id: \.self) { building in
                    pickerChip(
                        building.label,
                        selected: territory.building == building,
                        action: { update(building: building, floor: territory.floor) }
                    )
                }
            }

            HStack(spacing: 10) {
                pickerLabel("Этаж")
                ForEach(floors, id: \.self) { floor in
                    pickerChip(
                        "\(floor)",
                        selected: territory.floor == floor,
                        action: { update(building: territory.building, floor: floor) }
                    )
                }
            }
        }
    }

    private func pickerLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .black, design: .rounded))
            .foregroundStyle(OceanKeyTheme.secondaryText)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .frame(width: 70, alignment: .leading)
    }

    private func update(building: Building, floor: Int) {
        if let next = territories.first(where: { $0.building == building && $0.floor == floor }) {
            onChanged(next)
        }
    }

    private func pickerChip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        HoldActionTarget(
            enabled: true,
            useLongPress: true,
            semanticLabel: title,
            onActivate: action
        ) {
            Text(title)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.74)
                .frame(maxWidth: .infinity)
                .frame(height: 62)
                .foregroundStyle(selected ? OceanKeyTheme.roomForeground : .white)
                .background(selected ? OceanKeyTheme.accent : OceanKeyTheme.surface.opacity(0.58))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(selected ? .white.opacity(0.72) : OceanKeyTheme.accent.opacity(0.18), lineWidth: 1.2)
                }
        }
    }
}
