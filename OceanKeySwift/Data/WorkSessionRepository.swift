import Foundation

protocol WorkSessionRepository {
    func loadCarts() throws -> [CartSection]?
    func save(carts: [CartSection]) throws
}

