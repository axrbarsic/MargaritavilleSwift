import SwiftUI

private struct SettingsOpenRequiresLongPressKey: EnvironmentKey {
    static let defaultValue = false
}

private struct ZeroScreenReturnActionKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: (() -> Void)? = nil
}

extension EnvironmentValues {
    var settingsOpenRequiresLongPress: Bool {
        get { self[SettingsOpenRequiresLongPressKey.self] }
        set { self[SettingsOpenRequiresLongPressKey.self] = newValue }
    }

    var zeroScreenReturnAction: (() -> Void)? {
        get { self[ZeroScreenReturnActionKey.self] }
        set { self[ZeroScreenReturnActionKey.self] = newValue }
    }
}
