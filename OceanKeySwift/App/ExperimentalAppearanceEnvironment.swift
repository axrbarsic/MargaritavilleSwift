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

private struct ExperimentalSoundPackV2EnabledKey: EnvironmentKey {
    static let defaultValue = false
}

private struct ExperimentalHapticsV2EnabledKey: EnvironmentKey {
    static let defaultValue = false
}

private struct ExperimentalVIPParticlesEnabledKey: EnvironmentKey {
    static let defaultValue = false
}

private struct ExperimentalCellPhysicsEnabledKey: EnvironmentKey {
    static let defaultValue = false
}

private struct ExperimentalAssistantObjectEnabledKey: EnvironmentKey {
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

    var experimentalSoundPackV2Enabled: Bool {
        get { self[ExperimentalSoundPackV2EnabledKey.self] }
        set { self[ExperimentalSoundPackV2EnabledKey.self] = newValue }
    }

    var experimentalHapticsV2Enabled: Bool {
        get { self[ExperimentalHapticsV2EnabledKey.self] }
        set { self[ExperimentalHapticsV2EnabledKey.self] = newValue }
    }

    var experimentalVIPParticlesEnabled: Bool {
        get { self[ExperimentalVIPParticlesEnabledKey.self] }
        set { self[ExperimentalVIPParticlesEnabledKey.self] = newValue }
    }

    var experimentalCellPhysicsEnabled: Bool {
        get { self[ExperimentalCellPhysicsEnabledKey.self] }
        set { self[ExperimentalCellPhysicsEnabledKey.self] = newValue }
    }

    var experimentalAssistantObjectEnabled: Bool {
        get { self[ExperimentalAssistantObjectEnabledKey.self] }
        set { self[ExperimentalAssistantObjectEnabledKey.self] = newValue }
    }
}
