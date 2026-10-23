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
    case cartoon
    case lego
    case neonShadow
    case neonGlow
    case tron
    case blueprint
    case chalk
    case electric
    case emboss
    case goldRelief
    case silverRelief
    case copperRelief
    case stoneRelief
    case paperRelief
    case woodRelief
    case liveRelief

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
        case .cartoon: "Мультфильм"
        case .lego: "Лего"
        case .neonShadow: "Неоновая тень"
        case .neonGlow: "Неон-свечение"
        case .tron: "Трон"
        case .blueprint: "Чертёж"
        case .chalk: "Мел"
        case .electric: "Электричество"
        case .emboss: "Тиснение"
        case .goldRelief: "Золото"
        case .silverRelief: "Серебряная монета"
        case .copperRelief: "Медь"
        case .stoneRelief: "Барельеф"
        case .paperRelief: "Тиснение на бумаге"
        case .woodRelief: "Резьба по дереву"
        case .liveRelief: "Живой рельеф"
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
        case .cartoon: "Мир как в мультфильме: гладкие заливки, сочные цвета и чёткие контуры."
        case .lego: "Всё вокруг собрано из кубиков Лего с шипами в цветах настоящих деталей."
        case .neonShadow: "Вирусный эффект TikTok: розовая, голубая и жёлтая копии контура расходятся и сходятся."
        case .neonGlow: "Переливающиеся неоновые линии с широким светящимся ореолом."
        case .tron: "Голубые и оранжевые световые контуры на тёмной сетке, как в «Троне»."
        case .blueprint: "Белые линии на синем листе с миллиметровой сеткой, как технический чертёж."
        case .chalk: "Рваные меловые штрихи по контурам на школьной доске."
        case .electric: "Дрожащие фиолетовые разряды с белой сердцевиной."
        case .emboss: "Рельеф, будто изображение выдавлено в металле."
        case .goldRelief: "Рельеф из полированного золота с тёплыми бликами."
        case .silverRelief: "Чеканка на серебре, как на монете."
        case .copperRelief: "Медная чеканка с красноватым отливом."
        case .stoneRelief: "Изображение высечено в шершавом песчанике."
        case .paperRelief: "Слепое тиснение белым по белому, как на дорогой открытке."
        case .woodRelief: "Резьба по доске с годичными волокнами."
        case .liveRelief: "Серебряный рельеф, по которому по кругу ходит свет."
        }
    }

    /// Номер ветки в шейдере; порядок совпадает с `CameraBackgroundEffects.metal`.
    var shaderIndex: UInt32 {
        UInt32(Self.allCases.firstIndex(of: self) ?? 0)
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
