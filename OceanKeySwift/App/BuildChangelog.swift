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
            version: "0.2.0 (35)",
            date: "2026-06-07",
            changes: [
                "Replaced the cart consumables placeholder with real native cart consumable rows for towels, mats, sheets, and pillowcases.",
                "Consumables now support quantity changes, completion marks, timestamps, event history, and SwiftData persistence.",
                "Kept consumables as cart-specific domain data, separate from room-cell tasks."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (34)",
            date: "2026-06-07",
            changes: [
                "Added the first native history viewer in Settings.",
                "History cards show the event title, timestamp, and a compact visual preview of the main room screen snapshot.",
                "Changed rooms are highlighted inside the snapshot preview so the history is readable on the move."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (33)",
            date: "2026-06-07",
            changes: [
                "Added the native work-session event history foundation: room, cart, selection, schedule, note, media, VIP, and automatic scheduled-open changes now create timestamped history entries.",
                "Each history entry stores a lightweight visual snapshot of the main screen state so the future history UI can preview what the room grid looked like at that moment.",
                "Persisted history through SwiftData as separate records instead of returning to full JSON snapshot rewrites."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (32)",
            date: "2026-06-07",
            changes: [
                "Prepared the SwiftData schema for future Apple iCloud/CloudKit sync by removing the local unique attribute and making persisted relationships optional.",
                "Explicitly keeps the current SwiftData store local-only until iCloud entitlements, CloudKit container setup, and conflict policy are enabled deliberately.",
                "Kept build 31's SwiftData local persistence, async startup loading, and WorkSessionStore layer split."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (31)",
            date: "2026-06-07",
            changes: [
                "Work-session persistence now uses SwiftData as the native local-first store instead of rewriting the full JSON snapshot on every change.",
                "Legacy JSON work-session data is still imported on first SwiftData load so existing local installs keep their rooms, notes, schedules, VIP flags, and media metadata.",
                "The app now starts with a lightweight seed store and loads the saved work session off the main thread before applying it on the main actor.",
                "Moved WorkSessionStore out of Domain into the work-session feature layer, with persistence/bootstrap split into a dedicated extension.",
                "Moved room-cell geometry into the Design layer so Domain stays free of presentation sizing.",
                "Added SwiftData repository regression tests for complete round-trip persistence and stale child cleanup."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (30)",
            date: "2026-06-06",
            changes: [
                "Голосовые заметки теперь пишутся в файл и расшифровываются ПО ФАЙЛУ после остановки, без живого аудио-движка — это убирает краш записи/расшифровки на устройстве.",
                "Удалён живой AVAudioEngine-tap микрофона и Speech-буфер, из-за которых приложение падало.",
                "Аудио-сессия записи полностью деактивируется после каждой заметки."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (29)",
            date: "2026-06-06",
            changes: [
                "Removed debug traps from interaction sound setup so optional click audio cannot crash the app.",
                "Voice recording start and stop now use haptic-only feedback to avoid competing with the microphone audio session.",
                "Kept build 28's Apple-style Speech recording session and voice recorder diagnostics."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (28)",
            date: "2026-06-06",
            changes: [
                "Aligned live speech startup with Apple's documented AVAudioSession record/measurement pattern.",
                "Removed interaction sound playback from the voice record button so AVAudioPlayer no longer races Speech startup.",
                "Added structured voice-recorder runtime logs for start, stop, finish, and failure diagnosis."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (27)",
            date: "2026-06-06",
            changes: [
                "Hardened real-device voice recording shutdown with a locked Speech audio pipe.",
                "Speech audio now finishes exactly once even if the panel disappears, stop is tapped, or cleanup runs later.",
                "Microphone buffers are ignored after stop so the audio tap cannot append into a closed Speech request."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (26)",
            date: "2026-06-06",
            changes: [
                "Started the native-migration refactor pass: Flutter is now treated as product behavior reference, not an architecture template.",
                "Rebuilt voice notes around an iOS-native Speech service plus a small SwiftUI ViewModel instead of a UI-owned recorder controller.",
                "Voice stop now waits briefly for final Speech results so transcripts are not discarded during cleanup.",
                "Made the SpriteKit coordinator explicitly MainActor to match UIKit and SpriteKit lifecycle rules."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (25)",
            date: "2026-06-06",
            changes: [
                "Fixed a second voice-recording crash caused by overlapping audio tap startup.",
                "Voice capture now uses an explicit idle, starting, recording, and stopping state machine.",
                "Each voice recording gets a fresh AVAudioEngine so repeated recordings do not inherit stale input taps."
            ]
        ),
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
