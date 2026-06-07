import Foundation
import Observation

@Observable
final class WorkSessionStore {
    @ObservationIgnored let repository: WorkSessionRepository?
    @ObservationIgnored var lastPersistenceError: Error?

    var carts: [CartSection]
    var selection: WorkSessionSelectionState

    init(
        carts: [CartSection],
        selection: WorkSessionSelectionState? = nil,
        repository: WorkSessionRepository? = nil
    ) {
        self.carts = carts
        self.selection = selection ?? Self.selectionState(from: carts)
        self.repository = repository
    }

    var counts: SummaryCounts {
        let rooms = carts.flatMap(\.rooms)
        let completed = rooms.filter(\.isReady).count
        return SummaryCounts(
            total: rooms.count,
            completed: completed,
            remaining: rooms.count - completed
        )
    }

    var visibleRoomIDs: [RoomCell.ID] {
        carts.flatMap { cart in
            cart.rooms.map(\.id)
        }
    }

    func toggleTask(_ task: RoomTask, roomId: RoomCell.ID) {
        mutateRoom(roomId) { room in
            guard room.opened else { return }
            let previousTasks = room.completedTasks
            if room.completedTasks.contains(task) {
                room.completedTasks.remove(task)
            } else {
                room.completedTasks.insert(task)
            }
            room.timeline = room.timeline.updatedForTransition(
                previousOpened: true,
                nextOpened: true,
                previousTasks: previousTasks,
                nextTasks: room.completedTasks,
                changedAt: Date()
            )
        }
    }

    func toggleOpen(roomId: RoomCell.ID) {
        mutateRoom(roomId) { room in
            let previousOpened = room.opened
            let previousTasks = room.completedTasks
            if room.opened {
                guard room.completedTasks.isEmpty else { return }
                room.opened = false
            } else {
                room.opened = true
                room.scheduledTime = nil
            }
            room.timeline = room.timeline.updatedForTransition(
                previousOpened: previousOpened,
                nextOpened: room.opened,
                previousTasks: previousTasks,
                nextTasks: room.completedTasks,
                changedAt: Date()
            )
        }
    }

    func toggleVIP(roomId: RoomCell.ID) {
        mutateRoom(roomId) { room in
            room.isVIP.toggle()
        }
    }

    func toggleSchedule(roomId: RoomCell.ID) {
        mutateRoom(roomId) { room in
            if room.scheduledTime == nil {
                room.scheduledTime = Calendar.current.date(byAdding: .minute, value: 15, to: Date())
            } else {
                room.scheduledTime = nil
            }
        }
    }

    func setSchedule(_ scheduledTime: Date?, roomId: RoomCell.ID) {
        mutateRoom(roomId) { room in
            room.scheduledTime = scheduledTime
        }
    }

    @discardableResult
    func advanceScheduledRooms(now: Date = Date()) -> [RoomCell.ID] {
        var openedRoomIDs: [RoomCell.ID] = []
        var didMutate = false
        for cartIndex in carts.indices {
            for roomIndex in carts[cartIndex].rooms.indices {
                var room = carts[cartIndex].rooms[roomIndex]
                guard let scheduledTime = room.scheduledTime else { continue }
                guard scheduledTime <= now else { continue }
                guard !room.opened, room.completedTasks.isEmpty else {
                    room.scheduledTime = nil
                    carts[cartIndex].rooms[roomIndex] = room
                    didMutate = true
                    continue
                }

                room.opened = true
                room.scheduledTime = nil
                room.timeline.openedAt = room.timeline.openedAt ?? now
                carts[cartIndex].rooms[roomIndex] = room
                openedRoomIDs.append(room.id)
                didMutate = true
            }
        }

        if didMutate {
            persist()
        }
        return openedRoomIDs
    }

    func room(id roomId: RoomCell.ID) -> RoomCell? {
        carts.lazy.flatMap(\.rooms).first { $0.id == roomId }
    }

    func cart(id cartId: CartSection.ID) -> CartSection? {
        carts.first { $0.id == cartId }
    }

    func updateTextNote(_ text: String, roomId: RoomCell.ID) {
        mutateRoom(roomId) { room in
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            room.textNote = trimmed.isEmpty ? nil : text
            room.textNoteUpdatedAt = trimmed.isEmpty ? nil : Date()
        }
    }

    func updateVoiceTranscript(_ text: String, roomId: RoomCell.ID) {
        mutateRoom(roomId) { room in
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            room.voiceTranscript = trimmed.isEmpty ? nil : text
            room.voiceTranscriptUpdatedAt = trimmed.isEmpty ? nil : Date()
        }
    }

    func addRoomMedia(_ attachment: MediaAttachment, roomId: RoomCell.ID) {
        mutateRoom(roomId) { room in
            var attachments = room.mediaAttachments ?? []
            attachments.insert(attachment, at: 0)
            room.mediaAttachments = attachments
        }
    }

    func updateCartNote(_ text: String, cartId: CartSection.ID) {
        mutateCart(cartId) { cart in
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            cart.note = trimmed.isEmpty ? nil : text
            cart.noteUpdatedAt = trimmed.isEmpty ? nil : Date()
        }
    }

    func addCartMedia(_ attachment: MediaAttachment, cartId: CartSection.ID) {
        mutateCart(cartId) { cart in
            var attachments = cart.mediaAttachments ?? []
            attachments.insert(attachment, at: 0)
            cart.mediaAttachments = attachments
        }
    }

    private func mutateCart(_ cartId: CartSection.ID, update: (inout CartSection) -> Void) {
        guard let cartIndex = carts.firstIndex(where: { $0.id == cartId }) else { return }
        update(&carts[cartIndex])
        persist()
    }

    private func mutateRoom(_ roomId: RoomCell.ID, update: (inout RoomCell) -> Void) {
        guard let cartIndex = carts.firstIndex(where: { cart in
            cart.rooms.contains(where: { $0.id == roomId })
        }) else { return }
        guard let roomIndex = carts[cartIndex].rooms.firstIndex(where: { $0.id == roomId }) else {
            return
        }
        update(&carts[cartIndex].rooms[roomIndex])
        persist()
    }

}
