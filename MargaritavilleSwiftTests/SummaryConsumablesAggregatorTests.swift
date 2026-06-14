import Foundation
import Testing
@testable import MargaritavilleSwift

@Test
func summaryConsumablesAggregateTotalsAndHousekeepers() {
    let housekeepers = [
        Housekeeper(id: "fabiola", displayName: "Fabiola", palette: .orchid),
        Housekeeper(id: "gurline", displayName: "Gurline", palette: .mint)
    ]
    let sections = [
        MargaritavilleSummaryHousekeeperSection(
            id: "housekeeper-fabiola",
            cartIDs: [1, 2],
            housekeeperID: "fabiola",
            locationLabel: "A1 A2",
            rooms: []
        ),
        MargaritavilleSummaryHousekeeperSection(
            id: "housekeeper-gurline",
            cartIDs: [3],
            housekeeperID: "gurline",
            locationLabel: "B1",
            rooms: []
        )
    ]
    let carts = [
        testCart(id: 1, building: "A1", consumables: [
            CartConsumableItem(id: "bath_towel", title: "Полотенца банные", quantity: 4),
            CartConsumableItem(id: "sheet", title: "Простыни", quantity: 1)
        ]),
        testCart(id: 2, building: "A2", consumables: [
            CartConsumableItem(id: "bath_towel", title: "Полотенца банные", quantity: 3)
        ]),
        testCart(id: 3, building: "B1", consumables: [
            CartConsumableItem(id: "hand_towel", title: "Полотенца ручные", quantity: 2)
        ])
    ]

    let report = SummaryConsumablesAggregator.makeReport(
        sections: sections,
        carts: carts,
        housekeepers: housekeepers,
        catalog: CartConsumableCatalog.defaultCatalog
    )

    #expect(report.totals.map(\.id) == ["bath_towel", "hand_towel", "sheet"])
    #expect(report.totals.map(\.quantity) == [7, 2, 1])
    #expect(report.housekeepers[0].displayName == "Fabiola")
    #expect(report.housekeepers[0].tickerText == "Полотенца банные 7  •  Простыни 1")
    #expect(report.housekeepers[0].items.first { $0.id == "bath_towel" }?.sourceCartIDs == [1, 2])
    #expect(report.housekeepers[0].items.first { $0.id == "sheet" }?.sourceCartIDs == [1])
    #expect(report.housekeepers[1].displayName == "Gurline")
    #expect(report.housekeepers[1].tickerText == "Полотенца ручные 2")
    #expect(report.housekeepers[1].items.first { $0.id == "hand_towel" }?.sourceCartIDs == [3])
}

@Test
func summaryConsumablesIgnoreCompletedOrZeroQuantityItems() {
    let completed = Date()
    let sections = [
        MargaritavilleSummaryHousekeeperSection(
            id: "housekeeper-fabiola",
            cartIDs: [1],
            housekeeperID: "fabiola",
            locationLabel: "A1",
            rooms: []
        )
    ]
    let carts = [
        testCart(id: 1, building: "A1", consumables: [
            CartConsumableItem(id: "bath_towel", title: "Полотенца банные", quantity: 4, completedAt: completed),
            CartConsumableItem(id: "hand_towel", title: "Полотенца ручные", quantity: 0),
            CartConsumableItem(id: "sheet", title: "Простыни", quantity: 2)
        ])
    ]

    let report = SummaryConsumablesAggregator.makeReport(
        sections: sections,
        carts: carts,
        housekeepers: [
            Housekeeper(id: "fabiola", displayName: "Fabiola", palette: .orchid)
        ],
        catalog: CartConsumableCatalog.defaultCatalog
    )

    #expect(report.totals.map(\.id) == ["sheet"])
    #expect(report.totals.map(\.quantity) == [2])
    #expect(report.housekeepers[0].tickerText == "Простыни 2")
}

@Test
func summaryConsumablesFollowEditableGlobalCatalog() {
    let sections = [
        MargaritavilleSummaryHousekeeperSection(
            id: "housekeeper-fabiola",
            cartIDs: [1],
            housekeeperID: "fabiola",
            locationLabel: "A1",
            rooms: []
        )
    ]
    let carts = [
        testCart(id: 1, building: "A1", consumables: [
            CartConsumableItem(id: "bath_towel", title: "Old bath towel", quantity: 4),
            CartConsumableItem(id: "washcloth", title: "Салфетки", quantity: 8),
            CartConsumableItem(id: "coffee-kit", title: "Coffee kit", quantity: 2)
        ])
    ]
    let catalog = [
        CartConsumableCatalogItem(id: "bath_towel", title: "Полотенца большие"),
        CartConsumableCatalogItem(id: "coffee-kit", title: "Кофе-набор")
    ]

    let report = SummaryConsumablesAggregator.makeReport(
        sections: sections,
        carts: carts,
        housekeepers: [
            Housekeeper(id: "fabiola", displayName: "Fabiola", palette: .orchid)
        ],
        catalog: catalog
    )

    #expect(report.totals.map(\.id) == ["bath_towel", "coffee-kit"])
    #expect(report.totals.map(\.title) == ["Полотенца большие", "Кофе-набор"])
    #expect(report.totals.map(\.quantity) == [4, 2])
    #expect(report.housekeepers[0].tickerText == "Полотенца большие 4  •  Кофе-набор 2")
}

private func testCart(
    id: CartSection.ID,
    building: String,
    consumables: [CartConsumableItem]
) -> CartSection {
    CartSection(
        id: id,
        building: building,
        rooms: [],
        note: nil,
        noteUpdatedAt: nil,
        mediaAttachments: nil,
        consumables: consumables
    )
}
