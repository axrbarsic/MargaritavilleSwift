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
        VStack(alignment: .leading, spacing: 12) {
            Text("Секция")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(OceanKeyTheme.secondaryText)

            HStack(spacing: 10) {
                ForEach(buildings, id: \.self) { building in
                    pickerChip(
                        "Секция \(building.label)",
                        selected: territory.building == building,
                        action: { update(building: building, floor: territory.floor) }
                    )
                }
            }

            Text("Этаж")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(OceanKeyTheme.secondaryText)
                .padding(.top, 2)

            HStack(spacing: 10) {
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
                .font(.system(size: 19, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.74)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .foregroundStyle(selected ? OceanKeyTheme.roomForeground : .white)
                .background(selected ? OceanKeyTheme.accent : OceanKeyTheme.surface.opacity(0.58))
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(selected ? .white.opacity(0.72) : OceanKeyTheme.accent.opacity(0.18), lineWidth: 1.2)
                }
        }
        .buttonStyle(.plain)
    }
}
