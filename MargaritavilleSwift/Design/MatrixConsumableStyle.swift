import SwiftUI

enum MatrixConsumableStyle {
    static let green = Color(red: 0.32, green: 1.00, blue: 0.30)
    static let dimGreen = Color(red: 0.12, green: 0.80, blue: 0.22)
    static let panelFill = Color.black.opacity(0.42)
    static let rowFill = Color.black.opacity(0.30)
    static let completedFill = green.opacity(0.18)

    static func glow(radius: CGFloat = 7) -> some View {
        green.opacity(0.42).blur(radius: radius)
    }
}
