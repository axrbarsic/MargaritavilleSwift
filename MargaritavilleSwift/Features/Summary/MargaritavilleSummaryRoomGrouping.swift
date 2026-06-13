import Foundation

struct MargaritavilleSummaryRoomGroup: Equatable, Identifiable {
    let id: String
    let label: String
    let rooms: [RoomCell]
}

struct MargaritavilleSummaryHousekeeperSection: Equatable, Identifiable {
    let id: String
    let cartIDs: [CartSection.ID]
    let housekeeperID: HousekeeperID?
    let locationLabel: String
    let rooms: [RoomCell]

    var primaryCartID: CartSection.ID {
        cartIDs[0]
    }
}

enum MargaritavilleSummaryRoomGrouping {
    static func housekeeperSections(
        carts: [CartSection],
        selection: WorkSessionSelectionState,
        hotelProfile: HotelProfile,
        statusFilter: RoomStatus?
    ) -> [MargaritavilleSummaryHousekeeperSection] {
        let territoryOrder = Dictionary(
            uniqueKeysWithValues: hotelProfile.catalog.enumerated().map { index, territory in
                (territory.id, index)
            }
        )
        var buckets: [String: HousekeeperSectionAccumulator] = [:]

        for cart in carts {
            let housekeeperID = selection.housekeeperID(forCart: cart.id)
            let key = housekeeperID.map { "housekeeper-\($0)" } ?? "cart-\(cart.id)"
            let fallbackTerritory = selection.territory(forCart: cart.id, hotelProfile: hotelProfile)
            let filteredRooms = filteredRooms(from: cart.rooms, statusFilter: statusFilter)
            guard !filteredRooms.isEmpty else { continue }

            var bucket = buckets[key] ?? HousekeeperSectionAccumulator(
                id: key,
                firstCartID: cart.id,
                housekeeperID: housekeeperID
            )
            bucket.cartIDs.append(cart.id)
            bucket.rooms.append(contentsOf: filteredRooms)
            bucket.addLocations(
                for: filteredRooms,
                fallbackLabel: fallbackTerritory?.label ?? cart.building,
                hotelProfile: hotelProfile,
                territoryOrder: territoryOrder
            )
            buckets[key] = bucket
        }

        return buckets.values
            .sorted { $0.firstCartID < $1.firstCartID }
            .map { bucket in
                MargaritavilleSummaryHousekeeperSection(
                    id: bucket.id,
                    cartIDs: bucket.cartIDs.sorted(),
                    housekeeperID: bucket.housekeeperID,
                    locationLabel: bucket.locationLabel,
                    rooms: bucket.rooms.sorted { RoomCatalog.compareRoomIDs($0.id, $1.id) }
                )
            }
    }

    static func groups(
        rooms: [RoomCell],
        territories: [Territory],
        fallbackLabel: String
    ) -> [MargaritavilleSummaryRoomGroup] {
        var grouped: [MargaritavilleSummaryRoomGroup] = []
        var groupedRoomIDs = Set<RoomID>()

        for territory in territories {
            let territoryRoomIDs = Set(territory.rooms)
            let groupRooms = rooms
                .filter { territoryRoomIDs.contains($0.id) }
                .sorted { RoomCatalog.compareRoomIDs($0.id, $1.id) }
            guard !groupRooms.isEmpty else { continue }
            groupedRoomIDs.formUnion(groupRooms.map(\.id))
            grouped.append(
                MargaritavilleSummaryRoomGroup(
                    id: territory.id,
                    label: territory.label,
                    rooms: groupRooms
                )
            )
        }

        let fallbackRooms = rooms
            .filter { !groupedRoomIDs.contains($0.id) }
            .sorted { RoomCatalog.compareRoomIDs($0.id, $1.id) }
        if !fallbackRooms.isEmpty {
            grouped.append(
                MargaritavilleSummaryRoomGroup(
                    id: "fallback-\(fallbackLabel)",
                    label: fallbackLabel,
                    rooms: fallbackRooms
                )
            )
        }

        return grouped
    }

    private static func filteredRooms(
        from rooms: [RoomCell],
        statusFilter: RoomStatus?
    ) -> [RoomCell] {
        guard let statusFilter else { return rooms }
        return rooms.filter { $0.status(in: .simpleCycle) == statusFilter }
    }
}

private struct HousekeeperSectionAccumulator {
    let id: String
    let firstCartID: CartSection.ID
    let housekeeperID: HousekeeperID?
    var cartIDs: [CartSection.ID] = []
    var rooms: [RoomCell] = []
    private var locations: [String: Int] = [:]

    init(
        id: String,
        firstCartID: CartSection.ID,
        housekeeperID: HousekeeperID?
    ) {
        self.id = id
        self.firstCartID = firstCartID
        self.housekeeperID = housekeeperID
    }

    var locationLabel: String {
        locations
            .sorted {
                if $0.value != $1.value {
                    return $0.value < $1.value
                }
                return $0.key < $1.key
            }
            .map(\.key)
            .joined(separator: " ")
    }

    mutating func addLocations(
        for rooms: [RoomCell],
        fallbackLabel: String,
        hotelProfile: HotelProfile,
        territoryOrder: [String: Int]
    ) {
        var found = false
        for room in rooms {
            guard let territory = RoomCatalog.territory(for: room.id, in: hotelProfile) else { continue }
            locations[territory.label] = territoryOrder[territory.id] ?? Int.max
            found = true
        }
        if !found {
            for label in fallbackLabel.split(separator: "/").map(String.init) {
                locations[label] = territoryOrder[label] ?? Int.max
            }
        }
    }
}
