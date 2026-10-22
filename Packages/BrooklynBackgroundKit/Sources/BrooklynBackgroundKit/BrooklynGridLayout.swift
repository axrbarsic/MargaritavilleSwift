import Foundation
import simd

/// Одна ячейка сетки: координаты в шагах сетки (полуцелые) и зерно анимации.
/// Раскладка совпадает с GPU-буфером экземпляров: x, z, seed, padding.
struct BrooklynGridCell: Equatable {
    let gridX: Float
    let gridZ: Float
    let seed: Float

    var gpuValue: SIMD4<Float> { SIMD4(gridX, gridZ, seed, 0) }
}

/// Раскладка сетки Brooklyn. Исходная сетка 16×16 всегда на месте; при
/// уменьшении ячеек (зум камеры наружу) добавляются только те крайние ячейки,
/// которые попадают в кадр, чтобы сетка оставалась бесконечной.
enum BrooklynGridLayout {
    static let cameraZ: Float = 5
    static let coverageGuardCells: Float = 1.25
    private static let donorHalfExtent = Float(BrooklynDonorContract.gridSteps) / 2

    static let donorCells: [BrooklynGridCell] = makeDonorCells()

    private static func makeDonorCells() -> [BrooklynGridCell] {
        let size = BrooklynDonorContract.gridSize
        var cells: [BrooklynGridCell] = []
        cells.reserveCapacity(size * size)
        for index in 0..<(size * size) {
            let row = Float(index / size)
            let column = Float(index % size)
            let seed = Float(BrooklynDonorContract.stableSeed(for: index))
            cells.append(BrooklynGridCell(gridX: row - donorHalfExtent, gridZ: column - donorHalfExtent, seed: seed))
        }
        return cells
    }

    /// - Parameters:
    ///   - baseViewport: видимая область при исходном зуме 600 (в мировых единицах).
    ///   - spacing: шаг сетки, вычисленный от исходной области.
    static func cells(cellScale: Float, baseViewport: SIMD2<Float>, spacing: Float) -> [BrooklynGridCell] {
        guard cellScale < 1 else { return donorCells }
        let halfWidth = baseViewport.x / (2 * cellScale)
        let halfHeight = baseViewport.y / (2 * cellScale)
        let guardDistance = spacing * coverageGuardCells
        let corners: [SIMD2<Float>] = [
            SIMD2(-halfWidth, -halfHeight), SIMD2(-halfWidth, halfHeight),
            SIMD2(halfWidth, -halfHeight), SIMD2(halfWidth, halfHeight)
        ]
        var maximumLocal: Float = 0
        for corner in corners {
            guard let local = planeIntersection(screen: corner) else { continue }
            maximumLocal = max(maximumLocal, abs(local.x), abs(local.z))
        }
        let limit = Int(ceil(maximumLocal / spacing)) + 2

        var cells = donorCells
        for xIndex in -limit..<limit {
            for zIndex in -limit..<limit {
                let gridX = Float(xIndex) + 0.5
                let gridZ = Float(zIndex) + 0.5
                if abs(gridX) <= donorHalfExtent, abs(gridZ) <= donorHalfExtent { continue }
                let projected = toWorld(SIMD3(gridX * spacing, 0, gridZ * spacing))
                if abs(projected.x) > halfWidth + guardDistance || abs(projected.y) > halfHeight + guardDistance {
                    continue
                }
                cells.append(BrooklynGridCell(gridX: gridX, gridZ: gridZ, seed: coordinateSeed(gridX, gridZ)))
            }
        }
        return cells
    }

    /// Ячейка, которая подсвечивается белым: под точкой 20% от центра к правому
    /// верхнему углу кадра, как в исходной сцене.
    static func highlightedCell(cellScale: Float, baseViewport: SIMD2<Float>, spacing: Float) -> SIMD2<Float> {
        let screen = SIMD2(baseViewport.x / cellScale / 2 * 0.4, baseViewport.y / cellScale / 2 * 0.4)
        guard let target = planeIntersection(screen: screen) else { return SIMD2(repeating: .infinity) }
        return SIMD2(
            floor(target.x / spacing - 0.5 + 0.5) + 0.5,
            floor(target.z / spacing - 0.5 + 0.5) + 0.5
        )
    }

    static func coordinateSeed(_ gridX: Float, _ gridZ: Float) -> Float {
        let value = sin(Double(gridX) * 12.9898 + Double(gridZ) * 78.233) * 43_758.5453
        return Float(value - floor(value))
    }

    /// Поворот сетки сцены: Эйлер XYZ (π/5, −π/4, 0).
    static func toWorld(_ local: SIMD3<Float>) -> SIMD3<Float> {
        rotateX(rotateY(local, -.pi / 4), .pi / 5)
    }

    static func toLocal(_ world: SIMD3<Float>) -> SIMD3<Float> {
        rotateY(rotateX(world, -.pi / 5), .pi / 4)
    }

    /// Точка плоскости сетки под экранной точкой ортографической камеры.
    private static func planeIntersection(screen: SIMD2<Float>) -> SIMD3<Float>? {
        let origin = toLocal(SIMD3(screen.x, screen.y, cameraZ))
        let direction = toLocal(SIMD3(0, 0, -1))
        guard abs(direction.y) >= 0.0001 else { return nil }
        return origin + direction * (-origin.y / direction.y)
    }

    private static func rotateX(_ p: SIMD3<Float>, _ angle: Float) -> SIMD3<Float> {
        SIMD3(p.x, cos(angle) * p.y - sin(angle) * p.z, sin(angle) * p.y + cos(angle) * p.z)
    }

    private static func rotateY(_ p: SIMD3<Float>, _ angle: Float) -> SIMD3<Float> {
        SIMD3(cos(angle) * p.x + sin(angle) * p.z, p.y, -sin(angle) * p.x + cos(angle) * p.z)
    }
}
