import Foundation

extension WorkSessionStore {
    func addCartConsumable(
        title: String,
        quantity: Int = 0,
        cartId: CartSection.ID
    ) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        mutateCart(cartId, history: { _, after, _ in
            (.cartConsumablesChanged, "Тележка \(after.id): добавлен расходник \(trimmed)")
        }) { cart in
            var items = CartConsumableCatalog.merged(with: cart.consumables)
            items.append(
                CartConsumableItem(
                    id: "custom_\(UUID().uuidString)",
                    title: trimmed,
                    quantity: max(0, quantity),
                    updatedAt: Date(),
                    completedAt: nil
                )
            )
            cart.consumables = items
        }
    }

    func updateCartConsumableQuantity(
        itemID: CartConsumableItem.ID,
        quantity: Int,
        cartId: CartSection.ID
    ) {
        updateCartConsumableQuantity(
            itemID: itemID,
            title: nil,
            quantity: quantity,
            cartId: cartId
        )
    }

    func updateCartConsumableQuantity(
        itemID: CartConsumableItem.ID,
        title: String?,
        quantity: Int,
        cartId: CartSection.ID
    ) {
        let fallbackTitle = title
        mutateCart(cartId, history: { _, after, _ in
            let item = CartConsumableCatalog.merged(with: after.consumables).first { $0.id == itemID }
            let displayTitle = item?.title ?? fallbackTitle ?? "Расходник"
            return (.cartConsumablesChanged, "Тележка \(after.id): \(displayTitle) \(max(0, quantity))")
        }) { cart in
            let changedAt = Date()
            var items = CartConsumableCatalog.merged(with: cart.consumables)
            if items.firstIndex(where: { $0.id == itemID }) == nil,
               let title = title?.trimmingCharacters(in: .whitespacesAndNewlines),
               !title.isEmpty {
                items.append(CartConsumableItem(id: itemID, title: title, quantity: 0))
            }
            guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }
            if let title = title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty {
                items[index].title = title
            }
            items[index].quantity = max(0, quantity)
            items[index].updatedAt = changedAt
            if items[index].quantity == 0 {
                items[index].completedAt = nil
            }
            cart.consumables = items
        }
    }

    func toggleCartConsumableCompletion(
        itemID: CartConsumableItem.ID,
        cartId: CartSection.ID
    ) {
        toggleCartConsumableCompletion(itemID: itemID, title: nil, cartId: cartId)
    }

    func toggleCartConsumableCompletion(
        itemID: CartConsumableItem.ID,
        title: String?,
        cartId: CartSection.ID
    ) {
        let fallbackTitle = title
        mutateCart(cartId, history: { _, after, _ in
            let item = CartConsumableCatalog.merged(with: after.consumables).first { $0.id == itemID }
            let title = item?.title ?? fallbackTitle ?? "Расходник"
            let suffix = item?.isCompleted == true ? "выполнено" : "снова в работе"
            return (.cartConsumablesChanged, "Тележка \(after.id): \(title) \(suffix)")
        }) { cart in
            let changedAt = Date()
            var items = CartConsumableCatalog.merged(with: cart.consumables)
            if items.firstIndex(where: { $0.id == itemID }) == nil,
               let title = title?.trimmingCharacters(in: .whitespacesAndNewlines),
               !title.isEmpty {
                items.append(CartConsumableItem(id: itemID, title: title, quantity: 0))
            }
            guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }
            if let title = title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty {
                items[index].title = title
            }
            items[index].completedAt = items[index].completedAt == nil ? changedAt : nil
            items[index].updatedAt = changedAt
            cart.consumables = items
        }
    }
}
