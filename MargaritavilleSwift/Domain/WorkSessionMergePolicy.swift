import Foundation

enum WorkSessionMergePolicy {
    static func merged(local: WorkSessionSnapshot, remote: WorkSessionSnapshot) -> WorkSessionSnapshot {
        let selection = mergeSelection(local.selection, remote.selection)
        let carts = mergeCarts(
            local: local.carts,
            remote: remote.carts,
            selection: selection
        )
        let history = mergeHistory(local.history, remote.history)
        return WorkSessionSnapshot(
            schemaVersion: max(local.schemaVersion, remote.schemaVersion),
            selection: selection,
            carts: carts,
            history: history,
            updatedAt: max(local.updatedAt, remote.updatedAt)
        )
    }

    private static func mergeSelection(
        _ local: WorkSessionSelectionState,
        _ remote: WorkSessionSelectionState
    ) -> WorkSessionSelectionState {
        var result = WorkSessionSelectionState()
        let cartNumbers = Set(local.cartBindings.keys)
            .union(remote.cartBindings.keys)
            .union(local.cartBindingUpdatedAt.keys)
            .union(remote.cartBindingUpdatedAt.keys)
            .union(local.cartHousekeeperIDs.keys)
            .union(remote.cartHousekeeperIDs.keys)
            .union(local.cartHousekeeperUpdatedAt.keys)
            .union(remote.cartHousekeeperUpdatedAt.keys)

        for cart in cartNumbers {
            let useRemote = shouldUseRemote(
                localAt: local.cartBindingUpdatedAt[cart],
                remoteAt: remote.cartBindingUpdatedAt[cart],
                localExists: local.cartBindings[cart] != nil || local.cartBindingUpdatedAt[cart] != nil,
                remoteExists: remote.cartBindings[cart] != nil || remote.cartBindingUpdatedAt[cart] != nil
            )
            if useRemote {
                if let binding = remote.cartBindings[cart] {
                    result.cartBindings[cart] = binding
                }
                result.cartBindingUpdatedAt[cart] = remote.cartBindingUpdatedAt[cart]
            } else {
                if let binding = local.cartBindings[cart] {
                    result.cartBindings[cart] = binding
                }
                result.cartBindingUpdatedAt[cart] = local.cartBindingUpdatedAt[cart]
            }

            let useRemoteHousekeeper = shouldUseRemote(
                localAt: local.cartHousekeeperUpdatedAt[cart],
                remoteAt: remote.cartHousekeeperUpdatedAt[cart],
                localExists: local.cartHousekeeperIDs[cart] != nil || local.cartHousekeeperUpdatedAt[cart] != nil,
                remoteExists: remote.cartHousekeeperIDs[cart] != nil || remote.cartHousekeeperUpdatedAt[cart] != nil
            )
            if useRemoteHousekeeper {
                if result.cartBindings[cart] != nil, let housekeeperID = remote.cartHousekeeperIDs[cart] {
                    result.cartHousekeeperIDs[cart] = housekeeperID
                }
                result.cartHousekeeperUpdatedAt[cart] = remote.cartHousekeeperUpdatedAt[cart]
            } else {
                if result.cartBindings[cart] != nil, let housekeeperID = local.cartHousekeeperIDs[cart] {
                    result.cartHousekeeperIDs[cart] = housekeeperID
                }
                result.cartHousekeeperUpdatedAt[cart] = local.cartHousekeeperUpdatedAt[cart]
            }
        }

        let roomCartNumbers = Set(local.cartRoomSelections.keys)
            .union(remote.cartRoomSelections.keys)
            .union(local.roomSelectionUpdatedAt.keys)
            .union(remote.roomSelectionUpdatedAt.keys)
        for cart in roomCartNumbers {
            let localRooms = local.cartRoomSelections[cart, default: []]
            let remoteRooms = remote.cartRoomSelections[cart, default: []]
            let roomIDs = localRooms
                .union(remoteRooms)
                .union(local.roomSelectionUpdatedAt[cart, default: [:]].keys)
                .union(remote.roomSelectionUpdatedAt[cart, default: [:]].keys)
            for room in roomIDs {
                let useRemote = shouldUseRemote(
                    localAt: local.roomSelectionUpdatedAt[cart]?[room],
                    remoteAt: remote.roomSelectionUpdatedAt[cart]?[room],
                    localExists: localRooms.contains(room) || local.roomSelectionUpdatedAt[cart]?[room] != nil,
                    remoteExists: remoteRooms.contains(room) || remote.roomSelectionUpdatedAt[cart]?[room] != nil
                )
                let isSelected = useRemote ? remoteRooms.contains(room) : localRooms.contains(room)
                if isSelected {
                    result.cartRoomSelections[cart, default: []].insert(room)
                }
                let updatedAt = useRemote ? remote.roomSelectionUpdatedAt[cart]?[room] : local.roomSelectionUpdatedAt[cart]?[room]
                if let updatedAt {
                    var metadata = result.roomSelectionUpdatedAt[cart] ?? [:]
                    metadata[room] = updatedAt
                    result.roomSelectionUpdatedAt[cart] = metadata
                }
            }
        }

        let useRemoteLock = shouldUseRemote(
            localAt: local.workdayLockUpdatedAt,
            remoteAt: remote.workdayLockUpdatedAt,
            localExists: true,
            remoteExists: true
        )
        result.workdayLocked = useRemoteLock ? remote.workdayLocked : local.workdayLocked
        result.workdayLockUpdatedAt = useRemoteLock ? remote.workdayLockUpdatedAt : local.workdayLockUpdatedAt
        return result
    }

