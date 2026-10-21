#if os(iOS)
import Metal

struct BrooklynRoundedCubeMesh {
    let vertexBuffer: MTLBuffer
    let indexBuffer: MTLBuffer
    let indexCount: Int

    static func make(device: MTLDevice) throws -> BrooklynRoundedCubeMesh {
        let asset = try BrooklynDonorMeshAsset.load()
        let metadata = asset.metadata

        let vertexBuffer = asset.data.withUnsafeBytes { bytes in
            device.makeBuffer(
                bytes: bytes.baseAddress!.advanced(by: metadata.vertexOffset),
                length: metadata.vertexCount * metadata.vertexStride,
                options: .storageModeShared
            )
        }
        let indexBuffer = asset.data.withUnsafeBytes { bytes in
            device.makeBuffer(
                bytes: bytes.baseAddress!.advanced(by: metadata.indexOffset),
                length: metadata.indexCount * MemoryLayout<UInt16>.stride,
                options: .storageModeShared
            )
        }
        guard let vertexBuffer, let indexBuffer else {
            throw BrooklynRendererError.missingGPUResource
        }

        vertexBuffer.label = "Brooklyn donor ExtrudeGeometry vertices"
        indexBuffer.label = "Brooklyn donor ExtrudeGeometry indices"
        return BrooklynRoundedCubeMesh(
            vertexBuffer: vertexBuffer,
            indexBuffer: indexBuffer,
            indexCount: metadata.indexCount
        )
    }
}
#endif
