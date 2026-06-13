import Foundation

struct CartDetailsRoute: Identifiable {
    let cartID: CartSection.ID
    var title: String?
    var subtitle: String?

    var id: CartSection.ID { cartID }
}
