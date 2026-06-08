import SwiftUI

private struct ExperimentalLiquidGlassEnabledKey: EnvironmentKey {
    static let defaultValue = false
}

private struct ExperimentalGlassVIPEnabledKey: EnvironmentKey {
    static let defaultValue = false
}

private struct ExperimentalMetalAuroraEnabledKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var experimentalLiquidGlassEnabled: Bool {
        get { self[ExperimentalLiquidGlassEnabledKey.self] }
        set { self[ExperimentalLiquidGlassEnabledKey.self] = newValue }
    }

    var experimentalGlassVIPEnabled: Bool {
        get { self[ExperimentalGlassVIPEnabledKey.self] }
        set { self[ExperimentalGlassVIPEnabledKey.self] = newValue }
    }

    var experimentalMetalAuroraEnabled: Bool {
        get { self[ExperimentalMetalAuroraEnabledKey.self] }
        set { self[ExperimentalMetalAuroraEnabledKey.self] = newValue }
    }
}
