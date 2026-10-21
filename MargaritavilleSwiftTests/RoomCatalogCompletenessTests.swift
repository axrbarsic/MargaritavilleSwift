import Testing
@testable import MargaritavilleSwift

@Test
func confirmedRoomsBelongToTheirProductionTerritories() {
    let profile = HotelProfile.margaritaville
    for (room, territoryID) in [("142", "B1"), ("261", "B2")] {
        #expect(profile.territory(for: room)?.id == territoryID)
        #expect(RoomCatalog.inferredTerritory(for: room, in: profile)?.id == territoryID)
        #expect(RoomCatalog.contains(room, in: RoomCatalog.effectiveTerritories(
            for: profile, overrides: []
        )))
    }
}

@Test
func entireRoomCatalogHasUniqueOrderedFloorCorrectIdentifiers() {
    let territories = HotelProfile.margaritaville.catalog
    let allRooms = territories.flatMap(\.rooms)
    #expect(territories.count == 6)
    #expect(allRooms.count == 186)
    #expect(Set(allRooms).count == allRooms.count)
    for territory in territories {
        #expect(territory.rooms == territory.rooms.sorted(by: RoomCatalog.compareRoomIDs))
        for room in territory.rooms {
            #expect(Int(room).map { $0 / 100 } == territory.floor)
            #expect(HotelProfile.margaritaville.territory(for: room)?.id == territory.id)
        }
    }
}

@Test
func unrelatedSavedCatalogEditsPreserveRestoredRooms() {
    let territories = RoomCatalog.effectiveTerritories(
        for: .margaritaville,
        overrides: [RoomCatalogOverride(
            roomID: "101", territoryID: "A1", isRemoved: true, updatedAt: .distantPast
        )]
    )
    #expect(!RoomCatalog.contains("101", in: territories))
    #expect(territories.first { $0.id == "B1" }?.rooms.contains("142") == true)
    #expect(territories.first { $0.id == "B2" }?.rooms.contains("261") == true)
}
