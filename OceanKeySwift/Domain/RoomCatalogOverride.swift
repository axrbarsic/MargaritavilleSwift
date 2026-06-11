import Foundation

struct RoomCatalogOverride: Codable, Equatable, Identifiable, Sendable {
    let roomID: RoomID
    var territoryID: String
    var isRemoved: Bool
    var updatedAt: Date

    var id: RoomID { roomID }
}

enum RoomCatalogEditResult: Equatable, Sendable {
    case changed
    case duplicate
    case invalidRoom
    case blockedActiveRoom
    case unsupportedHotel
}
