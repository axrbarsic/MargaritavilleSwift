import Foundation
import Observation

@Observable
final class WorkSessionStore {
    var carts: [CartSection]

    init(carts: [CartSection]) {
        self.carts = carts
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

    private func mutateRoom(_ roomId: RoomCell.ID, update: (inout RoomCell) -> Void) {
        guard let cartIndex = carts.firstIndex(where: { cart in
            cart.rooms.contains(where: { $0.id == roomId })
        }) else { return }
        guard let roomIndex = carts[cartIndex].rooms.firstIndex(where: { $0.id == roomId }) else {
            return
        }
        update(&carts[cartIndex].rooms[roomIndex])
    }
}

extension WorkSessionStore {
    static func preview() -> WorkSessionStore {
        WorkSessionStore(carts: [
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
        ])
    }
}
