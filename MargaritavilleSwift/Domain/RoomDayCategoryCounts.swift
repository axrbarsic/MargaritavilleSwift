import Foundation

struct RoomDayCategoryCounts: Equatable, Sendable {
    private let values: [RoomDayCategory: Int]

    init(rooms: [RoomCell]) {
        var next: [RoomDayCategory: Int] = [:]
        for room in rooms {
            guard let category = room.dayCategory else { continue }
            next[category, default: 0] += 1
        }
        values = next
    }

    subscript(category: RoomDayCategory) -> Int {
        values[category, default: 0]
    }
}
