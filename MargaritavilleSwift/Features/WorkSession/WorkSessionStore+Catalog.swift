import Foundation

extension WorkSessionStore {
    func catalogTerritory(id: String) -> Territory? {
        effectiveCatalog.first { $0.id == id }
    }

    @discardableResult
    func addCatalogRoom(_ rawRoom: String) -> RoomCatalogEditResult {
        guard hotelProfile.id == HotelProfile.margaritaville.id else { return .unsupportedHotel }
        guard let roomID = RoomCatalog.normalizeRoomID(rawRoom),
              let territory = RoomCatalog.inferredTerritory(for: roomID, in: hotelProfile)
        else {
            return .invalidRoom
        }

        let now = Date()
        if let index = catalogOverrides.firstIndex(where: { $0.roomID == roomID }) {
            guard catalogOverrides[index].isRemoved else {
                return RoomCatalog.contains(roomID, in: effectiveCatalog) ? .duplicate : .changed
            }
            catalogOverrides[index].territoryID = territory.id
            catalogOverrides[index].isRemoved = false
            catalogOverrides[index].updatedAt = now
            persist()
            return .changed
        }

        guard !RoomCatalog.contains(roomID, in: effectiveCatalog) else { return .duplicate }
        catalogOverrides.append(RoomCatalogOverride(
            roomID: roomID,
            territoryID: territory.id,
            isRemoved: false,
            updatedAt: now
        ))
        persist()
        return .changed
    }

    @discardableResult
    func removeCatalogRoom(_ roomID: RoomID) -> RoomCatalogEditResult {
        guard hotelProfile.id == HotelProfile.margaritaville.id else { return .unsupportedHotel }
        guard let normalized = RoomCatalog.normalizeRoomID(roomID),
              let territory = RoomCatalog.inferredTerritory(for: normalized, in: hotelProfile)
        else {
            return .invalidRoom
        }
        guard !isRoomActiveInCurrentWorkday(normalized) else { return .blockedActiveRoom }

        let now = Date()
        if let index = catalogOverrides.firstIndex(where: { $0.roomID == normalized }) {
            if !catalogOverrides[index].isRemoved,
               RoomCatalog.territory(for: normalized, in: hotelProfile) == nil {
                catalogOverrides.remove(at: index)
            } else {
                catalogOverrides[index].territoryID = territory.id
                catalogOverrides[index].isRemoved = true
                catalogOverrides[index].updatedAt = now
            }
            persist()
            return .changed
        }

        guard RoomCatalog.contains(normalized, in: effectiveCatalog) else { return .invalidRoom }
        catalogOverrides.append(RoomCatalogOverride(
            roomID: normalized,
            territoryID: territory.id,
            isRemoved: true,
            updatedAt: now
        ))
        persist()
        return .changed
    }

    private func isRoomActiveInCurrentWorkday(_ roomID: RoomID) -> Bool {
        selection.selectedRooms.contains(roomID) || carts.contains { cart in
            cart.rooms.contains { $0.id == roomID }
        }
    }
}
