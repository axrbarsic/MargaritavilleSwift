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
        Housekeeper(id: "anazline", displayName: "Anazline", palette: .aqua),
        Housekeeper(id: "bebitha", displayName: "Bebitha", palette: .amber),
        Housekeeper(id: "denise", displayName: "Denise", palette: .coral),
        Housekeeper(id: "fabiola", displayName: "Fabiola", palette: .orchid),
        Housekeeper(id: "francia", displayName: "Francia", palette: .sky),
        Housekeeper(id: "gurline", displayName: "Gurline", palette: .mint),
        Housekeeper(id: "ketty", displayName: "Ketty", palette: .ruby),
        Housekeeper(id: "luisa", displayName: "Luisa", palette: .violet),
        Housekeeper(id: "marie", displayName: "Marie", palette: .lime),
        Housekeeper(id: "marie-pierre", displayName: "Marie Pierre", palette: .slate),
        Housekeeper(id: "nadia", displayName: "Nadia", palette: .aqua),
        Housekeeper(id: "nadia-m-dc", displayName: "Nadia M (DC)", palette: .amber),
        Housekeeper(id: "nidia", displayName: "Nidia", palette: .coral),
        Housekeeper(id: "omelene-pm", displayName: "Omelene PM", palette: .orchid),
        Housekeeper(id: "ritza", displayName: "Ritza", palette: .sky),
        Housekeeper(id: "rosalie", displayName: "Rosalie", palette: .mint),
        Housekeeper(id: "simone", displayName: "Simone", palette: .ruby),
        Housekeeper(id: "vida", displayName: "Vida", palette: .violet),
        Housekeeper(id: "wonderline", displayName: "Wonderline", palette: .lime)
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
