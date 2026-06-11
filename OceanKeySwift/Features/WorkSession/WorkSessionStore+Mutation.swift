import Foundation

extension WorkSessionStore {
    func mutateCart(
        _ cartId: CartSection.ID,
        history makeHistory: ((CartSection, CartSection, Date) -> (WorkSessionHistoryKind, String)?)? = nil,
        update: (inout CartSection) -> Void
    ) {
        guard let cartIndex = carts.firstIndex(where: { $0.id == cartId }) else { return }
        let changedAt = Date()
        let before = carts[cartIndex]
        update(&carts[cartIndex])
        let after = carts[cartIndex]
        guard before != after else { return }
        if let event = makeHistory?(before, after, changedAt) {
            appendHistory(kind: event.0, title: event.1, cartID: cartId, happenedAt: changedAt)
        }
        persist()
    }

    func mutateRoom(
        _ roomId: RoomCell.ID,
        history makeHistory: ((RoomCell, RoomCell, Date) -> (WorkSessionHistoryKind, String)?)? = nil,
        update: (inout RoomCell, Date) -> Void
    ) {
        guard let cartIndex = carts.firstIndex(where: { cart in
            cart.rooms.contains(where: { $0.id == roomId })
        }) else { return }
        guard let roomIndex = carts[cartIndex].rooms.firstIndex(where: { $0.id == roomId }) else {
            return
        }
        let changedAt = Date()
        let before = carts[cartIndex].rooms[roomIndex]
        update(&carts[cartIndex].rooms[roomIndex], changedAt)
        let after = carts[cartIndex].rooms[roomIndex]
        guard before != after else { return }
        if let event = makeHistory?(before, after, changedAt) {
            appendHistory(kind: event.0, title: event.1, roomID: roomId, cartID: carts[cartIndex].id, happenedAt: changedAt)
        }
        persist()
    }

    func mutateRoom(
        _ roomId: RoomCell.ID,
        history makeHistory: ((RoomCell, RoomCell, Date) -> (WorkSessionHistoryKind, String)?)? = nil,
        update: (inout RoomCell) -> Void
    ) {
        mutateRoom(roomId, history: makeHistory) { room, _ in
            update(&room)
        }
    }
}
