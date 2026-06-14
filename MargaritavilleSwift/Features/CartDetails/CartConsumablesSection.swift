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

    private var visibleQuantity: Int {
        previewQuantity ?? item.quantity
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 10) {
                Button(action: onToggleComplete) {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24, weight: .black))
                        .frame(width: 38, height: 40)
                        .foregroundStyle(item.isCompleted ? OceanKeyTheme.accent : OceanKeyTheme.secondaryText)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(OceanKeyTheme.secondaryText.opacity(0.82))
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Text("\(visibleQuantity)")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .frame(minWidth: 42, alignment: .trailing)
                    .foregroundStyle(OceanKeyTheme.accent)
            }

            CartConsumableQuantitySlider(
                quantity: item.quantity,
                onQuantityPreview: { previewQuantity = $0 },
                onQuantityChange: onQuantityChange
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(strokeColor, lineWidth: 1)
        }
        .onChange(of: item.quantity) { _, _ in previewQuantity = nil }
    }

    private var rowBackground: Color {
        return item.isCompleted ? OceanKeyTheme.accent.opacity(0.12) : .black.opacity(0.24)
    }

    private var strokeColor: Color {
        return item.isCompleted ? OceanKeyTheme.accent.opacity(0.36) : OceanKeyTheme.accent.opacity(0.14)
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
