#if os(iOS)
@preconcurrency import MetalKit
import OSLog
import QuartzCore
import UIKit
import simd

private struct BrooklynBloomDownsampleUniforms {
    var applyThreshold: UInt32
    var threshold: Float
    var smoothWidth: Float
    var padding: UInt32 = 0
}

private struct BrooklynBloomBlurUniforms {
    var level: UInt32
    var horizontal: UInt32
    var padding = SIMD2<UInt32>.zero
}

@MainActor
final class BrooklynRenderer: NSObject, MTKViewDelegate {
    private static let logger = Logger(
        subsystem: "BrooklynBackgroundKit",
        category: "MetalRenderer"
    )

    private let device: MTLDevice
    private let resources: BrooklynGPUResources
    private let scenePass = MTLRenderPassDescriptor()
    private let compositePass = MTLRenderPassDescriptor()
    private let telemetry: BrooklynPerformanceTelemetry?
    private var configuration: BrooklynBackgroundConfiguration
    private var timeline = BrooklynAnimationTimeline()
    private var targets: BrooklynRenderTargets?
    private let sceneState: BrooklynSceneState

    init?(view: MTKView, configuration: BrooklynBackgroundConfiguration) {
        guard let device = MTLCreateSystemDefaultDevice() else { return nil }
        do {
            resources = try BrooklynGPUCache.resources(for: device)
        } catch {
            Self.logger.error("Metal setup failed: \(String(describing: error), privacy: .public)")
            return nil
        }
        self.device = device
        self.configuration = configuration
        sceneState = BrooklynSceneState(device: device)
        let maximumFPS = UIScreen.main.maximumFramesPerSecond
        telemetry = BrooklynPerformanceTelemetry.makeIfRequested(maximumFPS: maximumFPS)
        super.init()

        configure(view: view, maximumFPS: maximumFPS)
        configureRenderPasses()
        resizeTargets(for: view.drawableSize)
    }

    func update(configuration: BrooklynBackgroundConfiguration) {
        self.configuration = configuration
    }

    func setActive(_ active: Bool, in view: MTKView) {
        timeline.setActive(active, at: CACurrentMediaTime())
        view.isPaused = !active
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        resizeTargets(for: size)
    }

