import Foundation

enum SummaryActionMenuExpansion {
    static func toggled(
        roomID: RoomCell.ID,
        in expandedRoomIDs: Set<RoomCell.ID>,
        allowsMultiple: Bool
    ) -> Set<RoomCell.ID> {
        if expandedRoomIDs.contains(roomID) {
            return expandedRoomIDs.subtracting([roomID])
        }

        if allowsMultiple {
            return expandedRoomIDs.union([roomID])
        }

        return [roomID]
    }

    static func normalized(
        _ expandedRoomIDs: Set<RoomCell.ID>,
        allowsMultiple: Bool
    ) -> Set<RoomCell.ID> {
        guard !allowsMultiple, expandedRoomIDs.count > 1 else { return expandedRoomIDs }
        guard let firstRoomID = expandedRoomIDs.sorted().first else { return [] }
        return [firstRoomID]
    }
}
