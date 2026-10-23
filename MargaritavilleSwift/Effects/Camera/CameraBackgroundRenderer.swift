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
    var scanLine: Float = 1
    var previousScanLine: Float = 1
    var resetHistory: UInt32 = 0
    var padding: Float = 0
}

/// Тайминг «Скана времени»: 5 с линия идёт сверху вниз, 2,5 с держится стоп-кадр.
enum CameraTimeScanTiming {
    static let sweepDuration: Double = 5
    static let cycleDuration: Double = 7.5

    static func line(elapsed: Double) -> Float {
        let phase = elapsed.truncatingRemainder(dividingBy: cycleDuration)
        return Float(min(max(phase / sweepDuration, 0), 1))
    }
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
    private let historyPipeline: MTLRenderPipelineState
    private let textureCache: CVMetalTextureCache
    private let blur: MPSImageGaussianBlur
    private let device: MTLDevice
    private let startTime = CACurrentMediaTime()
    /// Не больше двух кадров в работе у GPU: лишние кадры камеры отбрасываются.
    private let inFlight = DispatchSemaphore(value: 2)
    private var blurTexture: MTLTexture?
    /// Две текстуры истории кадров экрана, меняются местами каждый кадр.
    private var historyTextures: [MTLTexture] = []
    private var historyIndex = 0
    private var historyValid = false
    private var lastEffect: CameraBackgroundEffect?
    private var scanStart = CACurrentMediaTime()
    private var previousScanLine: Float = 0

    init?() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary(),
              let vertex = library.makeFunction(name: "cameraEffectVertex"),
              let fragment = library.makeFunction(name: "cameraEffectFragment"),
              let historyFragment = library.makeFunction(name: "cameraHistoryFragment")
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
            descriptor.label = "Camera background history"
            descriptor.fragmentFunction = historyFragment
            historyPipeline = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            Self.logger.error("camera.renderer.pipeline \(error.localizedDescription, privacy: .public)")
            return nil
        }
        self.device = device
        self.commandQueue = commandQueue
        textureCache = cache
        blur = MPSImageGaussianBlur(device: device, sigma: 22)
        blur.edgeMode = .clamp
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
        let now = CACurrentMediaTime()
        if effect != lastEffect {
            lastEffect = effect
            historyValid = false
            scanStart = now
            previousScanLine = 0
        }
        var sampled = source
        if effect.needsBlur, let blurred = blurTarget(width: width, height: height) {
            blur.encode(commandBuffer: commandBuffer, sourceTexture: source, destinationTexture: blurred)
            sampled = blurred
        }

        var uniforms = CameraEffectUniforms(
            viewSize: SIMD2(Float(drawable.texture.width), Float(drawable.texture.height)),
            textureSize: SIMD2(Float(width), Float(height)),
            time: Float(now - startTime),
            effect: effect.shaderIndex
        )
        var history = sampled
        if effect.needsHistory,
           let updated = encodeHistory(commandBuffer, camera: sampled, drawable: drawable, now: now, uniforms: &uniforms) {
            history = updated
        }

        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = drawable.texture
        pass.colorAttachments[0].loadAction = .dontCare
        pass.colorAttachments[0].storeAction = .store
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass) else { return }
        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentTexture(sampled, index: 0)
        encoder.setFragmentTexture(history, index: 1)
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

    /// Обновляет историю кадров экрана и возвращает её свежую текстуру.
    private func encodeHistory(
        _ commandBuffer: MTLCommandBuffer,
        camera: MTLTexture,
        drawable: CAMetalDrawable,
        now: CFTimeInterval,
        uniforms: inout CameraEffectUniforms
    ) -> MTLTexture? {
        let width = drawable.texture.width
        let height = drawable.texture.height
        if historyTextures.first?.width != width || historyTextures.first?.height != height {
            historyTextures = (0..<2).compactMap { _ in makeHistoryTexture(width: width, height: height) }
            historyValid = false
        }
        guard historyTextures.count == 2 else { return nil }

        let line = CameraTimeScanTiming.line(elapsed: now - scanStart)
        if line < previousScanLine {
            previousScanLine = 0
        }
        uniforms.scanLine = line
        uniforms.previousScanLine = previousScanLine
        uniforms.resetHistory = historyValid ? 0 : 1

        let next = 1 - historyIndex
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = historyTextures[next]
        pass.colorAttachments[0].loadAction = .dontCare
        pass.colorAttachments[0].storeAction = .store
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass) else { return nil }
        encoder.setRenderPipelineState(historyPipeline)
        encoder.setFragmentTexture(camera, index: 0)
        encoder.setFragmentTexture(historyTextures[historyIndex], index: 1)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<CameraEffectUniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()

        historyIndex = next
        historyValid = true
        previousScanLine = line
        return historyTextures[next]
    }

    private func makeHistoryTexture(width: Int, height: Int) -> MTLTexture? {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .private
        return device.makeTexture(descriptor: descriptor)
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
