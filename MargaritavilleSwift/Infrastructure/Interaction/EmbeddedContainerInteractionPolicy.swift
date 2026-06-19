import SwiftUI

private struct SettingsOpenRequiresLongPressKey: EnvironmentKey {
    static let defaultValue = false
}

private struct EmbeddedContainerReturnToZeroScreenKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: (() -> Void)? = nil
}

extension EnvironmentValues {
    var settingsOpenRequiresLongPress: Bool {
        get { self[SettingsOpenRequiresLongPressKey.self] }
        set { self[SettingsOpenRequiresLongPressKey.self] = newValue }
    }

    var embeddedContainerReturnToZeroScreen: (() -> Void)? {
        get { self[EmbeddedContainerReturnToZeroScreenKey.self] }
        set { self[EmbeddedContainerReturnToZeroScreenKey.self] = newValue }
    }
}
