#if os(iOS)
@preconcurrency import MetalKit
import QuartzCore
import UIKit

@MainActor
final class LiveCellMetalRenderer {
    private let resources: LiveCellMetalResources
    private var normalBuffer: MTLBuffer?
    private var vipBuffer: MTLBuffer?
    private var normalCount = 0
    private var vipCount = 0
    private var animationOrigin: CFTimeInterval?
    private var policy = LiveCellRenderPolicy.disabled
    private var viewportSize = CGSize.zero

    var hasVisibleInstances: Bool {
        normalCount + vipCount > 0
    }

    init?(view: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let resources = try? LiveCellMetalResources.make(device: device)
        else {
            return nil
        }
        self.resources = resources
        configure(view: view, device: device)
    }

    func update(
        instances: [LiveCellInstance],
        viewport: CGRect,
        policy: LiveCellRenderPolicy
    ) {
        self.policy = policy
        viewportSize = viewport.size
        let batches = LiveCellBatches(instances: instances, viewport: viewport)
        normalCount = batches.normal.count
        vipCount = batches.vip.count
        normalBuffer = makeBuffer(for: batches.normal)
        vipBuffer = makeBuffer(for: batches.vip)
    }

    func draw(
        in view: MTKView,
        timestamp: CFTimeInterval
    ) {
        guard policy.isEnabled,
              hasVisibleInstances,
              viewportSize.width > 0,
              viewportSize.height > 0,
              let renderPass = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let commandBuffer = resources.commandQueue.makeCommandBuffer()
        else {
            return
        }
        commandBuffer.label = "Live cell viewport frame"
        if animationOrigin == nil {
            animationOrigin = timestamp
        }
        let elapsed = Float(timestamp - (animationOrigin ?? timestamp))
        let baseUniforms = LiveCellFrameUniforms(
            viewportTimeHeadroom: SIMD4(
                Float(viewportSize.width),
                Float(viewportSize.height),
                elapsed,
                1
            )
        )
        let colorAttachment = renderPass.colorAttachments[0]!
        colorAttachment.loadAction = .clear
        colorAttachment.storeAction = .store
        colorAttachment.clearColor = MTLClearColorMake(0, 0, 0, 0)
        guard let encoder = commandBuffer.makeRenderCommandEncoder(
            descriptor: renderPass
        ) else {
            return
        }
        encoder.label = "Live cell viewport frame"
        var normalUniforms = baseUniforms
        normalUniforms.viewportTimeHeadroom.w = policy.normalCrestHeadroom
        encodeNormal(encoder: encoder, uniforms: &normalUniforms)
        var vipUniforms = baseUniforms
        vipUniforms.viewportTimeHeadroom.w = policy.vipCrestHeadroom
        encodeVIP(encoder: encoder, uniforms: &vipUniforms)
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    private func configure(view: MTKView, device: MTLDevice) {
        view.device = device
        view.colorPixelFormat = .rgba16Float
        view.depthStencilPixelFormat = .invalid
        view.sampleCount = 1
        view.framebufferOnly = true
        view.autoResizeDrawable = true
        view.enableSetNeedsDisplay = false
        view.isPaused = false
        view.presentsWithTransaction = false
        view.contentScaleFactor = min(UIScreen.main.scale, 2)
        view.clearColor = MTLClearColorMake(0, 0, 0, 0)
    }

    private func makeBuffer(
        for instances: [LiveCellInstance]
    ) -> MTLBuffer? {
        guard !instances.isEmpty else { return nil }
        let values = instances.map(makeGPUInstance)
        return resources.commandQueue.device.makeBuffer(
            bytes: values,
            length: MemoryLayout<LiveCellGPUInstance>.stride * values.count
        )
    }

    private func makeGPUInstance(
        _ instance: LiveCellInstance
    ) -> LiveCellGPUInstance {
        let rect = instance.visibleRect
        let color = instance.linearStatusRGB
        let geometry = instance.geometry
        return LiveCellGPUInstance(
            rect: SIMD4(
                Float(rect.minX),
                Float(rect.minY),
                Float(rect.width),
                Float(rect.height)
            ),
            colorDepth: SIMD4(
                color.red,
                color.green,
                color.blue,
                geometry.depth
            ),
            cornerRadii: SIMD4(
                geometry.topLeftRadius,
                geometry.bottomLeftRadius,
                geometry.bottomRightRadius,
                geometry.topRightRadius
            ),
            motion: SIMD4(
                Float(LiveCellMotion.normalizedSeed(instance.seed)),
                (instance.seed & 1) == 0 ? 0 : 1,
                0,
                0
            )
        )
    }

    private func encodeNormal(
        encoder: MTLRenderCommandEncoder,
        uniforms: inout LiveCellFrameUniforms
    ) {
        guard normalCount > 0, let normalBuffer else { return }
        encoder.setRenderPipelineState(resources.normalPipeline)
        encoder.setVertexBuffer(normalBuffer, offset: 0, index: 0)
        encoder.setVertexBytes(
            &uniforms,
            length: MemoryLayout<LiveCellFrameUniforms>.stride,
            index: 1
        )
        encoder.setFragmentBuffer(normalBuffer, offset: 0, index: 0)
        encoder.setFragmentBytes(
            &uniforms,
            length: MemoryLayout<LiveCellFrameUniforms>.stride,
            index: 1
        )
        encoder.drawPrimitives(
            type: .triangle,
            vertexStart: 0,
            vertexCount: 6,
            instanceCount: normalCount
        )
    }

    private func encodeVIP(
        encoder: MTLRenderCommandEncoder,
        uniforms: inout LiveCellFrameUniforms
    ) {
        guard vipCount > 0, let vipBuffer else { return }
        encoder.setRenderPipelineState(resources.vipPipeline)
        encoder.setVertexBuffer(resources.vipMesh, offset: 0, index: 0)
        encoder.setVertexBuffer(vipBuffer, offset: 0, index: 1)
        encoder.setVertexBytes(
            &uniforms,
            length: MemoryLayout<LiveCellFrameUniforms>.stride,
            index: 2
        )
        encoder.setFragmentBuffer(vipBuffer, offset: 0, index: 0)
        encoder.setFragmentBytes(
            &uniforms,
            length: MemoryLayout<LiveCellFrameUniforms>.stride,
            index: 1
        )
        encoder.drawPrimitives(
            type: .triangle,
            vertexStart: 0,
            vertexCount: resources.vipVertexCount,
            instanceCount: vipCount
        )
    }
}
#endif
