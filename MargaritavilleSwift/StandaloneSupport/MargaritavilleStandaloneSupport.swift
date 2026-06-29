import Foundation

typealias HousekeeperID = String

struct Housekeeper: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: HousekeeperID
    var displayName: String
    var palette: HousekeeperPalette
}

enum HousekeeperPalette: String, CaseIterable, Codable, Identifiable, Sendable {
    case aqua
    case amber
    case coral
    case orchid
    case sky
    case mint
    case ruby
    case violet
    case lime
    case slate

    var id: String { rawValue }
}

enum MargaritavilleHousekeeperCatalog {
    static let defaultHousekeepers: [Housekeeper] = [
        Housekeeper(id: "kerlange", displayName: "Kerlange", palette: .aqua),
        Housekeeper(id: "ritza", displayName: "Ritza", palette: .sky),
        Housekeeper(id: "ana", displayName: "Ana", palette: .coral),
        Housekeeper(id: "bebita", displayName: "Bebita", palette: .amber),
        Housekeeper(id: "fabiola", displayName: "Fabiola", palette: .orchid),
        Housekeeper(id: "francia", displayName: "Francia", palette: .sky),
        Housekeeper(id: "gurlene", displayName: "Gurlene", palette: .mint),
        Housekeeper(id: "rosaire", displayName: "Rosaire", palette: .lime),
        Housekeeper(id: "wonderline", displayName: "Wonderline", palette: .violet),
        Housekeeper(id: "vida", displayName: "Vida", palette: .slate),
        Housekeeper(id: "simone", displayName: "Simone", palette: .ruby),
        Housekeeper(id: "omelene-pm", displayName: "Omelene PM", palette: .orchid),
        Housekeeper(id: "marie", displayName: "Marie", palette: .lime),
        Housekeeper(id: "luisa", displayName: "Luisa", palette: .violet),
        Housekeeper(id: "denise", displayName: "Denise", palette: .coral)
    ]

    static func housekeeper(id: HousekeeperID?, in housekeepers: [Housekeeper]) -> Housekeeper? {
        guard let id else { return nil }
        return housekeepers.first { $0.id == id }
    }

    static func normalizedID(_ value: HousekeeperID?) -> HousekeeperID? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func normalizedHousekeepers(_ housekeepers: [Housekeeper]) -> [Housekeeper] {
        var usedIDs: Set<HousekeeperID> = []
        return housekeepers.compactMap { housekeeper in
            let name = housekeeper.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            let id = uniqueID(
                preferredID: normalizedID(housekeeper.id) ?? stableID(for: name),
                usedIDs: &usedIDs
            )
            return Housekeeper(id: id, displayName: name, palette: housekeeper.palette)
        }
    }

    static func makeHousekeeper(
        displayName: String,
        existing: [Housekeeper]
    ) -> Housekeeper? {
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        var usedIDs = Set(existing.map(\.id))
        let id = uniqueID(preferredID: stableID(for: name), usedIDs: &usedIDs)
        let palette = HousekeeperPalette.allCases[existing.count % HousekeeperPalette.allCases.count]
        return Housekeeper(id: id, displayName: name, palette: palette)
    }

    private static func stableID(for displayName: String) -> HousekeeperID {
        let folded = displayName
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
        let scalars = folded.unicodeScalars.map { scalar -> Character in
            CharacterSet.alphanumerics.contains(scalar) ? Character(scalar) : "-"
        }
        let collapsed = String(scalars)
            .split(separator: "-")
            .joined(separator: "-")
        return collapsed.isEmpty ? "housekeeper" : collapsed
    }

    private static func uniqueID(
        preferredID: HousekeeperID,
        usedIDs: inout Set<HousekeeperID>
    ) -> HousekeeperID {
        if !usedIDs.contains(preferredID) {
            usedIDs.insert(preferredID)
            return preferredID
        }
        var suffix = 2
        while usedIDs.contains("\(preferredID)-\(suffix)") {
            suffix += 1
        }
        let id = "\(preferredID)-\(suffix)"
        usedIDs.insert(id)
        return id
    }
}

enum HotelWorkflowKind: String, Codable, Sendable {
    case tasksSLB
    case simpleCycle
}

enum HotelSummaryLayout: String, Codable, Sendable {
    case fullWidthBars
    case squareGrid4
}

struct HotelProfile: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let name: String
    let catalog: [Territory]
    let workflowKind: HotelWorkflowKind
    let dayCategoriesEnabled: Bool
    let summaryLayout: HotelSummaryLayout

    static let margaritaville = HotelProfile(
        id: "margaritaville",
        name: "Margaritaville",
        catalog: MargaritavilleStandaloneRoomCatalog.territories,
        workflowKind: .simpleCycle,
        dayCategoriesEnabled: true,
        summaryLayout: .squareGrid4
    )

    static let current = margaritaville
    static let all: [HotelProfile] = [.margaritaville]

    static func profile(id: String?) -> HotelProfile? {
        guard let id else { return nil }
        return all.first { $0.id == id }
    }

    func territory(id: String) -> Territory? {
        catalog.first { $0.id == id }
    }

    func territory(for room: RoomID) -> Territory? {
        catalog.first { $0.rooms.contains(room) }
    }
}

private enum MargaritavilleStandaloneRoomCatalog {
    static let territories: [Territory] = [
        Territory(floor: 1, building: .a, rooms: ids(101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 114, 115, 116, 117, 118, 119, 120, 122, 123, 124, 125, 126, 127, 128, 129)),
        Territory(floor: 1, building: .b, rooms: ids(143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170)),
        Territory(floor: 2, building: .a, rooms: ids(201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232)),
        Territory(floor: 2, building: .b, rooms: ids(239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255, 256, 257, 258, 259, 260, 262, 263, 264, 265, 266, 267, 268, 269, 270)),
        Territory(floor: 3, building: .a, rooms: ids(301, 302, 303, 304, 305, 306, 307, 308, 309, 310, 311, 312, 314, 315, 316, 317, 318, 319, 320, 321, 322, 323, 324, 325, 326, 327, 328)),
        Territory(floor: 3, building: .b, rooms: ids(330, 331, 332, 333, 334, 335, 336, 337, 338, 339, 340, 341, 342, 343, 344, 345, 346, 347, 348, 349, 351, 352, 353, 354, 355, 356, 357, 358, 359, 360, 361, 362, 363, 364, 365, 366, 367, 368, 369, 370))
    ]

    private static func ids(_ values: Int...) -> [RoomID] {
        values.map(String.init)
    }
}
