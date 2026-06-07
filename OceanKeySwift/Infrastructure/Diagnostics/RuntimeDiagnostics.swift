import Foundation
import UIKit

enum RuntimeDiagnostics {
    static let appleSyncStatusLabel = "Локально, профиль не готов"

    static func proMotionOptIn(infoDictionary: [String: Any] = Bundle.main.infoDictionary ?? [:]) -> Bool {
        infoDictionary["CADisableMinimumFrameDurationOnPhone"] as? Bool == true
    }

    @MainActor
    static func currentProMotionStatusLabel() -> String {
        proMotionStatusLabel(
            maximumFramesPerSecond: UIScreen.main.maximumFramesPerSecond,
            infoDictionary: Bundle.main.infoDictionary ?? [:]
        )
    }

    static func proMotionStatusLabel(
        maximumFramesPerSecond: Int,
        infoDictionary: [String: Any]
    ) -> String {
        let optIn = proMotionOptIn(infoDictionary: infoDictionary) ? "вкл" : "выкл"
        return "\(optIn), до \(max(maximumFramesPerSecond, 60)) Гц"
    }
}
