import Foundation
import Observation
import SwiftUI

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

/// Экран, который целиком перекрывает фон (например, системная камера для
/// фото): пока он открыт, ни один живой фон не активен, а камера фона отпущена.
private struct AppBackgroundOccluder: ViewModifier {
    @State private var id = UUID()

    func body(content: Content) -> some View {
        content
            .onAppear { AppBackgroundPresence.shared.register(id) }
            .onDisappear { AppBackgroundPresence.shared.unregister(id) }
    }
}

extension View {
    func occludesAppBackground() -> some View {
        modifier(AppBackgroundOccluder())
    }
}
