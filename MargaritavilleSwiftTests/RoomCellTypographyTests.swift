import Foundation
import Testing
@testable import MargaritavilleSwift

@Test
func productionRoomCellTypographyMatchesApprovedPreset() {
    let typography = RoomCellTypography.production

    #expect(typography.roomNumberSize == 45)
    #expect(typography.roomNumberWeight == .black)
    #expect(typography.roomNumberVerticalOffset == 7)
    #expect(typography.activationTimeSize == 12)
    #expect(typography.activationTimeWeight == .regular)
    #expect(typography.activationTimeVerticalOffset == 1)
}

@Test
func typographyLabFixturesUseRealSimpleCycleStatuses() {
    let statuses = CellTypographyLabFixtures.regularRooms.map { $0.status(in: .simpleCycle) }

    #expect(statuses == [.pending, .open, .ready, .scheduled])
}

@Test
func typographyLabRangesContainProductionValues() {
    let production = RoomCellTypography.production

    #expect(RoomCellTypography.roomNumberSizeRange.contains(production.roomNumberSize))
    #expect(RoomCellTypography.activationTimeSizeRange.contains(production.activationTimeSize))
    #expect(RoomCellTypography.verticalOffsetRange.contains(production.roomNumberVerticalOffset))
    #expect(RoomCellTypography.verticalOffsetRange.contains(production.activationTimeVerticalOffset))
}

@Test
func typographySizeStopsAreStrictlyIncreasingWithoutPlateau() {
    let roomNumberStops = RoomCellTypography.sizeStops(in: RoomCellTypography.roomNumberSizeRange)
    let activationTimeStops = RoomCellTypography.sizeStops(in: RoomCellTypography.activationTimeSizeRange)

    for stops in [roomNumberStops, activationTimeStops] {
        #expect(stops.count == 5)
        #expect(zip(stops, stops.dropFirst()).allSatisfy(<))
    }
    #expect(roomNumberStops == [36, 39, 42, 45, 48])
    #expect(activationTimeStops == [12, 14, 15, 17, 18])
}

@Test
func cellTypographyPresetRoundTripsThroughPersistence() throws {
    let suiteName = "CellTypographyPresetTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let store = CellTypographyPresetStore(defaults: defaults)
    let typography = RoomCellTypography(
        roomNumberSize: 47,
        roomNumberWeight: .semibold,
        roomNumberVerticalOffset: -3,
        activationTimeSize: 17,
        activationTimeWeight: .medium,
        activationTimeVerticalOffset: 4
    )
    let savedAt = Date(timeIntervalSince1970: 1_783_856_096)

    let saved = try store.save(typography, at: savedAt)
    let loaded = store.load()

    #expect(saved.schemaVersion == 1)
    #expect(loaded == saved)
    #expect(loaded?.typography == typography)

    store.delete()
    #expect(store.load() == nil)
}

@Test
func cellTypographyPresetExportFormatIsStableAndComplete() throws {
    let preset = SavedCellTypographyPreset(
        typography: RoomCellTypography(
            roomNumberSize: 47,
            roomNumberWeight: .semibold,
            roomNumberVerticalOffset: -3,
            activationTimeSize: 17,
            activationTimeWeight: .medium,
            activationTimeVerticalOffset: 4
        ),
        savedAt: Date(timeIntervalSince1970: 1_783_856_096)
    )

    let json = try CellTypographyPresetStore.exportJSON(preset)

    #expect(json == """
    {
      "savedAt" : "2026-07-12T11:34:56Z",
      "schemaVersion" : 1,
      "typography" : {
        "activationTimeSize" : 17,
        "activationTimeVerticalOffset" : 4,
        "activationTimeWeight" : "medium",
        "roomNumberSize" : 47,
        "roomNumberVerticalOffset" : -3,
        "roomNumberWeight" : "semibold"
      }
    }
    """)
}
