import SwiftUI

struct CartConsumableQuantitySlider: View {
    static let maximum = 10

    let quantity: Int
    let onQuantityPreview: (Int?) -> Void
    let onQuantityChange: (Int) -> Void
    let onZeroCommitPendingChange: (Bool) -> Void

    @State private var draftQuantity: Int?
    @State private var editorSelection = 0
    @State private var isEditorPresented = false
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
                passiveTrack(width: width, handleCenter: handleCenter, horizontalInset: horizontalInset)

                CartConsumableQuantityPanSurface(
                    maximum: Self.maximum,
                    onBegin: beginSwipeEdit,
                    onChange: previewQuantity,
                    onCommit: selectQuantity,
                    onCancel: cancelSwipeEdit
                )
                .frame(width: width, height: 76)

                HoldActionTarget(
                    enabled: true,
                    useLongPress: true,
                    semanticLabel: "Изменить количество",
                    onActivate: openEditor
                ) {
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
                }
                .offset(x: handleOffset)
                .accessibilityLabel("Изменить количество")
                .accessibilityHint("Держите ручку, чтобы открыть точный выбор.")
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(
                        MatrixConsumableStyle.green.opacity(isPendingZeroCommit ? 1.0 : 0.92),
                        lineWidth: isPendingZeroCommit ? 2.2 : 1.4
                    )
            }
            .sheet(isPresented: $isEditorPresented) {
                CartConsumableQuantityEditorSheet(
                    selection: editorSelection,
                    maximum: Self.maximum,
                    onSelect: selectQuantity
                )
                .presentationDetents([.height(360)])
                .presentationDragIndicator(.visible)
            }
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

    private func passiveTrack(width: CGFloat, handleCenter: CGFloat, horizontalInset: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.black.opacity(0.36))

            CartConsumableQuantityRuler(quantity: visibleQuantity, maximum: Self.maximum)
                .padding(.horizontal, horizontalInset)
                .padding(.vertical, 9)

            Capsule()
                .fill(MatrixConsumableStyle.green)
                .frame(width: max(handleCenter - horizontalInset, 0), height: 9)
                .offset(x: horizontalInset, y: 1)
                .shadow(color: MatrixConsumableStyle.green.opacity(0.36), radius: 6)
        }
        .allowsHitTesting(false)
    }

    private func openEditor() {
        cancelPendingZeroCommit(clearPreview: true)
        editorSelection = visibleQuantity
        isEditorPresented = true
    }

    private func beginSwipeEdit() {
        cancelPendingZeroCommit(clearPreview: true)
        feedback.holdStart()
    }

    private func previewQuantity(_ quantity: Int) {
        let quantity = Self.clamped(quantity)
        guard draftQuantity != quantity else { return }
        draftQuantity = quantity
        onQuantityPreview(quantity)
        feedback.holdStart()
    }

    private func cancelSwipeEdit() {
        cancelPendingZeroCommit(clearPreview: true)
    }

    private func selectQuantity(_ quantity: Int) {
        isEditorPresented = false
        let quantity = Self.clamped(quantity)

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

    static func clamped(_ quantity: Int) -> Int {
        min(max(0, quantity), maximum)
    }
}
