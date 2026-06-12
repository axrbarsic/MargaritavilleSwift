import SwiftUI

private struct AppBackgroundModeEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppBackgroundMode = .matrixRain
}

private struct TVStaticNoiseConfigurationEnvironmentKey: EnvironmentKey {
    static let defaultValue: TVStaticNoiseConfiguration = .default
}

extension EnvironmentValues {
    var appBackgroundMode: AppBackgroundMode {
        get { self[AppBackgroundModeEnvironmentKey.self] }
        set { self[AppBackgroundModeEnvironmentKey.self] = newValue }
    }

    var tvStaticNoiseConfiguration: TVStaticNoiseConfiguration {
        get { self[TVStaticNoiseConfigurationEnvironmentKey.self] }
        set { self[TVStaticNoiseConfigurationEnvironmentKey.self] = newValue }
    }
}
