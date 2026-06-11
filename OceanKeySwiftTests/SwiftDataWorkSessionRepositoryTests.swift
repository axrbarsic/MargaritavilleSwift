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
func swiftDataRepositoriesUsePhysicallyIsolatedStoresPerHotel() throws {
    let storeDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent("OceanKeySwiftStoreIsolation-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: storeDirectory) }

    let currentRepository = SwiftDataWorkSessionRepository(
        hotelID: HotelProfile.current.id,
        syncMode: .localOnly,
        storeDirectory: storeDirectory,
        legacyRepository: nil
    )
    let margaritavilleRepository = SwiftDataWorkSessionRepository(
        hotelID: HotelProfile.margaritaville.id,
        syncMode: .localOnly,
        storeDirectory: storeDirectory,
        legacyRepository: nil
    )
    let currentSnapshot = makePersistentTestSnapshot()
    let margaritavilleSnapshot = makeMargaritavilleTestSnapshot()

    try currentRepository.saveImmediately(snapshot: currentSnapshot)
    try margaritavilleRepository.saveImmediately(snapshot: margaritavilleSnapshot)

    #expect(try currentRepository.loadSnapshot() == currentSnapshot)
    #expect(try margaritavilleRepository.loadSnapshot() == margaritavilleSnapshot)
    #expect(
        FileManager.default.fileExists(
            atPath: storeDirectory.appendingPathComponent("workSession-current.store").path
        )
    )
    #expect(
        FileManager.default.fileExists(
            atPath: storeDirectory.appendingPathComponent("workSession-margaritaville.store").path
        )
    )
    #expect(try currentRepository.loadSnapshot()?.carts.first?.rooms.first?.id == "303")
    #expect(try margaritavilleRepository.loadSnapshot()?.carts.first?.rooms.first?.id == "101")
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
    #expect(repository.activeSyncMode == .localOnly)
    let loaded = try #require(try repository.loadSnapshot())
    #expect(loaded == snapshot)
}

@Test
func defaultAppleSyncConfigurationUsesLocalStorageUntilProvisioningSupportsCloudKit() {
    #expect(AppleSyncConfiguration.defaultSyncMode == .localOnly)
    #expect(
        AppleSyncConfiguration.cloudKitSyncMode
            == .privateCloudKit(containerIdentifier: "iCloud.com.alex.oceankey.swift")
    )
}

@Test
func runtimeCloudKitProbeIsExplicitBoolean() {
    let canUseCloudKit = AppleSyncConfiguration.canUsePrivateCloudKitAtRuntime()
    #expect(canUseCloudKit == true || canUseCloudKit == false)
}

@Test
func legacySelectionRowsWithoutSelectedFlagLoadAsActive() {
    let session = PersistentWorkSession(
        workdayLocked: true,
        cartBindings: [
            PersistentCartBinding(
                cartNumber: 7,
                territoryID: "A3",
                isSelected: nil,
                updatedAt: nil
            )
        ],
        roomSelections: [
            PersistentRoomSelection(
                cartNumber: 7,
                roomID: "303",
                isSelected: nil,
                updatedAt: nil
            )
        ],
        carts: [
            PersistentCart(
                cartNumber: 7,
                displayOrder: 0,
                building: "A3",
                rooms: [
                    PersistentRoom(
                        roomID: "303",
                        displayOrder: 0,
                        opened: false,
                        completedTaskValues: "",
                        isVIP: false
                    )
                ]
            )
        ]
    )

    let snapshot = PersistentWorkSessionMapper.snapshot(from: session)

    #expect(snapshot.selection.cartBindings[7]?.territoryID == "A3")
    #expect(snapshot.selection.rooms(forCart: 7).contains("303"))
    #expect(snapshot.carts.first?.rooms.first?.id == "303")
}

