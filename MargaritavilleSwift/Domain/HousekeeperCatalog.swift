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
        Housekeeper(id: "kerlange", displayName: "Kerlange", palette: .slate),
        Housekeeper(id: "anazline", displayName: "Ana", palette: .aqua),
        Housekeeper(id: "bebitha", displayName: "Bebita", palette: .amber),
        Housekeeper(id: "denise", displayName: "Denise", palette: .coral),
        Housekeeper(id: "fabiola", displayName: "Fabiola", palette: .orchid),
        Housekeeper(id: "francia", displayName: "Francia", palette: .sky),
        Housekeeper(id: "gurline", displayName: "Gurlene", palette: .mint),
        Housekeeper(id: "ketty", displayName: "Ketty", palette: .ruby),
        Housekeeper(id: "luisa", displayName: "Luisa", palette: .violet),
        Housekeeper(id: "marie", displayName: "Marie", palette: .lime),
        Housekeeper(id: "marie-pierre", displayName: "Marie Pierre", palette: .slate),
        Housekeeper(id: "nadia", displayName: "Nadia", palette: .aqua),
        Housekeeper(id: "nadia-m-dc", displayName: "Nadia M (DC)", palette: .amber),
        Housekeeper(id: "nidia", displayName: "Nidia", palette: .coral),
        Housekeeper(id: "omelene-pm", displayName: "Omelene PM", palette: .orchid),
        Housekeeper(id: "ritza", displayName: "Ritza", palette: .sky),
        Housekeeper(id: "rosalie", displayName: "Rosaire", palette: .mint),
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

    static func canonicalHousekeepers(_ housekeepers: [Housekeeper]) -> [Housekeeper] {
        var canonical = normalizedHousekeepers(housekeepers).map { housekeeper in
            var next = housekeeper
            if let displayName = printedSheetDisplayNameByHousekeeperID[next.id] {
                next.displayName = displayName
            } else if let displayName = printedSheetDisplayName(for: next.displayName) {
                next.displayName = displayName
            }
            return next
        }
        guard !canonical.isEmpty else {
            return defaultHousekeepers
        }
        canonical = removingPrintedSheetDuplicates(from: canonical)
        if !containsHousekeeper(named: "Kerlange", in: canonical),
           let kerlange = makeHousekeeper(displayName: "Kerlange", existing: canonical) {
            canonical.insert(kerlange, at: 0)
        }
        return canonical.isEmpty ? defaultHousekeepers : canonical
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

    private static func removingPrintedSheetDuplicates(from housekeepers: [Housekeeper]) -> [Housekeeper] {
        var seenKeys: Set<String> = []
        return housekeepers.filter { housekeeper in
            seenKeys.insert(printedSheetDuplicateKey(for: housekeeper.displayName)).inserted
        }
    }

    private static func printedSheetDuplicateKey(for displayName: String) -> String {
        let candidates = Set(normalizedCandidates(for: displayName))
        for group in printedSheetDuplicateTokenGroups where !candidates.isDisjoint(with: group) {
            return group.sorted().joined(separator: "|")
        }
        return candidates.sorted().first ?? normalizedToken(displayName)
    }

    private static func containsHousekeeper(named name: String, in housekeepers: [Housekeeper]) -> Bool {
        let candidates = Set(normalizedCandidates(for: name))
        return housekeepers.contains { housekeeper in
            let housekeeperCandidates = normalizedCandidates(for: housekeeper.displayName)
            return housekeeperCandidates.contains { candidates.contains($0) }
        }
    }

    private static func printedSheetDisplayName(for displayName: String) -> String? {
        let key = printedSheetDuplicateKey(for: displayName)
        return printedSheetDisplayNameByDuplicateKey[key]
    }

    private static func normalizedCandidates(for displayName: String) -> [String] {
        let token = normalizedToken(displayName)
        var candidates: [String] = [token]
        if token.hasSuffix("pm") {
            candidates.append(String(token.dropLast(2)))
        }
        return candidates.filter { !$0.isEmpty }
    }

    private static func normalizedToken(_ displayName: String) -> String {
        displayName
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
            .unicodeScalars
            .filter { CharacterSet.alphanumerics.contains($0) }
            .map(String.init)
            .joined()
    }
}

private let printedSheetDuplicateTokenGroups: [Set<String>] = [
    ["ana", "anazine", "anazline"],
    ["bebita", "bebitha"],
    ["gurlene", "gurline"],
    ["kerlange", "kerlande"],
    ["milodene", "omelenepm"],
    ["rosaire", "rosalie", "rosario"]
]

private let printedSheetDisplayNameByHousekeeperID: [HousekeeperID: String] = [
    "anazline": "Ana",
    "bebitha": "Bebita",
    "gurline": "Gurlene",
    "omelene-pm": "Omelene PM",
    "rosalie": "Rosaire"
]

private let printedSheetDisplayNameByDuplicateKey: [String: String] = [
    "ana|anazine|anazline": "Ana",
    "bebita|bebitha": "Bebita",
    "gurlene|gurline": "Gurlene",
    "kerlande|kerlange": "Kerlange",
    "milodene|omelenepm": "Omelene PM",
    "rosaire|rosalie|rosario": "Rosaire"
]
