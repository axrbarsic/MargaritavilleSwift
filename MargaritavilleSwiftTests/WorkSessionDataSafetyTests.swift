import Foundation
import Testing
@testable import MargaritavilleSwift

@Test
func selectionEditsKeepCartNoteMediaAndConsumables() {
    let store = WorkSessionStore(carts: [], hotelProfile: .margaritaville)
    store.toggleCartSelection(1)
    store.toggleRoomSelection(cartNumber: 1, room: "101")
    let media = MediaAttachment(
        id: UUID(), kind: .photo, relativePath: "Media/test.jpg", createdAt: .distantPast
    )
    store.updateCartNote("Пятно на ковре", cartId: 1)
    store.addCartMedia(media, cartId: 1)
    store.addCartConsumable(title: "Шампунь", quantity: 3, cartId: 1)
    let before = store.cart(id: 1)

    store.lockWorkday()
    store.unlockWorkdayForEditing()
    store.toggleRoomSelection(cartNumber: 1, room: "102")
    store.toggleRoomSelection(cartNumber: 1, room: "101")

    let after = store.cart(id: 1)
    #expect(after?.rooms.map(\.id) == ["102"])
    #expect(after?.note == "Пятно на ковре")
    #expect(after?.noteUpdatedAt == before?.noteUpdatedAt)
    #expect(after?.mediaAttachments == [media])
    #expect(after?.consumables == before?.consumables)
    #expect(after?.consumables?.contains { $0.title == "Шампунь" } == true)
}

@Test
func cartRebuildToleratesDuplicateExistingRoomIDs() {
    let store = WorkSessionStore(carts: [], hotelProfile: .margaritaville)
    store.toggleCartSelection(1)
    store.toggleRoomSelection(cartNumber: 1, room: "101")
    let duplicate = RoomCell(id: "101", opened: true, completedTasks: [], isVIP: false)

    let carts = WorkSessionBuilder.makeCarts(
        from: store.selection,
        preserving: [duplicate, duplicate],
        hotelProfile: .margaritaville
    )

    #expect(carts.first?.rooms.first?.opened == true)
}

@Test
func loadFailureBlocksEveryWriteUntilASuccessfulLoad() {
    let repository = RecordingWorkSessionRepository()
    let store = WorkSessionStore.bootstrapping(hotelProfile: .margaritaville, repository: repository)

    store.recordLoadFailure(WorkSessionLoadFailure(message: "диск недоступен"))
    store.toggleCartSelection(1)
    store.toggleRoomSelection(cartNumber: 1, room: "101")
    store.persist(immediately: true)
    store.flushPendingPersistence()

    #expect(store.loadFailure?.message == "диск недоступен")
    #expect(repository.savedSnapshots.isEmpty)

    store.finishInitialLoadWithoutSnapshot()
    store.persist(immediately: true)

    #expect(store.loadFailure == nil)
    #expect(repository.savedSnapshots.count == 1)
}

@Test
func repositoryReportsInMemoryFallbackAsLoadFailure() throws {
    let blockingFile = FileManager.default.temporaryDirectory
        .appendingPathComponent("MargaritavilleSwiftNotADirectory-\(UUID().uuidString)")
    try Data("x".utf8).write(to: blockingFile)
    defer { try? FileManager.default.removeItem(at: blockingFile) }

    let repository = SwiftDataWorkSessionRepository(
        hotelID: HotelProfile.margaritaville.id,
        storeDirectory: blockingFile,
        legacyRepository: nil
    )

    #expect(repository.isInMemoryFallback)
    #expect(throws: WorkSessionLoadFailure.self) {
        try repository.loadSnapshot()
    }
}

private final class RecordingWorkSessionRepository: WorkSessionRepository, @unchecked Sendable {
    private(set) var savedSnapshots: [WorkSessionSnapshot] = []

    func loadSnapshot() throws -> WorkSessionSnapshot? { nil }

    func save(snapshot: WorkSessionSnapshot) {
        savedSnapshots.append(snapshot)
    }
}
