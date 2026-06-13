import Foundation

extension AppSettingsStore {
    func housekeeper(id: HousekeeperID?) -> Housekeeper? {
        MargaritavilleHousekeeperCatalog.housekeeper(id: id, in: housekeepers)
    }

    @discardableResult
    func addHousekeeper(named displayName: String) -> Housekeeper? {
        guard let housekeeper = MargaritavilleHousekeeperCatalog.makeHousekeeper(
            displayName: displayName,
            existing: housekeepers
        ) else { return nil }
        housekeepers.append(housekeeper)
        return housekeeper
    }

    func renameHousekeeper(id: HousekeeperID, displayName: String) {
        guard let index = housekeepers.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var next = housekeepers
        next[index].displayName = trimmed
        housekeepers = next
    }

    func setHousekeeperPalette(id: HousekeeperID, palette: HousekeeperPalette) {
        guard let index = housekeepers.firstIndex(where: { $0.id == id }) else { return }
        var next = housekeepers
        next[index].palette = palette
        housekeepers = next
    }

    func removeHousekeeper(id: HousekeeperID) {
        housekeepers.removeAll { $0.id == id }
        if housekeepers.isEmpty {
            housekeepers = MargaritavilleHousekeeperCatalog.defaultHousekeepers
        }
    }
}
