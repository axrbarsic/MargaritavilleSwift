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
            version: "0.2.0 (24)",
            date: "2026-06-06",
            changes: [
                "Fixed the real-device crash when starting voice recording from room or cart notes.",
                "Moved Speech and microphone permission callbacks outside MainActor isolation so iOS background permission queues cannot trip Swift concurrency checks.",
                "Kept the hardened audio-engine startup and tap cleanup from build 23."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (23)",
            date: "2026-06-06",
            changes: [
                "Hardened the native voice recorder against real-device Speech and microphone startup crashes.",
                "Voice recording no longer calls risky task finish or duplicate audio-tap removal paths.",
                "The recorder now validates the microphone input format before starting live transcription."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (22)",
            date: "2026-06-06",
            changes: [
                "Reduced gesture conflicts while scrolling the main room list.",
                "Long-press haptics now wait briefly so a normal vertical scroll does not buzz across room cells.",
                "Room swipe-menu arming now requires a stronger horizontal gesture before it gives feedback or toggles the menu."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (21)",
            date: "2026-06-06",
            changes: [
                "Added native Russian speech recognition for room voice notes.",
                "Cart notes now use the same voice-to-text control as room notes.",
                "Speech capture uses a shared Swift controller with microphone and speech permissions instead of a Gemini fallback."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (20)",
            date: "2026-06-06",
            changes: [
                "Restored the Flutter-style puzzle swipe handle in the summary header; dragging the puzzle now returns to room/cart selection.",
                "Room action-menu swipes now use an armed threshold state machine with start, warning, commit, and confirm feedback.",
                "Right-swipe handling now waits for a clear horizontal threshold so it does not fight room/task long-press actions."
            ]
        ),
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
