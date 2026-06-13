import Foundation

enum HousekeeperDetailsGestureMode: String, CaseIterable, Identifiable, Sendable {
    case tap
    case longPress
    case swipeLeft

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tap: "Тап"
        case .longPress: "Держать"
        case .swipeLeft: "Свайп"
        }
    }

    var settingsValue: String {
        switch self {
        case .tap: "Тап"
        case .longPress: "Долгий"
        case .swipeLeft: "Свайп"
        }
    }
}
