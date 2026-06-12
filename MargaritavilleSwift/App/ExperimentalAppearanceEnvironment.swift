import SwiftUI

private struct ExperimentalCellPhysicsEnabledKey: EnvironmentKey {
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

extension EnvironmentValues {
    var experimentalCellPhysicsEnabled: Bool {
        get { self[ExperimentalCellPhysicsEnabledKey.self] }
        set { self[ExperimentalCellPhysicsEnabledKey.self] = newValue }
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
}
