import SwiftUI
import UIKit

struct VIPParticleAnchor: Equatable {
    let id: String
    let tintColor: UIColor
    let bounds: Anchor<CGRect>

    static func == (lhs: VIPParticleAnchor, rhs: VIPParticleAnchor) -> Bool {
        lhs.id == rhs.id
    }
}

struct VIPParticleTarget: Equatable {
    let id: String
    let rect: CGRect
    let tintColor: UIColor

    static func == (lhs: VIPParticleTarget, rhs: VIPParticleTarget) -> Bool {
        lhs.id == rhs.id && lhs.rect == rhs.rect
    }
}

struct VIPParticleAnchorPreferenceKey: PreferenceKey {
    static let defaultValue: [VIPParticleAnchor] = []

    static func reduce(value: inout [VIPParticleAnchor], nextValue: () -> [VIPParticleAnchor]) {
        value.append(contentsOf: nextValue())
    }
}
