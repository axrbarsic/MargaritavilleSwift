import Foundation

protocol WorkSessionRepository: Sendable {
    func loadSnapshot() throws -> WorkSessionSnapshot?
    func save(snapshot: WorkSessionSnapshot)
}