    private static func mergeCarts(
        local: [CartSection],
        remote: [CartSection],
        selection: WorkSessionSelectionState
    ) -> [CartSection] {
        let localByID = Dictionary(uniqueKeysWithValues: local.map { ($0.id, $0) })
        let remoteByID = Dictionary(uniqueKeysWithValues: remote.map { ($0.id, $0) })
        return selection.selectedCartNumbers.compactMap { cartID in
            let territory = selection.territory(forCart: cartID)
            let mergedCart: CartSection?
            switch (localByID[cartID], remoteByID[cartID]) {
            case (.some(let localCart), .some(let remoteCart)):
                mergedCart = mergeCart(local: localCart, remote: remoteCart, territory: territory)
            case (.some(let localCart), .none):
                mergedCart = localCart
            case (.none, .some(let remoteCart)):
                mergedCart = remoteCart
            case (.none, .none):
                mergedCart = territory.map { CartSection(id: cartID, building: $0.label, rooms: []) }
            }
            guard var cart = mergedCart else { return nil }
            let selectedRooms = selection.rooms(forCart: cartID)
            cart.rooms = cart.rooms
                .filter { selectedRooms.contains($0.id) }
                .sorted { RoomCatalog.compareRoomIDs($0.id, $1.id) }
            cart.building = RoomCatalog.territorySummaryLabel(
                for: cart.rooms.map(\.id),
                fallback: territory?.label ?? cart.building
            )
            return cart
        }
    }

    private static func mergeCart(
        local: CartSection,
        remote: CartSection,
        territory: Territory?
    ) -> CartSection {
        let roomIDs = Set(local.rooms.map(\.id)).union(remote.rooms.map(\.id))
        let localRooms = Dictionary(uniqueKeysWithValues: local.rooms.map { ($0.id, $0) })
        let remoteRooms = Dictionary(uniqueKeysWithValues: remote.rooms.map { ($0.id, $0) })
        let rooms = roomIDs.compactMap { roomID -> RoomCell? in
            switch (localRooms[roomID], remoteRooms[roomID]) {
            case (.some(let localRoom), .some(let remoteRoom)):
                return mergeRoom(local: localRoom, remote: remoteRoom)
            case (.some(let room), .none), (.none, .some(let room)):
                return room
            case (.none, .none):
                return nil
            }
        }
        return CartSection(
            id: local.id,
            building: RoomCatalog.territorySummaryLabel(
                for: rooms.map(\.id),
                fallback: territory?.label ?? local.building
            ),
            rooms: rooms.sorted { RoomCatalog.compareRoomIDs($0.id, $1.id) },
            note: newestValue(
                local: local.note,
                localAt: local.noteUpdatedAt,
                remote: remote.note,
                remoteAt: remote.noteUpdatedAt
            ),
            noteUpdatedAt: newestDate(local.noteUpdatedAt, remote.noteUpdatedAt),
            mediaAttachments: mergeMedia(local.mediaAttachments, remote.mediaAttachments),
            consumables: mergeConsumables(local.consumables, remote.consumables)
        )
    }

