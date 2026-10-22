import Foundation
import Observation

/// Единая точка живого фона. Каждый экран кладёт под себя свой
/// `AppBackgroundView`, но анимируется только самый верхний: экраны под
/// навигацией и под листами замирают на последнем кадре и не тратят GPU.
@MainActor
@Observable
final class AppBackgroundPresence {
    static let shared = AppBackgroundPresence()

    private(set) var stack: [UUID] = []

    func register(_ id: UUID) {
        stack.removeAll { $0 == id }
        stack.append(id)
    }

    func unregister(_ id: UUID) {
        stack.removeAll { $0 == id }
    }

    func isActive(_ id: UUID) -> Bool {
        stack.last == id
    }
}
