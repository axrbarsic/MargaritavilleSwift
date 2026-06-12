import Foundation
import SwiftUI

private struct AppBackgroundVideoURLEnvironmentKey: EnvironmentKey {
    static let defaultValue: URL? = nil
}

private struct AppBackgroundVideoBlurEnvironmentKey: EnvironmentKey {
    static let defaultValue: Double = 0
}

private struct AppBackgroundVideoBrightnessEnvironmentKey: EnvironmentKey {
    static let defaultValue: Double = 0
}

private struct AppBackgroundVideoGreenTintEnvironmentKey: EnvironmentKey {
    static let defaultValue: Double = 0
}

private struct AppBackgroundVideoGridIntensityEnvironmentKey: EnvironmentKey {
    static let defaultValue: Double = 0
}

extension EnvironmentValues {
    var appBackgroundVideoURL: URL? {
        get { self[AppBackgroundVideoURLEnvironmentKey.self] }
        set { self[AppBackgroundVideoURLEnvironmentKey.self] = newValue }
    }

    var appBackgroundVideoBlur: Double {
        get { self[AppBackgroundVideoBlurEnvironmentKey.self] }
        set { self[AppBackgroundVideoBlurEnvironmentKey.self] = newValue }
    }

    var appBackgroundVideoBrightness: Double {
        get { self[AppBackgroundVideoBrightnessEnvironmentKey.self] }
        set { self[AppBackgroundVideoBrightnessEnvironmentKey.self] = newValue }
    }

    var appBackgroundVideoGreenTint: Double {
        get { self[AppBackgroundVideoGreenTintEnvironmentKey.self] }
        set { self[AppBackgroundVideoGreenTintEnvironmentKey.self] = newValue }
    }

    var appBackgroundVideoGridIntensity: Double {
        get { self[AppBackgroundVideoGridIntensityEnvironmentKey.self] }
        set { self[AppBackgroundVideoGridIntensityEnvironmentKey.self] = newValue }
    }
}
