import Foundation

extension WorkSessionStore {
    var selectedCartNumbers: [Int] {
        selection.selectedCartNumbers
    }

    func territory(forCart cartNumber: Int) -> Territory? {
        selection.territory(forCart: cartNumber, hotelProfile: hotelProfile)
    }

    func selectedRooms(forCart cartNumber: Int) -> Set<RoomID> {
        selection.rooms(forCart: cartNumber)
    }

    func housekeeperID(forCart cartNumber: Int) -> HousekeeperID? {
        selection.housekeeperID(forCart: cartNumber)
    }

    func blockedRooms(forCart cartNumber: Int, territory: Territory) -> [RoomID: Int] {
        selection.blockedRooms(forCart: cartNumber, territory: territory)
    }

    @discardableResult
    func toggleCartSelection(_ cartNumber: Int) -> WorkSessionSelectionCommandResult {
        let changedAt = Date()
        let result = selection.toggleCart(cartNumber, hotelProfile: hotelProfile, changedAt: changedAt)
        reconcileCartsAfterSelectionChange(
            result,
            title: "Тележка \(cartNumber): выбор изменен",
            happenedAt: changedAt
        )
        return result
    }

    @discardableResult
    func setCartBinding(cartNumber: Int, territory: Territory) -> WorkSessionSelectionCommandResult {
        let changedAt = Date()
        let result = selection.setCartBinding(cartNumber: cartNumber, territory: territory, changedAt: changedAt)
        reconcileCartsAfterSelectionChange(
            result,
            title: "Тележка \(cartNumber): зона \(territory.id)",
            happenedAt: changedAt
        )
        return result
    }

    @discardableResult
    func setCartHousekeeper(
        cartNumber: Int,
        housekeeperID: HousekeeperID?
    ) -> WorkSessionSelectionCommandResult {
        let changedAt = Date()
        let result = selection.setHousekeeper(housekeeperID, cartNumber: cartNumber, changedAt: changedAt)
        reconcileCartsAfterSelectionChange(
            result,
            title: "Тележка \(cartNumber): уборщица изменена",
            happenedAt: changedAt
        )
        return result
    }

    @discardableResult
    func removeHousekeeperAssignments(
        housekeeperID: HousekeeperID
    ) -> WorkSessionSelectionCommandResult {
        let changedAt = Date()
        let result = selection.removeHousekeeperAssignments(housekeeperID: housekeeperID, changedAt: changedAt)
        reconcileCartsAfterSelectionChange(
            result,
            title: "Уборщица удалена из назначений",
            happenedAt: changedAt
        )
        return result
    }

    @discardableResult
    func toggleRoomSelection(cartNumber: Int, room: RoomID) -> WorkSessionSelectionCommandResult {
        let changedAt = Date()
        let result = selection.toggleRoom(cartNumber: cartNumber, room: room, changedAt: changedAt)
        reconcileCartsAfterSelectionChange(
            result,
            title: "\(room): выбор комнаты изменен",
            happenedAt: changedAt
        )
        return result
    }

    @discardableResult
    func lockWorkday() -> WorkSessionSelectionCommandResult {
        let changedAt = Date()
        let result = selection.lockWorkday(changedAt: changedAt)
        if result == .changed {
            appendHistory(kind: .workdayLocked, title: "Рабочий день зафиксирован", happenedAt: changedAt)
            persist()
        }
        return result
    }

    @discardableResult
    func unlockWorkdayForEditing() -> WorkSessionSelectionCommandResult {
        let changedAt = Date()
        let result = selection.unlockWorkdayForEditing(changedAt: changedAt)
        if result == .changed {
            appendHistory(kind: .workdayUnlocked, title: "Рабочий день открыт для редактирования", happenedAt: changedAt)
            persist()
        }
        return result
    }

    static func selectionState(from carts: [CartSection], hotelProfile: HotelProfile = .current) -> WorkSessionSelectionState {
        var state = WorkSessionSelectionState()
        for cart in carts {
            let territory = RoomCatalog.territory(id: cart.building, in: hotelProfile)
                ?? cart.rooms.lazy.compactMap { RoomCatalog.territory(for: $0.id, in: hotelProfile) }.first
                ?? WorkSessionSelectionRules.preferredTerritory(
                    forCart: cart.id,
                    existingBindings: state.cartBindings,
                    hotelProfile: hotelProfile
                )
            let cartNumber = WorkSessionSelectionRules.clampedCartNumber(cart.id)
            state.cartBindings[cartNumber] = WorkSessionCartBinding(
                cartNumber: cartNumber,
                territoryID: territory.id
            )
            let selectedRooms = Set(cart.rooms.map(\.id))
            if !selectedRooms.isEmpty {
                state.cartRoomSelections[cartNumber] = selectedRooms
            }
        }
        return state
    }

    private func reconcileCartsAfterSelectionChange(
        _ result: WorkSessionSelectionCommandResult,
        title: String,
        happenedAt: Date
    ) {
        guard result == .changed else { return }
        carts = WorkSessionBuilder.makeCarts(
            from: selection,
            preserving: carts.flatMap(\.rooms),
            hotelProfile: hotelProfile
        )
        appendHistory(kind: .selectionChanged, title: title, happenedAt: happenedAt)
        persist()
    }
}
