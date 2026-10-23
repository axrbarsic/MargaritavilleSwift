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
    case ascii
    case dither
    case halftone
    case gameBoy
    case crt
    case sketch
    case kaleidoscope
    case glitch
    case timeScan
    case echo
    case matrixRain
    case anaglyph
    case xray
    case vaporwave
    case mirror
    case hologram

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
        case .ascii: "ASCII"
        case .dither: "1-бит"
        case .halftone: "Полутон"
        case .gameBoy: "Game Boy"
        case .crt: "ЭЛТ-телевизор"
        case .sketch: "Карандаш"
        case .kaleidoscope: "Калейдоскоп"
        case .glitch: "Глитч"
        case .timeScan: "Скан времени"
        case .echo: "Призрачный шлейф"
        case .matrixRain: "Матрица"
        case .anaglyph: "3D-анаглиф"
        case .xray: "Рентген"
        case .vaporwave: "Вейпорвейв"
        case .mirror: "Зеркало"
        case .hologram: "Голограмма"
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
        case .ascii: "Живое видео из символов, цвет берётся из камеры."
        case .dither: "Двухцветный дизеринг Байера в стиле игры Return of the Obra Dinn."
        case .halftone: "Печатный растр CMYK, как в старых газетах и комиксах."
        case .gameBoy: "Экран Game Boy: крупные пиксели и четыре оттенка зелёного."
        case .crt: "Выпуклый кинескоп с развёрткой, сдвигом цветов и маской триад."
        case .sketch: "Карандашная перекрёстная штриховка по теням и контуры."
        case .kaleidoscope: "Восемь зеркальных секторов, медленно вращаются."
        case .glitch: "Цифровой сбой: сдвиг полос, разделение каналов и вспышки."
        case .timeScan: "Вирусная «синяя линия» из TikTok: линия идёт вниз и замораживает всё над собой."
        case .echo: "Движение оставляет за собой цветные призрачные следы."
        case .matrixRain: "Камера проступает сквозь зелёный цифровой дождь."
        case .anaglyph: "Красно-голубое 3D, как для картонных очков."
        case .xray: "Инверсия в холодных тонах со светящимися контурами."
        case .vaporwave: "Фиолетово-розово-бирюзовая эстетика 80-х и 90-х."
        case .mirror: "Правая половина зеркально повторяет левую."
        case .hologram: "Синяя мерцающая голограмма с бегущими строками."
        }
    }

    /// Номер ветки в шейдере; порядок совпадает с `CameraBackgroundEffects.metal`.
    var shaderIndex: UInt32 {
        UInt32(Self.allCases.firstIndex(of: self) ?? 0)
    }

    var needsBlur: Bool { self == .matte }

    /// Эффекты с памятью кадров: рендер ведёт для них историю экрана.
    var needsHistory: Bool { self == .timeScan || self == .echo }
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
