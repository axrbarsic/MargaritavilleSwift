import Foundation

/// Категории эффектов камеры: меню сначала показывает категорию, потом её эффекты.
enum CameraEffectCategory: String, CaseIterable, Identifiable, Sendable {
    case classic
    case vision
    case pixels
    case retro
    case drawing
    case neon
    case relief

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic: "Классика"
        case .vision: "Приборы"
        case .pixels: "Пиксели"
        case .retro: "Ретро"
        case .drawing: "Рисунок"
        case .neon: "Неон"
        case .relief: "Рельеф"
        }
    }

    var systemImage: String {
        switch self {
        case .classic: "camera.fill"
        case .vision: "eye.fill"
        case .pixels: "square.grid.3x3.fill"
        case .retro: "tv.fill"
        case .drawing: "pencil.and.scribble"
        case .neon: "bolt.fill"
        case .relief: "mountain.2.fill"
        }
    }

    var effects: [CameraBackgroundEffect] {
        switch self {
        case .classic: [.normal, .matte, .grid, .kaleidoscope, .glitch]
        case .vision: [.nightVision, .thermal]
        case .pixels: [.pixels, .gameBoy, .lego, .ascii]
        case .retro: [.crt, .dither, .halftone]
        case .drawing: [.comic, .cartoon, .sketch, .blueprint, .chalk]
        case .neon: [.neon, .neonShadow, .tron, .electric]
        case .relief: [.emboss, .metal, .periodicMetals, .stoneRelief, .paperRelief, .woodRelief]
        }
    }
}

extension CameraBackgroundEffect {
    var category: CameraEffectCategory {
        CameraEffectCategory.allCases.first { $0.effects.contains(self) } ?? .classic
    }
}
