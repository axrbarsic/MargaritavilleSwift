import SwiftUI
import UIKit
import UIKit.UIGestureRecognizerSubclass

final class PassiveActivityGestureRecognizer: UIGestureRecognizer {
    var onActivity: (() -> Void)?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        onActivity?()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        onActivity?()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        onActivity?()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        onActivity?()
    }
}

struct UserActivityTracker: UIViewRepresentable {
    let onActivity: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onActivity: onActivity)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false

        DispatchQueue.main.async {
            if let window = view.window {
                context.coordinator.setupGesture(in: window)
            }
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onActivity = onActivity
        DispatchQueue.main.async {
            if let window = uiView.window {
                context.coordinator.setupGesture(in: window)
            }
        }
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.removeGesture()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onActivity: () -> Void
        private var gesture: PassiveActivityGestureRecognizer?
        private weak var currentWindow: UIWindow?

        init(onActivity: @escaping () -> Void) {
            self.onActivity = onActivity
        }

        func setupGesture(in window: UIWindow) {
            guard currentWindow !== window else { return }
            removeGesture()

            currentWindow = window
            let trackingGesture = PassiveActivityGestureRecognizer()
            trackingGesture.onActivity = { [weak self] in
                self?.onActivity()
            }
            trackingGesture.delegate = self
            trackingGesture.cancelsTouchesInView = false
            window.addGestureRecognizer(trackingGesture)
            self.gesture = trackingGesture
        }

        func removeGesture() {
            if let gesture, let window = currentWindow {
                window.removeGestureRecognizer(gesture)
            }
            gesture = nil
            currentWindow = nil
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}
