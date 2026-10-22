import Foundation

enum AppBackgroundMode: String, CaseIterable, Identifiable, Codable {
    case off
    case matrixRain
    case tvStaticNoise
    case video
    case brooklyn
    case camera

    var id: String { rawValue }

    var title: String {
        switch self {
        case .off:
            "Выкл"
        case .matrixRain:
            "Matrix"
        case .tvStaticNoise:
            "TV"
        case .video:
            "Видео"
        case .brooklyn:
            "Brooklyn"
        case .camera:
            "Камера"
        }
    }

    var description: String {
        switch self {
        case .off:
            "Чёрный фон"
        case .matrixRain:
            "Matrix Rain"
        case .tvStaticNoise:
            "Сломанный телевизор"
        case .video:
            "Видео фон"
        case .brooklyn:
            "Brooklyn 3D"
        case .camera:
            "Задняя камера"
        }
    }
}
