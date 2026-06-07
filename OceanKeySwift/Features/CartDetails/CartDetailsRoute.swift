import Foundation

struct CartDetailsRoute: Identifiable {
    let cartID: CartSection.ID

    var id: CartSection.ID { cartID }
}

