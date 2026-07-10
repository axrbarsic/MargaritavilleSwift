import Foundation
import Testing
@testable import MargaritavilleSwift

@Test
func testAssignmentUsesEveryRoomAndEveryAvailableHousekeeperEvenly() throws {
    var generator = SystemRandomNumberGenerator()
    let previousLockDate = Date(timeIntervalSince1970: 1_800_000_000)
    var current = WorkSessionSelectionState()
    current.workdayLocked = true
    current.workdayLockUpdatedAt = previousLockDate

    let generated = try #require(TestWorkAssignmentGenerator.makeSelection(
        territories: HotelProfile.margaritaville.catalog,
        housekeeperIDs: MargaritavilleHousekeeperCatalog.defaultHousekeepers.map(\.id),
        preservingLockFrom: current,
        changedAt: Date(timeIntervalSince1970: 1_900_000_000),
        using: &generator
    ))

    let expectedRooms = Set(HotelProfile.margaritaville.catalog.flatMap(\.rooms))
    let assignedRooms = generated.selection.cartRoomSelections.values.flatMap { $0 }
    let assignmentCounts = generated.selection.cartRoomSelections.values.map(\.count)

    #expect(Set(assignedRooms) == expectedRooms)
    #expect(assignedRooms.count == expectedRooms.count)
    #expect(generated.selection.cartHousekeeperIDs.count == MargaritavilleHousekeeperCatalog.defaultHousekeepers.count)
    #expect(Set(generated.selection.cartHousekeeperIDs.values) == Set(MargaritavilleHousekeeperCatalog.defaultHousekeepers.map(\.id)))
    #expect((assignmentCounts.max() ?? 0) - (assignmentCounts.min() ?? 0) <= 1)
    #expect(generated.selection.workdayLocked)
    #expect(generated.selection.workdayLockUpdatedAt == previousLockDate)
}
