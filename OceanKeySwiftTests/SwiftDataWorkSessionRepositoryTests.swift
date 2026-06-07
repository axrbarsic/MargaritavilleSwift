import Foundation
import Testing
@testable import OceanKeySwift

@Test
func swiftDataRepositoryRoundTripsCompleteWorkSessionSnapshot() throws {
    let repository = try SwiftDataWorkSessionRepository(inMemory: true)
    let snapshot = makePersistentTestSnapshot()

    try repository.saveImmediately(snapshot: snapshot)

    let loaded = try #require(try repository.loadSnapshot())
    #expect(loaded == snapshot)
}

@Test
func swiftDataRepositoryUpdatesExistingGraphWithoutKeepingStaleChildren() throws {
    let repository = try SwiftDataWorkSessionRepository(inMemory: true)
    let firstSnapshot = makePersistentTestSnapshot()
    try repository.saveImmediately(snapshot: firstSnapshot)

    var updatedSnapshot = firstSnapshot
    updatedSnapshot.updatedAt = Date(timeIntervalSince1970: 1_803_000_000)
    updatedSnapshot.selection.cartRoomSelections[7] = ["304"]
    updatedSnapshot.history = []
    updatedSnapshot.carts[0].rooms.removeAll { $0.id == "303" }
    updatedSnapshot.carts[0].rooms[0].opened = true
    updatedSnapshot.carts[0].rooms[0].completedTasks = [.stripped, .linen]
    updatedSnapshot.carts[0].rooms[0].mediaAttachments = nil
    try repository.saveImmediately(snapshot: updatedSnapshot)

    let loaded = try #require(try repository.loadSnapshot())
    #expect(loaded == updatedSnapshot)
}

@Test
func inMemoryCloudKitModeFallsBackToLocalStorage() throws {
    let repository = try SwiftDataWorkSessionRepository(
        inMemory: true,
        syncMode: .privateCloudKit(containerIdentifier: "iCloud.com.alex.oceankey.swift")
    )
    let snapshot = makePersistentTestSnapshot()

    try repository.saveImmediately(snapshot: snapshot)

    #expect(repository.syncMode == .privateCloudKit(containerIdentifier: "iCloud.com.alex.oceankey.swift"))
    let loaded = try #require(try repository.loadSnapshot())
    #expect(loaded == snapshot)
}

private func makePersistentTestSnapshot() -> WorkSessionSnapshot {
    let selectedAt = Date(timeIntervalSince1970: 1_801_000_000)
    let openedAt = Date(timeIntervalSince1970: 1_801_003_600)
    let noteAt = Date(timeIntervalSince1970: 1_801_007_200)
    let mediaAt = Date(timeIntervalSince1970: 1_801_010_800)
    let roomMediaID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    let cartMediaID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

    let carts = [
        CartSection(
            id: 7,
            building: "A3",
            rooms: [
                RoomCell(
                    id: "303",
                    opened: true,
                    completedTasks: [.stripped],
                    isVIP: true,
                    scheduledTime: nil,
                    timeline: RoomTimeline(
                        selectedAt: selectedAt,
                        openedAt: openedAt,
                        strippedAt: openedAt,
                        linenDeliveredAt: nil,
                        balconyCleanedAt: nil,
                        completedAt: nil
                    ),
                    textNote: "Check towels",
                    textNoteUpdatedAt: noteAt,
                    voiceTranscript: "Принести полотенца",
                    voiceTranscriptUpdatedAt: noteAt,
                    mediaAttachments: [
                        MediaAttachment(
                            id: roomMediaID,
                            kind: .photo,
                            relativePath: "room/303/photo.jpg",
                            createdAt: mediaAt,
                            completedAt: nil
                        )
                    ]
                ),
                RoomCell(
                    id: "304",
                    opened: false,
                    completedTasks: [],
                    isVIP: false,
                    scheduledTime: Date(timeIntervalSince1970: 1_801_014_400),
                    timeline: RoomTimeline(selectedAt: selectedAt),
                    textNote: nil,
                    textNoteUpdatedAt: nil,
                    voiceTranscript: nil,
                    voiceTranscriptUpdatedAt: nil,
                    mediaAttachments: nil
                )
            ],
            note: "Cart note",
            noteUpdatedAt: noteAt,
            mediaAttachments: [
                MediaAttachment(
                    id: cartMediaID,
                    kind: .video,
                    relativePath: "cart/7/video.mov",
                    createdAt: mediaAt,
                    completedAt: mediaAt
                )
            ],
            consumables: [
                CartConsumableItem(
                    id: "bath_towel",
                    title: "Полотенца банные",
                    quantity: 4,
                    updatedAt: noteAt,
                    completedAt: mediaAt
                )
            ]
        )
    ]
    let counts = SummaryCounts(total: 2, completed: 0, remaining: 2)
    let history = [
        WorkSessionHistoryEntry(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            happenedAt: openedAt,
            kind: .roomOpened,
            title: "303: открыта",
            roomID: "303",
            cartID: 7,
            snapshot: WorkSessionHistorySnapshot(carts: carts, counts: counts)
        )
    ]

    return WorkSessionSnapshot(
        schemaVersion: 1,
        selection: WorkSessionSelectionState(
            cartBindings: [
                7: WorkSessionCartBinding(cartNumber: 7, territoryID: "A3")
            ],
            cartRoomSelections: [
                7: ["303", "304"]
            ],
            workdayLocked: true
        ),
        carts: carts,
        history: history,
        updatedAt: Date(timeIntervalSince1970: 1_801_018_000)
    )
}
