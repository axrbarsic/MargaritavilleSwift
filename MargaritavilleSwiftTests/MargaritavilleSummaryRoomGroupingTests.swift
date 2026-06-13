import Testing
@testable import MargaritavilleSwift

@Test
func margaritavilleSummaryGroupingSplitsOneCartByTerritory() {
    let rooms = [
        RoomCell(id: "330", opened: false, completedTasks: [], isVIP: false),
        RoomCell(id: "314", opened: false, completedTasks: [], isVIP: false),
        RoomCell(id: "331", opened: false, completedTasks: [], isVIP: false)
    ]

    let groups = MargaritavilleSummaryRoomGrouping.groups(
        rooms: rooms,
        territories: HotelProfile.margaritaville.catalog,
        fallbackLabel: "A3/B3"
    )

    #expect(groups.map(\.label) == ["A3", "B3"])
    #expect(groups[0].rooms.map(\.id) == ["314"])
    #expect(groups[1].rooms.map(\.id) == ["330", "331"])
}

@Test
func margaritavilleSummaryHousekeeperSectionsMergeOneHousekeeperAcrossTerritories() {
    var selection = WorkSessionSelectionState()
    selection.cartBindings = [
        1: WorkSessionCartBinding(cartNumber: 1, territoryID: "A1"),
        2: WorkSessionCartBinding(cartNumber: 2, territoryID: "A2"),
        3: WorkSessionCartBinding(cartNumber: 3, territoryID: "B3")
    ]
    selection.cartHousekeeperIDs = [
        1: "fabiola",
        2: "fabiola",
        3: "fabiola"
    ]
    selection.cartRoomSelections = [
        1: ["106", "119"],
        2: ["202", "210"],
        3: ["330", "345"]
    ]
    let carts = WorkSessionBuilder.makeCarts(
        from: selection,
        hotelProfile: .margaritaville
    )

    let sections = MargaritavilleSummaryRoomGrouping.housekeeperSections(
        carts: carts,
        selection: selection,
        hotelProfile: .margaritaville,
        statusFilter: nil
    )

    #expect(sections.count == 1)
    #expect(sections[0].housekeeperID == "fabiola")
    #expect(sections[0].cartIDs == [1, 2, 3])
    #expect(sections[0].locationLabel == "A1 A2 B3")
    #expect(sections[0].rooms.map(\.id) == ["106", "119", "202", "210", "330", "345"])
}