    private static func mergeRoom(local: RoomCell, remote: RoomCell) -> RoomCell {
        var result = local
        result.opened = newestValue(
            local: local.opened,
            localAt: local.openedUpdatedAt,
            remote: remote.opened,
            remoteAt: remote.openedUpdatedAt
        )
        result.openedUpdatedAt = newestDate(local.openedUpdatedAt, remote.openedUpdatedAt)
        result.completedTasks = mergeTasks(local: local, remote: remote)
        result.strippedUpdatedAt = newestDate(local.strippedUpdatedAt, remote.strippedUpdatedAt)
        result.linenUpdatedAt = newestDate(local.linenUpdatedAt, remote.linenUpdatedAt)
        result.balconyUpdatedAt = newestDate(local.balconyUpdatedAt, remote.balconyUpdatedAt)
        result.isVIP = newestValue(local: local.isVIP, localAt: local.vipUpdatedAt, remote: remote.isVIP, remoteAt: remote.vipUpdatedAt)
        result.vipUpdatedAt = newestDate(local.vipUpdatedAt, remote.vipUpdatedAt)
        result.scheduledTime = newestValue(
            local: local.scheduledTime,
            localAt: local.scheduledUpdatedAt,
            remote: remote.scheduledTime,
            remoteAt: remote.scheduledUpdatedAt
        )
        result.scheduledUpdatedAt = newestDate(local.scheduledUpdatedAt, remote.scheduledUpdatedAt)
        result.timeline = mergeTimeline(local.timeline, remote.timeline)
        result.textNote = newestValue(local: local.textNote, localAt: local.textNoteUpdatedAt, remote: remote.textNote, remoteAt: remote.textNoteUpdatedAt)
        result.textNoteUpdatedAt = newestDate(local.textNoteUpdatedAt, remote.textNoteUpdatedAt)
        result.voiceTranscript = newestValue(
            local: local.voiceTranscript,
            localAt: local.voiceTranscriptUpdatedAt,
            remote: remote.voiceTranscript,
            remoteAt: remote.voiceTranscriptUpdatedAt
        )
        result.voiceTranscriptUpdatedAt = newestDate(local.voiceTranscriptUpdatedAt, remote.voiceTranscriptUpdatedAt)
        result.mediaAttachments = mergeMedia(local.mediaAttachments, remote.mediaAttachments)
        return result
    }

    private static func mergeTasks(local: RoomCell, remote: RoomCell) -> Set<RoomTask> {
        var tasks: Set<RoomTask> = []
        for task in RoomTask.allCases {
            let localHas = local.completedTasks.contains(task)
            let remoteHas = remote.completedTasks.contains(task)
            let useRemote: Bool
            switch task {
            case .stripped:
                useRemote = shouldUseRemote(localAt: local.strippedUpdatedAt, remoteAt: remote.strippedUpdatedAt, localExists: true, remoteExists: true)
            case .linen:
                useRemote = shouldUseRemote(localAt: local.linenUpdatedAt, remoteAt: remote.linenUpdatedAt, localExists: true, remoteExists: true)
            case .balcony:
                useRemote = shouldUseRemote(localAt: local.balconyUpdatedAt, remoteAt: remote.balconyUpdatedAt, localExists: true, remoteExists: true)
            }
            if useRemote ? remoteHas : localHas {
                tasks.insert(task)
            }
        }
        return tasks
    }

