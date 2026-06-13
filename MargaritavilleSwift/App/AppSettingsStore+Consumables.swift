import Foundation

extension AppSettingsStore {
    func addCartConsumableCatalogItem(named title: String) -> CartConsumableCatalogItem? {
        guard let item = CartConsumableCatalog.makeItem(title: title, existing: cartConsumableCatalog) else {
            return nil
        }
        cartConsumableCatalog.append(item)
        return item
    }

    func renameCartConsumableCatalogItem(id: CartConsumableCatalogItem.ID, title: String) {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty,
              let index = cartConsumableCatalog.firstIndex(where: { $0.id == id })
        else { return }
        cartConsumableCatalog[index].title = title
        cartConsumableCatalog = CartConsumableCatalog.normalizedCatalog(cartConsumableCatalog)
    }

    func removeCartConsumableCatalogItem(id: CartConsumableCatalogItem.ID) {
        cartConsumableCatalog.removeAll { $0.id == id }
        if cartConsumableCatalog.isEmpty {
            cartConsumableCatalog = CartConsumableCatalog.defaultCatalog
        }
    }
}
