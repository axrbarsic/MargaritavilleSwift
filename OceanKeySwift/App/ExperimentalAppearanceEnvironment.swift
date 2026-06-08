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

private struct ExperimentalCellVolumeEnabledKey: EnvironmentKey {
    static let defaultValue = false
}

private struct ExperimentalCellVolumeIntensityKey: EnvironmentKey {
    static let defaultValue = 0.78
}

private struct ExperimentalCellSpringIntensityKey: EnvironmentKey {
    static let defaultValue = 0.72
}

private struct ExperimentalCellSpringSpeedKey: EnvironmentKey {
    static let defaultValue = 0.82
}

private struct ExperimentalVIPZebraIntensityKey: EnvironmentKey {
    static let defaultValue = 0.86
}

private struct ExperimentalVIPZebraSpeedKey: EnvironmentKey {
    static let defaultValue = 0.78
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

    var experimentalCellVolumeEnabled: Bool {
        get { self[ExperimentalCellVolumeEnabledKey.self] }
        set { self[ExperimentalCellVolumeEnabledKey.self] = newValue }
    }

    var experimentalCellVolumeIntensity: Double {
        get { self[ExperimentalCellVolumeIntensityKey.self] }
        set { self[ExperimentalCellVolumeIntensityKey.self] = newValue }
    }

    var experimentalCellSpringIntensity: Double {
        get { self[ExperimentalCellSpringIntensityKey.self] }
        set { self[ExperimentalCellSpringIntensityKey.self] = newValue }
    }

    var experimentalCellSpringSpeed: Double {
        get { self[ExperimentalCellSpringSpeedKey.self] }
        set { self[ExperimentalCellSpringSpeedKey.self] = newValue }
    }

    var experimentalVIPZebraIntensity: Double {
        get { self[ExperimentalVIPZebraIntensityKey.self] }
        set { self[ExperimentalVIPZebraIntensityKey.self] = newValue }
    }

    var experimentalVIPZebraSpeed: Double {
        get { self[ExperimentalVIPZebraSpeedKey.self] }
        set { self[ExperimentalVIPZebraSpeedKey.self] = newValue }
    }
}
