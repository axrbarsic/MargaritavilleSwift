import Foundation

enum AppBackgroundMode: String, CaseIterable, Identifiable, Codable {
    case off
    case matrixRain
    case tvStaticNoise
    case video
    case brooklyn
    case brooklynWeb
    case aurora
    case liquidNeon
    case hyperspace
    case synthwave

    var id: String { rawValue }

    /// Режимы, которые рисуются общим хостом шейдерных живых обоев.
    var shaderWallpaper: ShaderWallpaperKind? {
        switch self {
        case .aurora: .aurora
        case .liquidNeon: .liquidNeon
        case .hyperspace: .hyperspace
        case .synthwave: .synthwave
        case .off, .matrixRain, .tvStaticNoise, .video, .brooklyn, .brooklynWeb: nil
        }
    }

    var title: String {
        if let shaderWallpaper { return shaderWallpaper.title }
        return switch self {
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
        case .brooklynWeb:
            "Brooklyn Web"
        case .aurora, .liquidNeon, .hyperspace, .synthwave:
            ""
        }
    }

    var description: String {
        if let shaderWallpaper { return shaderWallpaper.description }
        return switch self {
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
        case .brooklynWeb:
            "Brooklyn Web локально"
        case .aurora, .liquidNeon, .hyperspace, .synthwave:
            ""
        }
    }
}
