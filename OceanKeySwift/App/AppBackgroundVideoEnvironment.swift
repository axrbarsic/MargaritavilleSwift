import Foundation
import SwiftUI

private struct AppBackgroundVideoURLEnvironmentKey: EnvironmentKey {
    static let defaultValue: URL? = nil
}

private struct AppBackgroundVideoBlurEnvironmentKey: EnvironmentKey {
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
}
