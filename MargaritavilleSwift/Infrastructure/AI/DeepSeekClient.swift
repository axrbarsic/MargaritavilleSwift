import Foundation

struct DeepSeekClient: Sendable {
    enum ClientError: Error, LocalizedError {
        case missingAPIKey
        case invalidResponse
        case requestFailed(Int, String)
        case emptyContent

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                "DeepSeek API ключ не сохранён."
            case .invalidResponse:
                "DeepSeek вернул неожиданный ответ."
            case .requestFailed(let code, let body):
                "DeepSeek ошибка \(code): \(body)"
            case .emptyContent:
                "DeepSeek вернул пустой preset."
            }
        }
    }

    var endpoint = URL(string: "https://api.deepseek.com/chat/completions")!
    var urlSession: URLSession = .shared

    func generatePreset(
        apiKey: String,
        modelTier: DeepSeekModelTier,
        kind: AIVisualPresetKind,
        prompt: String
    ) async throws -> AIVisualPresetDraft {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { throw ClientError.missingAPIKey }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 45
        request.httpBody = try JSONEncoder().encode(DeepSeekChatRequest(
            model: modelTier.modelName,
            messages: DeepSeekPromptFactory.messages(kind: kind, userPrompt: prompt),
            temperature: 0.9,
            responseFormat: DeepSeekResponseFormat(type: "json_object")
        ))

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClientError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw ClientError.requestFailed(httpResponse.statusCode, body)
        }
        let decoded = try JSONDecoder().decode(DeepSeekChatResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content, !content.isEmpty else {
            throw ClientError.emptyContent
        }
        return try Self.decodePreset(content, fallbackKind: kind)
    }

    static func decodePreset(_ content: String, fallbackKind: AIVisualPresetKind) throws -> AIVisualPresetDraft {
        let data = Data(content.utf8)
        var draft = try JSONDecoder().decode(AIVisualPresetDraft.self, from: data)
        draft.kind = fallbackKind
        draft.payload.speed = clamp(draft.payload.speed, to: 0.2...3.0)
        draft.payload.glow = clamp(draft.payload.glow, to: 0...1)
        draft.payload.blur = clamp(draft.payload.blur, to: 0...1)
        draft.payload.density = clamp(draft.payload.density, to: 0...1)
        return draft
    }

    private static func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
    }
}

private struct DeepSeekChatRequest: Codable {
    let model: String
    let messages: [DeepSeekChatMessage]
    let temperature: Double
    let responseFormat: DeepSeekResponseFormat

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case responseFormat = "response_format"
    }
}

private struct DeepSeekResponseFormat: Codable {
    let type: String
}

private struct DeepSeekChatResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: DeepSeekChatMessage
    }
}
