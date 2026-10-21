#if os(iOS)
@preconcurrency import MetalKit

enum BrooklynRendererError: Error {
    case missingResource(String)
    case missingShaderFunction(String)
    case missingGPUResource
}

struct BrooklynGPUResources {
    let library: MTLLibrary
    let scenePipeline: MTLRenderPipelineState
    let compositePipeline: MTLRenderPipelineState
    let bloomDownsamplePipeline: MTLComputePipelineState
    let bloomBlurPipeline: MTLComputePipelineState
    let depthState: MTLDepthStencilState
    let textureSampler: MTLSamplerState
    let environmentSampler: MTLSamplerState
    let compositeSampler: MTLSamplerState
    let commandQueue: MTLCommandQueue
    let mesh: BrooklynRoundedCubeMesh
    let textures: BrooklynTextureAssets
}

@MainActor
enum BrooklynGPUCache {
    private static var resourcesByDevice: [UInt64: BrooklynGPUResources] = [:]

    static func resources(for device: MTLDevice) throws -> BrooklynGPUResources {
        let key = device.registryID
        if let cached = resourcesByDevice[key] {
            return cached
        }

        let libraryURL = try BrooklynBundledResource.url(
            named: "BrooklynShaders",
            extension: "metallib"
        )
        let library = try device.makeLibrary(URL: libraryURL)
        let sceneVertex = try function(named: "brooklynSceneVertex", in: library)
        let sceneFragment = try function(named: "brooklynSceneFragment", in: library)
        let compositeVertex = try function(named: "brooklynCompositeVertex", in: library)
        let compositeFragment = try function(named: "brooklynCompositeFragment", in: library)
        let bloomDownsample = try function(named: "brooklynBloomDownsample", in: library)
        let bloomBlur = try function(named: "brooklynBloomBlur", in: library)

        let sceneDescriptor = MTLRenderPipelineDescriptor()
        sceneDescriptor.label = "Brooklyn exact scene pipeline"
        sceneDescriptor.vertexFunction = sceneVertex
        sceneDescriptor.fragmentFunction = sceneFragment
        sceneDescriptor.vertexDescriptor = makeVertexDescriptor()
        sceneDescriptor.colorAttachments[0].pixelFormat = .rgba16Float
        sceneDescriptor.depthAttachmentPixelFormat = .depth32Float
        let scenePipeline = try device.makeRenderPipelineState(descriptor: sceneDescriptor)

        let compositeDescriptor = MTLRenderPipelineDescriptor()
        compositeDescriptor.label = "Brooklyn ACES bloom composite pipeline"
        compositeDescriptor.vertexFunction = compositeVertex
        compositeDescriptor.fragmentFunction = compositeFragment
        compositeDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        let compositePipeline = try device.makeRenderPipelineState(descriptor: compositeDescriptor)

        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.label = "Brooklyn depth state"
        depthDescriptor.depthCompareFunction = .less
        depthDescriptor.isDepthWriteEnabled = true

        guard let commandQueue = device.makeCommandQueue(),
              let depthState = device.makeDepthStencilState(descriptor: depthDescriptor),
              let textureSampler = makeSampler(device: device, repeatsHorizontally: false),
              let environmentSampler = makeSampler(device: device, repeatsHorizontally: true),
              let compositeSampler = makeSampler(device: device, repeatsHorizontally: false)
        else {
            throw BrooklynRendererError.missingGPUResource
        }
        commandQueue.label = "Brooklyn renderer command queue"

        let resources = BrooklynGPUResources(
            library: library,
            scenePipeline: scenePipeline,
            compositePipeline: compositePipeline,
            bloomDownsamplePipeline: try device.makeComputePipelineState(function: bloomDownsample),
            bloomBlurPipeline: try device.makeComputePipelineState(function: bloomBlur),
            depthState: depthState,
            textureSampler: textureSampler,
            environmentSampler: environmentSampler,
            compositeSampler: compositeSampler,
            commandQueue: commandQueue,
            mesh: try BrooklynRoundedCubeMesh.make(device: device),
            textures: try BrooklynTextureAssets.load(device: device, commandQueue: commandQueue)
        )
        resourcesByDevice[key] = resources
        return resources
    }

    private static func function(named name: String, in library: MTLLibrary) throws -> MTLFunction {
        guard let function = library.makeFunction(name: name) else {
            throw BrooklynRendererError.missingShaderFunction(name)
        }
        return function
    }

    private static func makeVertexDescriptor() -> MTLVertexDescriptor {
        let descriptor = MTLVertexDescriptor()
        descriptor.attributes[0].format = .float3
        descriptor.attributes[0].offset = 0
        descriptor.attributes[0].bufferIndex = 0
        descriptor.attributes[1].format = .float3
        descriptor.attributes[1].offset = 12
        descriptor.attributes[1].bufferIndex = 0
        descriptor.attributes[2].format = .float2
        descriptor.attributes[2].offset = 24
        descriptor.attributes[2].bufferIndex = 0
        descriptor.layouts[0].stride = BrooklynDonorMeshAsset.expectedVertexStride
        descriptor.layouts[0].stepFunction = .perVertex
        return descriptor
    }

    private static func makeSampler(
        device: MTLDevice,
        repeatsHorizontally: Bool
    ) -> MTLSamplerState? {
        let descriptor = MTLSamplerDescriptor()
        descriptor.minFilter = .linear
        descriptor.magFilter = .linear
        descriptor.mipFilter = .linear
        descriptor.maxAnisotropy = 16
        descriptor.sAddressMode = repeatsHorizontally ? .repeat : .clampToEdge
        descriptor.tAddressMode = .clampToEdge
        return device.makeSamplerState(descriptor: descriptor)
    }
}
#endif
