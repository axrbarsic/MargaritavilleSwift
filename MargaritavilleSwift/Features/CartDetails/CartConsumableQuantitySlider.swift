import SwiftUI

struct CartConsumableQuantitySlider: View {
    static let maximum = 10

    let quantity: Int
    let onQuantityPreview: (Int?) -> Void
    let onQuantityChange: (Int) -> Void

    @State private var draftQuantity: Int?
    @State private var dragIsHorizontal = false

    init(
        quantity: Int,
        onQuantityPreview: @escaping (Int?) -> Void = { _ in },
        onQuantityChange: @escaping (Int) -> Void
    ) {
        self.quantity = quantity
        self.onQuantityPreview = onQuantityPreview
        self.onQuantityChange = onQuantityChange
    }

    private var visibleQuantity: Int {
        draftQuantity ?? Self.clamped(quantity)
    }

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let horizontalInset: CGFloat = 18
            let handleWidth: CGFloat = 26
            let trackWidth = max(width - horizontalInset * 2, 1)
            let handleCenter = horizontalInset + (CGFloat(visibleQuantity) / CGFloat(Self.maximum)) * trackWidth
            let handleOffset = min(
                max(handleCenter - handleWidth / 2, 0),
                max(width - handleWidth, 0)
            )

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.black.opacity(0.36))

                ruler(width: width)
                    .padding(.horizontal, horizontalInset)
                    .padding(.vertical, 9)

                Capsule()
                    .fill(MatrixConsumableStyle.green)
                    .frame(width: max(handleCenter - horizontalInset, 0), height: 9)
                    .offset(x: horizontalInset, y: 1)
                    .shadow(color: MatrixConsumableStyle.green.opacity(0.36), radius: 6)

                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(MatrixConsumableStyle.green)
                    .overlay {
                        Text("\(visibleQuantity)")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.black)
                    }
                    .frame(width: handleWidth, height: 58)
                    .shadow(
                        color: MatrixConsumableStyle.green.opacity(0.46),
                        radius: 8,
                        x: 0,
                        y: 0
                    )
                    .offset(x: handleOffset)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(MatrixConsumableStyle.green.opacity(0.92), lineWidth: 1.4)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 6, coordinateSpace: .local)
                    .onChanged { value in
                        let horizontal = dragIsHorizontal || abs(value.translation.width) >= abs(value.translation.height)
                        dragIsHorizontal = horizontal
                        guard horizontal else { return }
                        let nextQuantity = detent(for: value.location.x, width: width)
                        guard draftQuantity != nextQuantity else { return }
                        draftQuantity = nextQuantity
                        onQuantityPreview(nextQuantity)
                    }
                    .onEnded { value in
                        let horizontal = dragIsHorizontal || abs(value.translation.width) >= abs(value.translation.height)
                        let finalQuantity = horizontal ? detent(for: value.location.x, width: width) : visibleQuantity
                        draftQuantity = nil
                        dragIsHorizontal = false
                        if finalQuantity != Self.clamped(quantity) {
                            onQuantityChange(finalQuantity)
                        }
                        onQuantityPreview(nil)
                    }
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Количество")
            .accessibilityValue("\(visibleQuantity)")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    onQuantityChange(Self.clamped(quantity + 1))
                case .decrement:
                    onQuantityChange(Self.clamped(quantity - 1))
                @unknown default:
                    break
                }
            }
        }
        .frame(height: 76)
    }

    private func ruler(width: CGFloat) -> some View {
        ZStack(alignment: .bottomLeading) {
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(0...Self.maximum, id: \.self) { index in
                    VStack(spacing: 7) {
                        Rectangle()
                            .fill(MatrixConsumableStyle.green.opacity(index <= visibleQuantity ? 0.94 : 0.42))
                            .frame(width: index % 5 == 0 ? 2 : 1, height: index % 5 == 0 ? 34 : 26)

                        Text("\(index)")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(MatrixConsumableStyle.green)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(width: max(width - 36, 1), alignment: .leading)
    }

    private func detent(for x: CGFloat, width: CGFloat) -> Int {
        let inset: CGFloat = 18
        let progress = min(max((x - inset) / max(width - inset * 2, 1), 0), 1)
        return Self.clamped(Int((progress * CGFloat(Self.maximum)).rounded()))
    }

    static func clamped(_ quantity: Int) -> Int {
        min(max(0, quantity), maximum)
    }
}
