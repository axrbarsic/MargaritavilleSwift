import Foundation
import QuartzCore

/// Эффекты фона «Камера». Каждый — ветка одного фрагментного шейдера
/// `cameraEffectFragment`; «Матовый» дополнительно размывается MPS-проходом.
enum CameraBackgroundEffect: String, CaseIterable, Identifiable, Sendable {
    case normal
    case matte
    case grid
    case nightVision
    case thermal
    case neonEdges
    case comic
    case pixels

    static let storageKey = "cameraBackgroundEffect"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .normal: "Обычный"
        case .matte: "Матовый"
        case .grid: "Сетка"
        case .nightVision: "Ночное видение"
        case .thermal: "Тепловизор"
        case .neonEdges: "Неон-контуры"
        case .comic: "Комикс"
        case .pixels: "Пиксели"
        }
    }

    var subtitle: String {
        switch self {
        case .normal: "Чистое изображение камеры."
        case .matte: "Матовое стекло: сильное размытие с лёгким зерном."
        case .grid: "Камера под неоновой сеткой с бегущей строкой сканирования."
        case .nightVision: "Зелёный прибор ночного видения с шумом и виньеткой."
        case .thermal: "Яркость превращается в тепловую карту."
        case .neonEdges: "Только светящиеся неоновые контуры на тёмном фоне."
        case .comic: "Плоские цвета и чёрные контуры, как в комиксе."
        case .pixels: "Крупная пиксельная мозаика."
        }
    }

    /// Номер ветки в шейдере; порядок совпадает с `CameraBackgroundEffects.metal`.
    var shaderIndex: UInt32 {
        UInt32(Self.allCases.firstIndex(of: self) ?? 0)
    }

    var needsBlur: Bool { self == .matte }
}

/// Куда рисовать кадры камеры: слой активного экрана и выбранный эффект.
/// Читается с очереди кадров, поэтому эффект защищён замком.
final class CameraRenderTarget: @unchecked Sendable {
    let layer: CAMetalLayer
    private let lock = NSLock()
    private var storedEffect: CameraBackgroundEffect = .normal

    init(layer: CAMetalLayer) {
        self.layer = layer
    }

    var effect: CameraBackgroundEffect {
        get { lock.lock(); defer { lock.unlock() }; return storedEffect }
        set { lock.lock(); storedEffect = newValue; lock.unlock() }
    }
}
