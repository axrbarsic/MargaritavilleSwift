import SwiftUI

enum InteractionSoundAsset: String, CaseIterable, Codable, Identifiable, Sendable {
    case none
    case legacyClick
    case legacyPressed
    case hotelBell
    case frontDeskBell
    case kenneyConfirmation1
    case kenneyConfirmation2
    case kenneyConfirmation3
    case kenneyConfirmation4
    case kenneySelect1
    case kenneySelect2
    case kenneySelect3
    case kenneySelect4
    case kenneyTick1
    case kenneyBong1

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: "Без звука"
        case .legacyClick: "Сухой щелчок"
        case .legacyPressed: "Мягкое нажатие"
        case .hotelBell: "Старый колокольчик"
        case .frontDeskBell: "Звонок стойки"
        case .kenneyConfirmation1: "Чистое подтверждение"
        case .kenneyConfirmation2: "Меню: мягкий сигнал"
        case .kenneyConfirmation3: "Плотное подтверждение"
        case .kenneyConfirmation4: "Яркое подтверждение"
        case .kenneySelect1: "Лёгкий выбор"
        case .kenneySelect2: "Чистый выбор"
        case .kenneySelect3: "Тихий выбор"
        case .kenneySelect4: "Глубокий выбор"
        case .kenneyTick1: "Тик шкалы"
        case .kenneyBong1: "Низкий бонг"
        }
    }

    static let settingsPalette: [InteractionSoundAsset] = [
        .none,
        .legacyClick,
        .legacyPressed,
        .kenneySelect1,
        .kenneyConfirmation4,
        .kenneyTick1,
        .kenneyBong1,
        .frontDeskBell
    ]

    static func settingsPickerAssets(current: InteractionSoundAsset) -> [InteractionSoundAsset] {
        if settingsPalette.contains(current) {
            return settingsPalette
        }
        return [current] + settingsPalette
    }

    var resourceName: String? {
        switch self {
        case .none, .legacyClick, .legacyPressed:
            nil
        case .hotelBell:
            "room_complete_hotel_bell"
        case .frontDeskBell:
            "front_desk_bell_real"
        case .kenneyConfirmation1:
            "kenney_confirmation_001"
        case .kenneyConfirmation2:
            "kenney_confirmation_002"
        case .kenneyConfirmation3:
            "kenney_confirmation_003"
        case .kenneyConfirmation4:
            "kenney_confirmation_004"
        case .kenneySelect1:
            "kenney_select_001"
        case .kenneySelect2:
            "kenney_select_002"
        case .kenneySelect3:
            "kenney_select_003"
        case .kenneySelect4:
            "kenney_select_004"
        case .kenneyTick1:
            "kenney_tick_001"
        case .kenneyBong1:
            "kenney_bong_001"
        }
    }
}

enum InteractionSoundEvent: String, CaseIterable, Codable, Identifiable, Sendable {
    case tap
    case confirm
    case longPress
    case holdStart
    case holdWarning
    case holdCommit
    case select
    case deselect
    case invalid
    case detent
    case settingsOpen
    case selectionOpen
    case actionMenuOpen
    case roomPending
    case roomOpen
    case roomInProgress
    case roomReady
    case roomScheduled

    var id: String { rawValue }

    static let settingsVisibleCases: [InteractionSoundEvent] = [
        .tap,
        .confirm,
        .actionMenuOpen,
        .roomPending,
        .roomOpen,
        .roomInProgress,
        .roomReady,
        .roomScheduled
    ]

    var title: String {
        switch self {
        case .tap: "Тап по экрану"
        case .confirm: "Подтверждение"
        case .longPress: "Долгое нажатие"
        case .holdStart: "Старт удержания"
        case .holdWarning: "Порог удержания"
        case .holdCommit: "Удержание выполнено"
        case .select: "Выбор"
        case .deselect: "Отмена выбора"
        case .invalid: "Ошибка"
        case .detent: "Щелчок шкалы"
        case .settingsOpen: "Открытие настроек"
        case .selectionOpen: "Первый экран"
        case .actionMenuOpen: "Меню комнаты"
        case .roomPending: "Жёлтая комната"
        case .roomOpen: "Красная комната"
        case .roomInProgress: "Синяя комната"
        case .roomReady: "Готово: зелёная"
        case .roomScheduled: "Комната по времени"
        }
    }

    var settingsSubtitle: String {
        switch self {
        case .tap:
            "Обычный короткий тап по интерфейсу."
        case .confirm:
            "Сохранение, успешный выбор или подтверждение."
        case .actionMenuOpen:
            "Один звук, когда открывается меню комнаты."
        case .roomPending:
            "Когда комната возвращается в жёлтый статус."
        case .roomOpen:
            "Когда комната становится красной."
        case .roomInProgress:
            "Когда комната становится синей."
        case .roomReady:
            "Финальный звук полностью готовой зелёной комнаты."
        case .roomScheduled:
            "Когда комната уходит в расписанный статус."
        case .longPress, .holdStart, .holdWarning, .holdCommit, .select, .deselect, .invalid,
             .detent, .settingsOpen, .selectionOpen:
            "Служебное событие, скрыто из простого выбора."
        }
    }

    var defaultAsset: InteractionSoundAsset {
        switch self {
        case .tap: .legacyClick
        case .confirm: .legacyPressed
        case .longPress: .legacyPressed
        case .holdStart: .none
        case .holdWarning: .kenneyTick1
        case .holdCommit: .legacyPressed
        case .select: .legacyPressed
        case .deselect: .legacyClick
        case .invalid: .legacyClick
        case .detent: .kenneyTick1
        case .settingsOpen: .kenneySelect1
        case .selectionOpen: .kenneyConfirmation1
        case .actionMenuOpen: .kenneyConfirmation2
        case .roomPending: .legacyClick
        case .roomOpen: .kenneyConfirmation1
        case .roomInProgress: .kenneySelect2
        case .roomReady: .frontDeskBell
        case .roomScheduled: .kenneyBong1
        }
    }

    var playbackPriority: Int {
        switch self {
        case .roomPending, .roomOpen, .roomInProgress, .roomReady, .roomScheduled:
            80
        case .settingsOpen, .selectionOpen, .actionMenuOpen:
            70
        case .holdCommit:
            60
        case .holdWarning, .longPress:
            50
        case .confirm, .select, .deselect, .invalid, .detent:
            40
        case .tap, .holdStart:
            20
        }
    }
}

struct InteractionSoundAssignments: Codable, Equatable, Sendable {
    private var storage: [String: String] = [:]

    init(storage: [String: String] = [:]) {
        self.storage = storage
    }

    func asset(for event: InteractionSoundEvent) -> InteractionSoundAsset {
        guard let raw = storage[event.rawValue],
              let asset = InteractionSoundAsset(rawValue: raw)
        else {
            return event.defaultAsset
        }
        return asset
    }

    mutating func set(_ asset: InteractionSoundAsset, for event: InteractionSoundEvent) {
        if asset == event.defaultAsset {
            storage.removeValue(forKey: event.rawValue)
        } else {
            storage[event.rawValue] = asset.rawValue
        }
    }
}

private struct InteractionSoundAssignmentsEnvironmentKey: EnvironmentKey {
    static let defaultValue = InteractionSoundAssignments()
}

extension EnvironmentValues {
    var interactionSoundAssignments: InteractionSoundAssignments {
        get { self[InteractionSoundAssignmentsEnvironmentKey.self] }
        set { self[InteractionSoundAssignmentsEnvironmentKey.self] = newValue }
    }
}
