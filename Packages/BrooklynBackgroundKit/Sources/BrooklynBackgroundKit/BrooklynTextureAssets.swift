import Foundation
#if os(iOS)
import MetalKit

struct BrooklynTextureAssets {
    let texture0: MTLTexture
    let texture1: MTLTexture
    let environment: MTLTexture

    static func load(device: MTLDevice, commandQueue: MTLCommandQueue) throws -> BrooklynTextureAssets {
        let loader = MTKTextureLoader(device: device)
        let donorOptions: [MTKTextureLoader.Option: Any] = [
            .SRGB: false,
            .generateMipmaps: true,
            .origin: MTKTextureLoader.Origin.topLeft.rawValue,
            .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
            .textureStorageMode: NSNumber(value: MTLStorageMode.private.rawValue)
        ]
        let texture0 = try loadPNG(named: "tex0", loader: loader, options: donorOptions)
        let texture1 = try loadPNG(named: "tex1", loader: loader, options: donorOptions)
        let environment = try loadEnvironment(device: device, commandQueue: commandQueue)
        texture0.label = "Brooklyn donor tex0"
        texture1.label = "Brooklyn donor tex1"
        environment.label = "Brooklyn Potsdamer Platz city HDR"
        return BrooklynTextureAssets(
            texture0: texture0,
            texture1: texture1,
            environment: environment
        )
    }

    private static func loadPNG(
        named name: String,
        loader: MTKTextureLoader,
        options: [MTKTextureLoader.Option: Any]
    ) throws -> MTLTexture {
        let url = try BrooklynBundledResource.url(named: name, extension: "png")
        return try loader.newTexture(URL: url, options: options)
    }

    private static func loadEnvironment(
        device: MTLDevice,
        commandQueue: MTLCommandQueue
    ) throws -> MTLTexture {
        let asset = try BrooklynCityHDRAsset.load()
        let data = asset.data
        let metadata = asset.metadata
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba16Float,
            width: metadata.width,
            height: metadata.height,
            mipmapped: true
        )
        descriptor.storageMode = .shared
        descriptor.usage = .shaderRead
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw BrooklynRendererError.missingGPUResource
        }

        data.withUnsafeBytes { bytes in
            texture.replace(
                region: MTLRegionMake2D(0, 0, metadata.width, metadata.height),
                mipmapLevel: 0,
                withBytes: bytes.baseAddress!.advanced(by: metadata.pixelOffset),
                bytesPerRow: metadata.width * metadata.bytesPerPixel
            )
        }
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let blit = commandBuffer.makeBlitCommandEncoder()
        else {
            throw BrooklynRendererError.missingGPUResource
        }
        commandBuffer.label = "Brooklyn city HDR mip upload"
        blit.label = "Brooklyn city HDR mip generation"
        blit.generateMipmaps(for: texture)
        blit.endEncoding()
        commandBuffer.commit()
        return texture
    }
}
#endif

enum BrooklynCityHDRAsset {
    static func load() throws -> (data: Data, metadata: BrooklynCityHDRMetadata) {
        let data = try BrooklynBundledResource.data(
            named: "PotsdamerPlatzCityHDR",
            extension: "bin"
        )
        return (data, try BrooklynCityHDRMetadata(data: data))
    }
}

struct BrooklynCityHDRMetadata: Equatable {
    static let pixelOffset = 24

    let width: Int
    let height: Int
    let channelCount: Int
    let bytesPerChannel: Int

    var pixelOffset: Int { Self.pixelOffset }
    var bytesPerPixel: Int { channelCount * bytesPerChannel }

    init(data: Data) throws {
        guard data.count >= Self.pixelOffset,
              String(data: data.prefix(8), encoding: .ascii) == "BRKHDR01"
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let version = Self.integer(in: data, at: 8, as: UInt32.self)
        width = Int(Self.integer(in: data, at: 12, as: UInt32.self))
        height = Int(Self.integer(in: data, at: 16, as: UInt32.self))
        channelCount = Int(Self.integer(in: data, at: 20, as: UInt16.self))
        bytesPerChannel = Int(Self.integer(in: data, at: 22, as: UInt16.self))
        guard version == 1,
              width == 1_024,
              height == 512,
              channelCount == 4,
              bytesPerChannel == 2,
              data.count == Self.pixelOffset + width * height * bytesPerPixel
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }

    private static func integer<T: FixedWidthInteger>(
        in data: Data,
        at offset: Int,
        as: T.Type
    ) -> T {
        data.withUnsafeBytes { bytes in
            T(littleEndian: bytes.loadUnaligned(fromByteOffset: offset, as: T.self))
        }
    }
}
