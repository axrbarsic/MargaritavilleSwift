import Foundation

enum HotelWorkflowKind: String, Codable, Sendable {
    case tasksSLB
    case simpleCycle
}

enum HotelSummaryLayout: String, Codable, Sendable {
    case fullWidthBars
    case squareGrid4
}

struct HotelProfile: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let name: String
    let catalog: [Territory]
    let workflowKind: HotelWorkflowKind
    let dayCategoriesEnabled: Bool
    let summaryLayout: HotelSummaryLayout

    static let current = HotelProfile(
        id: "current",
        name: "OceanKey",
        catalog: RoomCatalog.currentTerritories,
        workflowKind: .tasksSLB,
        dayCategoriesEnabled: false,
        summaryLayout: .fullWidthBars
    )

    static let margaritaville = HotelProfile(
        id: "margaritaville",
        name: "Margaritaville",
        catalog: MargaritavilleRoomCatalog.territories,
        workflowKind: .simpleCycle,
        dayCategoriesEnabled: true,
        summaryLayout: .squareGrid4
    )

    static let all: [HotelProfile] = [.current, .margaritaville]

    static func profile(id: String?) -> HotelProfile? {
        guard let id else { return nil }
        return all.first { $0.id == id }
    }

    func territory(id: String) -> Territory? {
        catalog.first { $0.id == id }
    }

    func territory(for room: RoomID) -> Territory? {
        catalog.first { $0.rooms.contains(room) }
    }
}

enum MargaritavilleRoomCatalog {
    static let territories: [Territory] = [
        Territory(floor: 1, building: .a, rooms: floor1A),
        Territory(floor: 1, building: .b, rooms: floor1B),
        Territory(floor: 2, building: .a, rooms: floor2A),
        Territory(floor: 2, building: .b, rooms: floor2B),
        Territory(floor: 3, building: .a, rooms: floor3A),
        Territory(floor: 3, building: .b, rooms: floor3B)
    ]

    private static let floor1A = ids(
        101, 102, 103, 104, 105, 106, 107, 108, 109, 110,
        111, 112, 114, 115, 116, 117, 118, 119, 120, 122,
        123, 124, 125, 126, 127, 128, 129
    )
    private static let floor1B = ids(
        143, 144, 145, 146, 147, 148, 149, 150, 151, 152,
        153, 154, 155, 156, 157, 158, 159, 160, 161, 162,
        163, 164, 165, 166, 167, 168, 169, 170
    )
    private static let floor2A = ids(
        201, 202, 203, 204, 205, 206, 207, 208, 209, 210,
        211, 212, 214, 215, 216, 217, 218, 219, 220, 221,
        222, 223, 224, 225, 226, 227, 228, 229, 230, 231,
        232
    )
    private static let floor2B = ids(
        239, 240, 241, 242, 243, 244, 245, 246, 247, 248,
        249, 250, 251, 252, 253, 254, 255, 256, 257, 258,
        259, 260, 262, 263, 264, 265, 266, 267, 268, 269,
        270
    )
    private static let floor3A = ids(
        301, 302, 303, 304, 305, 306, 307, 308, 309, 310,
        311, 312, 314, 315, 316, 317, 318, 319, 320, 321,
        322, 323, 324, 325, 326, 327, 328
    )
    private static let floor3B = ids(
        330, 331, 332, 333, 334, 335, 336, 337, 338, 339,
        340, 341, 342, 343, 344, 345, 346, 347, 348, 349,
        351, 352, 353, 354, 355, 356, 357, 358, 359, 360,
        361, 362, 363, 364, 365, 366, 367, 368, 369, 370
    )

    private static func ids(_ values: Int...) -> [RoomID] {
        values.map(String.init)
    }
}
