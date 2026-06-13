import SwiftUI

extension HousekeeperPalette {
    var color: Color {
        switch self {
        case .aqua:
            Color(red: 0.00, green: 0.78, blue: 0.82)
        case .amber:
            Color(red: 1.00, green: 0.68, blue: 0.18)
        case .coral:
            Color(red: 1.00, green: 0.38, blue: 0.30)
        case .orchid:
            Color(red: 0.78, green: 0.36, blue: 0.92)
        case .sky:
            Color(red: 0.22, green: 0.58, blue: 1.00)
        case .mint:
            Color(red: 0.32, green: 0.86, blue: 0.55)
        case .ruby:
            Color(red: 0.94, green: 0.18, blue: 0.36)
        case .violet:
            Color(red: 0.50, green: 0.42, blue: 1.00)
        case .lime:
            Color(red: 0.72, green: 0.92, blue: 0.22)
        case .slate:
            Color(red: 0.58, green: 0.66, blue: 0.76)
        }
    }
}
