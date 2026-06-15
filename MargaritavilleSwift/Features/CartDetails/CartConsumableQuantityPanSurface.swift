import SwiftUI
import UIKit

struct CartConsumableQuantityPanSurface: UIViewRepresentable {
    let maximum: Int
    let onBegin: () -> Void
    let onChange: (Int) -> Void
    let onCommit: (Int) -> Void
    let onCancel: () -> Void

    func makeUIView(context: Context) -> PanSurfaceView {
        let view = PanSurfaceView()
        view.maximum = maximum
        view.onBegin = onBegin
        view.onChange = onChange
        view.onCommit = onCommit
        view.onCancel = onCancel
        return view
    }

    func updateUIView(_ uiView: PanSurfaceView, context: Context) {
        uiView.maximum = maximum
        uiView.onBegin = onBegin
        uiView.onChange = onChange
        uiView.onCommit = onCommit
        uiView.onCancel = onCancel
    }
}

final class PanSurfaceView: UIView, UIGestureRecognizerDelegate {
    var maximum = 10
    var onBegin: (() -> Void)?
    var onChange: ((Int) -> Void)?
    var onCommit: ((Int) -> Void)?
    var onCancel: (() -> Void)?
    private var lastDetent: Int?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        pan.cancelsTouchesInView = false
        addGestureRecognizer(pan)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        let velocity = pan.velocity(in: self)
        let horizontal = abs(velocity.x)
        let vertical = abs(velocity.y)
        return horizontal > 36 && horizontal > vertical * 1.25
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }

    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        let detent = detent(for: recognizer.location(in: self).x)
        switch recognizer.state {
        case .began:
            lastDetent = nil
            onBegin?()
            publish(detent)
        case .changed:
            publish(detent)
        case .ended:
            onCommit?(detent)
            lastDetent = nil
        case .cancelled, .failed:
            onCancel?()
            lastDetent = nil
        default:
            break
        }
    }

    private func publish(_ detent: Int) {
        guard lastDetent != detent else { return }
        lastDetent = detent
        onChange?(detent)
    }

    private func detent(for x: CGFloat) -> Int {
        let inset: CGFloat = 18
        let width = max(bounds.width - inset * 2, 1)
        let progress = min(max((x - inset) / width, 0), 1)
        return min(max(0, Int((progress * CGFloat(maximum)).rounded())), maximum)
    }
}
