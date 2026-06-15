import SwiftUI

enum MatrixConsumableStyle {
    static let green = Color(red: 0.32, green: 1.00, blue: 0.30)
    static let warningRed = Color(red: 1.00, green: 0.10, blue: 0.08)
    static let dimGreen = Color(red: 0.12, green: 0.80, blue: 0.22)
    static let panelFill = Color.black.opacity(0.42)
    static let rowFill = Color.black.opacity(0.30)
    static let completedFill = green.opacity(0.18)

    static func glow(radius: CGFloat = 7) -> some View {
        green.opacity(0.42).blur(radius: radius)
    }
}

struct MatrixConsumableZeroWarning: View {
    @State private var isBright = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18, weight: .black))

            Text("ВНИМАНИЕ • 5 сек до скрытия")
                .font(.system(size: 17, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .foregroundStyle(.black)
        .frame(maxWidth: .infinity, minHeight: 46)
        .background(
            MatrixConsumableStyle.warningRed
                .opacity(isBright ? 1.0 : 0.38),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(MatrixConsumableStyle.warningRed.opacity(0.95), lineWidth: 1.2)
        }
        .shadow(color: MatrixConsumableStyle.warningRed.opacity(isBright ? 0.76 : 0.18), radius: 10)
        .animation(.easeInOut(duration: 0.34).repeatForever(autoreverses: true), value: isBright)
        .onAppear { isBright = true }
        .onDisappear { isBright = false }
    }
}
