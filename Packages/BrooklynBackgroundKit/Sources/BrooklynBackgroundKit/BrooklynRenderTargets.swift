#if os(iOS)
import Metal

struct BrooklynRenderTargets {
    static let bloomLevelCount = 5

    let size: SIMD2<Int>
    let scene: MTLTexture
    let depth: MTLTexture
    let bloomA: [MTLTexture]
    let bloomB: [MTLTexture]

    static func make(device: MTLDevice, width: Int, height: Int) throws -> BrooklynRenderTargets {
        let scene = try makeTexture(
            device: device,
            format: .rgba16Float,
            width: width,
            height: height,
            storage: .private,
            usage: [.renderTarget, .shaderRead],
            label: "Brooklyn HDR scene"
        )
        let depth = try makeTexture(
            device: device,
            format: .depth32Float,
            width: width,
            height: height,
            storage: .memoryless,
            usage: .renderTarget,
            label: "Brooklyn memoryless depth"
        )

        var bloomA: [MTLTexture] = []
        var bloomB: [MTLTexture] = []
        bloomA.reserveCapacity(bloomLevelCount)
        bloomB.reserveCapacity(bloomLevelCount)
        var levelWidth = width
        var levelHeight = height
        for level in 0..<bloomLevelCount {
            levelWidth = max(1, (levelWidth + 1) / 2)
            levelHeight = max(1, (levelHeight + 1) / 2)
            bloomA.append(try makeBloomTexture(
                device: device,
                width: levelWidth,
                height: levelHeight,
                label: "Brooklyn bloom A\(level)"
            ))
            bloomB.append(try makeBloomTexture(
                device: device,
                width: levelWidth,
                height: levelHeight,
                label: "Brooklyn bloom B\(level)"
            ))
        }
        return BrooklynRenderTargets(
            size: SIMD2(width, height),
            scene: scene,
            depth: depth,
            bloomA: bloomA,
            bloomB: bloomB
        )
    }

    private static func makeBloomTexture(
        device: MTLDevice,
        width: Int,
        height: Int,
        label: String
    ) throws -> MTLTexture {
        try makeTexture(
            device: device,
            format: .rgba16Float,
            width: width,
            height: height,
            storage: .private,
            usage: [.shaderRead, .shaderWrite],
            label: label
        )
    }

    private static func makeTexture(
        device: MTLDevice,
        format: MTLPixelFormat,
        width: Int,
        height: Int,
        storage: MTLStorageMode,
        usage: MTLTextureUsage,
        label: String
    ) throws -> MTLTexture {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: format,
            width: max(1, width),
            height: max(1, height),
            mipmapped: false
        )
        descriptor.storageMode = storage
        descriptor.usage = usage
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw BrooklynRendererError.missingGPUResource
        }
        texture.label = label
        return texture
    }
}
#endif
