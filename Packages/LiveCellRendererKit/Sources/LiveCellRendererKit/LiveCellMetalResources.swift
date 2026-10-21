#if os(iOS)
@preconcurrency import MetalKit
import Foundation

enum LiveCellRendererError: Error {
    case missingShaderFunction(String)
    case missingGPUResource
}

struct LiveCellGPUInstance {
    var rect: SIMD4<Float>
    var colorDepth: SIMD4<Float>
    var cornerRadii: SIMD4<Float>
    var motion: SIMD4<Float>
}

struct LiveCellFrameUniforms {
    var viewportTimeHeadroom: SIMD4<Float>
}

@MainActor
struct LiveCellMetalResources {
    let commandQueue: MTLCommandQueue
    let normalPipeline: MTLRenderPipelineState
    let vipPipeline: MTLRenderPipelineState
    let vipMesh: MTLBuffer
    let vipVertexCount: Int

    static func make(device: MTLDevice) throws -> Self {
        let library = try device.makeDefaultLibrary(bundle: Bundle.module)
        let normalVertex = try function(named: "liveCellNormalVertex", in: library)
        let normalFragment = try function(named: "liveCellNormalFragment", in: library)
        let vipVertex = try function(named: "liveCellVIPVertex", in: library)
        let vipFragment = try function(named: "liveCellVIPFragment", in: library)

        let normalPipeline = try pipeline(
            device: device,
            label: "Live cells normal instanced pipeline",
            vertex: normalVertex,
            fragment: normalFragment
        )
        let vipPipeline = try pipeline(
            device: device,
            label: "Live cells VIP mesh instanced pipeline",
            vertex: vipVertex,
            fragment: vipFragment
        )
        guard let commandQueue = device.makeCommandQueue() else {
            throw LiveCellRendererError.missingGPUResource
        }
        commandQueue.label = "Live cell viewport command queue"

        let vipVertices = makeVIPMesh(columns: 34, rows: 24)
        guard let vipMesh = device.makeBuffer(
            bytes: vipVertices,
            length: MemoryLayout<SIMD2<Float>>.stride * vipVertices.count
        ) else {
            throw LiveCellRendererError.missingGPUResource
        }
        vipMesh.label = "Live cell dense VIP front mesh"

        return Self(
            commandQueue: commandQueue,
            normalPipeline: normalPipeline,
            vipPipeline: vipPipeline,
            vipMesh: vipMesh,
            vipVertexCount: vipVertices.count
        )
    }

    private static func function(
        named name: String,
        in library: MTLLibrary
    ) throws -> MTLFunction {
        guard let function = library.makeFunction(name: name) else {
            throw LiveCellRendererError.missingShaderFunction(name)
        }
        return function
    }

    private static func pipeline(
        device: MTLDevice,
        label: String,
        vertex: MTLFunction,
        fragment: MTLFunction
    ) throws -> MTLRenderPipelineState {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = label
        descriptor.vertexFunction = vertex
        descriptor.fragmentFunction = fragment
        let attachment = descriptor.colorAttachments[0]!
        attachment.pixelFormat = .rgba16Float
        attachment.isBlendingEnabled = true
        attachment.rgbBlendOperation = .add
        attachment.alphaBlendOperation = .add
        attachment.sourceRGBBlendFactor = .sourceAlpha
        attachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
        attachment.sourceAlphaBlendFactor = .one
        attachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        return try device.makeRenderPipelineState(descriptor: descriptor)
    }

    private static func makeVIPMesh(
        columns: Int,
        rows: Int
    ) -> [SIMD2<Float>] {
        var vertices: [SIMD2<Float>] = []
        vertices.reserveCapacity(columns * rows * 6)
        for row in 0..<rows {
            let v0 = Float(row) / Float(rows)
            let v1 = Float(row + 1) / Float(rows)
            for column in 0..<columns {
                let u0 = Float(column) / Float(columns)
                let u1 = Float(column + 1) / Float(columns)
                vertices.append(contentsOf: [
                    SIMD2(u0, v0),
                    SIMD2(u1, v0),
                    SIMD2(u0, v1),
                    SIMD2(u1, v0),
                    SIMD2(u1, v1),
                    SIMD2(u0, v1)
                ])
            }
        }
        return vertices
    }
}
#endif
