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
            version: "0.2.0 (19)",
            date: "2026-06-06",
            changes: [
                "Replaced the temporary +15 minute schedule toggle with a native time picker for hour, 00/15/30/45 minutes, and AM/PM.",
                "Scheduled rooms now always render as pink while a schedule is attached, matching the Flutter behavior.",
                "Scheduled rooms automatically open and clear their schedule when the chosen time is due.",
                "Added local iOS notifications for scheduled room opening times, including foreground banner presentation.",
                "Added regression coverage for scheduled status priority, due-time opening, and quarter-hour AM/PM selection."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (18)",
            date: "2026-06-06",
            changes: [
                "Ported the Flutter interaction feedback foundation to native Swift: UIKit haptics plus bundled click/pressed WAV sounds.",
                "Interaction sounds now use an ambient mixed audio session so they do not take over other playback.",
                "Room number and S/L/B actions now use the Flutter-style protected long-press interaction by default.",
                "Added a Settings toggle to switch room actions between long-press and quick-tap mode.",
                "Right-swipe room menus now give one clean haptic response when the horizontal gesture is recognized and committed.",
                "Removed the conflicting whole-cell VIP long press; VIP stays in the swipe action menu."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (17)",
            date: "2026-06-06",
            changes: [
                "Added a settings action to unlock the workday and return to the setup screen for editing carts and rooms.",
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
