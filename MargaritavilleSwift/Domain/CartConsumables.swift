import Foundation

struct CartConsumableCatalogItem: Codable, Identifiable, Equatable, Sendable {
    let id: String
    var title: String
}

struct CartConsumableItem: Codable, Identifiable, Equatable, Sendable {
    let id: String
    var title: String
    var quantity: Int
    var updatedAt: Date?
    var completedAt: Date?

    var isCompleted: Bool {
        completedAt != nil
    }
}

enum CartConsumableCatalog {
    static let defaultCatalog: [CartConsumableCatalogItem] = [
        CartConsumableCatalogItem(id: "bath_towel", title: "Полотенца банные"),
        CartConsumableCatalogItem(id: "hand_towel", title: "Полотенца ручные"),
        CartConsumableCatalogItem(id: "washcloth", title: "Салфетки"),
        CartConsumableCatalogItem(id: "bath_mat", title: "Коврики"),
        CartConsumableCatalogItem(id: "sheet", title: "Простыни"),
        CartConsumableCatalogItem(id: "pillowcase", title: "Наволочки")
    ]

    static let defaults: [CartConsumableItem] = defaultCatalog.map {
        CartConsumableItem(id: $0.id, title: $0.title, quantity: 0)
    }

    static func normalizedCatalog(_ items: [CartConsumableCatalogItem]) -> [CartConsumableCatalogItem] {
        var usedIDs: Set<String> = []
        return items.compactMap { item in
            let title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { return nil }
            let preferredID = item.id.trimmingCharacters(in: .whitespacesAndNewlines)
            let id = uniqueID(
                preferredID: preferredID.isEmpty ? stableID(for: title) : preferredID,
                usedIDs: &usedIDs
            )
            return CartConsumableCatalogItem(id: id, title: title)
        }
    }

    static func makeItem(title: String, existing: [CartConsumableCatalogItem]) -> CartConsumableCatalogItem? {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return nil }
        var usedIDs = Set(existing.map(\.id))
        return CartConsumableCatalogItem(
            id: uniqueID(preferredID: stableID(for: title), usedIDs: &usedIDs),
            title: title
        )
    }

    static func merged(
        with storedItems: [CartConsumableItem]?,
        catalog: [CartConsumableCatalogItem] = defaultCatalog
    ) -> [CartConsumableItem] {
        let normalizedCatalog = normalizedCatalog(catalog)
        let storedByID = Dictionary(uniqueKeysWithValues: (storedItems ?? []).map { ($0.id, $0) })
        let catalogItems = normalizedCatalog.map { catalogItem -> CartConsumableItem in
            var stored = storedByID[catalogItem.id] ?? CartConsumableItem(
                id: catalogItem.id,
                title: catalogItem.title,
                quantity: 0
            )
            stored.title = catalogItem.title
            return stored
        }
        return catalogItems
    }

    private static func stableID(for title: String) -> String {
        let folded = title
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
        let scalars = folded.unicodeScalars.map { scalar -> Character in
            CharacterSet.alphanumerics.contains(scalar) ? Character(scalar) : "-"
        }
        let collapsed = String(scalars)
            .split(separator: "-")
            .joined(separator: "-")
        return collapsed.isEmpty ? "consumable" : collapsed
    }

    private static func uniqueID(preferredID: String, usedIDs: inout Set<String>) -> String {
        if !usedIDs.contains(preferredID) {
            usedIDs.insert(preferredID)
            return preferredID
        }
        var suffix = 2
        while usedIDs.contains("\(preferredID)-\(suffix)") {
            suffix += 1
        }
        let id = "\(preferredID)-\(suffix)"
        usedIDs.insert(id)
        return id
    }
}
