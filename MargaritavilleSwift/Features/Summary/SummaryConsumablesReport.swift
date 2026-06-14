import Foundation

struct SummaryConsumableLine: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let quantity: Int
    let sortOrder: Int
    let sourceCartIDs: [CartSection.ID]
}

struct SummaryHousekeeperConsumables: Equatable, Identifiable, Sendable {
    let id: String
    let displayName: String
    let palette: HousekeeperPalette?
    let locationLabel: String
    let items: [SummaryConsumableLine]

    var tickerText: String {
        items.map { "\($0.title) \($0.quantity)" }.joined(separator: "  •  ")
    }
}

struct SummaryConsumablesReport: Equatable, Sendable {
    let totals: [SummaryConsumableLine]
    let housekeepers: [SummaryHousekeeperConsumables]

    var isEmpty: Bool {
        totals.isEmpty && housekeepers.isEmpty
    }
}

enum SummaryConsumablesAggregator {
    static func makeReport(
        sections: [MargaritavilleSummaryHousekeeperSection],
        carts: [CartSection],
        housekeepers: [Housekeeper],
        catalog: [CartConsumableCatalogItem]
    ) -> SummaryConsumablesReport {
        let cartsByID = Dictionary(uniqueKeysWithValues: carts.map { ($0.id, $0) })
        let housekeepersByID = Dictionary(uniqueKeysWithValues: housekeepers.map { ($0.id, $0) })
        let catalogOrder = Dictionary(uniqueKeysWithValues: catalog.enumerated().map { index, item in (item.id, index) })
        var totalCounts: [String: ConsumableAccumulator] = [:]
        var housekeeperRows: [SummaryHousekeeperConsumables] = []

        for section in sections {
            let sectionCarts = section.cartIDs.compactMap { cartsByID[$0] }
            let items = aggregatedItems(
                for: sectionCarts,
                catalog: catalog,
                catalogOrder: catalogOrder
            )
            guard !items.isEmpty else { continue }

            for item in items {
                totalCounts[item.id, default: ConsumableAccumulator(
                    title: item.title,
                    quantity: 0,
                    sortOrder: item.sortOrder,
                    sourceCartIDs: []
                )].quantity += item.quantity
            }

            let housekeeper = section.housekeeperID.flatMap { housekeepersByID[$0] }
            housekeeperRows.append(
                SummaryHousekeeperConsumables(
                    id: section.id,
                    displayName: housekeeper?.displayName ?? "Уборщица",
                    palette: housekeeper?.palette,
                    locationLabel: section.locationLabel,
                    items: items
                )
            )
        }

        return SummaryConsumablesReport(
            totals: totalCounts.map { id, value in
                SummaryConsumableLine(
                    id: id,
                    title: value.title,
                    quantity: value.quantity,
                    sortOrder: value.sortOrder,
                    sourceCartIDs: []
                )
            }
            .sorted(by: compareLines),
            housekeepers: housekeeperRows
        )
    }

    private static func aggregatedItems(
        for carts: [CartSection],
        catalog: [CartConsumableCatalogItem],
        catalogOrder: [String: Int]
    ) -> [SummaryConsumableLine] {
        var counts: [String: ConsumableAccumulator] = [:]

        for cart in carts {
            for item in CartConsumableCatalog.merged(with: cart.consumables, catalog: catalog) {
                guard item.quantity > 0, !item.isCompleted else { continue }
                var accumulator = counts[item.id, default: ConsumableAccumulator(
                    title: item.title,
                    quantity: 0,
                    sortOrder: catalogOrder[item.id] ?? catalog.count + 100,
                    sourceCartIDs: []
                )]
                accumulator.quantity += item.quantity
                if !accumulator.sourceCartIDs.contains(cart.id) {
                    accumulator.sourceCartIDs.append(cart.id)
                }
                counts[item.id] = accumulator
            }
        }

        return counts.map { id, value in
            SummaryConsumableLine(
                id: id,
                title: value.title,
                quantity: value.quantity,
                sortOrder: value.sortOrder,
                sourceCartIDs: value.sourceCartIDs
            )
        }
        .sorted(by: compareLines)
    }

    private static func compareLines(_ left: SummaryConsumableLine, _ right: SummaryConsumableLine) -> Bool {
        if left.sortOrder != right.sortOrder {
            return left.sortOrder < right.sortOrder
        }
        return left.title.localizedStandardCompare(right.title) == .orderedAscending
    }
}

private struct ConsumableAccumulator {
    let title: String
    var quantity: Int
    let sortOrder: Int
    var sourceCartIDs: [CartSection.ID]
}
