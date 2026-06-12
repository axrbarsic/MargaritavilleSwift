import Foundation
import Testing
@testable import MargaritavilleSwift

@Test
func mergeKeepsNewerLocalRoomFieldsAgainstStaleRemote() {
    let old = Date(timeIntervalSince1970: 1_801_000_000)
    let new = Date(timeIntervalSince1970: 1_801_100_000)
    let local = mergeTestSnapshot(
        room: RoomCell(
            id: "303",
            opened: true,
            openedUpdatedAt: new,
            completedTasks: [],
            strippedUpdatedAt: new,
            isVIP: true,
            vipUpdatedAt: new,
            scheduledTime: nil,
            scheduledUpdatedAt: new,
            timeline: RoomTimeline(openedAt: old, strippedAt: old)
        ),
        selectedRooms: ["303"],
        selectionMetadata: ["303": new],
        updatedAt: new
    )
    let remote = mergeTestSnapshot(
        room: RoomCell(
            id: "303",
            opened: false,
            openedUpdatedAt: old,
            completedTasks: [.stripped],
            strippedUpdatedAt: old,
            isVIP: false,
            vipUpdatedAt: old,
            scheduledTime: Date(timeIntervalSince1970: 1_801_200_000),
            scheduledUpdatedAt: old,
            timeline: RoomTimeline(openedAt: new, strippedAt: new)
        ),
        selectedRooms: ["303"],
        selectionMetadata: ["303": old],
        updatedAt: old
    )

    let merged = WorkSessionMergePolicy.merged(local: local, remote: remote)
    let room = merged.carts.first?.rooms.first

    #expect(room?.opened == true)
    #expect(room?.completedTasks.isEmpty == true)
    #expect(room?.isVIP == true)
    #expect(room?.scheduledTime == nil)
    #expect(room?.timeline.openedAt == old)
    #expect(room?.timeline.strippedAt == old)
}

@Test
func mergeAppliesNewerRemoteRoomDeselectionTombstone() {
    let old = Date(timeIntervalSince1970: 1_801_000_000)
    let new = Date(timeIntervalSince1970: 1_801_100_000)
    let local = mergeTestSnapshot(
        room: RoomCell(id: "303", opened: false, completedTasks: [], isVIP: false),
        selectedRooms: ["303"],
        selectionMetadata: ["303": old],
        updatedAt: old
    )
    let remote = mergeTestSnapshot(
        room: RoomCell(id: "303", opened: false, completedTasks: [], isVIP: false),
        selectedRooms: [],
        selectionMetadata: ["303": new],
        updatedAt: new
    )

    let merged = WorkSessionMergePolicy.merged(local: local, remote: remote)

    #expect(!merged.selection.rooms(forCart: 7).contains("303"))
    #expect(merged.selection.roomSelectionUpdatedAt[7]?["303"] == new)
    #expect(merged.carts.first?.rooms.isEmpty == true)
}

@Test
func mergeUnionsHistoryEntriesByID() {
    let localEntry = mergeHistoryEntry(id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!)
    let remoteEntry = mergeHistoryEntry(id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!)
    var local = mergeTestSnapshot(
        room: RoomCell(id: "303", opened: false, completedTasks: [], isVIP: false),
        selectedRooms: ["303"],
        selectionMetadata: [:],
        updatedAt: Date(timeIntervalSince1970: 1_801_000_000)
    )
    var remote = local
    local.history = [localEntry]
    remote.history = [remoteEntry]

    let merged = WorkSessionMergePolicy.merged(local: local, remote: remote)

    #expect(Set(merged.history.map(\.id)) == [localEntry.id, remoteEntry.id])
}

private func mergeTestSnapshot(
    room: RoomCell,
    selectedRooms: Set<RoomID>,
    selectionMetadata: [RoomID: Date],
    updatedAt: Date
) -> WorkSessionSnapshot {
    let cartBindingAt = Date(timeIntervalSince1970: 1_800_900_000)
    return WorkSessionSnapshot(
        selection: WorkSessionSelectionState(
            cartBindings: [
                7: WorkSessionCartBinding(cartNumber: 7, territoryID: "A3")
            ],
            cartBindingUpdatedAt: [
                7: cartBindingAt
            ],
            cartRoomSelections: [
                7: selectedRooms
            ],
            roomSelectionUpdatedAt: [
                7: selectionMetadata
            ],
            workdayLocked: true,
            workdayLockUpdatedAt: cartBindingAt
        ),
        carts: [
            CartSection(id: 7, building: "A3", rooms: [room])
        ],
        updatedAt: updatedAt
    )
}

private func mergeHistoryEntry(id: UUID) -> WorkSessionHistoryEntry {
    WorkSessionHistoryEntry(
        id: id,
        happenedAt: Date(timeIntervalSince1970: 1_801_000_000),
        kind: .selectionChanged,
        title: "selection",
        snapshot: WorkSessionHistorySnapshot(
            carts: [],
            counts: SummaryCounts(total: 0, completed: 0, remaining: 0)
        )
    )
}
