import Foundation

enum RoomDayCategoryTimePreset: String, CaseIterable, Codable, Identifiable, Sendable {
    case noon
    case twoPM
    case fivePM

    var id: String { rawValue }

    var title: String {
        switch self {
        case .noon: "12 PM"
        case .twoPM: "2 PM"
        case .fivePM: "5 PM"
        }
    }

    func dateToday(now: Date = Date(), calendar: Calendar = .current) -> Date {
        let parts = calendar.dateComponents([.year, .month, .day], from: now)
        return calendar.date(
            from: DateComponents(
                year: parts.year,
                month: parts.month,
                day: parts.day,
                hour: hour24,
                minute: 0
            )
        ) ?? now
    }

    private var hour24: Int {
        switch self {
        case .noon: 12
        case .twoPM: 14
        case .fivePM: 17
        }
    }
}
