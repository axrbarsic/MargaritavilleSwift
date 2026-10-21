import Foundation

extension WorkSessionStore {
    func setSimpleCycleStatus(_ targetStatus: RoomStatus, roomId: RoomCell.ID) {
        guard targetStatus == .open || targetStatus == .ready else { return }
        mutateRoom(roomId, history: { before, after, _ in
            guard before.status(in: .simpleCycle) != after.status(in: .simpleCycle) else { return nil }
            return (.roomStatusChanged, "\(after.id): \(after.status(in: .simpleCycle).summaryLabel)")
        }) { room, changedAt in
            let previousStatus = room.status(in: .simpleCycle)
            let previousOpened = room.opened
            let previousTasks = room.completedTasks

            room.opened = true
            room.openedUpdatedAt = changedAt
            room.scheduledTime = nil
            room.scheduledUpdatedAt = changedAt
            room.completedTasks = targetStatus == .ready ? Set(RoomTask.allCases) : []
            for task in RoomTask.allCases where previousTasks.contains(task) != room.completedTasks.contains(task) {
                room.markTaskStateUpdated(task, at: changedAt)
            }
            room.timeline = room.timeline.updatedForTransition(
                previousOpened: previousOpened,
                nextOpened: room.opened,
                previousTasks: previousTasks,
                nextTasks: room.completedTasks,
                changedAt: changedAt
            )
            room.markStatusChangedIfNeeded(
                from: previousStatus,
                workflowKind: .simpleCycle,
                changedAt: changedAt
            )
        }
    }

    func advanceSimpleCycle(roomId: RoomCell.ID) {
        mutateRoom(roomId, history: { before, after, _ in
            guard before.status(in: HotelWorkflowKind.simpleCycle) != after.status(in: HotelWorkflowKind.simpleCycle) else { return nil }
            return (.roomStatusChanged, "\(after.id): \(after.status(in: HotelWorkflowKind.simpleCycle).summaryLabel)")
        }) { room, changedAt in
            let previousStatus = room.status(in: HotelWorkflowKind.simpleCycle)
            switch previousStatus {
            case .pending:
                room.opened = true
                room.openedUpdatedAt = changedAt
                room.scheduledTime = nil
                room.scheduledUpdatedAt = changedAt
                room.timeline.openedAt = room.timeline.openedAt ?? changedAt
            case .open, .inProgress:
                room.opened = true
                room.completedTasks = Set(RoomTask.allCases)
                room.openedUpdatedAt = room.openedUpdatedAt ?? changedAt
                room.strippedUpdatedAt = changedAt
                room.linenUpdatedAt = changedAt
                room.balconyUpdatedAt = changedAt
                room.timeline.completedAt = room.timeline.completedAt ?? changedAt
            case .ready:
                return
            case .scheduled:
                room.scheduledTime = nil
                room.scheduledUpdatedAt = changedAt
                room.opened = true
                room.openedUpdatedAt = changedAt
                room.timeline.openedAt = room.timeline.openedAt ?? changedAt
            }
            room.markStatusChangedIfNeeded(
                from: previousStatus,
                workflowKind: HotelWorkflowKind.simpleCycle,
                changedAt: changedAt
            )
        }
    }

    func resetSimpleCycle(roomId: RoomCell.ID) {
        mutateRoom(roomId, history: { before, after, _ in
            guard before.status(in: HotelWorkflowKind.simpleCycle) != after.status(in: HotelWorkflowKind.simpleCycle) else { return nil }
            return (.roomStatusChanged, "\(after.id): \(after.status(in: HotelWorkflowKind.simpleCycle).summaryLabel)")
        }) { room, changedAt in
            let previousStatus = room.status(in: HotelWorkflowKind.simpleCycle)
            room.opened = false
            room.openedUpdatedAt = changedAt
            room.completedTasks = []
            room.strippedUpdatedAt = nil
            room.linenUpdatedAt = nil
            room.balconyUpdatedAt = nil
            room.scheduledTime = nil
            room.scheduledUpdatedAt = nil
            room.markStatusChangedIfNeeded(
                from: previousStatus,
                workflowKind: HotelWorkflowKind.simpleCycle,
                changedAt: changedAt
            )
        }
    }
}

private extension RoomStatus {
    var summaryLabel: String {
        switch self {
        case .pending: "жёлтый"
        case .open: "красный"
        case .inProgress: "синий"
        case .ready: "зелёный"
        case .scheduled: "назначено"
        }
    }
}
