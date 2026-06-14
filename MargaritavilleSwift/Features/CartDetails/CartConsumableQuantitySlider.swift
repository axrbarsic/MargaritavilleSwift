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
            let handleWidth: CGFloat = 18
            let handleOffset = min(
                max((CGFloat(visibleQuantity) / CGFloat(Self.maximum)) * width - handleWidth / 2, 0),
                max(width - handleWidth, 0)
            )

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.black.opacity(0.34))

                equalizerBars
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)

                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(visibleQuantity == 0 ? OceanKeyTheme.secondaryText.opacity(0.34) : OceanKeyTheme.accent)
                    .frame(width: handleWidth, height: 30)
                    .shadow(
                        color: visibleQuantity == 0 ? .clear : OceanKeyTheme.accent.opacity(0.36),
                        radius: 6,
                        x: 0,
                        y: 0
                    )
                    .offset(x: handleOffset)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(
                        visibleQuantity == 0 ? OceanKeyTheme.secondaryText.opacity(0.18) : OceanKeyTheme.accent.opacity(0.42),
                        lineWidth: 1
                    )
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
        .frame(height: 40)
    }

    private var equalizerBars: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(1...Self.maximum, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(index <= visibleQuantity ? OceanKeyTheme.accent : OceanKeyTheme.secondaryText.opacity(0.2))
                    .frame(maxWidth: .infinity)
                    .frame(height: barHeight(for: index))
            }
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let minimum: CGFloat = 8
        let maximum: CGFloat = 26
        let progress = CGFloat(index - 1) / CGFloat(max(Self.maximum - 1, 1))
        return minimum + (maximum - minimum) * progress
    }

    private func detent(for x: CGFloat, width: CGFloat) -> Int {
        let progress = min(max(x / max(width, 1), 0), 1)
        return Self.clamped(Int((progress * CGFloat(Self.maximum)).rounded()))
    }

    static func clamped(_ quantity: Int) -> Int {
        min(max(0, quantity), maximum)
    }
}
