import Foundation

extension WorkSessionStore {
    func appendHistory(
        kind: WorkSessionHistoryKind,
        title: String,
        roomID: RoomID? = nil,
        cartID: CartSection.ID? = nil,
        happenedAt: Date = Date()
    ) {
        let snapshot = WorkSessionHistorySnapshot(
            carts: carts,
            counts: counts
        )
        let entry = WorkSessionHistoryEntry(
            happenedAt: happenedAt,
            kind: kind,
            title: title,
            roomID: roomID,
            cartID: cartID,
            snapshot: snapshot
        )
        history.insert(entry, at: 0)
    }
}
