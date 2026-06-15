import SwiftUI

struct CartConsumableQuantitySlider: View {
    static let maximum = 10

    let quantity: Int
    let onQuantityPreview: (Int?) -> Void
    let onQuantityChange: (Int) -> Void
    let onZeroCommitPendingChange: (Bool) -> Void

    @State private var draftQuantity: Int?
    @State private var isSliderArmed = false
    @State private var isPendingZeroCommit = false
    @State private var pendingZeroCommitTask: Task<Void, Never>?
    @Environment(\.interactionFeedback) private var feedback

    init(
        quantity: Int,
        onQuantityPreview: @escaping (Int?) -> Void = { _ in },
        onZeroCommitPendingChange: @escaping (Bool) -> Void = { _ in },
        onQuantityChange: @escaping (Int) -> Void
    ) {
        self.quantity = quantity
        self.onQuantityPreview = onQuantityPreview
        self.onZeroCommitPendingChange = onZeroCommitPendingChange
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
                    .stroke(
                        MatrixConsumableStyle.green.opacity(isSliderArmed || isPendingZeroCommit ? 1.0 : 0.92),
                        lineWidth: isSliderArmed || isPendingZeroCommit ? 2.2 : 1.4
                    )
            }
            .contentShape(Rectangle())
            .gesture(armedDragGesture(width: width))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Количество")
            .accessibilityValue("\(visibleQuantity)")
            .accessibilityAdjustableAction { direction in
                cancelPendingZeroCommit(clearPreview: true)
                switch direction {
                case .increment:
                    onQuantityChange(Self.clamped(quantity + 1))
                case .decrement:
                    onQuantityChange(Self.clamped(quantity - 1))
                @unknown default:
                    break
                }
            }
            .onChange(of: quantity) { _, _ in
                cancelPendingZeroCommit(clearPreview: true)
            }
            .onDisappear {
                cancelPendingZeroCommit(clearPreview: true)
            }
        }
        .frame(height: 76)
    }

    private func armedDragGesture(width: CGFloat) -> some Gesture {
        LongPressGesture(minimumDuration: 0.26, maximumDistance: 12)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
            .onChanged { value in
                switch value {
                case .first(true):
                    armSliderIfNeeded()
                case .second(true, let drag?):
                    armSliderIfNeeded()
                    preview(detent(for: drag.location.x, width: width))
                default:
                    break
                }
            }
            .onEnded { value in
                switch value {
                case .second(true, let drag?):
                    commit(detent(for: drag.location.x, width: width))
                default:
                    isSliderArmed = false
                }
            }
    }

    private func armSliderIfNeeded() {
        guard !isSliderArmed else { return }
        isSliderArmed = true
        cancelPendingZeroCommit(clearPreview: true)
        feedback.holdStart()
    }

    private func preview(_ quantity: Int) {
        guard draftQuantity != quantity else { return }
        draftQuantity = quantity
        onQuantityPreview(quantity)
    }

    private func commit(_ quantity: Int) {
        let quantity = Self.clamped(quantity)
        isSliderArmed = false

        if quantity == 0, Self.clamped(self.quantity) != 0 {
            beginPendingZeroCommit()
            return
        }

        cancelPendingZeroCommit(clearPreview: false)
        draftQuantity = nil
        if quantity != Self.clamped(self.quantity) {
            onQuantityChange(quantity)
        }
        onQuantityPreview(nil)
    }

    private func beginPendingZeroCommit() {
        pendingZeroCommitTask?.cancel()
        draftQuantity = 0
        isPendingZeroCommit = true
        onQuantityPreview(0)
        onZeroCommitPendingChange(true)
        feedback.holdWarning()

        pendingZeroCommitTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled, isPendingZeroCommit else { return }
            isPendingZeroCommit = false
            pendingZeroCommitTask = nil
            draftQuantity = nil
            onZeroCommitPendingChange(false)
            onQuantityChange(0)
            onQuantityPreview(nil)
            feedback.holdCommit()
        }
    }

    private func cancelPendingZeroCommit(clearPreview: Bool) {
        pendingZeroCommitTask?.cancel()
        pendingZeroCommitTask = nil
        if isPendingZeroCommit {
            isPendingZeroCommit = false
            onZeroCommitPendingChange(false)
        }
        if clearPreview {
            draftQuantity = nil
            onQuantityPreview(nil)
        }
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
