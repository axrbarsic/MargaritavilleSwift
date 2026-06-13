import SwiftUI

struct QuantityRadialPickerOverlay: View {
    let title: String
    let selectedQuantity: Int

    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .foregroundStyle(.white)

            ZStack {
                Circle()
                    .fill(.black.opacity(0.74))
                    .overlay {
                        Circle()
                            .stroke(OceanKeyTheme.accent.opacity(0.58), lineWidth: 1.5)
                    }

                ForEach(1...10, id: \.self) { quantity in
                    quantityDot(quantity)
                }

                Text("\(selectedQuantity)")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(OceanKeyTheme.roomForeground)
                    .frame(width: 68, height: 68)
                    .background(OceanKeyTheme.accent, in: Circle())
            }
            .frame(width: 190, height: 190)
        }
        .padding(16)
        .background(.ultraThinMaterial.opacity(0.58), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.42), radius: 22, x: 0, y: 12)
    }

    private func quantityDot(_ quantity: Int) -> some View {
        let point = point(for: quantity)
        let isSelected = selectedQuantity == quantity
        return Text("\(quantity)")
            .font(.system(size: isSelected ? 21 : 16, weight: .black, design: .rounded))
            .monospacedDigit()
            .frame(width: isSelected ? 42 : 34, height: isSelected ? 42 : 34)
            .foregroundStyle(isSelected ? OceanKeyTheme.roomForeground : .white)
            .background(isSelected ? OceanKeyTheme.accent : Color.white.opacity(0.13), in: Circle())
            .position(point)
            .animation(.spring(response: 0.16, dampingFraction: 0.78), value: selectedQuantity)
    }

    private func point(for quantity: Int) -> CGPoint {
        let angle = -.pi / 2 + (Double(quantity - 1) / 9.0) * 2 * .pi
        let radius = 76.0
        return CGPoint(
            x: 95 + cos(angle) * radius,
            y: 95 + sin(angle) * radius
        )
    }
}
