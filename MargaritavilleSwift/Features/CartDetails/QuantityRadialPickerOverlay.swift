import SwiftUI

struct QuantityRadialPickerOverlay: View {
    let title: String
    let selectedQuantity: Int
    let onQuantityChange: (Int) -> Void
    let onCommit: (Int) -> Void
    let onCancel: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let diameter = min(proxy.size.width - 28, proxy.size.height * 0.58)
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height * 0.50)
            let dotRadius = diameter * 0.42

            ZStack {
                Color.black.opacity(0.54)
                    .ignoresSafeArea()
                    .onTapGesture(perform: onCancel)

                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.60)
                        .foregroundStyle(.white)

                    Text("Проведи пальцем или нажми цифру")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(OceanKeyTheme.secondaryText)
                }
                .frame(width: proxy.size.width - 44)
                .position(x: center.x, y: max(86, center.y - diameter * 0.62))

                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .black))
                        .frame(width: 52, height: 52)
                        .foregroundStyle(.white)
                        .background(.black.opacity(0.72), in: Circle())
                }
                .buttonStyle(.plain)
                .position(x: proxy.size.width - 46, y: 56)

                Circle()
                    .fill(.black.opacity(0.82))
                    .overlay {
                        Circle()
                            .stroke(OceanKeyTheme.accent.opacity(0.70), lineWidth: 2)
                    }
                    .shadow(color: OceanKeyTheme.accent.opacity(0.24), radius: 26)
                    .frame(width: diameter, height: diameter)
                    .position(center)

                Circle()
                    .fill(.clear)
                    .contentShape(Circle())
                    .frame(width: diameter, height: diameter)
                    .position(center)
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .local)
                            .onChanged { value in
                                onQuantityChange(quantity(for: value.location, center: center, radius: dotRadius))
                            }
                            .onEnded { value in
                                onCommit(quantity(for: value.location, center: center, radius: dotRadius))
                            }
                    )

                ForEach(1...10, id: \.self) { quantity in
                    quantityDot(
                        quantity,
                        center: center,
                        radius: dotRadius
                    )
                }

                Button(action: { onCommit(selectedQuantity) }) {
                    Text("\(selectedQuantity)")
                        .font(.system(size: 74, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .frame(width: diameter * 0.32, height: diameter * 0.32)
                        .foregroundStyle(OceanKeyTheme.roomForeground)
                        .background(OceanKeyTheme.accent, in: Circle())
                }
                .buttonStyle(.plain)
                .position(center)

                Text("Отпусти палец, чтобы сохранить")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.90))
                    .frame(width: proxy.size.width - 36)
                    .position(x: center.x, y: min(proxy.size.height - 70, center.y + diameter * 0.62))
            }
        }
    }

    private func quantityDot(_ quantity: Int, center: CGPoint, radius: Double) -> some View {
        let point = point(for: quantity, center: center, radius: radius)
        let isSelected = selectedQuantity == quantity
        return Button(action: {
            onQuantityChange(quantity)
            onCommit(quantity)
        }) {
            Text("\(quantity)")
                .font(.system(size: isSelected ? 28 : 24, weight: .black, design: .rounded))
                .monospacedDigit()
                .frame(width: isSelected ? 62 : 54, height: isSelected ? 62 : 54)
                .foregroundStyle(isSelected ? OceanKeyTheme.roomForeground : .white)
                .background(isSelected ? OceanKeyTheme.accent : Color.white.opacity(0.14), in: Circle())
                .overlay {
                    Circle()
                        .stroke(isSelected ? .white.opacity(0.34) : .clear, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .position(point)
        .animation(.spring(response: 0.16, dampingFraction: 0.78), value: selectedQuantity)
    }

    private func quantity(for location: CGPoint, center: CGPoint, radius: Double) -> Int {
        let dx = location.x - center.x
        let dy = location.y - center.y
        guard abs(dx) + abs(dy) > 20 else {
            return max(1, min(selectedQuantity, 10))
        }
        let angle = atan2(dy, dx)
        let normalized = angle < -.pi / 2 ? angle + 2 * .pi : angle
        let index = Int(round((normalized + .pi / 2) / (2 * .pi) * 9))
        return min(max(index + 1, 1), 10)
    }

    private func point(for quantity: Int, center: CGPoint, radius: Double) -> CGPoint {
        let angle = -.pi / 2 + (Double(quantity - 1) / 9.0) * 2 * .pi
        return CGPoint(
            x: center.x + cos(angle) * radius,
            y: center.y + sin(angle) * radius
        )
    }
}

#Preview {
    QuantityRadialPickerOverlay(
        title: "Полотенца ручные",
        selectedQuantity: 4,
        onQuantityChange: { _ in },
        onCommit: { _ in },
        onCancel: {}
    )
        .preferredColorScheme(.dark)
}
