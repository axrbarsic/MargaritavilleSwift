import Testing
@testable import OceanKeySwift

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
