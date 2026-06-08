import MetalKit
import SwiftUI

struct MetalAuroraBackgroundView: UIViewRepresentable {
    func makeCoordinator() -> Renderer {
        Renderer()
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .black
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        view.colorPixelFormat = .bgra8Unorm
        view.framebufferOnly = true
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        view.preferredFramesPerSecond = 120
        context.coordinator.attach(to: view)
        return view
    }

    func updateUIView(_ view: MTKView, context: Context) {
        view.preferredFramesPerSecond = 120
        context.coordinator.attach(to: view)
    }

    final class Renderer: NSObject, MTKViewDelegate {
        private var device: MTLDevice?
        private var commandQueue: MTLCommandQueue?
        private var pipelineState: MTLRenderPipelineState?
        private var startTime = CACurrentMediaTime()

        @MainActor
        func attach(to view: MTKView) {
            if device == nil {
                let selectedDevice = MTLCreateSystemDefaultDevice()
                device = selectedDevice
                view.device = selectedDevice
                commandQueue = selectedDevice?.makeCommandQueue()
                buildPipeline(for: view)
            } else if view.device == nil {
                view.device = device
            }
            view.delegate = self
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        func draw(in view: MTKView) {
            guard
                let commandQueue,
                let pipelineState,
                let descriptor = view.currentRenderPassDescriptor,
                let drawable = view.currentDrawable,
                let commandBuffer = commandQueue.makeCommandBuffer(),
                let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
            else { return }

            var uniforms = MetalAuroraUniforms(
                time: Float(CACurrentMediaTime() - startTime),
                width: Float(max(view.drawableSize.width, 1)),
                height: Float(max(view.drawableSize.height, 1)),
                intensity: 1
            )

            encoder.setRenderPipelineState(pipelineState)
            encoder.setFragmentBytes(&uniforms, length: MemoryLayout<MetalAuroraUniforms>.stride, index: 0)
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            encoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }

        @MainActor
        private func buildPipeline(for view: MTKView) {
            guard
                let device = view.device,
                let library = device.makeDefaultLibrary(),
                let vertexFunction = library.makeFunction(name: "metalAuroraVertex"),
                let fragmentFunction = library.makeFunction(name: "metalAuroraFragment")
            else { return }

            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = vertexFunction
            descriptor.fragmentFunction = fragmentFunction
            descriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
            pipelineState = try? device.makeRenderPipelineState(descriptor: descriptor)
        }
    }
}

private struct MetalAuroraUniforms {
    var time: Float
    var width: Float
    var height: Float
    var intensity: Float
}
