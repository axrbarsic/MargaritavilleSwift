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
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                ForEach(buildings, id: \.self) { building in
                    pickerChip(
                        building.label,
                        selected: territory.building == building,
                        action: { update(building: building, floor: territory.floor) }
                    )
                }
            }

            HStack(spacing: 8) {
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

    private func update(building: Building, floor: Int) {
        if let next = territories.first(where: { $0.building == building && $0.floor == floor }) {
            onChanged(next)
        }
    }

    private func pickerChip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .frame(minWidth: 46)
                .padding(.vertical, 10)
                .foregroundStyle(selected ? OceanKeyTheme.roomForeground : .white)
                .background(selected ? OceanKeyTheme.accent : .black.opacity(0.16))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
