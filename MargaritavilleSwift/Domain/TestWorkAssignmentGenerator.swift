import Foundation

struct TestWorkAssignmentSummary: Equatable, Sendable {
    let housekeeperCount: Int
    let roomCount: Int
}

enum TestWorkAssignmentGenerator {
    static func makeSelection<R: RandomNumberGenerator>(
        territories: [Territory],
        housekeeperIDs: [HousekeeperID],
        preservingLockFrom current: WorkSessionSelectionState,
        changedAt: Date,
        using generator: inout R
    ) -> (selection: WorkSessionSelectionState, summary: TestWorkAssignmentSummary)? {
        var rooms = Array(Set(territories.flatMap(\.rooms)))
        var housekeepers = uniqueHousekeeperIDs(housekeeperIDs)
        guard !rooms.isEmpty, !housekeepers.isEmpty else { return nil }

        rooms.shuffle(using: &generator)
        housekeepers.shuffle(using: &generator)
        let activeHousekeepers = Array(
            housekeepers.prefix(min(rooms.count, WorkSessionSelectionRules.cartRange.count))
        )

        var roomBuckets = Array(repeating: Set<RoomID>(), count: activeHousekeepers.count)
        for (index, room) in rooms.enumerated() {
            roomBuckets[index % activeHousekeepers.count].insert(room)
        }

        let territoryByRoom = Dictionary(
            uniqueKeysWithValues: territories.flatMap { territory in
                territory.rooms.map { ($0, territory) }
            }
        )
        var selection = WorkSessionSelectionState()
        selection.workdayLocked = current.workdayLocked
        selection.workdayLockUpdatedAt = current.workdayLockUpdatedAt

        for (index, housekeeperID) in activeHousekeepers.enumerated() {
            let cartNumber = WorkSessionSelectionRules.cartRange.lowerBound + index
            let assignedRooms = roomBuckets[index]
            guard let firstRoom = assignedRooms.sorted(by: RoomCatalog.compareRoomIDs).first,
                  let territory = territoryByRoom[firstRoom]
            else {
                continue
            }

            selection.cartBindings[cartNumber] = WorkSessionCartBinding(
                cartNumber: cartNumber,
                territoryID: territory.id
            )
            selection.cartBindingUpdatedAt[cartNumber] = changedAt
            selection.cartHousekeeperIDs[cartNumber] = housekeeperID
            selection.cartHousekeeperUpdatedAt[cartNumber] = changedAt
            selection.cartRoomSelections[cartNumber] = assignedRooms
            selection.roomSelectionUpdatedAt[cartNumber] = Dictionary(
                uniqueKeysWithValues: assignedRooms.map { ($0, changedAt) }
            )
        }

        return (
            selection,
            TestWorkAssignmentSummary(
                housekeeperCount: activeHousekeepers.count,
                roomCount: rooms.count
            )
        )
    }

    private static func uniqueHousekeeperIDs(_ values: [HousekeeperID]) -> [HousekeeperID] {
        var seen: Set<HousekeeperID> = []
        return values.compactMap { value in
            guard let id = MargaritavilleHousekeeperCatalog.normalizedID(value),
                  seen.insert(id).inserted
            else {
                return nil
            }
            return id
        }
    }
}
