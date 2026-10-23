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
    var amount: Float = 1
    var brightness: Float = 1
    var reliefDepth: Float = 1
    /// Направление света в радианах, ось y вниз.
    var lightAngle: Float = Float(CameraEffectTuning.defaultLightAngle * .pi / 180)
    var edgeSensitivity: Float = 1
    var detailScale: Float = 1

    init(viewSize: SIMD2<Float>, textureSize: SIMD2<Float>, time: Float, effect: UInt32, tuning: CameraEffectTuning = .default) {
        self.viewSize = viewSize
        self.textureSize = textureSize
        self.time = time
        self.effect = effect
        amount = Float(tuning.amount)
        brightness = Float(tuning.brightness)
        reliefDepth = Float(tuning.reliefDepth)
        lightAngle = Float(tuning.lightAngle * .pi / 180)
        edgeSensitivity = Float(tuning.edgeSensitivity)
        detailScale = Float(tuning.detailScale)
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
    /// Поворот альбомного кадра в портрет: передняя камера присылает кадры
    /// 1920×1080, хотя соединению задан поворот на 90°.
    private let rotatePipeline: MTLRenderPipelineState
    private var portraitTexture: MTLTexture?
    private let textureCache: CVMetalTextureCache
    private let blur: MPSImageGaussianBlur
    /// Медиана сглаживает, сохраняя края — основа «Мультфильма». Два прохода
    /// диаметром 9: один проход на кадре 1080p почти не заметен.
    private let median: MPSImageMedian
    private let device: MTLDevice
    private let startTime = CACurrentMediaTime()
    /// Не больше двух кадров в работе у GPU: лишние кадры камеры отбрасываются.
    private let inFlight = DispatchSemaphore(value: 2)
    private var blurTexture: MTLTexture?
    private var medianScratch: MTLTexture?

    init?() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary(),
              let vertex = library.makeFunction(name: "cameraEffectVertex"),
              let fragment = library.makeFunction(name: "cameraEffectFragment"),
              let rotateFragment = library.makeFunction(name: "cameraRotateFragment")
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
            descriptor.label = "Camera background portrait rotation"
            descriptor.fragmentFunction = rotateFragment
            rotatePipeline = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            Self.logger.error("camera.renderer.pipeline \(error.localizedDescription, privacy: .public)")
            return nil
        }
        self.device = device
        self.commandQueue = commandQueue
        textureCache = cache
        blur = MPSImageGaussianBlur(device: device, sigma: 22)
        blur.edgeMode = .clamp
        median = MPSImageMedian(device: device, kernelDiameter: 9)
        median.edgeMode = .clamp
    }

    func render(_ pixelBuffer: CVPixelBuffer, to target: CameraRenderTarget) {
        guard inFlight.wait(timeout: .now()) == .success else { return }
        var didCommit = false
        defer { if !didCommit { inFlight.signal() } }

        let bufferWidth = CVPixelBufferGetWidth(pixelBuffer)
        let bufferHeight = CVPixelBufferGetHeight(pixelBuffer)
        var cvTexture: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer, nil, .bgra8Unorm, bufferWidth, bufferHeight, 0, &cvTexture)
        guard let cvTexture,
              let cameraTexture = CVMetalTextureGetTexture(cvTexture),
              let drawable = target.layer.nextDrawable(),
              let commandBuffer = commandQueue.makeCommandBuffer()
        else { return }
        commandBuffer.label = "Camera background frame"

        var source = cameraTexture
        if bufferWidth > bufferHeight, let portrait = rotateToPortrait(cameraTexture, commandBuffer: commandBuffer) {
            source = portrait
        }
        let width = source.width
        let height = source.height

        let effect = target.effect
        var sampled = source
        switch effect.prefilter {
        case .none:
            break
        case .blur:
            if let filtered = scratchTexture(&blurTexture, width: width, height: height) {
                blur.encode(commandBuffer: commandBuffer, sourceTexture: source, destinationTexture: filtered)
                sampled = filtered
            }
        case .median:
            if let scratch = scratchTexture(&medianScratch, width: width, height: height),
               let filtered = scratchTexture(&blurTexture, width: width, height: height) {
                median.encode(commandBuffer: commandBuffer, sourceTexture: source, destinationTexture: scratch)
                median.encode(commandBuffer: commandBuffer, sourceTexture: scratch, destinationTexture: filtered)
                sampled = filtered
            }
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
            effect: effect.shaderIndex,
            tuning: target.tuning
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

    /// Поворачивает альбомный кадр на 90° по часовой стрелке в портретную текстуру.
    private func rotateToPortrait(_ texture: MTLTexture, commandBuffer: MTLCommandBuffer) -> MTLTexture? {
        let width = texture.height
        let height = texture.width
        if portraitTexture?.width != width || portraitTexture?.height != height {
            let descriptor = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: .bgra8Unorm,
                width: width,
                height: height,
                mipmapped: false
            )
            descriptor.usage = [.renderTarget, .shaderRead]
            descriptor.storageMode = .private
            portraitTexture = device.makeTexture(descriptor: descriptor)
        }
        guard let portraitTexture else { return nil }
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = portraitTexture
        pass.colorAttachments[0].loadAction = .dontCare
        pass.colorAttachments[0].storeAction = .store
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass) else { return nil }
        encoder.setRenderPipelineState(rotatePipeline)
        encoder.setFragmentTexture(texture, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        return portraitTexture
    }

    private func scratchTexture(_ slot: inout MTLTexture?, width: Int, height: Int) -> MTLTexture? {
        if let texture = slot, texture.width == width, texture.height == height {
            return texture
        }
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        descriptor.usage = [.shaderRead, .shaderWrite]
        descriptor.storageMode = .private
        slot = device.makeTexture(descriptor: descriptor)
        return slot
    }
}
