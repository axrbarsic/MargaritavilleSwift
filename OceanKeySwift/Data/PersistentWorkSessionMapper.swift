import Foundation
import SwiftData

enum PersistentWorkSessionMapper {
    static func snapshot(from session: PersistentWorkSession) -> WorkSessionSnapshot {
        WorkSessionSnapshot(
            schemaVersion: session.schemaVersion,
            selection: selection(from: session),
            carts: (session.carts ?? [])
                .sorted { $0.displayOrder < $1.displayOrder }
                .map(cart(from:)),
            history: history(from: session.historyEntries ?? []),
            updatedAt: session.updatedAt
        )
    }

    static func upsert(
        snapshot: WorkSessionSnapshot,
        in context: ModelContext
    ) throws {
        let session = try fetchOrCreateSession(in: context)
        session.schemaVersion = snapshot.schemaVersion
        session.updatedAt = snapshot.updatedAt
        session.workdayLocked = snapshot.selection.workdayLocked
        session.workdayLockUpdatedAt = snapshot.selection.workdayLockUpdatedAt
        syncCartBindings(snapshot.selection, session: session, context: context)
        syncRoomSelections(
            snapshot.selection.cartRoomSelections,
            metadata: snapshot.selection.roomSelectionUpdatedAt,
            session: session,
            context: context
        )
        syncCarts(snapshot.carts, session: session, context: context)
        try syncHistory(snapshot.history, session: session, context: context)
    }

    private static func selection(from session: PersistentWorkSession) -> WorkSessionSelectionState {
        var bindings: [Int: WorkSessionCartBinding] = [:]
        var bindingUpdatedAt: [Int: Date] = [:]
        for binding in session.cartBindings ?? [] {
            if let updatedAt = binding.updatedAt {
                bindingUpdatedAt[binding.cartNumber] = updatedAt
            }
            if binding.isSelected != false, !binding.territoryID.isEmpty {
                bindings[binding.cartNumber] = WorkSessionCartBinding(
                    cartNumber: binding.cartNumber,
                    territoryID: binding.territoryID
                )
            }
        }
        var groupedRooms: [Int: Set<RoomID>] = [:]
        var roomUpdatedAt: [Int: [RoomID: Date]] = [:]
        for selection in session.roomSelections ?? [] {
            if selection.isSelected != false {
                groupedRooms[selection.cartNumber, default: []].insert(selection.roomID)
            }
            if let updatedAt = selection.updatedAt {
                var roomMetadata = roomUpdatedAt[selection.cartNumber] ?? [:]
                roomMetadata[selection.roomID] = updatedAt
                roomUpdatedAt[selection.cartNumber] = roomMetadata
            }
        }
        return WorkSessionSelectionState(
            cartBindings: bindings,
            cartBindingUpdatedAt: bindingUpdatedAt,
            cartRoomSelections: groupedRooms,
            roomSelectionUpdatedAt: roomUpdatedAt,
            workdayLocked: session.workdayLocked,
            workdayLockUpdatedAt: session.workdayLockUpdatedAt
        )
    }

    private static func cart(from record: PersistentCart) -> CartSection {
        CartSection(
            id: record.cartNumber,
            building: record.building,
            rooms: (record.rooms ?? []).sorted { $0.displayOrder < $1.displayOrder }.map(room(from:)),
            note: record.note,
            noteUpdatedAt: record.noteUpdatedAt,
            mediaAttachments: media(from: record.mediaAttachments ?? []),
            consumables: consumables(from: record.consumables ?? [])
        )
    }

    private static func room(from record: PersistentRoom) -> RoomCell {
        RoomCell(
            id: record.roomID,
            opened: record.opened,
            openedUpdatedAt: record.openedUpdatedAt,
            completedTasks: taskSet(from: record.completedTaskValues),
            strippedUpdatedAt: record.strippedUpdatedAt,
            linenUpdatedAt: record.linenUpdatedAt,
            balconyUpdatedAt: record.balconyUpdatedAt,
            isVIP: record.isVIP,
            vipUpdatedAt: record.vipUpdatedAt,
            scheduledTime: record.scheduledTime,
            scheduledUpdatedAt: record.scheduledUpdatedAt,
            timeline: RoomTimeline(
                selectedAt: record.selectedAt,
                openedAt: record.openedAt,
                strippedAt: record.strippedAt,
                linenDeliveredAt: record.linenDeliveredAt,
                balconyCleanedAt: record.balconyCleanedAt,
                completedAt: record.completedAt
            ),
            textNote: record.textNote,
            textNoteUpdatedAt: record.textNoteUpdatedAt,
            voiceTranscript: record.voiceTranscript,
            voiceTranscriptUpdatedAt: record.voiceTranscriptUpdatedAt,
            mediaAttachments: media(from: record.mediaAttachments ?? [])
        )
    }

