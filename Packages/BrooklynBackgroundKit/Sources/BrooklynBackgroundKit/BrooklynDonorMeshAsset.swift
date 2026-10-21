import Foundation
import simd

struct BrooklynDonorMeshMetadata: Equatable {
    let vertexCount: Int
    let indexCount: Int
    let vertexStride: Int
    let vertexOffset: Int
    let indexOffset: Int
    let boundsMin: SIMD3<Float>
    let boundsMax: SIMD3<Float>
}

enum BrooklynDonorMeshAsset {
    static let expectedVertexCount = 13_321
    static let expectedIndexCount = 13_860
    static let expectedVertexStride = 32
    static let headerSize = 24

    static func load() throws -> (data: Data, metadata: BrooklynDonorMeshMetadata) {
        let data = try BrooklynBundledResource.data(
            named: "BrooklynDonorMesh",
            extension: "bin"
        )
        return (data, try metadata(for: data))
    }

    static func metadata(for data: Data) throws -> BrooklynDonorMeshMetadata {
        guard data.count >= headerSize,
              String(data: data.prefix(8), encoding: .ascii) == "BRKMESH1"
        else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let version = integer(in: data, at: 8, as: UInt32.self)
        let vertexCount = Int(integer(in: data, at: 12, as: UInt32.self))
        let indexCount = Int(integer(in: data, at: 16, as: UInt32.self))
        let vertexStride = Int(integer(in: data, at: 20, as: UInt32.self))
        let indexOffset = headerSize + vertexCount * vertexStride
        guard version == 1,
              vertexCount == expectedVertexCount,
              indexCount == expectedIndexCount,
              vertexStride == expectedVertexStride,
              data.count == indexOffset + indexCount * MemoryLayout<UInt16>.stride
        else {
            throw CocoaError(.fileReadCorruptFile)
        }

        var boundsMin = SIMD3<Float>(repeating: .greatestFiniteMagnitude)
        var boundsMax = SIMD3<Float>(repeating: -.greatestFiniteMagnitude)
        for index in 0..<vertexCount {
            let offset = headerSize + index * vertexStride
            let position = SIMD3(
                float(in: data, at: offset),
                float(in: data, at: offset + 4),
                float(in: data, at: offset + 8)
            )
            boundsMin = simd_min(boundsMin, position)
            boundsMax = simd_max(boundsMax, position)
        }

        return BrooklynDonorMeshMetadata(
            vertexCount: vertexCount,
            indexCount: indexCount,
            vertexStride: vertexStride,
            vertexOffset: headerSize,
            indexOffset: indexOffset,
            boundsMin: boundsMin,
            boundsMax: boundsMax
        )
    }

    private static func integer<T: FixedWidthInteger>(in data: Data, at offset: Int, as: T.Type) -> T {
        data.withUnsafeBytes { raw in
            T(littleEndian: raw.loadUnaligned(fromByteOffset: offset, as: T.self))
        }
    }

    private static func float(in data: Data, at offset: Int) -> Float {
        Float(bitPattern: integer(in: data, at: offset, as: UInt32.self))
    }
}
