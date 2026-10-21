import BrooklynBackgroundKit
import BrooklynWebBackgroundKit
import SwiftUI

private struct AppBackgroundModeEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppBackgroundMode = .matrixRain
}

private struct TVStaticNoiseConfigurationEnvironmentKey: EnvironmentKey {
    static let defaultValue: TVStaticNoiseConfiguration = .default
}

private struct BrooklynSurfaceStyleEnvironmentKey: EnvironmentKey {
    static let defaultValue: BrooklynSurfaceStyle = .donorExact
}

private struct BrooklynWebConfigurationEnvironmentKey: EnvironmentKey {
    static let defaultValue: BrooklynWebConfiguration = .default
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

    var brooklynSurfaceStyle: BrooklynSurfaceStyle {
        get { self[BrooklynSurfaceStyleEnvironmentKey.self] }
        set { self[BrooklynSurfaceStyleEnvironmentKey.self] = newValue }
    }

    var brooklynWebConfiguration: BrooklynWebConfiguration {
        get { self[BrooklynWebConfigurationEnvironmentKey.self] }
        set { self[BrooklynWebConfigurationEnvironmentKey.self] = newValue }
    }
}
