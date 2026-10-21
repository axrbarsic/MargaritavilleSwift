import Foundation

enum RoomAtomicCommand: Equatable, Sendable {
    case status(RoomStatus)
    case vip
}

enum RoomChildFlow: Equatable, Sendable {
    case schedule
    case details(RoomDetailsMode)
}

enum RoomCommandCenterPhase: Equatable, Sendable {
    case idle
    case executing(RoomAtomicCommand)
    case awaiting(RoomChildFlow)
}

enum RoomCommandCenterCompletion: Equatable, Sendable {
    case stayOpen
    case collapse
}

struct RoomCommandCenterStateMachine: Equatable, Sendable {
    private(set) var phase: RoomCommandCenterPhase = .idle

    mutating func begin(_ command: RoomAtomicCommand) -> Bool {
        guard phase == .idle else { return false }
        phase = .executing(command)
        return true
    }

    mutating func finishAtomic(succeeded: Bool) -> RoomCommandCenterCompletion {
        guard case .executing = phase else { return .stayOpen }
        phase = .idle
        return succeeded ? .collapse : .stayOpen
    }

    mutating func begin(_ flow: RoomChildFlow) -> Bool {
        guard phase == .idle else { return false }
        phase = .awaiting(flow)
        return true
    }

    mutating func childDidMutateRoom() -> RoomCommandCenterCompletion {
        guard case .awaiting = phase else { return .stayOpen }
        phase = .idle
        return .collapse
    }

    mutating func childDismissedWithoutMutation() {
        guard case .awaiting = phase else { return }
        phase = .idle
    }

    mutating func reset() {
        phase = .idle
    }
}