    private static func media(from records: [PersistentMediaAttachment]) -> [MediaAttachment]? {
        let attachments = records
            .sorted { $0.displayOrder < $1.displayOrder }
            .compactMap { record -> MediaAttachment? in
                guard let kind = MediaKind(rawValue: record.kindRawValue) else { return nil }
                return MediaAttachment(
                    id: record.attachmentID,
                    kind: kind,
                    relativePath: record.relativePath,
                    createdAt: record.createdAt,
                    completedAt: record.completedAt
                )
            }
        return attachments.isEmpty ? nil : attachments
    }

    private static func fetchOrCreateSession(in context: ModelContext) throws -> PersistentWorkSession {
        var descriptor = FetchDescriptor<PersistentWorkSession>(
            predicate: #Predicate { $0.id == "current" }
        )
        descriptor.fetchLimit = 1
        if let session = try context.fetch(descriptor).first {
            return session
        }
        let session = PersistentWorkSession()
        context.insert(session)
        return session
    }

    private static func syncCartBindings(
        _ selection: WorkSessionSelectionState,
        session: PersistentWorkSession,
        context: ModelContext
    ) {
        (session.cartBindings ?? []).forEach { context.delete($0) }
        let cartNumbers = Set(selection.cartBindings.keys).union(selection.cartBindingUpdatedAt.keys)
        session.cartBindings = cartNumbers.sorted().compactMap { cartNumber in
            if let binding = selection.cartBindings[cartNumber] {
                return PersistentCartBinding(
                    cartNumber: cartNumber,
                    territoryID: binding.territoryID,
                    isSelected: true,
                    updatedAt: selection.cartBindingUpdatedAt[cartNumber]
                )
            }
            return PersistentCartBinding(
                cartNumber: cartNumber,
                territoryID: "",
                isSelected: false,
                updatedAt: selection.cartBindingUpdatedAt[cartNumber]
            )
        }
    }

    private static func syncRoomSelections(
        _ selections: [Int: Set<RoomID>],
        metadata: [Int: [RoomID: Date]],
        session: PersistentWorkSession,
        context: ModelContext
    ) {
        (session.roomSelections ?? []).forEach { context.delete($0) }
        let cartNumbers = Set(selections.keys).union(metadata.keys)
        session.roomSelections = cartNumbers.sorted().flatMap { cartNumber in
            let activeRooms = selections[cartNumber, default: []]
            let metadataRooms = Set(metadata[cartNumber, default: [:]].keys)
            return activeRooms.union(metadataRooms).sorted(by: RoomCatalog.compareRoomIDs).map { room in
                PersistentRoomSelection(
                    cartNumber: cartNumber,
                    roomID: room,
                    isSelected: activeRooms.contains(room),
                    updatedAt: metadata[cartNumber]?[room]
                )
            }
        }
    }


    private static func syncCarts(
        _ carts: [CartSection],
        session: PersistentWorkSession,
        context: ModelContext
    ) {
        let desiredCartNumbers = Set(carts.map(\.id))
        (session.carts ?? []).filter { !desiredCartNumbers.contains($0.cartNumber) }
            .forEach { context.delete($0) }

        var existing: [Int: PersistentCart] = [:]
        for record in session.carts ?? [] {
            existing[record.cartNumber] = record
        }
        var nextCarts = (session.carts ?? []).filter { desiredCartNumbers.contains($0.cartNumber) }
        for (index, cart) in carts.enumerated() {
            let record: PersistentCart
            if existing[cart.id] == nil {
                record = PersistentCart(
                    cartNumber: cart.id,
                    displayOrder: index,
                    building: cart.building
                )
                context.insert(record)
                existing[cart.id] = record
                nextCarts.append(record)
            } else {
                record = existing[cart.id]!
            }
            record.displayOrder = index
            record.building = cart.building
            record.note = cart.note
            record.noteUpdatedAt = cart.noteUpdatedAt
            syncRooms(cart.rooms, cart: record, context: context)
            record.mediaAttachments = syncMedia(
                cart.mediaAttachments ?? [],
                existingRecords: record.mediaAttachments,
                context: context
            )
            record.consumables = syncConsumables(
                cart.consumables ?? [],
                existingRecords: record.consumables,
                context: context
            )
        }
        session.carts = nextCarts
    }

