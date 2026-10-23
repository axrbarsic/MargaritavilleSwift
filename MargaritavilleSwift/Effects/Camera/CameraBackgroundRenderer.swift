import CoreVideo
import Metal
import MetalPerformanceShaders
import OSLog
import QuartzCore

struct CameraEffectUniforms {
    var viewSize: SIMD2<Float>
    var textureSize: SIMD2<Float>
    var time: Float
    var effect: UInt32
}

/// Отрисовка кадров камеры с эффектом прямо в `CAMetalLayer` активного экрана.
/// Вызывается только с очереди кадров камеры, главный поток не участвует.
final class CameraBackgroundRenderer {
    private static let logger = Logger(
        subsystem: AppIdentity.loggerSubsystem,
        category: "CameraBackgroundRenderer"
    )

    private let commandQueue: MTLCommandQueue
    private let pipeline: MTLRenderPipelineState
    private let textureCache: CVMetalTextureCache
    private let blur: MPSImageGaussianBlur
    /// Медиана сглаживает, сохраняя края — основа «Мультфильма».
    private let median: MPSImageMedian
    private let device: MTLDevice
    private let startTime = CACurrentMediaTime()
    /// Не больше двух кадров в работе у GPU: лишние кадры камеры отбрасываются.
    private let inFlight = DispatchSemaphore(value: 2)
    private var blurTexture: MTLTexture?

    init?() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary(),
              let vertex = library.makeFunction(name: "cameraEffectVertex"),
              let fragment = library.makeFunction(name: "cameraEffectFragment")
        else {
            Self.logger.error("camera.renderer.metal-unavailable")
            return nil
        }
        var cache: CVMetalTextureCache?
        guard CVMetalTextureCacheCreate(nil, nil, device, nil, &cache) == kCVReturnSuccess, let cache else {
            return nil
        }
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = "Camera background effect"
        descriptor.vertexFunction = vertex
        descriptor.fragmentFunction = fragment
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        do {
            pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            Self.logger.error("camera.renderer.pipeline \(error.localizedDescription, privacy: .public)")
            return nil
        }
        self.device = device
        self.commandQueue = commandQueue
        textureCache = cache
        blur = MPSImageGaussianBlur(device: device, sigma: 22)
        blur.edgeMode = .clamp
        median = MPSImageMedian(device: device, kernelDiameter: 7)
        median.edgeMode = .clamp
    }

    func render(_ pixelBuffer: CVPixelBuffer, to target: CameraRenderTarget) {
        guard inFlight.wait(timeout: .now()) == .success else { return }
        var didCommit = false
        defer { if !didCommit { inFlight.signal() } }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        var cvTexture: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer, nil, .bgra8Unorm, width, height, 0, &cvTexture)
        guard let cvTexture,
              let source = CVMetalTextureGetTexture(cvTexture),
              let drawable = target.layer.nextDrawable(),
              let commandBuffer = commandQueue.makeCommandBuffer()
        else { return }
        commandBuffer.label = "Camera background frame"

        let effect = target.effect
        var sampled = source
        if effect.prefilter != .none, let filtered = blurTarget(width: width, height: height) {
            let kernel: MPSUnaryImageKernel = effect.prefilter == .blur ? blur : median
            kernel.encode(commandBuffer: commandBuffer, sourceTexture: source, destinationTexture: filtered)
            sampled = filtered
        }

        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = drawable.texture
        pass.colorAttachments[0].loadAction = .dontCare
        pass.colorAttachments[0].storeAction = .store
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass) else { return }
        var uniforms = CameraEffectUniforms(
            viewSize: SIMD2(Float(drawable.texture.width), Float(drawable.texture.height)),
            textureSize: SIMD2(Float(width), Float(height)),
            time: Float(CACurrentMediaTime() - startTime),
            effect: effect.shaderIndex
        )
        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentTexture(sampled, index: 0)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<CameraEffectUniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()

        let semaphore = inFlight
        commandBuffer.addCompletedHandler { _ in
            // Текстура кадра должна жить, пока GPU её читает.
            withExtendedLifetime(cvTexture) {}
            semaphore.signal()
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
        didCommit = true
    }

    private func blurTarget(width: Int, height: Int) -> MTLTexture? {
        if let blurTexture, blurTexture.width == width, blurTexture.height == height {
            return blurTexture
        }
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        descriptor.usage = [.shaderRead, .shaderWrite]
        descriptor.storageMode = .private
        blurTexture = device.makeTexture(descriptor: descriptor)
        return blurTexture
    }
}
