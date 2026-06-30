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
    case uiClickBright
    case uiClickSoft
    case uiRolloverTick
    case uiSwitchLight
    case uiSwitchDeep
    case uiConfirmPop
    case uiConfirmGlass
    case uiAlertSnap
    case uiErrorLow
    case uiMenuOpen

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
        case .uiClickBright: "Яркий клик"
        case .uiClickSoft: "Мягкий клик"
        case .uiRolloverTick: "Короткий тик"
        case .uiSwitchLight: "Лёгкий переключатель"
        case .uiSwitchDeep: "Глубокий переключатель"
        case .uiConfirmPop: "Сочный поп"
        case .uiConfirmGlass: "Стеклянное подтверждение"
        case .uiAlertSnap: "Резкий сигнал"
        case .uiErrorLow: "Низкий отказ"
        case .uiMenuOpen: "Открытие меню"
        }
    }

    static let settingsPalette: [InteractionSoundAsset] = [
        .none,
        .uiClickBright,
        .uiClickSoft,
        .uiRolloverTick,
        .uiSwitchLight,
        .uiSwitchDeep,
        .uiConfirmPop,
        .uiConfirmGlass,
        .kenneyConfirmation3,
        .uiAlertSnap,
        .uiErrorLow,
        .uiMenuOpen,
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
        case .uiClickBright:
            "xhotel_ui_click_bright"
        case .uiClickSoft:
            "xhotel_ui_click_soft"
        case .uiRolloverTick:
            "xhotel_ui_rollover_tick"
        case .uiSwitchLight:
            "xhotel_ui_switch_light"
        case .uiSwitchDeep:
            "xhotel_ui_switch_deep"
        case .uiConfirmPop:
            "xhotel_ui_confirm_pop"
        case .uiConfirmGlass:
            "xhotel_ui_confirm_glass"
        case .uiAlertSnap:
            "xhotel_ui_alert_snap"
        case .uiErrorLow:
            "xhotel_ui_error_low"
        case .uiMenuOpen:
            "xhotel_ui_menu_open"
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
        .roomOpen,
        .roomReady
    ]

    var title: String {
        switch self {
        case .tap: "Все остальные действия"
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
        case .roomOpen: "Ячейка"
        case .roomInProgress: "Синяя комната"
        case .roomReady: "Зелёная ячейка"
        case .roomScheduled: "Комната по времени"
        }
    }

    var settingsSubtitle: String {
        switch self {
        case .tap:
            "Любые действия, которые не касаются ячеек."
        case .roomOpen:
            "Любое взаимодействие с ячейкой, кроме финального зелёного статуса."
        case .roomReady:
            "Когда ячейка становится зелёной."
        case .confirm:
            "Сохранение, успешный выбор или подтверждение."
        case .actionMenuOpen:
            "Один звук, когда открывается меню комнаты."
        case .roomPending:
            "Когда комната возвращается в жёлтый статус."
        case .roomInProgress:
            "Когда комната становится синей."
        case .roomScheduled:
            "Когда комната уходит в расписанный статус."
        case .longPress, .holdStart, .holdWarning, .holdCommit, .select, .deselect, .invalid,
             .detent, .settingsOpen, .selectionOpen:
            "Служебное событие, скрыто из простого выбора."
        }
    }

    var soundAssignmentEvent: InteractionSoundEvent {
        switch self {
        case .roomReady:
            .roomReady
        case .actionMenuOpen, .roomPending, .roomOpen, .roomInProgress, .roomScheduled:
            .roomOpen
        case .tap, .confirm, .longPress, .holdStart, .holdWarning, .holdCommit,
             .select, .deselect, .invalid, .detent, .settingsOpen, .selectionOpen:
            .tap
        }
    }

    var defaultAsset: InteractionSoundAsset {
        switch self {
        case .tap: .uiRolloverTick
        case .confirm: .uiConfirmPop
        case .longPress: .uiConfirmGlass
        case .holdStart: .none
        case .holdWarning: .uiRolloverTick
        case .holdCommit: .uiConfirmPop
        case .select: .uiSwitchLight
        case .deselect: .uiClickBright
        case .invalid: .uiErrorLow
        case .detent: .uiRolloverTick
        case .settingsOpen: .uiMenuOpen
        case .selectionOpen: .uiConfirmGlass
        case .actionMenuOpen: .uiMenuOpen
        case .roomPending: .uiClickSoft
        case .roomOpen: .uiConfirmGlass
        case .roomInProgress: .uiSwitchDeep
        case .roomReady: .frontDeskBell
        case .roomScheduled: .uiAlertSnap
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
        let assignmentEvent = event.soundAssignmentEvent
        guard let raw = storage[assignmentEvent.rawValue],
              let asset = InteractionSoundAsset(rawValue: raw)
        else {
            return assignmentEvent.defaultAsset
        }
        return asset
    }

    mutating func set(_ asset: InteractionSoundAsset, for event: InteractionSoundEvent) {
        let assignmentEvent = event.soundAssignmentEvent
        if asset == assignmentEvent.defaultAsset {
            storage.removeValue(forKey: assignmentEvent.rawValue)
        } else {
            storage[assignmentEvent.rawValue] = asset.rawValue
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
