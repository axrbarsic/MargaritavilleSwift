#if os(iOS)
@preconcurrency import MetalKit
import simd

struct BrooklynSceneUniforms {
    var viewProjection: simd_float4x4
    var cameraPosition: SIMD4<Float>
    var viewportSpacingScale: SIMD4<Float>
    var baseColor: SIMD4<Float>
    var fogColor: SIMD4<Float>
    var highlightGrid: SIMD2<Float>
    var time: Float
    var surfaceStyle: UInt32
    var environmentMaxMip: Float
}

struct BrooklynCompositeUniforms {
    var brightness: Float
    var contrast: Float
    var applyCorrection: UInt32
    var padding: UInt32 = 0

    init(appearance: BrooklynAppearance) {
        brightness = Float(appearance.brightness - 1)
        contrast = Float(appearance.contrast)
        applyCorrection = abs(brightness) > 0.0001 || abs(contrast) > 0.0001 ? 1 : 0
    }
}

/// Подготовка кадра: параметры сцены и буфер ячеек сетки. Буфер
/// пересобирается только при смене размера вью или масштаба ячеек.
@MainActor
final class BrooklynSceneState {
    private struct LayoutKey: Equatable {
        let pointSize: SIMD2<Float>
        let cellScale: Float
    }

    private let device: MTLDevice
    private var layoutKey: LayoutKey?
    private var highlightGrid = SIMD2<Float>(repeating: .infinity)
    private(set) var instanceBuffer: MTLBuffer?
    private(set) var instanceCount = 0

    init(device: MTLDevice) {
        self.device = device
    }

    func uniforms(
        viewSizeInPoints: CGSize,
        elapsedTime: Float,
        style: BrooklynSurfaceStyle,
        appearance: BrooklynAppearance,
        environmentMaxMip: Float
    ) -> BrooklynSceneUniforms {
        let pointSize = SIMD2(max(Float(viewSizeInPoints.width), 1), max(Float(viewSizeInPoints.height), 1))
        let cellScale = Float(appearance.cellScale)
        let baseViewport = BrooklynDonorContract.viewportSize(for: pointSize)
        let spacing = BrooklynDonorContract.spacing(for: baseViewport)
        updateLayout(LayoutKey(pointSize: pointSize, cellScale: cellScale), baseViewport: baseViewport, spacing: spacing)

        let viewport = baseViewport / cellScale
        let projection = Self.orthographic(
            left: -viewport.x * 0.5,
            right: viewport.x * 0.5,
            bottom: -viewport.y * 0.5,
            top: viewport.y * 0.5,
            near: 0.1,
            far: 1_000
        )
        let cameraZ = BrooklynGridLayout.cameraZ
        return BrooklynSceneUniforms(
            viewProjection: projection * Self.translation(SIMD3(0, 0, -cameraZ)),
            cameraPosition: SIMD4(0, 0, cameraZ, 1),
            viewportSpacingScale: SIMD4(viewport.x, viewport.y, spacing, spacing * 0.9),
            baseColor: Self.linearColor(appearance.shiftedColor(BrooklynDonorContract.baseColorSRGB)),
            fogColor: Self.linearColor(appearance.shiftedColor(BrooklynDonorContract.fogColorSRGB)),
            highlightGrid: highlightGrid,
            time: elapsedTime,
            surfaceStyle: style == .donorExact ? 0 : 1,
            environmentMaxMip: environmentMaxMip
        )
    }

    private func updateLayout(_ key: LayoutKey, baseViewport: SIMD2<Float>, spacing: Float) {
        guard key != layoutKey else { return }
        let cells = BrooklynGridLayout.cells(cellScale: key.cellScale, baseViewport: baseViewport, spacing: spacing)
        let values = cells.map(\.gpuValue)
        instanceBuffer = values.withUnsafeBytes { bytes in
            device.makeBuffer(bytes: bytes.baseAddress!, length: bytes.count, options: .storageModeShared)
        }
        instanceCount = instanceBuffer == nil ? 0 : cells.count
        highlightGrid = BrooklynGridLayout.highlightedCell(cellScale: key.cellScale, baseViewport: baseViewport, spacing: spacing)
        layoutKey = key
    }

    private static func linearColor(_ srgb: SIMD3<Float>) -> SIMD4<Float> {
        func channel(_ value: Float) -> Float {
            value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return SIMD4(channel(srgb.x), channel(srgb.y), channel(srgb.z), 1)
    }

    private static func translation(_ value: SIMD3<Float>) -> simd_float4x4 {
        simd_float4x4(
            SIMD4(1, 0, 0, 0),
            SIMD4(0, 1, 0, 0),
            SIMD4(0, 0, 1, 0),
            SIMD4(value.x, value.y, value.z, 1)
        )
    }

    private static func orthographic(
        left: Float,
        right: Float,
        bottom: Float,
        top: Float,
        near: Float,
        far: Float
    ) -> simd_float4x4 {
        simd_float4x4(
            SIMD4(2 / (right - left), 0, 0, 0),
            SIMD4(0, 2 / (top - bottom), 0, 0),
            SIMD4(0, 0, 1 / (near - far), 0),
            SIMD4(
                -(right + left) / (right - left),
                -(top + bottom) / (top - bottom),
                near / (near - far),
                1
            )
        )
    }
}
#endif
