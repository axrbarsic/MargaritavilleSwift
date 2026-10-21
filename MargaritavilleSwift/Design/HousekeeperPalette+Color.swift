import SwiftUI

extension HousekeeperPalette {
    var color: Color {
        let components = rgbComponents
        return Color(red: components.red, green: components.green, blue: components.blue)
    }

    var rgbComponents: (red: CGFloat, green: CGFloat, blue: CGFloat) {
        switch self {
        case .aqua:
            (0.00, 0.78, 0.82)
        case .amber:
            (1.00, 0.68, 0.18)
        case .coral:
            (1.00, 0.38, 0.30)
        case .orchid:
            (0.78, 0.36, 0.92)
        case .sky:
            (0.22, 0.58, 1.00)
        case .mint:
            (0.32, 0.86, 0.55)
        case .ruby:
            (0.94, 0.18, 0.36)
        case .violet:
            (0.50, 0.42, 1.00)
        case .lime:
            (0.72, 0.92, 0.22)
        case .slate:
            (0.58, 0.66, 0.76)
        }
    }
}