    private static func syncRooms(
        _ rooms: [RoomCell],
        cart: PersistentCart,
        context: ModelContext
    ) {
        let desiredRoomIDs = Set(rooms.map(\.id))
        (cart.rooms ?? []).filter { !desiredRoomIDs.contains($0.roomID) }
            .forEach { context.delete($0) }

        var existing: [RoomID: PersistentRoom] = [:]
        for record in cart.rooms ?? [] {
            existing[record.roomID] = record
        }
        var nextRooms = (cart.rooms ?? []).filter { desiredRoomIDs.contains($0.roomID) }
        for (index, room) in rooms.enumerated() {
            let record: PersistentRoom
            if existing[room.id] == nil {
                record = PersistentRoom(
                    roomID: room.id,
                    displayOrder: index,
                    opened: room.opened,
                    openedUpdatedAt: room.openedUpdatedAt,
                    completedTaskValues: taskValues(from: room.completedTasks),
                    strippedUpdatedAt: room.strippedUpdatedAt,
                    linenUpdatedAt: room.linenUpdatedAt,
                    balconyUpdatedAt: room.balconyUpdatedAt,
                    isVIP: room.isVIP,
                    vipUpdatedAt: room.vipUpdatedAt,
                    scheduledTime: room.scheduledTime,
                    scheduledUpdatedAt: room.scheduledUpdatedAt
                )
                context.insert(record)
                existing[room.id] = record
                nextRooms.append(record)
            } else {
                record = existing[room.id]!
            }
            record.displayOrder = index
            record.opened = room.opened
            record.openedUpdatedAt = room.openedUpdatedAt
            record.completedTaskValues = taskValues(from: room.completedTasks)
            record.strippedUpdatedAt = room.strippedUpdatedAt
            record.linenUpdatedAt = room.linenUpdatedAt
            record.balconyUpdatedAt = room.balconyUpdatedAt
            record.isVIP = room.isVIP
            record.vipUpdatedAt = room.vipUpdatedAt
            record.scheduledTime = room.scheduledTime
            record.scheduledUpdatedAt = room.scheduledUpdatedAt
            record.selectedAt = room.timeline.selectedAt
            record.openedAt = room.timeline.openedAt
            record.strippedAt = room.timeline.strippedAt
            record.linenDeliveredAt = room.timeline.linenDeliveredAt
            record.balconyCleanedAt = room.timeline.balconyCleanedAt
            record.completedAt = room.timeline.completedAt
            record.textNote = room.textNote
            record.textNoteUpdatedAt = room.textNoteUpdatedAt
            record.voiceTranscript = room.voiceTranscript
            record.voiceTranscriptUpdatedAt = room.voiceTranscriptUpdatedAt
            record.mediaAttachments = syncMedia(
                room.mediaAttachments ?? [],
                existingRecords: record.mediaAttachments,
                context: context
            )
        }
        cart.rooms = nextRooms
    }

    private static func syncMedia(
        _ attachments: [MediaAttachment],
        existingRecords records: [PersistentMediaAttachment]?,
        context: ModelContext
    ) -> [PersistentMediaAttachment] {
        let records = records ?? []
        let desiredIDs = Set(attachments.map(\.id))
        records.filter { !desiredIDs.contains($0.attachmentID) }
            .forEach { context.delete($0) }

        var existing: [UUID: PersistentMediaAttachment] = [:]
        for record in records {
            existing[record.attachmentID] = record
        }
        var nextRecords: [PersistentMediaAttachment] = []
        for (index, attachment) in attachments.enumerated() {
            let record: PersistentMediaAttachment
            if existing[attachment.id] == nil {
                record = PersistentMediaAttachment(
                    attachmentID: attachment.id,
                    kindRawValue: attachment.kind.rawValue,
                    relativePath: attachment.relativePath,
                    createdAt: attachment.createdAt,
                    completedAt: attachment.completedAt,
                    displayOrder: index
                )
                context.insert(record)
                existing[attachment.id] = record
            } else {
                record = existing[attachment.id]!
            }
            record.kindRawValue = attachment.kind.rawValue
            record.relativePath = attachment.relativePath
            record.createdAt = attachment.createdAt
            record.completedAt = attachment.completedAt
            record.displayOrder = index
            nextRecords.append(record)
        }
        return nextRecords
    }

    private static func taskValues(from tasks: Set<RoomTask>) -> String {
        tasks.map(\.rawValue).sorted().joined(separator: ",")
    }

    private static func taskSet(from values: String) -> Set<RoomTask> {
        Set(values.split(separator: ",").compactMap { RoomTask(rawValue: String($0)) })
    }
}
