import AVFoundation

/// Какая камера снимает фон «Камера».
enum CameraBackgroundPosition: String, CaseIterable, Identifiable, Sendable {
    case back
    case front

    static let storageKey = "cameraBackgroundPosition"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .back: "Задняя"
        case .front: "Передняя"
        }
    }

    var devicePosition: AVCaptureDevice.Position {
        switch self {
        case .back: .back
        case .front: .front
        }
    }

    /// Передняя камера показывается зеркально, как в селфи-режиме.
    var isMirrored: Bool { self == .front }
}
