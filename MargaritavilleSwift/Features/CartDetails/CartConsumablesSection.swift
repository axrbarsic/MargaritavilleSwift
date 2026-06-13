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
                    onDecrement: {
                        setQuantity(item.id, item.quantity - 1)
                    },
                    onIncrement: {
                        setQuantity(item.id, item.quantity + 1)
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
        let quantity = min(max(0, quantity), 99)
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
    let onDecrement: () -> Void
    let onIncrement: () -> Void
    let onToggleComplete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onToggleComplete) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .black))
                    .frame(width: 38, height: 44)
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

            HStack(spacing: 6) {
                quantityButton(systemName: "minus", action: onDecrement)

                Text("\(item.quantity)")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .frame(width: 42)
                    .foregroundStyle(.white)

                quantityButton(systemName: "plus", action: onIncrement)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(strokeColor, lineWidth: 1)
        }
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

    private func quantityButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .black))
                .frame(width: 36, height: 36)
                .foregroundStyle(OceanKeyTheme.roomForeground)
                .background(OceanKeyTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(systemName == "minus" && item.quantity == 0)
        .opacity(systemName == "minus" && item.quantity == 0 ? 0.35 : 1)
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
