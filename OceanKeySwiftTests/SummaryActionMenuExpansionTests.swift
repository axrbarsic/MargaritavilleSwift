import Testing
@testable import OceanKeySwift

@Test
func summaryActionMenuSingleModeReplacesPreviousRoom() {
    let expanded = SummaryActionMenuExpansion.toggled(
        roomID: "304",
        in: ["303"],
        allowsMultiple: false
    )

    #expect(expanded == ["304"])
}

@Test
func summaryActionMenuMultiModeKeepsPreviousRooms() {
    let expanded = SummaryActionMenuExpansion.toggled(
        roomID: "304",
        in: ["303"],
        allowsMultiple: true
    )

    #expect(expanded == ["303", "304"])
}

@Test
func summaryActionMenuSecondSwipeClosesSameRoom() {
    let expanded = SummaryActionMenuExpansion.toggled(
        roomID: "303",
        in: ["303", "304"],
        allowsMultiple: true
    )

    #expect(expanded == ["304"])
}

@Test
func summaryActionMenuNormalizationKeepsOnlyOneRoomInSingleMode() {
    let expanded = SummaryActionMenuExpansion.normalized(
        ["305", "303", "304"],
        allowsMultiple: false
    )

    #expect(expanded == ["303"])
}
