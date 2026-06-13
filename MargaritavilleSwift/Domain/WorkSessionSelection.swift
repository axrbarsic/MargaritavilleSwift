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
    var cartBindingUpdatedAt: [Int: Date] = [:]
    var cartHousekeeperIDs: [Int: HousekeeperID] = [:]
    var cartHousekeeperUpdatedAt: [Int: Date] = [:]
    var cartRoomSelections: [Int: Set<RoomID>] = [:]
    var roomSelectionUpdatedAt: [Int: [RoomID: Date]] = [:]
    var workdayLocked = false
    var workdayLockUpdatedAt: Date?

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
        territory(forCart: cartNumber, hotelProfile: .current)
    }

    func territory(forCart cartNumber: Int, hotelProfile: HotelProfile) -> Territory? {
        let cart = WorkSessionSelectionRules.clampedCartNumber(cartNumber)
        guard let binding = cartBindings[cart] else { return nil }
        return RoomCatalog.territory(id: binding.territoryID, in: hotelProfile)
    }

    func housekeeperID(forCart cartNumber: Int) -> HousekeeperID? {
        cartHousekeeperIDs[WorkSessionSelectionRules.clampedCartNumber(cartNumber)]
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

    static let margaritavillePreferredTerritoryByCart: [Int: String] = [
        1: "A1",
        2: "B1",
        3: "A2",
        4: "B2",
        5: "A3",
        6: "B3"
    ]

    static func clampedCartNumber(_ cartNumber: Int) -> Int {
        min(max(cartNumber, cartRange.lowerBound), cartRange.upperBound)
    }

    static func preferredTerritory(
        forCart cartNumber: Int,
        existingBindings: [Int: WorkSessionCartBinding]
    ) -> Territory {
        preferredTerritory(forCart: cartNumber, existingBindings: existingBindings, hotelProfile: .current)
    }

    static func preferredTerritory(
        forCart cartNumber: Int,
        existingBindings: [Int: WorkSessionCartBinding],
        hotelProfile: HotelProfile
    ) -> Territory {
        let cart = clampedCartNumber(cartNumber)
        let preferredMap = hotelProfile.id == HotelProfile.margaritaville.id
            ? margaritavillePreferredTerritoryByCart
            : preferredTerritoryByCart
        if let preferredID = preferredMap[cart],
           let preferred = RoomCatalog.territory(id: preferredID, in: hotelProfile) {
            return preferred
        }

        let boundTerritoryIDs = Set(existingBindings.values.map(\.territoryID))
        return hotelProfile.catalog.first { !boundTerritoryIDs.contains($0.id) }
            ?? hotelProfile.catalog[0]
    }
}

enum WorkSessionSelectionCommandResult: Equatable, Sendable {
    case changed
    case blocked
    case ignored
}

extension WorkSessionSelectionState {
    @discardableResult
    mutating func toggleCart(
        _ cartNumber: Int,
        changedAt: Date = Date()
    ) -> WorkSessionSelectionCommandResult {
        toggleCart(cartNumber, hotelProfile: .current, changedAt: changedAt)
    }

    @discardableResult
    mutating func toggleCart(
        _ cartNumber: Int,
        hotelProfile: HotelProfile,
        changedAt: Date = Date()
    ) -> WorkSessionSelectionCommandResult {
        guard !workdayLocked else { return .ignored }
        let cart = WorkSessionSelectionRules.clampedCartNumber(cartNumber)
        if cartBindings[cart] != nil {
            removeCart(cart, changedAt: changedAt)
            return .changed
        }

        let territory = WorkSessionSelectionRules.preferredTerritory(
            forCart: cart,
            existingBindings: cartBindings,
            hotelProfile: hotelProfile
        )
        cartBindings[cart] = WorkSessionCartBinding(cartNumber: cart, territoryID: territory.id)
        cartBindingUpdatedAt[cart] = changedAt
        return .changed
    }

    @discardableResult
    mutating func setCartBinding(
        cartNumber: Int,
        territory: Territory,
        changedAt: Date = Date()
    ) -> WorkSessionSelectionCommandResult {
        guard !workdayLocked else { return .ignored }
        let cart = WorkSessionSelectionRules.clampedCartNumber(cartNumber)
        cartBindings[cart] = WorkSessionCartBinding(cartNumber: cart, territoryID: territory.id)
        cartBindingUpdatedAt[cart] = changedAt
        return .changed
    }

    @discardableResult
    mutating func setHousekeeper(
        _ housekeeperID: HousekeeperID?,
        cartNumber: Int,
        changedAt: Date = Date()
    ) -> WorkSessionSelectionCommandResult {
        guard !workdayLocked else { return .ignored }
        let cart = WorkSessionSelectionRules.clampedCartNumber(cartNumber)
        guard cartBindings[cart] != nil else { return .ignored }
        let normalizedID = MargaritavilleHousekeeperCatalog.normalizedID(housekeeperID)
        guard cartHousekeeperIDs[cart] != normalizedID else { return .ignored }

        if let normalizedID {
            cartHousekeeperIDs[cart] = normalizedID
        } else {
            cartHousekeeperIDs.removeValue(forKey: cart)
        }
        cartHousekeeperUpdatedAt[cart] = changedAt
        return .changed
    }

