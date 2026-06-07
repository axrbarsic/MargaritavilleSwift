import Foundation
import Observation

@Observable
final class WorkSessionStore {
    @ObservationIgnored private let repository: WorkSessionRepository?
    @ObservationIgnored private(set) var lastPersistenceError: Error?

    var carts: [CartSection]

    init(carts: [CartSection], repository: WorkSessionRepository? = nil) {
        self.carts = carts
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
            if !room.opened {
                room.opened = true
                room.timeline.openedAt = room.timeline.openedAt ?? Date()
            }
            if room.completedTasks.contains(task) {
                room.completedTasks.remove(task)
            } else {
                room.completedTasks.insert(task)
                switch task {
                case .stripped:
                    room.timeline.strippedAt = room.timeline.strippedAt ?? Date()
                case .linen:
                    room.timeline.linenDeliveredAt = room.timeline.linenDeliveredAt ?? Date()
                case .balcony:
                    room.timeline.balconyCleanedAt = room.timeline.balconyCleanedAt ?? Date()
                }
            }
            room.timeline.completedAt = room.isReady ? room.timeline.completedAt ?? Date() : nil
        }
    }

    func toggleOpen(roomId: RoomCell.ID) {
        mutateRoom(roomId) { room in
            if room.opened || !room.completedTasks.isEmpty {
                room.opened = false
                room.completedTasks.removeAll()
                room.timeline.openedAt = nil
                room.timeline.strippedAt = nil
                room.timeline.linenDeliveredAt = nil
                room.timeline.balconyCleanedAt = nil
                room.timeline.completedAt = nil
            } else {
                room.opened = true
                room.scheduledTime = nil
                room.timeline.openedAt = room.timeline.openedAt ?? Date()
            }
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

    func room(id roomId: RoomCell.ID) -> RoomCell? {
        carts.lazy.flatMap(\.rooms).first { $0.id == roomId }
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

    private func persist() {
        guard let repository else { return }
        do {
            try repository.save(carts: carts)
            lastPersistenceError = nil
        } catch {
            lastPersistenceError = error
        }
    }
}

extension WorkSessionStore {
    static func load(repository: WorkSessionRepository = LocalWorkSessionRepository()) -> WorkSessionStore {
        do {
            if let storedCarts = try repository.loadCarts() {
                return WorkSessionStore(carts: storedCarts, repository: repository)
            }
        } catch {
            let store = WorkSessionStore(carts: seedCarts(), repository: repository)
            store.lastPersistenceError = error
            return store
        }
        return WorkSessionStore(carts: seedCarts(), repository: repository)
    }

    static func preview() -> WorkSessionStore {
        WorkSessionStore(carts: seedCarts())
    }

    private static func seedCarts() -> [CartSection] {
        [
            CartSection(id: 7, building: "A3", rooms: [
                RoomCell(id: "303", opened: true, completedTasks: Set(RoomTask.allCases), isVIP: true),
                RoomCell(id: "304", opened: true, completedTasks: Set(RoomTask.allCases), isVIP: false),
                RoomCell(id: "305", opened: true, completedTasks: Set(RoomTask.allCases), isVIP: false),
                RoomCell(id: "306", opened: false, completedTasks: [], isVIP: false, scheduledTime: Calendar.current.date(bySettingHour: 10, minute: 15, second: 0, of: Date())),
                RoomCell(id: "307", opened: true, completedTasks: [], isVIP: false),
                RoomCell(id: "308", opened: true, completedTasks: [.stripped], isVIP: true)
            ]),
            CartSection(id: 8, building: "A4", rooms: [
                RoomCell(id: "401", opened: false, completedTasks: [], isVIP: false),
                RoomCell(id: "402", opened: false, completedTasks: [], isVIP: false)
            ])
        ]
    }
}
