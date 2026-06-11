import SwiftData

extension PersistentWorkSessionMapper {
    static func catalogOverrides(from records: [PersistentCatalogOverride]) -> [RoomCatalogOverride] {
        records
            .sorted { RoomCatalog.compareRoomIDs($0.roomID, $1.roomID) }
            .map {
                RoomCatalogOverride(
                    roomID: $0.roomID,
                    territoryID: $0.territoryID,
                    isRemoved: $0.isRemoved,
                    updatedAt: $0.updatedAt
                )
            }
    }

    static func syncCatalogOverrides(
        _ overrides: [RoomCatalogOverride],
        session: PersistentWorkSession,
        context: ModelContext
    ) {
        (session.catalogOverrides ?? []).forEach { context.delete($0) }
        session.catalogOverrides = overrides
            .sorted { RoomCatalog.compareRoomIDs($0.roomID, $1.roomID) }
            .map { override in
                let record = PersistentCatalogOverride(
                    roomID: override.roomID,
                    territoryID: override.territoryID,
                    isRemoved: override.isRemoved,
                    updatedAt: override.updatedAt
                )
                record.session = session
                return record
            }
    }
}
