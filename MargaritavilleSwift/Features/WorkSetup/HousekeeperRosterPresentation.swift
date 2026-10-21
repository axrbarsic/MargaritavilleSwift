import Foundation

enum HousekeeperRosterPresentation {
    static func sorted(
        _ housekeepers: [Housekeeper],
        locale: Locale = .current
    ) -> [Housekeeper] {
        housekeepers.sorted { lhs, rhs in
            compare(lhs, rhs, locale: locale)
        }
    }

    static func suggestions(
        for rawPrefix: String,
        in housekeepers: [Housekeeper],
        locale: Locale = .current
    ) -> [Housekeeper] {
        let prefix = trimmed(rawPrefix)
        guard !prefix.isEmpty else { return [] }
        return sorted(
            housekeepers.filter { housekeeper in
                trimmed(housekeeper.displayName).range(
                    of: prefix,
                    options: [.anchored, .caseInsensitive, .diacriticInsensitive],
                    range: nil,
                    locale: locale
                ) != nil
            },
            locale: locale
        )
    }

    private static func compare(
        _ lhs: Housekeeper,
        _ rhs: Housekeeper,
        locale: Locale
    ) -> Bool {
        let lhsTrimmed = trimmed(lhs.displayName)
        let rhsTrimmed = trimmed(rhs.displayName)
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]

        let normalizedOrder = lhsTrimmed.compare(
            rhsTrimmed,
            options: options,
            range: nil,
            locale: locale
        )
        if normalizedOrder != .orderedSame {
            return normalizedOrder == .orderedAscending
        }

        let originalOrder = lhsTrimmed.compare(
            rhsTrimmed,
            options: [],
            range: nil,
            locale: locale
        )
        if originalOrder != .orderedSame {
            return originalOrder == .orderedAscending
        }
        return lhs.id < rhs.id
    }

    private static func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
