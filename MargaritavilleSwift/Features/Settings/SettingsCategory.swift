import Foundation

enum SettingsCategory: String, CaseIterable, Identifiable {
    case appearance
    case background
    case workflow
    case developer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appearance:
            "Внешний вид"
        case .background:
            "Фон"
        case .workflow:
            "Работа"
        case .developer:
            "Разработчик"
        }
    }

    var iconName: String {
        switch self {
        case .appearance:
            "paintpalette.fill"
        case .background:
            "film.stack.fill"
        case .workflow:
            "hand.tap.fill"
        case .developer:
            "hammer.fill"
        }
    }
}
