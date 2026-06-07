import Foundation

struct WorkSessionSnapshot: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var selection: WorkSessionSelectionState
    var carts: [CartSection]
    var history: [WorkSessionHistoryEntry]
    var updatedAt: Date

    init(
        schemaVersion: Int = 1,
        selection: WorkSessionSelectionState,
        carts: [CartSection],
        history: [WorkSessionHistoryEntry] = [],
        updatedAt: Date = Date()
    ) {
        self.schemaVersion = schemaVersion
        self.selection = selection
        self.carts = carts
        self.history = history
        self.updatedAt = updatedAt
    }
}
