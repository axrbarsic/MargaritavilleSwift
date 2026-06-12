import Foundation

enum RoomDetailsMode: String, Identifiable {
    case text
    case voice
    case media

    var id: String { rawValue }

    var title: String {
        switch self {
        case .text:
            "Заметки"
        case .voice:
            "Голос/медиа"
        case .media:
            "Медиа"
        }
    }
}

struct RoomDetailsRoute: Identifiable, Equatable {
    let roomID: RoomCell.ID
    let mode: RoomDetailsMode

    var id: String {
        "\(roomID)-\(mode.rawValue)"
    }
}