    func draw(in view: MTKView) {
        guard timeline.isActive else { return }
        let frameStart = CACurrentMediaTime()
        let frameToken = telemetry?.beginFrame(at: frameStart)
        resizeTargets(for: view.drawableSize)
        guard let targets,
              let drawable = view.currentDrawable,
              let commandBuffer = resources.commandQueue.makeCommandBuffer()
        else {
            recordSkipped(frameToken)
            return
        }

        commandBuffer.label = "Brooklyn frame"
        let elapsedTime = Float(timeline.advance(to: frameStart))
        let style = frameToken?.mode.style ?? configuration.style
        var sceneUniforms = sceneState.uniforms(
            viewSizeInPoints: view.bounds.size,
            elapsedTime: elapsedTime,
            style: style,
            appearance: configuration.appearance,
            environmentMaxMip: Float(resources.textures.environment.mipmapLevelCount - 1)
        )
        guard encodeScene(
            commandBuffer: commandBuffer,
            targets: targets,
            uniforms: &sceneUniforms
        ), encodeBloom(commandBuffer: commandBuffer, targets: targets),
           encodeComposite(commandBuffer: commandBuffer, targets: targets, drawable: drawable)
        else {
            recordSkipped(frameToken)
            return
        }

        let encodedAt = CACurrentMediaTime()
        if let telemetry, let frameToken {
            telemetry.recordCPU(frameToken, endedAt: encodedAt)
            commandBuffer.addCompletedHandler { [telemetry] completed in
                telemetry.recordGPU(frameToken, commandBuffer: completed)
                telemetry.recordCommandCompletionFallback(
                    frameToken,
                    completedAt: CACurrentMediaTime(),
                    committedAt: encodedAt
                )
            }
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    private func configure(view: MTKView, maximumFPS: Int) {
        view.device = device
        view.colorPixelFormat = .bgra8Unorm
        (view.layer as? CAMetalLayer)?.colorspace = CGColorSpace(name: CGColorSpace.sRGB)
        view.depthStencilPixelFormat = .invalid
        view.sampleCount = 1
        view.framebufferOnly = true
        view.autoResizeDrawable = true
        view.enableSetNeedsDisplay = false
        view.presentsWithTransaction = false
        view.contentScaleFactor = min(UIScreen.main.scale, 1.5)
        view.preferredFramesPerSecond = maximumFPS
        view.clearColor = MTLClearColorMake(0, 0, 0, 1)
    }

    private func configureRenderPasses() {
        scenePass.colorAttachments[0].loadAction = .clear
        scenePass.colorAttachments[0].storeAction = .store
        scenePass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
        scenePass.depthAttachment.loadAction = .clear
        scenePass.depthAttachment.storeAction = .dontCare
        scenePass.depthAttachment.clearDepth = 1

        compositePass.colorAttachments[0].loadAction = .dontCare
        compositePass.colorAttachments[0].storeAction = .store
    }

    private func resizeTargets(for drawableSize: CGSize) {
        let width = max(1, Int(drawableSize.width.rounded(.up)))
        let height = max(1, Int(drawableSize.height.rounded(.up)))
        guard targets?.size != SIMD2(width, height) else { return }
        do {
            let targets = try BrooklynRenderTargets.make(
                device: device,
                width: width,
                height: height
            )
            self.targets = targets
            scenePass.colorAttachments[0].texture = targets.scene
            scenePass.depthAttachment.texture = targets.depth
        } catch {
            targets = nil
            Self.logger.error("Render target allocation failed")
        }
    }

    private func encodeScene(
        commandBuffer: MTLCommandBuffer,
        targets: BrooklynRenderTargets,
        uniforms: inout BrooklynSceneUniforms
    ) -> Bool {
        guard let instanceBuffer = sceneState.instanceBuffer,
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: scenePass)
        else {
            return false
        }
        encoder.label = "Brooklyn exact instanced scene"
        encoder.setRenderPipelineState(resources.scenePipeline)
        encoder.setDepthStencilState(resources.depthState)
        encoder.setCullMode(.back)
        encoder.setFrontFacing(.counterClockwise)
        encoder.setVertexBuffer(resources.mesh.vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBytes(
            &uniforms,
            length: MemoryLayout<BrooklynSceneUniforms>.stride,
            index: 1
        )
        encoder.setVertexBuffer(instanceBuffer, offset: 0, index: 2)
        encoder.setFragmentBytes(
            &uniforms,
            length: MemoryLayout<BrooklynSceneUniforms>.stride,
            index: 1
        )
        encoder.setFragmentTexture(resources.textures.texture0, index: 0)
        encoder.setFragmentTexture(resources.textures.texture1, index: 1)
        encoder.setFragmentTexture(resources.textures.environment, index: 2)
        encoder.setFragmentSamplerState(resources.textureSampler, index: 0)
        encoder.setFragmentSamplerState(resources.environmentSampler, index: 1)
        encoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: resources.mesh.indexCount,
            indexType: .uint16,
            indexBuffer: resources.mesh.indexBuffer,
            indexBufferOffset: 0,
            instanceCount: sceneState.instanceCount
        )
        encoder.endEncoding()
        return true
    }

    private func encodeBloom(
        commandBuffer: MTLCommandBuffer,
        targets: BrooklynRenderTargets
    ) -> Bool {
        guard let encoder = commandBuffer.makeComputeCommandEncoder() else { return false }
        encoder.label = "Brooklyn five mip UnrealBloom"

        var downsample = BrooklynBloomDownsampleUniforms(
            applyThreshold: 1,
            threshold: BrooklynDonorContract.bloomThreshold,
            smoothWidth: 0.01
        )
        encoder.setComputePipelineState(resources.bloomDownsamplePipeline)
        encoder.setTexture(targets.scene, index: 0)
        encoder.setTexture(targets.bloomA[0], index: 1)
        encoder.setBytes(
            &downsample,
            length: MemoryLayout<BrooklynBloomDownsampleUniforms>.stride,
            index: 0
        )
        dispatch(
            encoder: encoder,
            pipeline: resources.bloomDownsamplePipeline,
            texture: targets.bloomA[0]
        )
        encoder.memoryBarrier(scope: .textures)

        for level in 0..<BrooklynRenderTargets.bloomLevelCount {
            var blur = BrooklynBloomBlurUniforms(level: UInt32(level), horizontal: 1)
            encoder.setComputePipelineState(resources.bloomBlurPipeline)
            encoder.setTexture(level == 0 ? targets.bloomA[0] : targets.bloomA[level - 1], index: 0)
            encoder.setTexture(targets.bloomB[level], index: 1)
            encoder.setBytes(
                &blur,
                length: MemoryLayout<BrooklynBloomBlurUniforms>.stride,
                index: 0
            )
            dispatch(encoder: encoder, pipeline: resources.bloomBlurPipeline, texture: targets.bloomB[level])
            encoder.memoryBarrier(scope: .textures)

            blur.horizontal = 0
            encoder.setTexture(targets.bloomB[level], index: 0)
            encoder.setTexture(targets.bloomA[level], index: 1)
            encoder.setBytes(
                &blur,
                length: MemoryLayout<BrooklynBloomBlurUniforms>.stride,
                index: 0
            )
            dispatch(encoder: encoder, pipeline: resources.bloomBlurPipeline, texture: targets.bloomA[level])
            encoder.memoryBarrier(scope: .textures)
        }
        encoder.endEncoding()
        return true
    }

    private func encodeComposite(
        commandBuffer: MTLCommandBuffer,
        targets: BrooklynRenderTargets,
        drawable: CAMetalDrawable
    ) -> Bool {
        compositePass.colorAttachments[0].texture = drawable.texture
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: compositePass) else {
            return false
        }
        encoder.label = "Brooklyn ACES and sRGB composite"
        encoder.setRenderPipelineState(resources.compositePipeline)
        encoder.setFragmentTexture(targets.scene, index: 0)
        for level in 0..<BrooklynRenderTargets.bloomLevelCount {
            encoder.setFragmentTexture(targets.bloomA[level], index: level + 1)
        }
        encoder.setFragmentSamplerState(resources.compositeSampler, index: 0)
        var correction = BrooklynCompositeUniforms(appearance: configuration.appearance)
        encoder.setFragmentBytes(
            &correction,
            length: MemoryLayout<BrooklynCompositeUniforms>.stride,
            index: 0
        )
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        return true
    }

    private func dispatch(
        encoder: MTLComputeCommandEncoder,
        pipeline: MTLComputePipelineState,
        texture: MTLTexture
    ) {
        let width = pipeline.threadExecutionWidth
        let height = max(1, min(8, pipeline.maxTotalThreadsPerThreadgroup / width))
        encoder.dispatchThreads(
            MTLSize(width: texture.width, height: texture.height, depth: 1),
            threadsPerThreadgroup: MTLSize(width: width, height: height, depth: 1)
        )
    }

    private func recordSkipped(_ token: BrooklynPerformanceFrameToken?) {
        guard let telemetry, let token else { return }
        telemetry.recordSkipped(token)
    }
}
#endif
