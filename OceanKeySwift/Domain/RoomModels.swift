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

    var isReady: Bool {
        completedTasks.count == RoomTask.allCases.count
    }

    var status: RoomStatus {
        if scheduledTime != nil, !opened, completedTasks.isEmpty {
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
}

struct SummaryCounts: Codable, Equatable {
    var total: Int
    var completed: Int
    var remaining: Int
}
