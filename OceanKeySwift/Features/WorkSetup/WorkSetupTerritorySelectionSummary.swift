import SwiftUI

struct WorkSetupTerritorySelectionGroup: Identifiable, Equatable {
    let territoryID: String
    let territoryLabel: String
    let rooms: [RoomID]

    var id: String { territoryID }

    init(territory: Territory, rooms: [RoomID]) {
        territoryID = territory.id
        territoryLabel = territory.label
        self.rooms = rooms.sorted(by: RoomCatalog.compareRoomIDs)
    }
}

struct WorkSetupTerritorySelectionSummary: View {
    let groups: [WorkSetupTerritorySelectionGroup]

    var body: some View {
        if !groups.isEmpty {
            VStack(alignment: .leading, spacing: 7) {
                Text("Уже выбрано в других зонах")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(OceanKeyTheme.secondaryText)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(groups) { group in
                            groupChip(group)
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func groupChip(_ group: WorkSetupTerritorySelectionGroup) -> some View {
        HStack(spacing: 7) {
            Text(group.territoryLabel)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(OceanKeyTheme.roomForeground)
                .padding(.horizontal, 7)
                .frame(height: 24)
                .background(OceanKeyTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(previewText(for: group.rooms))
                .font(.system(size: 13, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 9)
        .frame(height: 36)
        .background(Color.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(OceanKeyTheme.accent.opacity(0.22), lineWidth: 1)
        }
    }

    private func previewText(for rooms: [RoomID]) -> String {
        let visibleRooms = Array(rooms.prefix(3))
        let visible = visibleRooms
            .map { RoomCatalog.displayRoomID($0, compactLetteredLabels: true) }
            .joined(separator: ", ")
        let hiddenCount = rooms.count - visibleRooms.count
        return hiddenCount > 0 ? "\(visible) +\(hiddenCount)" : visible
    }
}
