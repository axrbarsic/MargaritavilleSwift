import Foundation
import Testing
@testable import MargaritavilleSwift

@MainActor
@Test
func onlyTopmostBackgroundAnimatesAcrossPushSheetAndPop() {
    let presence = AppBackgroundPresence()
    let summary = UUID()
    let room = UUID()
    let settings = UUID()

    presence.register(summary)
    #expect(presence.isActive(summary))

    // Переход на экран номера: новый фон появляется, нижний уходит.
    presence.register(room)
    presence.unregister(summary)
    #expect(presence.isActive(room))
    #expect(!presence.isActive(summary))

    // Возврат: сводка появляется раньше, чем исчезает экран номера.
    presence.register(summary)
    presence.unregister(room)
    #expect(presence.isActive(summary))

    // Лист настроек поверх сводки: сводка остаётся в стеке, но замирает.
    presence.register(settings)
    #expect(presence.isActive(settings))
    #expect(!presence.isActive(summary))

    presence.unregister(settings)
    #expect(presence.isActive(summary))
    #expect(presence.stack == [summary])
}

@MainActor
@Test
func reappearingBackgroundMovesToTopWithoutDuplicates() {
    let presence = AppBackgroundPresence()
    let first = UUID()
    let second = UUID()

    presence.register(first)
    presence.register(second)
    presence.register(first)

    #expect(presence.stack == [second, first])
    #expect(presence.isActive(first))
}

@Test
func appSettingsPersistsCameraBackgroundMode() {
    let suiteName = "AppBackgroundPresenceTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let settings = AppSettingsStore(userDefaults: defaults)
    settings.appBackgroundMode = .camera

    #expect(AppSettingsStore.load(userDefaults: defaults).appBackgroundMode == .camera)
    #expect(defaults.string(forKey: "appBackgroundMode") == "camera")
}
