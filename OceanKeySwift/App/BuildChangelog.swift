import Foundation

struct BuildChangelogEntry: Identifiable, Equatable {
    let id = UUID()
    let version: String
    let date: String
    let changes: [String]
}

enum BuildChangelog {
    static let entries = [
        BuildChangelogEntry(
            version: "0.2.0 (16)",
            date: "2026-06-06",
            changes: [
                "Added the native first work setup screen for selecting carts, territory, and rooms before opening the summary.",
                "Added native domain rules for room catalog, cart binding, room selection, duplicate blocking, and workday locking.",
                "Moved local persistence to a work-session snapshot that stores selection and carts together, with legacy cart-list restore support.",
                "Aligned core room task invariants: S/L/B require an open room and ready status requires open plus all tasks.",
                "Documented Apple-first iCloud/CloudKit sync direction; Firebase is not a Swift migration target.",
                "Scheduled pink rooms now automatically become open/red when their time arrives.",
                "Added a settings switch between taller first-test cells and compact Flutter-parity cells.",
                "Restored the taller first-test room-cell geometry as a deliberate Swift-only visual exception.",
                "Native Swift rewrite runs on physical iPhone with SpriteKit Matrix background.",
                "Main screen has cart sections, room cells, S/L/B actions, VIP, schedule, and one-open swipe menu.",
                "Room and cart state now persists locally through Application Support JSON storage.",
                "Room text notes, voice transcript drafts, cart notes, and local photo/video attachments are domain data.",
                "Room and cart media use native camera capture and local thumbnail previews.",
                "Settings screen shows build, diagnostics basics, and this changelog."
            ]
        )
    ]
}
