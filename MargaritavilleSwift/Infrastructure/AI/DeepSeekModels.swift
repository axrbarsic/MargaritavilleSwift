import Foundation

enum DeepSeekModelTier: String, CaseIterable, Identifiable, Codable, Sendable {
    case pro
    case flash

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pro: "Pro"
        case .flash: "Flash"
        }
    }

    var modelName: String {
        switch self {
        case .pro:
            "deepseek-chat"
        case .flash:
            "deepseek-chat"
        }
    }
}

enum AIVisualPresetKind: String, CaseIterable, Identifiable, Codable, Sendable {
    case matrixCodeRain
    case vipEffect

    var id: String { rawValue }

    var title: String {
        switch self {
        case .matrixCodeRain: "Matrix Code Rain"
        case .vipEffect: "VIP эффект"
        }
    }
}

struct AIVisualPresetPayload: Codable, Equatable, Sendable {
    var palette: String
    var speed: Double
    var glow: Double
    var blur: Double
    var density: Double
    var glyphSource: String
    var motion: String
    var seed: Int

    static let matrixDefault = AIVisualPresetPayload(
        palette: "green_terminal",
        speed: 1,
        glow: 0.7,
        blur: 0.2,
        density: 0.8,
        glyphSource: "swift_code",
        motion: "downward_code_rain",
        seed: 1
    )

    static let vipDefault = AIVisualPresetPayload(
        palette: "status_adaptive",
        speed: 1,
        glow: 0.55,
        blur: 0.35,
        density: 0.5,
        glyphSource: "none",
        motion: "organic_status_pulse",
        seed: 1
    )
}

struct AIVisualPresetDraft: Codable, Equatable, Sendable {
    var title: String
    var summary: String
    var kind: AIVisualPresetKind
    var payload: AIVisualPresetPayload
}

struct DeepSeekPromptFactory {
    static func messages(kind: AIVisualPresetKind, userPrompt: String) -> [DeepSeekChatMessage] {
        [
            DeepSeekChatMessage(
                role: "system",
                content: """
                You design visual presets for a native Swift iOS app using SpriteKit/SwiftUI shaders.
                Return only compact JSON. Do not include markdown.
                Schema:
                {
                  "title": "short Russian title",
                  "summary": "one Russian sentence",
                  "kind": "\(kind.rawValue)",
                  "payload": {
                    "palette": "green_terminal|status_adaptive|emerald_code|acid_debug",
                    "speed": 0.2-3.0,
                    "glow": 0.0-1.0,
                    "blur": 0.0-1.0,
                    "density": 0.0-1.0,
                    "glyphSource": "swift_code|hotel_ops|symbols|none",
                    "motion": "short machine-readable motion name",
                    "seed": integer
                  }
                }
                Keep effects GPU-friendly and loop-stable.
                """
            ),
            DeepSeekChatMessage(role: "user", content: userPrompt)
        ]
    }
}

struct DeepSeekChatMessage: Codable, Equatable, Sendable {
    let role: String
    let content: String
}
