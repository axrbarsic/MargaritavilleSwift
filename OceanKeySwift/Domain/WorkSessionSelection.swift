import Foundation

struct WorkSessionCartBinding: Codable, Equatable, Hashable, Sendable {
    let cartNumber: Int
    let territoryID: String

    var isValid: Bool {
        cartNumber > 0 && !territoryID.isEmpty
    }
}

struct WorkSessionSelectionState: Codable, Equatable, Sendable {
    var cartBindings: [Int: WorkSessionCartBinding] = [:]
    var cartRoomSelections: [Int: Set<RoomID>] = [:]
    var workdayLocked = false

    var selectedCartNumbers: [Int] {
        cartBindings.keys.sorted()
    }

    var selectedRooms: Set<RoomID> {
        Set(cartRoomSelections.values.flatMap { $0 })
    }

    var hasSelectedRooms: Bool {
        !selectedRooms.isEmpty
    }

    func rooms(forCart cartNumber: Int) -> Set<RoomID> {
        cartRoomSelections[WorkSessionSelectionRules.clampedCartNumber(cartNumber)] ?? []
    }

    func rooms(forCart cartNumber: Int, territory: Territory) -> Set<RoomID> {
        rooms(forCart: cartNumber).filter { territory.rooms.contains($0) }
    }

    func roomOwnerCart(_ room: RoomID) -> Int? {
        for cart in cartRoomSelections.keys.sorted() {
            if cartRoomSelections[cart]?.contains(room) == true {
                return cart
            }
        }
        return nil
    }

    func blockedRooms(forCart cartNumber: Int, territory: Territory) -> [RoomID: Int] {
        let cart = WorkSessionSelectionRules.clampedCartNumber(cartNumber)
        var blocked: [RoomID: Int] = [:]
        for room in territory.rooms {
            if let owner = roomOwnerCart(room), owner != cart {
                blocked[room] = owner
            }
        }
        return blocked
    }

    func territory(forCart cartNumber: Int) -> Territory? {
        let cart = WorkSessionSelectionRules.clampedCartNumber(cartNumber)
        guard let binding = cartBindings[cart] else { return nil }
        return RoomCatalog.territory(id: binding.territoryID)
    }
}

enum WorkSessionSelectionRules {
    static let cartRange = 1...10

    static let preferredTerritoryByCart: [Int: String] = [
        1: "B5",
        2: "B5",
        3: "B4",
        4: "B4",
        5: "B3",
        6: "B3",
        7: "A3",
        8: "A4",
        9: "A5"
    ]

    static func clampedCartNumber(_ cartNumber: Int) -> Int {
        min(max(cartNumber, cartRange.lowerBound), cartRange.upperBound)
    }

    static func preferredTerritory(
        forCart cartNumber: Int,
        existingBindings: [Int: WorkSessionCartBinding]
    ) -> Territory {
        let cart = clampedCartNumber(cartNumber)
        if let preferredID = preferredTerritoryByCart[cart],
           let preferred = RoomCatalog.territory(id: preferredID) {
            return preferred
        }

        let boundTerritoryIDs = Set(existingBindings.values.map(\.territoryID))
        return RoomCatalog.territories.first { !boundTerritoryIDs.contains($0.id) }
            ?? RoomCatalog.territories[0]
    }
}

enum WorkSessionSelectionCommandResult: Equatable, Sendable {
    case changed
    case blocked
    case ignored
}

extension WorkSessionSelectionState {
    @discardableResult
    mutating func toggleCart(_ cartNumber: Int) -> WorkSessionSelectionCommandResult {
        guard !workdayLocked else { return .ignored }
        let cart = WorkSessionSelectionRules.clampedCartNumber(cartNumber)
        if cartBindings[cart] != nil {
            removeCart(cart)
            return .changed
        }

        let territory = WorkSessionSelectionRules.preferredTerritory(
            forCart: cart,
            existingBindings: cartBindings
        )
        cartBindings[cart] = WorkSessionCartBinding(cartNumber: cart, territoryID: territory.id)
        return .changed
    }

    @discardableResult
    mutating func setCartBinding(cartNumber: Int, territory: Territory) -> WorkSessionSelectionCommandResult {
        guard !workdayLocked else { return .ignored }
        let cart = WorkSessionSelectionRules.clampedCartNumber(cartNumber)
        cartBindings[cart] = WorkSessionCartBinding(cartNumber: cart, territoryID: territory.id)
        if let rooms = cartRoomSelections[cart] {
            cartRoomSelections[cart] = rooms.filter { territory.rooms.contains($0) }
        }
        trimEmptyRoomSelections()
        return .changed
    }

    @discardableResult
    mutating func toggleRoom(cartNumber: Int, room rawRoom: RoomID) -> WorkSessionSelectionCommandResult {
        guard !workdayLocked else { return .ignored }
        guard let room = RoomCatalog.normalizeRoomID(rawRoom) else { return .ignored }
        let cart = WorkSessionSelectionRules.clampedCartNumber(cartNumber)
        if let owner = roomOwnerCart(room), owner != cart {
            return .blocked
        }

        var cartRooms = cartRoomSelections[cart] ?? []
        if cartRooms.contains(room) {
            cartRooms.remove(room)
            cartRoomSelections[cart] = cartRooms
            trimEmptyRoomSelections()
            return .changed
        }

        cartRooms.insert(room)
        cartRoomSelections[cart] = cartRooms
        for otherCart in cartRoomSelections.keys where otherCart != cart {
            cartRoomSelections[otherCart]?.remove(room)
        }
        trimEmptyRoomSelections()
        return .changed
    }

    @discardableResult
    mutating func lockWorkday() -> WorkSessionSelectionCommandResult {
        guard !workdayLocked, hasSelectedRooms else { return .ignored }
        workdayLocked = true
        return .changed
    }

    @discardableResult
    mutating func unlockWorkdayForEditing() -> WorkSessionSelectionCommandResult {
        guard workdayLocked else { return .ignored }
        workdayLocked = false
        return .changed
    }

    mutating func removeRooms(_ rooms: Set<RoomID>) {
        for cart in cartRoomSelections.keys {
            cartRoomSelections[cart]?.subtract(rooms)
        }
        trimEmptyRoomSelections()
    }

    private mutating func removeCart(_ cart: Int) {
        cartBindings.removeValue(forKey: cart)
        cartRoomSelections.removeValue(forKey: cart)
    }

    private mutating func trimEmptyRoomSelections() {
        cartRoomSelections = cartRoomSelections.filter { !$0.value.isEmpty }
    }
}

enum WorkSessionBuilder {
    static func makeCarts(
        from selection: WorkSessionSelectionState,
        preserving existingRooms: [RoomCell] = [],
        now: Date = Date()
    ) -> [CartSection] {
        let existingByID = Dictionary(uniqueKeysWithValues: existingRooms.map { ($0.id, $0) })
        return selection.selectedCartNumbers.compactMap { cartNumber in
            guard let territory = selection.territory(forCart: cartNumber) else { return nil }
            let rooms = selection
                .rooms(forCart: cartNumber, territory: territory)
                .sorted(by: RoomCatalog.compareRoomIDs)
                .map { roomID in
                    existingByID[roomID] ?? RoomCell(
                        id: roomID,
                        opened: false,
                        completedTasks: [],
                        isVIP: false,
                        timeline: RoomTimeline(selectedAt: now)
                    )
                }
            guard !rooms.isEmpty || selection.cartBindings[cartNumber] != nil else {
                return nil
            }
            return CartSection(id: cartNumber, building: territory.label, rooms: rooms)
        }
    }
}
