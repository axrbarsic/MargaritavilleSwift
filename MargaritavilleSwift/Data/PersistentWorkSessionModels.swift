import Foundation
import SwiftData

@Model
final class PersistentWorkSession {
    static let currentID = "current"

    var id: String = PersistentWorkSession.currentID
    var schemaVersion: Int = 1
    var updatedAt: Date = Date()
    var workdayLocked: Bool = false
    var workdayLockUpdatedAt: Date?
    @Relationship(deleteRule: .cascade, inverse: \PersistentCartBinding.session) var cartBindings: [PersistentCartBinding]?
    @Relationship(deleteRule: .cascade, inverse: \PersistentRoomSelection.session) var roomSelections: [PersistentRoomSelection]?
    @Relationship(deleteRule: .cascade, inverse: \PersistentCatalogOverride.session) var catalogOverrides: [PersistentCatalogOverride]?
    @Relationship(deleteRule: .cascade, inverse: \PersistentCart.session) var carts: [PersistentCart]?
    @Relationship(deleteRule: .cascade, inverse: \PersistentHistoryEntry.session) var historyEntries: [PersistentHistoryEntry]?

    init(
        id: String = PersistentWorkSession.currentID,
        schemaVersion: Int = 1,
        updatedAt: Date = Date(),
        workdayLocked: Bool = false,
        workdayLockUpdatedAt: Date? = nil,
        cartBindings: [PersistentCartBinding] = [],
        roomSelections: [PersistentRoomSelection] = [],
        catalogOverrides: [PersistentCatalogOverride] = [],
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
        self.catalogOverrides = catalogOverrides
        self.carts = carts
        self.historyEntries = historyEntries
    }
}

@Model
final class PersistentCatalogOverride {
    var roomID: String = ""
    var territoryID: String = ""
    var isRemoved: Bool = false
    var updatedAt: Date = Date()
    var session: PersistentWorkSession?

    init(
        roomID: String,
        territoryID: String,
        isRemoved: Bool,
        updatedAt: Date
    ) {
        self.roomID = roomID
        self.territoryID = territoryID
        self.isRemoved = isRemoved
        self.updatedAt = updatedAt
    }
}

@Model
final class PersistentCartBinding {
    var cartNumber: Int = 0
    var territoryID: String = ""
    var housekeeperID: String?
    var housekeeperUpdatedAt: Date?
    var isSelected: Bool?
    var updatedAt: Date?
    var session: PersistentWorkSession?

    init(
        cartNumber: Int,
        territoryID: String,
        housekeeperID: String? = nil,
        housekeeperUpdatedAt: Date? = nil,
        isSelected: Bool? = true,
        updatedAt: Date? = nil
    ) {
        self.cartNumber = cartNumber
        self.territoryID = territoryID
        self.housekeeperID = housekeeperID
        self.housekeeperUpdatedAt = housekeeperUpdatedAt
        self.isSelected = isSelected
        self.updatedAt = updatedAt
    }
}

@Model
final class PersistentRoomSelection {
    var cartNumber: Int = 0
    var roomID: String = ""
    var isSelected: Bool?
    var updatedAt: Date?
    var session: PersistentWorkSession?

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
    var cartNumber: Int = 0
    var displayOrder: Int = 0
    var building: String = ""
    var note: String?
    var noteUpdatedAt: Date?
    var session: PersistentWorkSession?
    @Relationship(deleteRule: .cascade, inverse: \PersistentRoom.cart) var rooms: [PersistentRoom]?
    @Relationship(deleteRule: .cascade, inverse: \PersistentMediaAttachment.cart) var mediaAttachments: [PersistentMediaAttachment]?
    @Relationship(deleteRule: .cascade, inverse: \PersistentCartConsumable.cart) var consumables: [PersistentCartConsumable]?

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
    var roomID: String = ""
    var displayOrder: Int = 0
    var opened: Bool = false
    var openedUpdatedAt: Date?
    var completedTaskValues: String = ""
    var strippedUpdatedAt: Date?
    var linenUpdatedAt: Date?
    var balconyUpdatedAt: Date?
    var isVIP: Bool = false
    var vipUpdatedAt: Date?
    var scheduledTime: Date?
    var scheduledUpdatedAt: Date?
    var statusChangedAt: Date?
    var dayCategoryRawValue: String?
    var dayCategoryTime: Date?
    var dayCategoryUpdatedAt: Date?
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
    var cart: PersistentCart?
    @Relationship(deleteRule: .cascade, inverse: \PersistentMediaAttachment.room) var mediaAttachments: [PersistentMediaAttachment]?

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
        statusChangedAt: Date? = nil,
        dayCategoryRawValue: String? = nil,
        dayCategoryTime: Date? = nil,
        dayCategoryUpdatedAt: Date? = nil,
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
        self.statusChangedAt = statusChangedAt
        self.dayCategoryRawValue = dayCategoryRawValue
        self.dayCategoryTime = dayCategoryTime
        self.dayCategoryUpdatedAt = dayCategoryUpdatedAt
        self.mediaAttachments = mediaAttachments
    }
}

@Model
final class PersistentMediaAttachment {
    var attachmentID: UUID = UUID()
    var kindRawValue: String = ""
    var relativePath: String = ""
    var createdAt: Date = Date()
    var transcript: String?
    var completedAt: Date?
    var displayOrder: Int = 0
    var cart: PersistentCart?
    var room: PersistentRoom?

    init(
        attachmentID: UUID,
        kindRawValue: String,
        relativePath: String,
        createdAt: Date,
        transcript: String? = nil,
        completedAt: Date?,
        displayOrder: Int
    ) {
        self.attachmentID = attachmentID
        self.kindRawValue = kindRawValue
        self.relativePath = relativePath
        self.createdAt = createdAt
        self.transcript = transcript
        self.completedAt = completedAt
        self.displayOrder = displayOrder
    }
}

@Model
final class PersistentCartConsumable {
    var itemID: String = ""
    var title: String = ""
    var quantity: Int = 0
    var updatedAt: Date?
    var completedAt: Date?
    var displayOrder: Int = 0
    var cart: PersistentCart?

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
    var eventID: UUID = UUID()
    var happenedAt: Date = Date()
    var kindRawValue: String = ""
    var title: String = ""
    var roomID: String?
    var cartID: Int?
    var snapshotData: Data = Data()
    var displayOrder: Int = 0
    var session: PersistentWorkSession?

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
