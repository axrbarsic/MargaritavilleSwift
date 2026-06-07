import Foundation

enum RoomTask: String, CaseIterable, Codable, Identifiable {
    case stripped = "S"
    case linen = "L"
    case balcony = "B"

    var id: String { rawValue }
}

enum RoomStatus: String, CaseIterable, Codable {
    case pending
    case open
    case inProgress
    case ready
    case scheduled
}

struct RoomCell: Codable, Identifiable, Equatable {
    let id: String
    var opened: Bool
    var completedTasks: Set<RoomTask>
    var isVIP: Bool
    var scheduledTime: Date? = nil
    var timeline = RoomTimeline()
    var textNote: String?
    var textNoteUpdatedAt: Date?
    var voiceTranscript: String?
    var voiceTranscriptUpdatedAt: Date?
    var mediaAttachments: [MediaAttachment]?

    var isReady: Bool {
        opened && completedTasks.count == RoomTask.allCases.count
    }

    var hasAnyTask: Bool {
        !completedTasks.isEmpty
    }

    var status: RoomStatus {
        if scheduledTime != nil {
            return .scheduled
        }
        if isReady {
            return .ready
        }
        if !completedTasks.isEmpty {
            return .inProgress
        }
        if opened {
            return .open
        }
        return .pending
    }
}

struct CartSection: Codable, Identifiable, Equatable {
    let id: Int
    var building: String
    var rooms: [RoomCell]
    var note: String?
    var noteUpdatedAt: Date?
    var mediaAttachments: [MediaAttachment]?
}

enum MediaKind: String, Codable, CaseIterable, Identifiable {
    case photo
    case video

    var id: String { rawValue }
}

struct MediaAttachment: Codable, Identifiable, Equatable {
    let id: UUID
    let kind: MediaKind
    let relativePath: String
    let createdAt: Date
    var completedAt: Date?

    var isCompleted: Bool {
        completedAt != nil
    }
}

struct RoomTimeline: Codable, Equatable {
    var selectedAt: Date?
    var openedAt: Date?
    var strippedAt: Date?
    var linenDeliveredAt: Date?
    var balconyCleanedAt: Date?
    var completedAt: Date?

    var visibleMilestones: [(String, Date)] {
        [
            ("Y", selectedAt),
            ("R", openedAt),
            ("S", strippedAt),
            ("L", linenDeliveredAt),
            ("B", balconyCleanedAt),
            ("G", completedAt)
        ].compactMap { label, date in
            guard let date else { return nil }
            return (label, date)
        }
    }

    func markingSelected(_ changedAt: Date) -> RoomTimeline {
        guard selectedAt == nil else { return self }
        var next = self
        next.selectedAt = changedAt
        return next
    }

    func updatedForTransition(
        previousOpened: Bool,
        nextOpened: Bool,
        previousTasks: Set<RoomTask>,
        nextTasks: Set<RoomTask>,
        changedAt: Date
    ) -> RoomTimeline {
        var next = self
        if !previousOpened, nextOpened, next.openedAt == nil {
            next.openedAt = changedAt
        }
        if !previousTasks.contains(.stripped), nextTasks.contains(.stripped), next.strippedAt == nil {
            next.strippedAt = changedAt
        }
        if !previousTasks.contains(.linen), nextTasks.contains(.linen), next.linenDeliveredAt == nil {
            next.linenDeliveredAt = changedAt
        }
        if !previousTasks.contains(.balcony), nextTasks.contains(.balcony), next.balconyCleanedAt == nil {
            next.balconyCleanedAt = changedAt
        }

        let previousComplete = previousOpened && previousTasks.count == RoomTask.allCases.count
        let nextComplete = nextOpened && nextTasks.count == RoomTask.allCases.count
        if !previousComplete, nextComplete, next.completedAt == nil {
            next.completedAt = changedAt
        }
        return next
    }
}

struct SummaryCounts: Codable, Equatable {
    var total: Int
    var completed: Int
    var remaining: Int
}
