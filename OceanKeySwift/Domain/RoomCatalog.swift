import Foundation

typealias RoomID = String

enum Building: String, CaseIterable, Codable, Hashable, Sendable {
    case a
    case b

    var label: String {
        rawValue.uppercased()
    }
}

struct Territory: Codable, Hashable, Identifiable, Sendable {
    let floor: Int
    let building: Building
    let rooms: [RoomID]

    var id: String {
        "\(building.label)\(floor)"
    }

    var label: String {
        id
    }
}

enum RoomCatalog {
    static let currentTerritories: [Territory] = [2, 3, 4, 5].flatMap { floor in
        [
            Territory(
                floor: floor,
                building: .a,
                rooms: floor == 2
                    ? roomsOnFloor(floor, from: 1, through: 9) + ["\(floor)10A", "\(floor)10B"]
                    : roomsOnFloor(floor, from: 1, through: 10)
            ),
            Territory(
                floor: floor,
                building: .b,
                rooms: roomsOnFloor(floor, from: 11, through: 29)
            )
        ]
    }

    static let territories = currentTerritories

    static func roomsOnFloor(_ floor: Int, from: Int, through: Int) -> [RoomID] {
        (from...through).map { "\(floor * 100 + $0)" }
    }

    static func normalizeRoomID(_ value: String?) -> RoomID? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return trimmed.isEmpty ? nil : trimmed
    }

    static func compareRoomIDs(_ left: RoomID, _ right: RoomID) -> Bool {
        compareRoomIDOrder(left, right) == .orderedAscending
    }

    static func compareRoomIDOrder(_ left: RoomID, _ right: RoomID) -> ComparisonResult {
        let parsedLeft = parseRoomID(left)
        let parsedRight = parseRoomID(right)
        guard let parsedLeft, let parsedRight else {
            return left.compare(right)
        }
        if parsedLeft.number != parsedRight.number {
            return parsedLeft.number < parsedRight.number ? .orderedAscending : .orderedDescending
        }
        return parsedLeft.suffix.compare(parsedRight.suffix)
    }

    static func displayRoomID(_ room: RoomID, compactLetteredLabels: Bool) -> RoomID {
        guard compactLetteredLabels else { return room }
        switch room {
        case "210A": return "21A"
        case "210B": return "21B"
        default: return room
        }
    }

    static func territory(id: String) -> Territory? {
        territories.first { $0.id == id }
    }

    static func territory(id: String, in profile: HotelProfile) -> Territory? {
        profile.territory(id: id)
    }

    static func territory(for room: RoomID) -> Territory? {
        territories.first { $0.rooms.contains(room) }
    }

    static func territory(for room: RoomID, in profile: HotelProfile) -> Territory? {
        profile.territory(for: room)
    }

    static func effectiveTerritories(
        for profile: HotelProfile,
        overrides: [RoomCatalogOverride]
    ) -> [Territory] {
        var roomSets = Dictionary(
            uniqueKeysWithValues: profile.catalog.map { territory in
                (territory.id, Set(territory.rooms))
            }
        )
        let territoryOrder = Dictionary(
            uniqueKeysWithValues: profile.catalog.enumerated().map { index, territory in
                (territory.id, index)
            }
        )

        for override in overrides {
            guard profile.territory(id: override.territoryID) != nil else { continue }
            if override.isRemoved {
                roomSets[override.territoryID, default: []].remove(override.roomID)
            } else {
                roomSets[override.territoryID, default: []].insert(override.roomID)
            }
        }

        return profile.catalog.compactMap { territory in
            let rooms = (roomSets[territory.id] ?? [])
                .sorted(by: compareRoomIDs)
            guard !rooms.isEmpty || territoryOrder[territory.id] != nil else { return nil }
            return Territory(floor: territory.floor, building: territory.building, rooms: rooms)
        }
    }

    static func inferredTerritory(for room: RoomID, in profile: HotelProfile) -> Territory? {
        if let existing = territory(for: room, in: profile) {
            return existing
        }
        guard let parsed = parseRoomID(room) else { return nil }
        let floor = parsed.number / 100
        let sameFloor = profile.catalog.filter { $0.floor == floor }
        guard !sameFloor.isEmpty else { return nil }

        if profile.id == HotelProfile.margaritaville.id,
           let bTerritory = sameFloor.first(where: { $0.building == .b }),
           let bStart = bTerritory.rooms.compactMap({ parseRoomID($0)?.number }).min(),
           parsed.number >= bStart {
            return bTerritory
        }

        if profile.id == HotelProfile.margaritaville.id,
           let aTerritory = sameFloor.first(where: { $0.building == .a }) {
            return aTerritory
        }

        if let aTerritory = sameFloor.first(where: { $0.building == .a }),
           let aMax = aTerritory.rooms.compactMap({ parseRoomID($0)?.number }).max(),
           parsed.number <= aMax {
            return aTerritory
        }
        return sameFloor.first(where: { $0.building == .b }) ?? sameFloor.first
    }

    static func contains(_ room: RoomID, in territories: [Territory]) -> Bool {
        territories.contains { $0.rooms.contains(room) }
    }

    static func territorySummaryLabel(for rooms: some Sequence<RoomID>, fallback: String) -> String {
        let labels = Set(rooms.compactMap { territory(for: $0)?.label })
        guard !labels.isEmpty else { return fallback }
        return labels.sorted { compareTerritoryLabels($0, $1) }.joined(separator: "/")
    }

    static func territorySummaryLabel(
        for rooms: some Sequence<RoomID>,
        fallback: String,
        profile: HotelProfile
    ) -> String {
        let labels = Set(rooms.compactMap { territory(for: $0, in: profile)?.label })
        guard !labels.isEmpty else { return fallback }
        return labels.sorted { compareTerritoryLabels($0, $1, profile: profile) }.joined(separator: "/")
    }

    private static func compareTerritoryLabels(_ left: String, _ right: String) -> Bool {
        guard let leftTerritory = territory(id: left),
              let rightTerritory = territory(id: right)
        else {
            return left < right
        }
        if leftTerritory.building != rightTerritory.building {
            return leftTerritory.building.label < rightTerritory.building.label
        }
        return leftTerritory.floor < rightTerritory.floor
    }

    private static func compareTerritoryLabels(_ left: String, _ right: String, profile: HotelProfile) -> Bool {
        guard let leftTerritory = territory(id: left, in: profile),
              let rightTerritory = territory(id: right, in: profile)
        else {
            return left < right
        }
        if leftTerritory.building != rightTerritory.building {
            return leftTerritory.building.label < rightTerritory.building.label
        }
        return leftTerritory.floor < rightTerritory.floor
    }

    private static func parseRoomID(_ value: RoomID) -> (number: Int, suffix: String)? {
        let pattern = #"^(\d+)([A-Z]*)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        guard let match = regex.firstMatch(in: value, range: range),
              match.numberOfRanges == 3,
              let numberRange = Range(match.range(at: 1), in: value),
              let number = Int(value[numberRange]),
              let suffixRange = Range(match.range(at: 2), in: value)
        else {
            return nil
        }
        return (number, String(value[suffixRange]))
    }
}
