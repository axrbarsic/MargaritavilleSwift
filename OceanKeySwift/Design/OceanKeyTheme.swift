import SwiftUI

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
    static let roomForeground = Color(hex: 0x050505)

    static func fill(for status: RoomStatus) -> Color {
        switch status {
        case .pending: pending
        case .open: open
        case .inProgress: inProgress
        case .ready: ready
        case .scheduled: scheduled
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
}
