import Foundation

enum RoomSchedulePeriod: String, CaseIterable, Codable, Identifiable, Sendable {
    case am
    case pm

    var id: String { rawValue }

    var label: String {
        rawValue.uppercased()
    }
}

struct RoomScheduleSelection: Codable, Equatable, Sendable {
    static let hours = [8, 9, 10, 11, 12, 1, 2, 3, 4]
    static let minutes = [0, 15, 30, 45]

    var hour: Int
    var minute: Int
    var period: RoomSchedulePeriod

    var displayLabel: String {
        "\(hour):\(String(format: "%02d", minute)) \(period.label)"
    }

    init(hour: Int, minute: Int, period: RoomSchedulePeriod) {
        self.hour = hour
        self.minute = minute
        self.period = period
    }

    init(date: Date, calendar: Calendar = .current) {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let hour24 = components.hour ?? 11
        let roundedMinute = Self.closestQuarterMinute(components.minute ?? 0)
        period = hour24 >= 12 ? .pm : .am
        let hour12 = hour24 % 12
        let displayHour = hour12 == 0 ? 12 : hour12
        hour = Self.hours.contains(displayHour) ? displayHour : 11
        minute = roundedMinute
    }

    func dateToday(now: Date = Date(), calendar: Calendar = .current) -> Date {
        var hour24 = hour % 12
        if period == .pm {
            hour24 += 12
        }
        let parts = calendar.dateComponents([.year, .month, .day], from: now)
        return calendar.date(
            from: DateComponents(
                year: parts.year,
                month: parts.month,
                day: parts.day,
                hour: hour24,
                minute: minute
            )
        ) ?? now
    }

    static func defaultSelection(now: Date = Date(), calendar: Calendar = .current) -> RoomScheduleSelection {
        let components = calendar.dateComponents([.minute], from: now)
        let minute = components.minute ?? 0
        let minutesToNextQuarter = 15 - (minute % 15)
        let rounded = calendar.date(byAdding: .minute, value: minutesToNextQuarter, to: now) ?? now
        return RoomScheduleSelection(date: rounded, calendar: calendar)
    }

    private static func closestQuarterMinute(_ minute: Int) -> Int {
        minutes.min(by: { abs($0 - minute) < abs($1 - minute) }) ?? 0
    }
}
