import SwiftUI
import UIKit

enum OceanKeyTheme {
    static let background = Color(red: 0.016, green: 0.031, blue: 0.020)
    static let surface = Color(red: 0.008, green: 0.016, blue: 0.008)
    static let accent = Color(red: 0.118, green: 1.000, blue: 0.353)
    static let mutedText = Color(red: 0.294, green: 0.702, blue: 0.396)
    static let secondaryText = Color(red: 0.608, green: 1.000, blue: 0.722)
    static let ready = Color(hex: 0x25D366)
    static let pending = Color(hex: 0xFFD83D)
    static let open = Color(hex: 0xFF3B30)
    static let inProgress = Color(hex: 0x2F80FF)
    static let scheduled = Color(hex: 0xFF4DB8)
    static let margaritavilleScheduled = Color(hex: 0x8E5BFF)
    static let roomForeground = Color(hex: 0x050505)

    static func fill(for status: RoomStatus, saturation: Double = 1) -> Color {
        fill(for: status, saturation: saturation, usesPurpleScheduled: false)
    }

    static func fill(
        for status: RoomStatus,
        saturation: Double = 1,
        usesPurpleScheduled: Bool
    ) -> Color {
        if saturation >= 1.5 {
            return Color(hex: vividHex(for: status, usesPurpleScheduled: usesPurpleScheduled))
        }
        return Color.status(hex: hex(for: status, usesPurpleScheduled: usesPurpleScheduled), saturationMultiplier: saturation)
    }

    static func fill(for dayCategory: RoomDayCategory) -> Color {
        Color(hex: hex(for: dayCategory))
    }

    private static func hex(for status: RoomStatus, usesPurpleScheduled: Bool = false) -> UInt32 {
        switch status {
        case .pending: 0xFFD83D
        case .open: 0xFF3B30
        case .inProgress: 0x2F80FF
        case .ready: 0x25D366
        case .scheduled: usesPurpleScheduled ? 0x8E5BFF : 0xFF4DB8
        }
    }

    private static func vividHex(for status: RoomStatus, usesPurpleScheduled: Bool = false) -> UInt32 {
        switch status {
        case .pending: 0xFFC400
        case .open: 0xFF1208
        case .inProgress: 0x0877FF
        case .ready: 0x00E524
        case .scheduled: usesPurpleScheduled ? 0x9B63FF : 0xFF31B8
        }
    }

    private static func hex(for dayCategory: RoomDayCategory) -> UInt32 {
        switch dayCategory {
        case .dueOut: 0xFFD83D
        case .stayover: 0x25D366
        case .departed: 0xFF3B30
        case .pickUp: 0x2F80FF
        case .outOfOrder: 0x8E5BFF
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }

    static func status(hex: UInt32, saturationMultiplier: Double) -> Color {
        let red = CGFloat((hex >> 16) & 0xFF) / 255.0
        let green = CGFloat((hex >> 8) & 0xFF) / 255.0
        let blue = CGFloat(hex & 0xFF) / 255.0
        let uiColor = UIColor(red: red, green: green, blue: blue, alpha: 1)

        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        guard uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
            return Color(uiColor)
        }

        let adjustedSaturation = min(max(saturation * CGFloat(saturationMultiplier), 0), 1)
        return Color(
            uiColor: UIColor(
                hue: hue,
                saturation: adjustedSaturation,
                brightness: brightness,
                alpha: alpha
            )
        )
    }
}