    private static func mergeTimeline(_ local: RoomTimeline, _ remote: RoomTimeline) -> RoomTimeline {
        RoomTimeline(
            selectedAt: earliestDate(local.selectedAt, remote.selectedAt),
            openedAt: earliestDate(local.openedAt, remote.openedAt),
            strippedAt: earliestDate(local.strippedAt, remote.strippedAt),
            linenDeliveredAt: earliestDate(local.linenDeliveredAt, remote.linenDeliveredAt),
            balconyCleanedAt: earliestDate(local.balconyCleanedAt, remote.balconyCleanedAt),
            completedAt: earliestDate(local.completedAt, remote.completedAt)
        )
    }

    private static func mergeHistory(
        _ local: [WorkSessionHistoryEntry],
        _ remote: [WorkSessionHistoryEntry]
    ) -> [WorkSessionHistoryEntry] {
        var entriesByID = Dictionary(uniqueKeysWithValues: local.map { ($0.id, $0) })
        for entry in remote where entriesByID[entry.id] == nil {
            entriesByID[entry.id] = entry
        }
        return entriesByID.values.sorted { $0.happenedAt > $1.happenedAt }
    }

    private static func mergeMedia(
        _ local: [MediaAttachment]?,
        _ remote: [MediaAttachment]?
    ) -> [MediaAttachment]? {
        var attachmentsByID = Dictionary(uniqueKeysWithValues: (local ?? []).map { ($0.id, $0) })
        for attachment in remote ?? [] where attachmentsByID[attachment.id] == nil {
            attachmentsByID[attachment.id] = attachment
        }
        let attachments = attachmentsByID.values.sorted { $0.createdAt > $1.createdAt }
        return attachments.isEmpty ? nil : attachments
    }

    private static func mergeConsumables(
        _ local: [CartConsumableItem]?,
        _ remote: [CartConsumableItem]?
    ) -> [CartConsumableItem]? {
        let ids = Set((local ?? []).map(\.id)).union((remote ?? []).map(\.id))
        let localByID = Dictionary(uniqueKeysWithValues: (local ?? []).map { ($0.id, $0) })
        let remoteByID = Dictionary(uniqueKeysWithValues: (remote ?? []).map { ($0.id, $0) })
        let items = ids.sorted().compactMap { id -> CartConsumableItem? in
            switch (localByID[id], remoteByID[id]) {
            case (.some(let localItem), .some(let remoteItem)):
                return shouldUseRemote(
                    localAt: localItem.updatedAt,
                    remoteAt: remoteItem.updatedAt,
                    localExists: true,
                    remoteExists: true
                ) ? remoteItem : localItem
            case (.some(let item), .none), (.none, .some(let item)):
                return item
            case (.none, .none):
                return nil
            }
        }
        return items.isEmpty ? nil : items
    }

    private static func newestValue<T>(
        local: T,
        localAt: Date?,
        remote: T,
        remoteAt: Date?
    ) -> T {
        shouldUseRemote(localAt: localAt, remoteAt: remoteAt, localExists: true, remoteExists: true) ? remote : local
    }

    private static func shouldUseRemote(
        localAt: Date?,
        remoteAt: Date?,
        localExists: Bool,
        remoteExists: Bool
    ) -> Bool {
        guard remoteExists else { return false }
        guard localExists else { return true }
        guard let remoteAt else { return false }
        guard let localAt else { return true }
        return remoteAt > localAt
    }

    private static func newestDate(_ local: Date?, _ remote: Date?) -> Date? {
        switch (local, remote) {
        case (.some(let local), .some(let remote)):
            return max(local, remote)
        case (.some(let local), .none):
            return local
        case (.none, .some(let remote)):
            return remote
        case (.none, .none):
            return nil
        }
    }

    private static func earliestDate(_ local: Date?, _ remote: Date?) -> Date? {
        switch (local, remote) {
        case (.some(let local), .some(let remote)):
            return min(local, remote)
        case (.some(let local), .none):
            return local
        case (.none, .some(let remote)):
            return remote
        case (.none, .none):
            return nil
        }
    }
}
