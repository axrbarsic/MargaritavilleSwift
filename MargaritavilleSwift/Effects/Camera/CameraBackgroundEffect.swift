import Foundation
import QuartzCore

/// Эффекты фона «Камера». Каждый — ветка фрагментного шейдера
/// `cameraEffectFragment` с явным номером `shaderIndex`; порядок в меню задают
/// категории `CameraEffectCategory`.
enum CameraBackgroundEffect: String, CaseIterable, Identifiable, Sendable {
    case normal
    case matte
    case grid
    case kaleidoscope
    case glitch
    case nightVision
    case thermal
    case pixels
    case gameBoy
    case lego
    case ascii
    case crt
    case dither
    case halftone
    case comic
    case cartoon
    case sketch
    case blueprint
    case chalk
    case neon
    case neonShadow
    case tron
    case electric
    case emboss
    case metal
    case stoneRelief
    case paperRelief
    case woodRelief

    static let storageKey = "cameraBackgroundEffect"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .normal: "Обычный"
        case .matte: "Матовый"
        case .grid: "Сетка"
        case .kaleidoscope: "Калейдоскоп"
        case .glitch: "Глитч"
        case .nightVision: "Ночное видение"
        case .thermal: "Тепловизор"
        case .pixels: "Пиксели"
        case .gameBoy: "Game Boy"
        case .lego: "Лего"
        case .ascii: "ASCII"
        case .crt: "ЭЛТ-телевизор"
        case .dither: "1-бит"
        case .halftone: "Полутон"
        case .comic: "Комикс"
        case .cartoon: "Мультфильм"
        case .sketch: "Карандаш"
        case .blueprint: "Чертёж"
        case .chalk: "Мел"
        case .neon: "Неон"
        case .neonShadow: "Неоновая тень"
        case .tron: "Трон"
        case .electric: "Электричество"
        case .emboss: "Тиснение"
        case .metal: "Металл"
        case .stoneRelief: "Камень"
        case .paperRelief: "Бумага"
        case .woodRelief: "Дерево"
        }
    }

    var subtitle: String {
        switch self {
        case .normal: "Чистое изображение камеры."
        case .matte: "Матовое стекло: сильное размытие с лёгким зерном."
        case .grid: "Камера под неоновой сеткой с бегущей строкой сканирования."
        case .kaleidoscope: "Восемь зеркальных секторов, медленно вращаются."
        case .glitch: "Цифровой сбой: сдвиг полос, разделение каналов и вспышки."
        case .nightVision: "Зелёный прибор ночного видения с шумом и виньеткой."
        case .thermal: "Яркость превращается в тепловую карту."
        case .pixels: "Крупная пиксельная мозаика."
        case .gameBoy: "Экран Game Boy: крупные пиксели и четыре оттенка зелёного."
        case .lego: "Всё вокруг собрано из кубиков Лего с шипами в цветах настоящих деталей."
        case .ascii: "Живое видео из символов, цвет берётся из камеры."
        case .crt: "Выпуклый кинескоп с развёрткой, сдвигом цветов и маской триад."
        case .dither: "Двухцветный дизеринг Байера в стиле игры Return of the Obra Dinn."
        case .halftone: "Печатный растр CMYK, как в старых газетах и комиксах."
        case .comic: "Плоские цвета и чёрные контуры, как в комиксе."
        case .cartoon: "Мир как в мультфильме: гладкие заливки, сочные цвета и чёткие контуры."
        case .sketch: "Карандашная перекрёстная штриховка по теням и контуры."
        case .blueprint: "Белые линии на синем листе с миллиметровой сеткой, как технический чертёж."
        case .chalk: "Рваные меловые штрихи по контурам на школьной доске."
        case .neon: "Переливающиеся неоновые контуры; ползунок «Ореол» добавляет свечение."
        case .neonShadow: "Вирусный эффект TikTok: розовая, голубая и жёлтая копии контура расходятся и сходятся."
        case .tron: "Голубые и оранжевые световые контуры на тёмной сетке, как в «Троне»."
        case .electric: "Дрожащие фиолетовые разряды с белой сердцевиной."
        case .emboss: "Серый рельеф, будто изображение выдавлено в листе."
        case .metal: "Чеканка на металле любого цвета: от серебра до золота, меди и синей стали."
        case .stoneRelief: "Изображение высечено в шершавом песчанике."
        case .paperRelief: "Слепое тиснение белым по белому, как на дорогой открытке."
        case .woodRelief: "Резьба по доске с годичными волокнами."
        }
    }

    /// Номер ветки в `CameraBackgroundEffects.metal`; не зависит от порядка в меню.
    var shaderIndex: UInt32 {
        switch self {
        case .normal: 0
        case .matte: 1
        case .grid: 2
        case .nightVision: 3
        case .thermal: 4
        case .comic: 6
        case .pixels: 7
        case .ascii: 8
        case .dither: 9
        case .halftone: 10
        case .gameBoy: 11
        case .crt: 12
        case .sketch: 13
        case .kaleidoscope: 14
        case .glitch: 15
        case .cartoon: 16
        case .lego: 17
        case .neonShadow: 18
        case .neon: 19
        case .tron: 20
        case .blueprint: 21
        case .chalk: 22
        case .electric: 23
        case .emboss: 24
        case .metal: 25
        case .stoneRelief: 28
        case .paperRelief: 29
        case .woodRelief: 30
        }
    }

    /// Предварительный проход MPS перед шейдером эффекта.
    enum Prefilter: Sendable {
        case none
        case blur
        case median
    }

    var prefilter: Prefilter {
        switch self {
        case .matte: .blur
        case .cartoon: .median
        default: .none
        }
    }
}

/// Куда рисовать кадры камеры: слой активного экрана, эффект и его настройки.
/// Читается с очереди кадров, поэтому всё защищено замком.
final class CameraRenderTarget: @unchecked Sendable {
    let layer: CAMetalLayer
    private let lock = NSLock()
    private var storedEffect: CameraBackgroundEffect = .normal
    private var storedTuning = CameraEffectTuning.default

    init(layer: CAMetalLayer) {
        self.layer = layer
    }

    var effect: CameraBackgroundEffect {
        get { lock.lock(); defer { lock.unlock() }; return storedEffect }
        set { lock.lock(); storedEffect = newValue; lock.unlock() }
    }

    var tuning: CameraEffectTuning {
        get { lock.lock(); defer { lock.unlock() }; return storedTuning }
        set { lock.lock(); storedTuning = newValue.clamped; lock.unlock() }
    }
}
