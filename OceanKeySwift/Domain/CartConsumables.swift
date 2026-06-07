import Foundation

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
    static let defaults: [CartConsumableItem] = [
        CartConsumableItem(id: "bath_towel", title: "Полотенца банные", quantity: 0),
        CartConsumableItem(id: "hand_towel", title: "Полотенца ручные", quantity: 0),
        CartConsumableItem(id: "washcloth", title: "Салфетки", quantity: 0),
        CartConsumableItem(id: "bath_mat", title: "Коврики", quantity: 0),
        CartConsumableItem(id: "sheet", title: "Простыни", quantity: 0),
        CartConsumableItem(id: "pillowcase", title: "Наволочки", quantity: 0)
    ]

    static func merged(with storedItems: [CartConsumableItem]?) -> [CartConsumableItem] {
        let storedByID = Dictionary(uniqueKeysWithValues: (storedItems ?? []).map { ($0.id, $0) })
        return defaults.map { storedByID[$0.id] ?? $0 }
    }
}
