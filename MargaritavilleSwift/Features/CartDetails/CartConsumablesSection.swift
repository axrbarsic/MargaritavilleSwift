import SwiftUI

struct CartConsumablesSection: View {
    let cartID: CartSection.ID
    @Bindable var workSession: WorkSessionStore
    let catalog: [CartConsumableCatalogItem]
    @Environment(\.interactionFeedback) private var feedback

    private var items: [CartConsumableItem] {
        CartConsumableCatalog.merged(with: workSession.cart(id: cartID)?.consumables, catalog: catalog)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(items) { item in
                CartConsumableRow(
                    item: item,
                    onQuantityChange: { quantity in
                        setQuantity(item.id, quantity)
                    },
                    onToggleComplete: {
                        feedback.confirm()
                        workSession.toggleCartConsumableCompletion(
                            itemID: item.id,
                            title: item.title,
                            cartId: cartID
                        )
                    }
                )
            }
        }
        .padding(12)
        .background(MatrixConsumableStyle.panelFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(MatrixConsumableStyle.green.opacity(0.90), lineWidth: 1.2)
        }
    }

    private func setQuantity(
        _ itemID: CartConsumableItem.ID,
        _ quantity: Int,
        feedback playsFeedback: Bool = true
    ) {
        let quantity = CartConsumableQuantitySlider.clamped(quantity)
        workSession.updateCartConsumableQuantity(
            itemID: itemID,
            title: items.first { $0.id == itemID }?.title,
            quantity: quantity,
            cartId: cartID
        )
        if playsFeedback {
            feedback.confirm()
        }
    }
}

private struct CartConsumableRow: View {
    let item: CartConsumableItem
    let onQuantityChange: (Int) -> Void
    let onToggleComplete: () -> Void
    @State private var previewQuantity: Int?
    @State private var pendingZeroCommit = false

    private var visibleQuantity: Int {
        previewQuantity ?? item.quantity
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                HoldActionTarget(
                    enabled: true,
                    useLongPress: true,
                    semanticLabel: "\(item.title) выполнено",
                    onActivate: onToggleComplete
                ) {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 28, weight: .black))
                        .frame(width: 42, height: 42)
                        .foregroundStyle(MatrixConsumableStyle.green)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(MatrixConsumableStyle.green)
                        .lineLimit(1)
                        .minimumScaleFactor(0.66)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(MatrixConsumableStyle.green.opacity(0.68))
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Text("\(visibleQuantity)")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .frame(minWidth: 46, alignment: .trailing)
                    .foregroundStyle(MatrixConsumableStyle.green)
            }

            CartConsumableQuantitySlider(
                quantity: item.quantity,
                onQuantityPreview: { previewQuantity = $0 },
                onZeroCommitPendingChange: { pendingZeroCommit = $0 },
                onQuantityChange: onQuantityChange
            )

            if pendingZeroCommit {
                MatrixConsumableZeroWarning()
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(strokeColor, lineWidth: 1)
        }
        .onChange(of: item.quantity) { _, _ in
            previewQuantity = nil
            pendingZeroCommit = false
        }
    }

    private var rowBackground: Color {
        return item.isCompleted ? MatrixConsumableStyle.completedFill : MatrixConsumableStyle.rowFill
    }

    private var strokeColor: Color {
        return MatrixConsumableStyle.green.opacity(item.isCompleted ? 0.98 : 0.82)
    }

    private var subtitle: String {
        if let completedAt = item.completedAt {
            return "Выполнено \(timeLabel(completedAt))"
        }
        if let updatedAt = item.updatedAt {
            return "Обновлено \(timeLabel(updatedAt))"
        }
        return "Не задано"
    }

    private func timeLabel(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .hour(.defaultDigits(amPM: .abbreviated))
                .minute(.twoDigits)
                .locale(Locale(identifier: "en_US_POSIX"))
        )
    }
}

#Preview {
    CartConsumablesSection(
        cartID: 7,
        workSession: .preview(),
        catalog: CartConsumableCatalog.defaultCatalog
    )
        .padding()
        .background(OceanKeyTheme.background)
        .preferredColorScheme(.dark)
}
