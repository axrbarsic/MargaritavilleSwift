import Foundation

enum RoomDayCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case dueOut
    case stayover
    case departed
    case pickUp
    case outOfOrder

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dueOut: "Due Out"
        case .stayover: "Stayover"
        case .departed: "Departed"
        case .pickUp: "Pick Up"
        case .outOfOrder: "OOO"
        }
    }

    var shortTitle: String {
        switch self {
        case .dueOut: "DO"
        case .stayover: "ST"
        case .departed: "DP"
        case .pickUp: "PU"
        case .outOfOrder: "OOO"
        }
    }
}
