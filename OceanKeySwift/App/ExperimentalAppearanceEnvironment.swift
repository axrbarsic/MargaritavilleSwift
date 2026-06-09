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

private struct ExperimentalCellTVStaticEnabledKey: EnvironmentKey {
    static let defaultValue = false
}

private struct ExperimentalVIPZebraIntensityKey: EnvironmentKey {
    static let defaultValue = 0.86
}

private struct ExperimentalVIPZebraSpeedKey: EnvironmentKey {
    static let defaultValue = 0.78
}

private struct ExperimentalVIPZebraSharpnessKey: EnvironmentKey {
    static let defaultValue = 0.62
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

    var experimentalCellTVStaticEnabled: Bool {
        get { self[ExperimentalCellTVStaticEnabledKey.self] }
        set { self[ExperimentalCellTVStaticEnabledKey.self] = newValue }
    }

    var experimentalVIPZebraIntensity: Double {
        get { self[ExperimentalVIPZebraIntensityKey.self] }
        set { self[ExperimentalVIPZebraIntensityKey.self] = newValue }
    }

    var experimentalVIPZebraSpeed: Double {
        get { self[ExperimentalVIPZebraSpeedKey.self] }
        set { self[ExperimentalVIPZebraSpeedKey.self] = newValue }
    }

    var experimentalVIPZebraSharpness: Double {
        get { self[ExperimentalVIPZebraSharpnessKey.self] }
        set { self[ExperimentalVIPZebraSharpnessKey.self] = newValue }
    }
}
