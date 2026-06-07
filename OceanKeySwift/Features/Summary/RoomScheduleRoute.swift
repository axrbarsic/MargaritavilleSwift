import Foundation

struct RoomScheduleRoute: Identifiable {
    let roomID: RoomCell.ID
    let initialDate: Date?

    var id: RoomCell.ID { roomID }
}
