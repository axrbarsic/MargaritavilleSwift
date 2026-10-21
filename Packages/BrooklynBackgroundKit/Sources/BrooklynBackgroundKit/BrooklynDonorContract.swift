import Foundation
import simd

enum BrooklynDonorContract {
    static let gridSize = 16
    static let gridSteps = 15
    static let cameraZoom: Float = 600
    static let baseColorSRGB = SIMD3<Float>(245.0 / 255.0, 17.0 / 255.0, 85.0 / 255.0)
    static let fogColorSRGB = SIMD3<Float>(248.0 / 255.0, 0, 168.0 / 255.0)
    static let fogDensity: Float = 0.08
    static let bloomRadius: Float = 0.95
    static let bloomStrength: Float = 0.25
    static let bloomThreshold: Float = 0.01

    static func viewportSize(for viewSizeInPoints: SIMD2<Float>) -> SIMD2<Float> {
        viewSizeInPoints / cameraZoom
    }

    static func span(for viewportSize: SIMD2<Float>) -> Float {
        max(4, max(viewportSize.x, viewportSize.y) * 1.1)
    }

    static func spacing(for viewportSize: SIMD2<Float>) -> Float {
        span(for: viewportSize) / Float(gridSteps)
    }

    static func stableSeed(for id: Int) -> Double {
        (Double(id) * 0.618033988749895).truncatingRemainder(dividingBy: 1)
    }

    static func turnDuration(for seed: Double) -> Double {
        Double.pi / 2 + seed * Double.pi
    }

    static func turnDelay(for seed: Double) -> Double {
        0.2 + seed * 1.8
    }

    static func repeatDelay(for seed: Double) -> Double {
        2 + seed
    }

    static func easePower(for seed: Double) -> Int {
        min(4, 2 + Int(floor(seed * 3)))
    }

    static func powerEaseInOut(_ progress: Double, powerName: Int) -> Double {
        let t = min(max(progress, 0), 1)
        let exponent = Double(powerName + 1)
        if t < 0.5 {
            return pow(t * 2, exponent) / 2
        }
        return 1 - pow((1 - t) * 2, exponent) / 2
    }

    static func turnAngle(for id: Int, at time: Double) -> Double {
        let seed = stableSeed(for: id)
        let delay = turnDelay(for: seed)
        let duration = turnDuration(for: seed)
        let cycleDuration = delay + duration + repeatDelay(for: seed)
        let cycle = max(0, Int(floor(time / cycleDuration)))
        let localTime = max(0, time - Double(cycle) * cycleDuration)
        let progress = powerEaseInOut((localTime - delay) / duration, powerName: easePower(for: seed))
        return (Double(cycle) + progress) * Double.pi / 2
    }

    static func particleScale(for id: Int, spacing: Double, at time: Double) -> Double {
        let seed = stableSeed(for: id)
        let base = spacing * 0.9
        let localTime = time - turnDelay(for: seed)
        guard localTime > 0, localTime < 4 else { return base }
        let scalar = seed * 0.05 - 0.05
        let progress = localTime <= 2 ? localTime / 2 : (4 - localTime) / 2
        let sineEase = 0.5 - cos(Double.pi * progress) * 0.5
        return base + scalar * sineEase
    }

    static func highlightedInstance(viewportSize: SIMD2<Float>, spacing: Float) -> UInt32 {
        let halfX = Float.pi / 10
        let halfY = -Float.pi / 8
        let rotation = simd_quatf(
            ix: sin(halfX) * cos(halfY),
            iy: cos(halfX) * sin(halfY),
            iz: sin(halfX) * sin(halfY),
            r: cos(halfX) * cos(halfY)
        )
        let inverse = rotation.inverse
        let origin = inverse.act(SIMD3(viewportSize.x * 0.2, viewportSize.y * 0.2, 10))
        let direction = inverse.act(SIMD3<Float>(0, 0, -1))
        guard abs(direction.y) >= 0.0001 else { return UInt32.max }
        let distance = -origin.y / direction.y

        func cell(_ value: Float) -> Int {
            let raw = floor(value / spacing + Float(gridSize) / 2 - 0.5 + 0.5)
            return min(gridSize - 1, max(0, Int(raw)))
        }

        let row = cell(origin.x + distance * direction.x)
        let column = cell(origin.z + distance * direction.z)
        return UInt32(row * gridSize + column)
    }
}
