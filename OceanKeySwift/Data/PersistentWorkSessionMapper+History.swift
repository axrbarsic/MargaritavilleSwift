import Foundation
import SwiftData

extension PersistentWorkSessionMapper {
    static func history(from records: [PersistentHistoryEntry]) -> [WorkSessionHistoryEntry] {
        records
            .sorted { $0.displayOrder < $1.displayOrder }
            .compactMap { record -> WorkSessionHistoryEntry? in
                guard let kind = WorkSessionHistoryKind(rawValue: record.kindRawValue) else { return nil }
                guard let snapshot = try? JSONDecoder().decode(
                    WorkSessionHistorySnapshot.self,
                    from: record.snapshotData
                ) else {
                    return nil
                }
                return WorkSessionHistoryEntry(
                    id: record.eventID,
                    happenedAt: record.happenedAt,
                    kind: kind,
                    title: record.title,
                    roomID: record.roomID,
                    cartID: record.cartID,
                    snapshot: snapshot
                )
            }
    }

    static func syncHistory(
        _ history: [WorkSessionHistoryEntry],
        session: PersistentWorkSession,
        context: ModelContext
    ) throws {
        let records = session.historyEntries ?? []
        let desiredIDs = Set(history.map(\.id))
        records.filter { !desiredIDs.contains($0.eventID) }
            .forEach { context.delete($0) }

        var existing: [UUID: PersistentHistoryEntry] = [:]
        for record in records {
            existing[record.eventID] = record
        }
        var nextRecords = records.filter { desiredIDs.contains($0.eventID) }
        for (index, entry) in history.enumerated() {
            let snapshotData = try JSONEncoder().encode(entry.snapshot)
            let record: PersistentHistoryEntry
            if existing[entry.id] == nil {
                record = PersistentHistoryEntry(
                    eventID: entry.id,
                    happenedAt: entry.happenedAt,
                    kindRawValue: entry.kind.rawValue,
                    title: entry.title,
                    roomID: entry.roomID,
                    cartID: entry.cartID,
                    snapshotData: snapshotData,
                    displayOrder: index
                )
                context.insert(record)
                existing[entry.id] = record
                nextRecords.append(record)
            } else {
                record = existing[entry.id]!
            }
            record.happenedAt = entry.happenedAt
            record.kindRawValue = entry.kind.rawValue
            record.title = entry.title
            record.roomID = entry.roomID
            record.cartID = entry.cartID
            record.snapshotData = snapshotData
            record.displayOrder = index
            record.session = session
        }
        session.historyEntries = nextRecords
    }
}
