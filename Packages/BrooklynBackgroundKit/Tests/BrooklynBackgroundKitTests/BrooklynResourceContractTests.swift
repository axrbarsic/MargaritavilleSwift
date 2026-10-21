import CryptoKit
import Foundation
import XCTest
@testable import BrooklynBackgroundKit

final class BrooklynResourceContractTests: XCTestCase {
    func testMeshMatchesExactThreeR167Export() throws {
        let asset = try BrooklynDonorMeshAsset.load()
        XCTAssertEqual(asset.metadata.vertexCount, 13_321)
        XCTAssertEqual(asset.metadata.indexCount, 13_860)
        XCTAssertEqual(asset.metadata.vertexStride, 32)
        XCTAssertEqual(asset.metadata.boundsMin.x, -0.649999976, accuracy: 0.0000001)
        XCTAssertEqual(asset.metadata.boundsMin.y, -0.649999976, accuracy: 0.0000001)
        XCTAssertEqual(asset.metadata.boundsMin.z, -0.612495005, accuracy: 0.0000001)
        XCTAssertEqual(asset.metadata.boundsMax.x, 0.649999976, accuracy: 0.0000001)
        XCTAssertEqual(asset.metadata.boundsMax.y, 0.649999976, accuracy: 0.0000001)
        XCTAssertEqual(asset.metadata.boundsMax.z, 0.612495005, accuracy: 0.0000001)
        XCTAssertEqual(
            sha256(asset.data),
            "b5f797be05df6a6bceb69043fce5812dec0f82b7bbb67e42d97bc03bc7be1305"
        )
    }

    func testCityHDRMatchesPinnedDreiPresetAsset() throws {
        let asset = try BrooklynCityHDRAsset.load()
        XCTAssertEqual(asset.metadata.width, 1_024)
        XCTAssertEqual(asset.metadata.height, 512)
        XCTAssertEqual(asset.metadata.channelCount, 4)
        XCTAssertEqual(asset.metadata.bytesPerChannel, 2)
        XCTAssertEqual(
            sha256(asset.data),
            "7d6376c60e33ec2840abac6359e0088529cc368a5024d3278e3660e50da19e3a"
        )
    }

    func testOriginalTexturesAndPrecompiledShaderAreBundled() throws {
        let texture0 = try BrooklynBundledResource.data(named: "tex0", extension: "png")
        let texture1 = try BrooklynBundledResource.data(named: "tex1", extension: "png")
        let shader = try BrooklynBundledResource.data(
            named: "BrooklynShaders",
            extension: "metallib"
        )
        XCTAssertEqual(
            sha256(texture0),
            "8eeecc01de0196b20eb3c74038eac28ccf58c63edd88b8c4db35c10023516ad2"
        )
        XCTAssertEqual(
            sha256(texture1),
            "7a99f66974d77abed24f12bce7553b6295f9fc03b11405baefa21724d962184e"
        )
        XCTAssertEqual(String(data: shader.prefix(4), encoding: .ascii), "MTLB")
    }

    private func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
