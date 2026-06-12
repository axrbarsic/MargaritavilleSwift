import Foundation

enum PersonalCartMarkerTone: String, CaseIterable, Codable, Hashable, Sendable {
    case yellow
    case gray
}

struct PersonalCartMarkerSlot: Identifiable, Hashable, Sendable {
    let building: Building
    let tone: PersonalCartMarkerTone

    var id: String {
        "\(building.rawValue)-\(tone.rawValue)"
    }

    var title: String {
        "\(building.label) \(toneTitle)"
    }

    private var toneTitle: String {
        switch tone {
        case .yellow:
            "жёлтая"
        case .gray:
            "серая"
        }
    }
}

struct PersonalCartMarkers: Codable, Equatable, Sendable {
    static let allowedFloors = Array(2...5)
    static let `default` = PersonalCartMarkers()

    var aYellowFloor: Int?
    var aGrayFloor: Int?
    var bYellowFloor: Int?
    var bGrayFloor: Int?

    static let slots: [PersonalCartMarkerSlot] = [
        PersonalCartMarkerSlot(building: .a, tone: .yellow),
        PersonalCartMarkerSlot(building: .a, tone: .gray),
        PersonalCartMarkerSlot(building: .b, tone: .yellow),
        PersonalCartMarkerSlot(building: .b, tone: .gray)
    ]

    func floor(for slot: PersonalCartMarkerSlot) -> Int? {
        switch (slot.building, slot.tone) {
        case (.a, .yellow):
            aYellowFloor
        case (.a, .gray):
            aGrayFloor
        case (.b, .yellow):
            bYellowFloor
        case (.b, .gray):
            bGrayFloor
        }
    }

    mutating func setFloor(_ floor: Int?, for slot: PersonalCartMarkerSlot) {
        let normalizedFloor = floor.flatMap(Self.normalizedFloor)
        switch (slot.building, slot.tone) {
        case (.a, .yellow):
            aYellowFloor = normalizedFloor
        case (.a, .gray):
            aGrayFloor = normalizedFloor
        case (.b, .yellow):
            bYellowFloor = normalizedFloor
        case (.b, .gray):
            bGrayFloor = normalizedFloor
        }
    }

    func settingFloor(_ floor: Int?, for slot: PersonalCartMarkerSlot) -> PersonalCartMarkers {
        var copy = self
        copy.setFloor(floor, for: slot)
        return copy
    }

    func normalized() -> PersonalCartMarkers {
        var copy = self
        for slot in Self.slots {
            copy.setFloor(floor(for: slot), for: slot)
        }
        return copy
    }

    private static func normalizedFloor(_ floor: Int) -> Int? {
        allowedFloors.contains(floor) ? floor : nil
    }
}