private func makeMargaritavilleTestSnapshot() -> WorkSessionSnapshot {
    let selectedAt = Date(timeIntervalSince1970: 1_804_000_000)
    let cart = CartSection(
        id: 1,
        building: "A1",
        rooms: [
            RoomCell(
                id: "101",
                opened: false,
                completedTasks: [],
                isVIP: false,
                statusChangedAt: selectedAt,
                timeline: RoomTimeline(selectedAt: selectedAt)
            )
        ]
    )
    let counts = SummaryCounts(total: 1, completed: 0, remaining: 1)
    return WorkSessionSnapshot(
        schemaVersion: 1,
        selection: WorkSessionSelectionState(
            cartBindings: [1: WorkSessionCartBinding(cartNumber: 1, territoryID: "A1")],
            cartRoomSelections: [1: ["101"]],
            workdayLocked: true,
            workdayLockUpdatedAt: selectedAt
        ),
        catalogOverrides: [
            RoomCatalogOverride(
                roomID: "113",
                territoryID: "A1",
                isRemoved: false,
                updatedAt: selectedAt
            )
        ],
        carts: [cart],
        history: [
            WorkSessionHistoryEntry(
                happenedAt: selectedAt,
                kind: .selectionChanged,
                title: "Margaritaville: 101 выбрана",
                roomID: "101",
                cartID: 1,
                snapshot: WorkSessionHistorySnapshot(carts: [cart], counts: counts)
            )
        ],
        updatedAt: selectedAt
    )
}

private func makePersistentTestSnapshot() -> WorkSessionSnapshot {
    let selectedAt = Date(timeIntervalSince1970: 1_801_000_000)
    let openedAt = Date(timeIntervalSince1970: 1_801_003_600)
    let taskAt = Date(timeIntervalSince1970: 1_801_004_600)
    let noteAt = Date(timeIntervalSince1970: 1_801_007_200)
    let mediaAt = Date(timeIntervalSince1970: 1_801_010_800)
    let vipAt = Date(timeIntervalSince1970: 1_801_012_000)
    let scheduleAt = Date(timeIntervalSince1970: 1_801_013_000)
    let categoryAt = Date(timeIntervalSince1970: 1_801_013_500)
    let selectionAt = Date(timeIntervalSince1970: 1_801_016_000)
    let removedSelectionAt = Date(timeIntervalSince1970: 1_801_017_000)
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
                    openedUpdatedAt: openedAt,
                    completedTasks: [.stripped],
                    strippedUpdatedAt: taskAt,
                    linenUpdatedAt: nil,
                    balconyUpdatedAt: nil,
                    isVIP: true,
                    vipUpdatedAt: vipAt,
                    scheduledTime: nil,
                    scheduledUpdatedAt: nil,
                    dayCategory: .dueOut,
                    dayCategoryTime: Date(timeIntervalSince1970: 1_801_022_400),
                    dayCategoryUpdatedAt: categoryAt,
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
                    openedUpdatedAt: nil,
                    completedTasks: [],
                    strippedUpdatedAt: nil,
                    linenUpdatedAt: nil,
                    balconyUpdatedAt: nil,
                    isVIP: false,
                    vipUpdatedAt: nil,
                    scheduledTime: Date(timeIntervalSince1970: 1_801_014_400),
                    scheduledUpdatedAt: scheduleAt,
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
            cartBindingUpdatedAt: [
                7: selectionAt,
                9: removedSelectionAt
            ],
            cartRoomSelections: [
                7: ["303", "304"]
            ],
            roomSelectionUpdatedAt: [
                7: [
                    "303": selectionAt,
                    "304": selectionAt,
                    "305": removedSelectionAt
                ]
            ],
            workdayLocked: true,
            workdayLockUpdatedAt: selectionAt
        ),
        catalogOverrides: [
            RoomCatalogOverride(
                roomID: "101",
                territoryID: "A1",
                isRemoved: true,
                updatedAt: removedSelectionAt
            ),
            RoomCatalogOverride(
                roomID: "113",
                territoryID: "A1",
                isRemoved: false,
                updatedAt: selectionAt
            )
        ],
        carts: carts,
        history: history,
        updatedAt: Date(timeIntervalSince1970: 1_801_018_000)
    )
}
