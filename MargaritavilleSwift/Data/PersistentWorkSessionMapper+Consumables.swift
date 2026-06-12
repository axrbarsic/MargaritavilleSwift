import SwiftData

extension PersistentWorkSessionMapper {
    static func consumables(from records: [PersistentCartConsumable]) -> [CartConsumableItem]? {
        let items = records
            .sorted { $0.displayOrder < $1.displayOrder }
            .map {
                CartConsumableItem(
                    id: $0.itemID,
                    title: $0.title,
                    quantity: $0.quantity,
                    updatedAt: $0.updatedAt,
                    completedAt: $0.completedAt
                )
            }
        return items.isEmpty ? nil : items
    }

    static func syncConsumables(
        _ items: [CartConsumableItem],
        existingRecords records: [PersistentCartConsumable]?,
        context: ModelContext
    ) -> [PersistentCartConsumable] {
        let records = records ?? []
        let desiredIDs = Set(items.map(\.id))
        records.filter { !desiredIDs.contains($0.itemID) }
            .forEach { context.delete($0) }

        var existing: [String: PersistentCartConsumable] = [:]
        for record in records {
            existing[record.itemID] = record
        }
        var nextRecords: [PersistentCartConsumable] = []
        for (index, item) in items.enumerated() {
            let record: PersistentCartConsumable
            if existing[item.id] == nil {
                record = PersistentCartConsumable(
                    itemID: item.id,
                    title: item.title,
                    quantity: item.quantity,
                    updatedAt: item.updatedAt,
                    completedAt: item.completedAt,
                    displayOrder: index
                )
                context.insert(record)
                existing[item.id] = record
            } else {
                record = existing[item.id]!
            }
            record.title = item.title
            record.quantity = item.quantity
            record.updatedAt = item.updatedAt
            record.completedAt = item.completedAt
            record.displayOrder = index
            nextRecords.append(record)
        }
        return nextRecords
    }
}
