import SwiftUI

private struct ExperimentalCellPhysicsEnabledKey: EnvironmentKey {
    static let defaultValue = false
}

private struct ExperimentalLive3DCellsEnabledKey: EnvironmentKey {
    static let defaultValue = false
}

private struct ExperimentalLive3DCellsRendererReadyKey: EnvironmentKey {
    static let defaultValue = false
}

private struct ExperimentalCellSpringIntensityKey: EnvironmentKey {
    static let defaultValue = 0.72
}

private struct ExperimentalCellSpringSpeedKey: EnvironmentKey {
    static let defaultValue = 0.82
}

private struct ExperimentalVIPJellyEnabledKey: EnvironmentKey {
    static let defaultValue = false
}

private struct ExperimentalVIPJellySpeedKey: EnvironmentKey {
    static let defaultValue = 0.75
}

private struct ExperimentalVIPHDREnabledKey: EnvironmentKey {
    static let defaultValue = false
}

private struct ExperimentalStatusHDRPulseEnabledKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var experimentalCellPhysicsEnabled: Bool {
        get { self[ExperimentalCellPhysicsEnabledKey.self] }
        set { self[ExperimentalCellPhysicsEnabledKey.self] = newValue }
    }

    var experimentalLive3DCellsEnabled: Bool {
        get { self[ExperimentalLive3DCellsEnabledKey.self] }
        set { self[ExperimentalLive3DCellsEnabledKey.self] = newValue }
    }

    var experimentalLive3DCellsRendererReady: Bool {
        get { self[ExperimentalLive3DCellsRendererReadyKey.self] }
        set { self[ExperimentalLive3DCellsRendererReadyKey.self] = newValue }
    }

    var experimentalCellSpringIntensity: Double {
        get { self[ExperimentalCellSpringIntensityKey.self] }
        set { self[ExperimentalCellSpringIntensityKey.self] = newValue }
    }

    var experimentalCellSpringSpeed: Double {
        get { self[ExperimentalCellSpringSpeedKey.self] }
        set { self[ExperimentalCellSpringSpeedKey.self] = newValue }
    }

    var experimentalVIPJellyEnabled: Bool {
        get { self[ExperimentalVIPJellyEnabledKey.self] }
        set { self[ExperimentalVIPJellyEnabledKey.self] = newValue }
    }

    var experimentalVIPJellySpeed: Double {
        get { self[ExperimentalVIPJellySpeedKey.self] }
        set { self[ExperimentalVIPJellySpeedKey.self] = newValue }
    }

    var experimentalVIPHDREnabled: Bool {
        get { self[ExperimentalVIPHDREnabledKey.self] }
        set { self[ExperimentalVIPHDREnabledKey.self] = newValue }
    }

    var experimentalStatusHDRPulseEnabled: Bool {
        get { self[ExperimentalStatusHDRPulseEnabledKey.self] }
        set { self[ExperimentalStatusHDRPulseEnabledKey.self] = newValue }
    }
}
