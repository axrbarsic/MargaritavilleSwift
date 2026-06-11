import Foundation

struct MargaritavilleSummaryRoomGroup: Equatable, Identifiable {
    let id: String
    let label: String
    let rooms: [RoomCell]
}

enum MargaritavilleSummaryRoomGrouping {
    static func groups(
        rooms: [RoomCell],
        territories: [Territory],
        fallbackLabel: String
    ) -> [MargaritavilleSummaryRoomGroup] {
        var grouped: [MargaritavilleSummaryRoomGroup] = []
        var groupedRoomIDs = Set<RoomID>()

        for territory in territories {
            let territoryRoomIDs = Set(territory.rooms)
            let groupRooms = rooms
                .filter { territoryRoomIDs.contains($0.id) }
                .sorted { RoomCatalog.compareRoomIDs($0.id, $1.id) }
            guard !groupRooms.isEmpty else { continue }
            groupedRoomIDs.formUnion(groupRooms.map(\.id))
            grouped.append(
                MargaritavilleSummaryRoomGroup(
                    id: territory.id,
                    label: territory.label,
                    rooms: groupRooms
                )
            )
        }

        let fallbackRooms = rooms
            .filter { !groupedRoomIDs.contains($0.id) }
            .sorted { RoomCatalog.compareRoomIDs($0.id, $1.id) }
        if !fallbackRooms.isEmpty {
            grouped.append(
                MargaritavilleSummaryRoomGroup(
                    id: "fallback-\(fallbackLabel)",
                    label: fallbackLabel,
                    rooms: fallbackRooms
                )
            )
        }

        return grouped
    }
}