    @discardableResult
    mutating func toggleRoom(
        cartNumber: Int,
        room rawRoom: RoomID,
        changedAt: Date = Date()
    ) -> WorkSessionSelectionCommandResult {
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
            markRoomSelection(cart: cart, room: room, changedAt: changedAt)
            trimEmptyRoomSelections()
            return .changed
        }

        cartRooms.insert(room)
        cartRoomSelections[cart] = cartRooms
        markRoomSelection(cart: cart, room: room, changedAt: changedAt)
        for otherCart in cartRoomSelections.keys where otherCart != cart {
            if cartRoomSelections[otherCart]?.remove(room) != nil {
                markRoomSelection(cart: otherCart, room: room, changedAt: changedAt)
            }
        }
        trimEmptyRoomSelections()
        return .changed
    }

    @discardableResult
    mutating func lockWorkday(changedAt: Date = Date()) -> WorkSessionSelectionCommandResult {
        guard !workdayLocked, hasSelectedRooms else { return .ignored }
        workdayLocked = true
        workdayLockUpdatedAt = changedAt
        return .changed
    }

    @discardableResult
    mutating func unlockWorkdayForEditing(changedAt: Date = Date()) -> WorkSessionSelectionCommandResult {
        guard workdayLocked else { return .ignored }
        workdayLocked = false
        workdayLockUpdatedAt = changedAt
        return .changed
    }

    mutating func removeRooms(_ rooms: Set<RoomID>, changedAt: Date = Date()) {
        for cart in cartRoomSelections.keys {
            let removed = cartRoomSelections[cart]?.intersection(rooms) ?? []
            cartRoomSelections[cart]?.subtract(rooms)
            for room in removed {
                markRoomSelection(cart: cart, room: room, changedAt: changedAt)
            }
        }
        trimEmptyRoomSelections()
    }

    mutating func removeHousekeeperAssignments(
        housekeeperID: HousekeeperID,
        changedAt: Date = Date()
    ) -> WorkSessionSelectionCommandResult {
        guard !workdayLocked else { return .ignored }
        let carts = cartHousekeeperIDs
            .filter { $0.value == housekeeperID }
            .map(\.key)
        guard !carts.isEmpty else { return .ignored }
        for cart in carts {
            cartHousekeeperIDs.removeValue(forKey: cart)
            cartHousekeeperUpdatedAt[cart] = changedAt
        }
        return .changed
    }

    private mutating func removeCart(_ cart: Int, changedAt: Date) {
        for room in cartRoomSelections[cart] ?? [] {
            markRoomSelection(cart: cart, room: room, changedAt: changedAt)
        }
        cartBindings.removeValue(forKey: cart)
        cartBindingUpdatedAt[cart] = changedAt
        cartHousekeeperIDs.removeValue(forKey: cart)
        cartHousekeeperUpdatedAt[cart] = changedAt
        cartRoomSelections.removeValue(forKey: cart)
    }

    private mutating func markRoomSelection(cart: Int, room: RoomID, changedAt: Date) {
        var metadata = roomSelectionUpdatedAt[cart] ?? [:]
        metadata[room] = changedAt
        roomSelectionUpdatedAt[cart] = metadata
    }

    private mutating func trimEmptyRoomSelections() {
        cartRoomSelections = cartRoomSelections.filter { !$0.value.isEmpty }
    }
}

enum WorkSessionBuilder {
    static func makeCarts(
        from selection: WorkSessionSelectionState,
        preserving existingRooms: [RoomCell] = [],
        hotelProfile: HotelProfile = .current,
        now: Date = Date()
    ) -> [CartSection] {
        let existingByID = Dictionary(uniqueKeysWithValues: existingRooms.map { ($0.id, $0) })
        return selection.selectedCartNumbers.compactMap { cartNumber in
            guard let territory = selection.territory(forCart: cartNumber, hotelProfile: hotelProfile) else { return nil }
            let rooms = selection
                .rooms(forCart: cartNumber)
                .sorted(by: RoomCatalog.compareRoomIDs)
                .map { roomID in
                    existingByID[roomID] ?? RoomCell(
                        id: roomID,
                        opened: false,
                        completedTasks: [],
                        isVIP: false,
                        statusChangedAt: now,
                        timeline: RoomTimeline(selectedAt: now)
                    )
                }
            guard !rooms.isEmpty || selection.cartBindings[cartNumber] != nil else {
                return nil
            }
            let buildingLabel = RoomCatalog.territorySummaryLabel(
                for: rooms.map(\.id),
                fallback: territory.label,
                profile: hotelProfile
            )
            return CartSection(id: cartNumber, building: buildingLabel, rooms: rooms)
        }
    }
}
