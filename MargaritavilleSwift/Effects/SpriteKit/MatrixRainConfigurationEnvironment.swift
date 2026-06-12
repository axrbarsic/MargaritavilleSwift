import SwiftUI

private struct MatrixRainConfigurationKey: EnvironmentKey {
    static let defaultValue = MatrixRainConfiguration.default
}

extension EnvironmentValues {
    var matrixRainConfiguration: MatrixRainConfiguration {
        get { self[MatrixRainConfigurationKey.self] }
        set { self[MatrixRainConfigurationKey.self] = newValue }
    }
}
