import Foundation

extension WorkSessionStore {
    func updateCartConsumableQuantity(
        itemID: CartConsumableItem.ID,
        quantity: Int,
        cartId: CartSection.ID
    ) {
        mutateCart(cartId, history: { _, after, _ in
            let item = CartConsumableCatalog.merged(with: after.consumables).first { $0.id == itemID }
            let title = item?.title ?? "Расходник"
            return (.cartConsumablesChanged, "Тележка \(after.id): \(title) \(max(0, quantity))")
        }) { cart in
            let changedAt = Date()
            var items = CartConsumableCatalog.merged(with: cart.consumables)
            guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }
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
        mutateCart(cartId, history: { _, after, _ in
            let item = CartConsumableCatalog.merged(with: after.consumables).first { $0.id == itemID }
            let title = item?.title ?? "Расходник"
            let suffix = item?.isCompleted == true ? "выполнено" : "снова в работе"
            return (.cartConsumablesChanged, "Тележка \(after.id): \(title) \(suffix)")
        }) { cart in
            let changedAt = Date()
            var items = CartConsumableCatalog.merged(with: cart.consumables)
            guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }
            items[index].completedAt = items[index].completedAt == nil ? changedAt : nil
            items[index].updatedAt = changedAt
            cart.consumables = items
        }
    }
}
