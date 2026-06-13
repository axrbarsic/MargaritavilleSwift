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
            carts: historySnapshotCarts(roomID: roomID, cartID: cartID, kind: kind),
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

    private func historySnapshotCarts(
        roomID: RoomID?,
        cartID: CartSection.ID?,
        kind: WorkSessionHistoryKind
    ) -> [CartSection] {
        if let cartID {
            return carts.filter { $0.id == cartID }
        }
        if let roomID {
            return carts.filter { cart in
                cart.rooms.contains { $0.id == roomID }
            }
        }
        switch kind {
        case .workdayLocked, .workdayUnlocked:
            return carts
        default:
            return []
        }
    }
}
