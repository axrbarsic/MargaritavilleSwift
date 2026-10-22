import AVFoundation
import SwiftUI
import UIKit

/// Фон «Камера»: полноэкранный предпросмотр задней камеры вместо живых обоев.
/// Камера включена только пока экран верхний и приложение активно.
struct CameraBackgroundView: UIViewRepresentable {
    var isActive = true
    @Environment(\.scenePhase) private var scenePhase

    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.isUserInteractionEnabled = false
        update(view)
        return view
    }

    func updateUIView(_ view: CameraPreviewView, context: Context) {
        update(view)
    }

    static func dismantleUIView(_ view: CameraPreviewView, coordinator: ()) {
        view.setLive(false)
    }

    private func update(_ view: CameraPreviewView) {
        view.setLive(isActive && scenePhase == .active)
    }
}

final class CameraPreviewView: UIView {
    private static var liveView: CameraPreviewView?

    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    private var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        previewLayer.videoGravity = .resizeAspectFill
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Сессия подключена ровно к одному слою — активного экрана. Когда активных
    /// экранов нет, камера останавливается.
    func setLive(_ isLive: Bool) {
        if isLive {
            guard Self.liveView !== self else { return }
            Self.liveView?.previewLayer.session = nil
            Self.liveView = self
            previewLayer.session = CameraBackgroundSession.shared.session
            CameraBackgroundSession.shared.start()
        } else if Self.liveView === self {
            Self.liveView = nil
            previewLayer.session = nil
            CameraBackgroundSession.shared.stop()
        }
    }
}
