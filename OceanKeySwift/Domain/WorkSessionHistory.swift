import Foundation

enum WorkSessionHistoryKind: String, Codable, CaseIterable, Sendable {
    case roomOpened
    case roomClosed
    case roomTaskChanged
    case roomVIPChanged
    case roomScheduleChanged
    case roomTextNoteChanged
    case roomVoiceTranscriptChanged
    case roomMediaAdded
    case cartNoteChanged
    case cartMediaAdded
    case cartConsumablesChanged
    case selectionChanged
    case workdayLocked
    case workdayUnlocked
    case scheduledRoomAutoOpened
}

struct WorkSessionHistorySnapshot: Codable, Equatable, Sendable {
    var carts: [CartSection]
    var counts: SummaryCounts
}

struct WorkSessionHistoryEntry: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let happenedAt: Date
    let kind: WorkSessionHistoryKind
    let title: String
    let roomID: RoomID?
    let cartID: CartSection.ID?
    let snapshot: WorkSessionHistorySnapshot

    init(
        id: UUID = UUID(),
        happenedAt: Date = Date(),
        kind: WorkSessionHistoryKind,
        title: String,
        roomID: RoomID? = nil,
        cartID: CartSection.ID? = nil,
        snapshot: WorkSessionHistorySnapshot
    ) {
        self.id = id
        self.happenedAt = happenedAt
        self.kind = kind
        self.title = title
        self.roomID = roomID
        self.cartID = cartID
        self.snapshot = snapshot
    }
}
