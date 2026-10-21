#if os(iOS)
import MetalKit
import SwiftUI

public struct BrooklynBackgroundView: View {
    @Environment(\.scenePhase) private var scenePhase
    private let configuration: BrooklynBackgroundConfiguration

    public init(configuration: BrooklynBackgroundConfiguration = .authorPreset) {
        self.configuration = configuration
    }

    public var body: some View {
        BrooklynMetalViewRepresentable(
            configuration: configuration,
            isActive: scenePhase == .active
        )
        .background(Color.black)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct BrooklynMetalViewRepresentable: UIViewRepresentable {
    let configuration: BrooklynBackgroundConfiguration
    let isActive: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero)
        view.backgroundColor = .black
        view.isOpaque = true
        view.isUserInteractionEnabled = false
        guard let renderer = BrooklynRenderer(view: view, configuration: configuration) else {
            return view
        }
        context.coordinator.renderer = renderer
        view.delegate = renderer
        renderer.setActive(isActive, in: view)
        return view
    }

    func updateUIView(_ view: MTKView, context: Context) {
        context.coordinator.renderer?.update(configuration: configuration)
        context.coordinator.renderer?.setActive(isActive, in: view)
    }

    static func dismantleUIView(_ view: MTKView, coordinator: Coordinator) {
        coordinator.renderer?.setActive(false, in: view)
        view.delegate = nil
        coordinator.renderer = nil
    }

    final class Coordinator {
        var renderer: BrooklynRenderer?
    }
}
#endif
