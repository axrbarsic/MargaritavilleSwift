#if os(iOS)
@preconcurrency import MetalKit
import QuartzCore
import SwiftUI
import UIKit

public struct LiveCellMetalViewport: UIViewRepresentable {
    private let instances: [LiveCellInstance]
    private let policy: LiveCellRenderPolicy
    private let onRendererAvailabilityChange: @MainActor (Bool) -> Void

    public init(
        instances: [LiveCellInstance],
        policy: LiveCellRenderPolicy,
        onRendererAvailabilityChange: @escaping @MainActor (Bool) -> Void = { _ in }
    ) {
        self.instances = instances
        self.policy = policy
        self.onRendererAvailabilityChange = onRendererAvailabilityChange
    }

    public func makeUIView(context: Context) -> LiveCellViewportView {
        let view = LiveCellViewportView()
        view.update(
            instances: instances,
            policy: policy,
            onRendererAvailabilityChange: onRendererAvailabilityChange
        )
        return view
    }

    public func updateUIView(
        _ uiView: LiveCellViewportView,
        context: Context
    ) {
        uiView.update(
            instances: instances,
            policy: policy,
            onRendererAvailabilityChange: onRendererAvailabilityChange
        )
    }

    public static func dismantleUIView(
        _ uiView: LiveCellViewportView,
        coordinator: Void
    ) {
        uiView.shutdown()
    }
}

@MainActor
public final class LiveCellViewportView: UIView, MTKViewDelegate {
    private let metalView = MTKView(frame: .zero)
    private var renderer: LiveCellMetalRenderer?
    private var instances: [LiveCellInstance] = []
    private var policy = LiveCellRenderPolicy.disabled
    private var rendererInitializationAttempted = false
    private var lastReportedRendererAvailability: Bool?
    private var onRendererAvailabilityChange: (@MainActor (Bool) -> Void)?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        accessibilityElementsHidden = true

        metalView.isOpaque = false
        metalView.backgroundColor = .clear
        metalView.isUserInteractionEnabled = false
        metalView.isAccessibilityElement = false
        metalView.accessibilityElementsHidden = true
        metalView.delegate = self
        addSubview(metalView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        metalView.frame = bounds
        renderer?.update(
            instances: instances,
            viewport: bounds,
            policy: effectivePolicy
        )
        updateRenderingState()
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        updateRenderingState()
    }

    func update(
        instances: [LiveCellInstance],
        policy: LiveCellRenderPolicy,
        onRendererAvailabilityChange: @escaping @MainActor (Bool) -> Void
    ) {
        self.instances = instances
        self.policy = policy
        self.onRendererAvailabilityChange = onRendererAvailabilityChange

        if !rendererInitializationAttempted, policy.isEnabled {
            rendererInitializationAttempted = true
            renderer = LiveCellMetalRenderer(view: metalView)
        }
        reportRendererAvailabilityIfNeeded()
        configureDynamicRange(for: effectivePolicy)
        renderer?.update(
            instances: instances,
            viewport: bounds,
            policy: effectivePolicy
        )
        configureFrameRate()
        updateRenderingState()
    }

    func shutdown() {
        metalView.isPaused = true
        metalView.delegate = nil
        onRendererAvailabilityChange = nil
        renderer = nil
    }

    private var effectivePolicy: LiveCellRenderPolicy {
#if targetEnvironment(simulator)
        LiveCellRenderPolicy(
            isEnabled: policy.isEnabled,
            targetFramesPerSecond: policy.targetFramesPerSecond,
            allowsExtendedDynamicRange: false,
            maximumCrestHeadroom: 1
        )
#else
        policy
#endif
    }

    private func reportRendererAvailabilityIfNeeded() {
        let isAvailable = renderer != nil
        guard lastReportedRendererAvailability != isAvailable,
              let onRendererAvailabilityChange
        else {
            return
        }
        lastReportedRendererAvailability = isAvailable
        Task { @MainActor in
            onRendererAvailabilityChange(isAvailable)
        }
    }

    private func configureFrameRate() {
        metalView.preferredFramesPerSecond = effectivePolicy.targetFramesPerSecond
    }

    private func updateRenderingState() {
        metalView.isPaused = !(
            window != nil
                && effectivePolicy.isEnabled
                && renderer?.hasVisibleInstances == true
        )
    }

    public func mtkView(
        _ view: MTKView,
        drawableSizeWillChange size: CGSize
    ) {}

    public func draw(in view: MTKView) {
        renderer?.draw(in: view, timestamp: CACurrentMediaTime())
    }

    private func configureDynamicRange(for policy: LiveCellRenderPolicy) {
        guard let metalLayer = metalView.layer as? CAMetalLayer else { return }
        metalLayer.colorspace = CGColorSpace(
            name: CGColorSpace.extendedLinearDisplayP3
        )
        metalLayer.wantsExtendedDynamicRangeContent = policy.allowsExtendedDynamicRange
        if #available(iOS 26.0, *) {
            metalLayer.preferredDynamicRange = policy.allowsExtendedDynamicRange
                ? .high
                : .standard
            metalLayer.contentsHeadroom = CGFloat(policy.maximumCrestHeadroom)
        }
    }
}
#endif
