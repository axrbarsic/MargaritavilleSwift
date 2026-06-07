import Foundation
import SwiftData

@Model
final class PersistentWorkSession {
    static let currentID = "current"

    var id: String
    var schemaVersion: Int
    var updatedAt: Date
    var workdayLocked: Bool
    var workdayLockUpdatedAt: Date?
    @Relationship(deleteRule: .cascade) var cartBindings: [PersistentCartBinding]?
    @Relationship(deleteRule: .cascade) var roomSelections: [PersistentRoomSelection]?
    @Relationship(deleteRule: .cascade) var carts: [PersistentCart]?
    @Relationship(deleteRule: .cascade) var historyEntries: [PersistentHistoryEntry]?

    init(
        id: String = PersistentWorkSession.currentID,
        schemaVersion: Int = 1,
        updatedAt: Date = Date(),
        workdayLocked: Bool = false,
        workdayLockUpdatedAt: Date? = nil,
        cartBindings: [PersistentCartBinding] = [],
        roomSelections: [PersistentRoomSelection] = [],
        carts: [PersistentCart] = [],
        historyEntries: [PersistentHistoryEntry] = []
    ) {
        self.id = id
        self.schemaVersion = schemaVersion
        self.updatedAt = updatedAt
        self.workdayLocked = workdayLocked
        self.workdayLockUpdatedAt = workdayLockUpdatedAt
        self.cartBindings = cartBindings
        self.roomSelections = roomSelections
        self.carts = carts
        self.historyEntries = historyEntries
    }
}

@Model
final class PersistentCartBinding {
    var cartNumber: Int
    var territoryID: String
    var isSelected: Bool?
    var updatedAt: Date?

    init(
        cartNumber: Int,
        territoryID: String,
        isSelected: Bool? = true,
        updatedAt: Date? = nil
    ) {
        self.cartNumber = cartNumber
        self.territoryID = territoryID
        self.isSelected = isSelected
        self.updatedAt = updatedAt
    }
}

@Model
final class PersistentRoomSelection {
    var cartNumber: Int
    var roomID: String
    var isSelected: Bool?
    var updatedAt: Date?

    init(
        cartNumber: Int,
        roomID: String,
        isSelected: Bool? = true,
        updatedAt: Date? = nil
    ) {
        self.cartNumber = cartNumber
        self.roomID = roomID
        self.isSelected = isSelected
        self.updatedAt = updatedAt
    }
}

@Model
final class PersistentCart {
    var cartNumber: Int
    var displayOrder: Int
    var building: String
    var note: String?
    var noteUpdatedAt: Date?
    @Relationship(deleteRule: .cascade) var rooms: [PersistentRoom]?
    @Relationship(deleteRule: .cascade) var mediaAttachments: [PersistentMediaAttachment]?
    @Relationship(deleteRule: .cascade) var consumables: [PersistentCartConsumable]?

    init(
        cartNumber: Int,
        displayOrder: Int,
        building: String,
        note: String? = nil,
        noteUpdatedAt: Date? = nil,
        rooms: [PersistentRoom] = [],
        mediaAttachments: [PersistentMediaAttachment] = [],
        consumables: [PersistentCartConsumable] = []
    ) {
        self.cartNumber = cartNumber
        self.displayOrder = displayOrder
        self.building = building
        self.note = note
        self.noteUpdatedAt = noteUpdatedAt
        self.rooms = rooms
        self.mediaAttachments = mediaAttachments
        self.consumables = consumables
    }
}

@Model
final class PersistentRoom {
    var roomID: String
    var displayOrder: Int
    var opened: Bool
    var openedUpdatedAt: Date?
    var completedTaskValues: String
    var strippedUpdatedAt: Date?
    var linenUpdatedAt: Date?
    var balconyUpdatedAt: Date?
    var isVIP: Bool
    var vipUpdatedAt: Date?
    var scheduledTime: Date?
    var scheduledUpdatedAt: Date?
    var selectedAt: Date?
    var openedAt: Date?
    var strippedAt: Date?
    var linenDeliveredAt: Date?
    var balconyCleanedAt: Date?
    var completedAt: Date?
    var textNote: String?
    var textNoteUpdatedAt: Date?
    var voiceTranscript: String?
    var voiceTranscriptUpdatedAt: Date?
    @Relationship(deleteRule: .cascade) var mediaAttachments: [PersistentMediaAttachment]?

    init(
        roomID: String,
        displayOrder: Int,
        opened: Bool,
        openedUpdatedAt: Date? = nil,
        completedTaskValues: String,
        strippedUpdatedAt: Date? = nil,
        linenUpdatedAt: Date? = nil,
        balconyUpdatedAt: Date? = nil,
        isVIP: Bool,
        vipUpdatedAt: Date? = nil,
        scheduledTime: Date? = nil,
        scheduledUpdatedAt: Date? = nil,
        mediaAttachments: [PersistentMediaAttachment] = []
    ) {
        self.roomID = roomID
        self.displayOrder = displayOrder
        self.opened = opened
        self.openedUpdatedAt = openedUpdatedAt
        self.completedTaskValues = completedTaskValues
        self.strippedUpdatedAt = strippedUpdatedAt
        self.linenUpdatedAt = linenUpdatedAt
        self.balconyUpdatedAt = balconyUpdatedAt
        self.isVIP = isVIP
        self.vipUpdatedAt = vipUpdatedAt
        self.scheduledTime = scheduledTime
        self.scheduledUpdatedAt = scheduledUpdatedAt
        self.mediaAttachments = mediaAttachments
    }
}

@Model
final class PersistentMediaAttachment {
    var attachmentID: UUID
    var kindRawValue: String
    var relativePath: String
    var createdAt: Date
    var completedAt: Date?
    var displayOrder: Int

    init(
        attachmentID: UUID,
        kindRawValue: String,
        relativePath: String,
        createdAt: Date,
        completedAt: Date?,
        displayOrder: Int
    ) {
        self.attachmentID = attachmentID
        self.kindRawValue = kindRawValue
        self.relativePath = relativePath
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.displayOrder = displayOrder
    }
}

@Model
final class PersistentCartConsumable {
    var itemID: String
    var title: String
    var quantity: Int
    var updatedAt: Date?
    var completedAt: Date?
    var displayOrder: Int

    init(
        itemID: String,
        title: String,
        quantity: Int,
        updatedAt: Date?,
        completedAt: Date?,
        displayOrder: Int
    ) {
        self.itemID = itemID
        self.title = title
        self.quantity = quantity
        self.updatedAt = updatedAt
        self.completedAt = completedAt
        self.displayOrder = displayOrder
    }
}

@Model
final class PersistentHistoryEntry {
    var eventID: UUID
    var happenedAt: Date
    var kindRawValue: String
    var title: String
    var roomID: String?
    var cartID: Int?
    var snapshotData: Data
    var displayOrder: Int

    init(
        eventID: UUID,
        happenedAt: Date,
        kindRawValue: String,
        title: String,
        roomID: String?,
        cartID: Int?,
        snapshotData: Data,
        displayOrder: Int
    ) {
        self.eventID = eventID
        self.happenedAt = happenedAt
        self.kindRawValue = kindRawValue
        self.title = title
        self.roomID = roomID
        self.cartID = cartID
        self.snapshotData = snapshotData
        self.displayOrder = displayOrder
    }
}
