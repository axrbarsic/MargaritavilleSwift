import Foundation

enum AppSurfaceTransparency {
    nonisolated(unsafe) static var isEnabled = false

    static func apply(_ isEnabled: Bool) {
        Self.isEnabled = isEnabled
    }
}
