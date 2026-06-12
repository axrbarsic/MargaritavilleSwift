import Foundation
import SwiftData

@Model
final class PersistentAIVisualPreset {
    var id: UUID = UUID()
    var title: String = ""
    var summary: String = ""
    var kindRawValue: String = ""
    var payloadData: Data = Data()
    var modelTierRawValue: String = ""
    var prompt: String = ""
    var isFavorite: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        title: String,
        summary: String,
        kindRawValue: String,
        payloadData: Data,
        modelTierRawValue: String,
        prompt: String,
        isFavorite: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.kindRawValue = kindRawValue
        self.payloadData = payloadData
        self.modelTierRawValue = modelTierRawValue
        self.prompt = prompt
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
