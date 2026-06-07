import Foundation

struct WorkSessionSnapshot: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var selection: WorkSessionSelectionState
    var carts: [CartSection]
    var updatedAt: Date

    init(
        schemaVersion: Int = 1,
        selection: WorkSessionSelectionState,
        carts: [CartSection],
        updatedAt: Date = Date()
    ) {
        self.schemaVersion = schemaVersion
        self.selection = selection
        self.carts = carts
        self.updatedAt = updatedAt
    }
}
