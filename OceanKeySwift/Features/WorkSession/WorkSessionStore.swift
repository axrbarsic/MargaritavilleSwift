import Foundation
import Observation

@Observable
final class WorkSessionStore {
    @ObservationIgnored let repository: WorkSessionRepository?
    @ObservationIgnored let hotelProfile: HotelProfile
    @ObservationIgnored var lastPersistenceError: Error?

    var carts: [CartSection]
    var selection: WorkSessionSelectionState
    var catalogOverrides: [RoomCatalogOverride]
    var history: [WorkSessionHistoryEntry]

    init(
        carts: [CartSection],
        selection: WorkSessionSelectionState? = nil,
        catalogOverrides: [RoomCatalogOverride] = [],
        history: [WorkSessionHistoryEntry] = [],
        hotelProfile: HotelProfile = .current,
        repository: WorkSessionRepository? = nil
    ) {
        self.carts = carts
        self.selection = selection ?? Self.selectionState(from: carts, hotelProfile: hotelProfile)
        self.catalogOverrides = catalogOverrides
        self.history = history
        self.hotelProfile = hotelProfile
        self.repository = repository
    }

    var counts: SummaryCounts {
        let rooms = carts.flatMap(\.rooms)
        let completed = rooms.filter { $0.isReady(in: hotelProfile.workflowKind) }.count
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

    var effectiveCatalog: [Territory] {
        RoomCatalog.effectiveTerritories(for: hotelProfile, overrides: catalogOverrides)
    }

    func toggleTask(_ task: RoomTask, roomId: RoomCell.ID) {
        mutateRoom(roomId, history: { before, after, _ in
            guard before.completedTasks != after.completedTasks else { return nil }
            let enabled = after.completedTasks.contains(task)
            return (
                .roomTaskChanged,
                "\(after.id): \(task.rawValue) \(enabled ? "отмечено" : "снято")"
            )
        }) { room, changedAt in
            guard room.opened else { return }
            let previousStatus = room.status(in: hotelProfile.workflowKind)
            let previousTasks = room.completedTasks
            if room.completedTasks.contains(task) {
                room.completedTasks.remove(task)
            } else {
                room.completedTasks.insert(task)
            }
            room.markTaskStateUpdated(task, at: changedAt)
            room.timeline = room.timeline.updatedForTransition(
                previousOpened: true,
                nextOpened: true,
                previousTasks: previousTasks,
                nextTasks: room.completedTasks,
                changedAt: changedAt
            )
            room.markStatusChangedIfNeeded(
                from: previousStatus,
                workflowKind: hotelProfile.workflowKind,
                changedAt: changedAt
            )
        }
    }

    func toggleOpen(roomId: RoomCell.ID) {
        if hotelProfile.workflowKind == .simpleCycle {
            advanceSimpleCycle(roomId: roomId)
            return
        }
        mutateRoom(roomId, history: { before, after, _ in
            guard before.opened != after.opened else { return nil }
            return (
                after.opened ? .roomOpened : .roomClosed,
                "\(after.id): \(after.opened ? "открыта" : "закрыта")"
            )
        }) { room, changedAt in
            let previousStatus = room.status(in: hotelProfile.workflowKind)
            let previousOpened = room.opened
            let previousTasks = room.completedTasks
            if room.opened {
                guard room.completedTasks.isEmpty else { return }
                room.opened = false
            } else {
                room.opened = true
                room.scheduledTime = nil
            }
            room.openedUpdatedAt = changedAt
            room.timeline = room.timeline.updatedForTransition(
                previousOpened: previousOpened,
                nextOpened: room.opened,
                previousTasks: previousTasks,
                nextTasks: room.completedTasks,
                changedAt: changedAt
            )
            room.markStatusChangedIfNeeded(
                from: previousStatus,
                workflowKind: hotelProfile.workflowKind,
                changedAt: changedAt
            )
        }
    }

    func toggleVIP(roomId: RoomCell.ID) {
        mutateRoom(roomId, history: { _, after, _ in
            (
                .roomVIPChanged,
                "\(after.id): VIP \(after.isVIP ? "включен" : "выключен")"
            )
        }) { room, changedAt in
            room.isVIP.toggle()
            room.vipUpdatedAt = changedAt
        }
    }

    func toggleSchedule(roomId: RoomCell.ID) {
        mutateRoom(roomId, history: { before, after, _ in
            guard before.scheduledTime != after.scheduledTime else { return nil }
            return (
                .roomScheduleChanged,
                "\(after.id): время \(after.scheduledTime == nil ? "снято" : "установлено")"
            )
        }) { room, changedAt in
            let previousStatus = room.status(in: hotelProfile.workflowKind)
            if room.scheduledTime == nil {
                room.scheduledTime = Calendar.current.date(byAdding: .minute, value: 15, to: changedAt)
            } else {
                room.scheduledTime = nil
            }
            room.scheduledUpdatedAt = changedAt
            room.markStatusChangedIfNeeded(
                from: previousStatus,
                workflowKind: hotelProfile.workflowKind,
                changedAt: changedAt
            )
        }
    }

    func setSchedule(_ scheduledTime: Date?, roomId: RoomCell.ID) {
        mutateRoom(roomId, history: { before, after, _ in
            guard before.scheduledTime != after.scheduledTime else { return nil }
            return (
                .roomScheduleChanged,
                "\(after.id): время \(after.scheduledTime == nil ? "снято" : "установлено")"
            )
        }) { room, changedAt in
            let previousStatus = room.status(in: hotelProfile.workflowKind)
            room.scheduledTime = scheduledTime
            room.scheduledUpdatedAt = changedAt
            room.markStatusChangedIfNeeded(
                from: previousStatus,
                workflowKind: hotelProfile.workflowKind,
                changedAt: changedAt
            )
        }
    }

    func setDayCategory(_ category: RoomDayCategory?, time: Date? = nil, roomId: RoomCell.ID) {
        guard hotelProfile.dayCategoriesEnabled else { return }
        mutateRoom(roomId, history: { before, after, _ in
            guard before.dayCategory != after.dayCategory || before.dayCategoryTime != after.dayCategoryTime else {
                return nil
            }
            let label = after.dayCategory?.title ?? "без категории"
            return (.roomDayCategoryChanged, "\(after.id): \(label)")
        }) { room, changedAt in
            room.dayCategory = category
            room.dayCategoryTime = category == nil ? nil : time
            room.dayCategoryUpdatedAt = changedAt
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
                let previousStatus = room.status(in: hotelProfile.workflowKind)
                guard !room.opened, room.completedTasks.isEmpty else {
                    room.scheduledTime = nil
                    room.scheduledUpdatedAt = now
                    room.markStatusChangedIfNeeded(
                        from: previousStatus,
                        workflowKind: hotelProfile.workflowKind,
                        changedAt: now
                    )
                    carts[cartIndex].rooms[roomIndex] = room
                    didMutate = true
                    continue
                }

                room.opened = true
                room.openedUpdatedAt = now
                room.scheduledTime = nil
                room.scheduledUpdatedAt = now
                room.timeline.openedAt = room.timeline.openedAt ?? now
                room.markStatusChangedIfNeeded(
                    from: previousStatus,
                    workflowKind: hotelProfile.workflowKind,
                    changedAt: now
                )
                carts[cartIndex].rooms[roomIndex] = room
                openedRoomIDs.append(room.id)
                didMutate = true
            }
        }

        if didMutate {
            for roomID in openedRoomIDs {
                appendHistory(
                    kind: .scheduledRoomAutoOpened,
                    title: "\(roomID): открыта по времени",
                    roomID: roomID,
                    happenedAt: now
                )
            }
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
}
