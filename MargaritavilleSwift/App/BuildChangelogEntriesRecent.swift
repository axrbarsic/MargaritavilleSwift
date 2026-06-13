import Foundation

extension BuildChangelog {
    static let recentEntries = [
        BuildChangelogEntry(
            version: "0.1.0 (7)",
            date: "2026-06-13",
            changes: [
                "Restored Margaritaville scheduled rooms and status filter chips to the pink scheduled color instead of purple.",
                "Increased Margaritaville summary room numbers and time labels while preserving the square tile layout.",
                "Removed the crown badge from VIP summary tiles; VIP is now indicated by the live jelly visual effect only.",
                "Moved room media indicators into a lower-right corner flag so media is visible without covering the room number.",
                "Made selected housekeeper chips toggle off when tapped again from the setup screen."
            ]
        ),
        BuildChangelogEntry(
            version: "0.1.0 (6)",
            date: "2026-06-13",
            changes: [
                "Changed Margaritaville setup to start from housekeeper names instead of visible cart numbers.",
                "Removed cart-number labels from Margaritaville setup cards and summary sections; cart IDs now stay internal.",
                "Simplified Margaritaville summary group headers to show the housekeeper and territory only, without the confusing room-count number beside A/B floor labels.",
                "Redesigned the Margaritaville setup cards for one-handed use with larger housekeeper chips, building/floor controls, and room-number buttons."
            ]
        ),
        BuildChangelogEntry(
            version: "0.1.0 (5)",
            date: "2026-06-13",
            changes: [
                "Removed the setup-screen room catalog regex hotspot that made rapid room selection stall the main thread.",
                "Moved interaction sound playback work off the main thread and deferred feedback one UI turn so tap state changes can paint immediately.",
                "Kept the full native haptic/audio feedback behavior without using the temporary diagnostics-only feedback bypass."
            ]
        ),
        BuildChangelogEntry(
            version: "0.1.0 (4)",
            date: "2026-06-12",
            changes: [
                "Reduced tap-frame work by debouncing work-session persistence after rapid room/status changes and flushing pending saves when the app leaves active state.",
                "Changed history snapshots to keep only the affected cart for normal room/selection events instead of copying the full workday on every tap.",
                "Reworked interaction sounds through a small preloaded AVAudioPlayer pool so fast taps do not cut off or lose feedback sounds.",
                "Moved haptic generator preparation out of the synchronous tap path while keeping strong native iPhone feedback."
            ]
        ),
        BuildChangelogEntry(
            version: "0.1.0 (3)",
            date: "2026-06-12",
            changes: [
                "Rebuilt Margaritaville setup around cart, housekeeper, section, floor, and room selection, removing day-category/time clutter from the first screen.",
                "Added editable housekeeper names and individual color palettes in Settings, with assignments persisted per cart.",
                "Made summary status chips tappable filters and enlarged square room numbers/times for on-the-move readability.",
                "Strengthened native iPhone haptic feedback for confirmations, warnings, invalid actions, and hold commits."
            ]
        ),
        BuildChangelogEntry(
            version: "0.1.0 (2)",
            date: "2026-06-12",
            changes: [
                "Hardened Margaritaville runtime identity so storage, notifications, backup documents, logs, and CloudKit identifiers use Margaritaville-specific values.",
                "Restored live wallpapers on the Margaritaville square summary screen instead of forcing a black background.",
                "Added a startup loading gate so the setup screen no longer flashes before a saved locked workday opens."
            ]
        ),
        BuildChangelogEntry(
            version: "0.1.0 (1)",
            date: "2026-06-11",
            changes: [
                "Split Margaritaville into a separate installed iOS app with its own bundle identifier and app storage.",
                "The app now boots directly into the Margaritaville workflow instead of showing a hotel chooser.",
                "Simplified the Margaritaville summary header to match the main OceanKey structure: settings, center stats, and a direct edit-entry button."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (121)",
            date: "2026-06-11",
            changes: [
                "Split WorkSessionStore note/media mutations and shared mutation plumbing into focused extension files.",
                "Kept work-session behavior unchanged while reducing the central store file size."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (120)",
            date: "2026-06-11",
            changes: [
                "Split AppSettingsStore helper code into focused Swift extension files.",
                "Kept settings behavior unchanged while reducing the central settings store file size."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (119)",
            date: "2026-06-11",
            changes: [
                "Split build changelog entries into smaller source files.",
                "Kept the in-app changelog behavior unchanged while reducing the main app file size."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (118)",
            date: "2026-06-11",
            changes: [
                "Split DeepSeek Lab visual components out of the main settings section.",
                "Kept the AI preset generator behavior unchanged while reducing settings file size."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (117)",
            date: "2026-06-11",
            changes: [
                "Replaced room/cart media rows with a shared vertical media grid.",
                "Stopped thumbnail video previews before opening the full-screen viewer.",
                "Changed full-screen video playback to a direct AVPlayerLayer lifecycle for more reliable video rendering."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (116)",
            date: "2026-06-11",
            changes: [
                "Grouped Margaritaville summary tiles into separate building/floor islands inside a cart.",
                "Added regression coverage so a multi-territory Margaritaville cart renders A3 and B3 as separate summary groups."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (115)",
            date: "2026-06-11",
            changes: [
                "Added a Margaritaville setup summary for rooms already selected in other buildings or floors of the same cart.",
                "Split setup picker and room tile controls into smaller SwiftUI components to keep the setup screen maintainable."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (114)",
            date: "2026-06-11",
            changes: [
                "Reworked full-screen video media playback to use the native iOS player controller.",
                "Stopped background video thumbnails when opening the media viewer."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (113)",
            date: "2026-06-11",
            changes: [
                "Added live Margaritaville setup counters for every day category.",
                "Made the category filter chips show their current selected-room totals."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (112)",
            date: "2026-06-11",
            changes: [
                "Changed Margaritaville setup time controls to Due Out presets: 12 PM, 2 PM, and 5 PM.",
                "Prevented non-Due-Out setup categories from carrying an accidental time value."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (111)",
            date: "2026-06-11",
            changes: [
                "Added a regression test proving Margaritaville green rooms do not reset from a normal status tap.",
                "Documented the guarded simple-cycle reset path so completed Margaritaville rooms only return to yellow through the explicit reset action."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (110)",
            date: "2026-06-11",
            changes: [
                "Added Margaritaville square-tile actions for voice/media, VIP, scheduling, and reset.",
                "Reused the shared media badge on Margaritaville tiles so rooms with audio, photo, or video are visible in the grid.",
                "Moved VIP jelly and media indicator rendering into shared summary components."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (109)",
            date: "2026-06-11",
            changes: [
                "Added a Margaritaville catalog editor in Settings for adding and removing room numbers.",
                "Catalog changes are stored in the active hotel's SwiftData store and immediately update setup room grids.",
                "Deletion now refuses rooms that are already part of the active workday."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (108)",
            date: "2026-06-11",
            changes: [
                "Added optional 15-minute time tagging to Margaritaville setup categories.",
                "Moved day-category setup controls into their own SwiftUI component to keep setup files smaller and cleaner.",
                "Selected Margaritaville setup tiles now show both the category badge and its optional time."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (107)",
            date: "2026-06-11",
            changes: [
                "Added Margaritaville day-category tagging for setup rooms: Due Out, Stayover, Departed, Pick Up, and OOO.",
                "Persisted room day-category data, optional category time, and update timestamps through SwiftData and visual history.",
                "Added setup category chips and a category filter for Margaritaville without changing the current OceanKey S/L/B setup flow."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (106)",
            date: "2026-06-11",
            changes: [
                "Added a confirmation step before switching hotels from Settings so a work session is not changed accidentally.",
                "Hardened multi-hotel persistence with a regression test that writes OceanKey and Margaritaville into separate physical SwiftData store files.",
                "Adjusted Margaritaville setup room picking to use fixed 4-column square tiles while keeping the current OceanKey setup layout unchanged."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (105)",
            date: "2026-06-11",
            changes: [
                "Added hotel profiles with a startup hotel selector and persisted hotel switching between OceanKey and Margaritaville.",
                "Added a Margaritaville 4-column square summary with simple yellow/red/green room cycle, purple scheduled rooms, live status counters, and status-change time labels.",
                "Moved work-session persistence to hotel-specific SwiftData stores while migrating the existing OceanKey store forward."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (104)",
            date: "2026-06-10",
            changes: [
                "Fixed physical iPhone startup by skipping CloudKit-backed AI preset storage when the installed build has no iCloud entitlement.",
                "AI/live-wallpaper presets now fall back directly to local storage plus manual Files/iCloud Drive backup on Personal Team builds.",
                "Removed the last force-unwrap fallback from AI preset store startup so a storage setup failure is shown as state instead of crashing."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (103)",
            date: "2026-06-10",
            changes: [
                "Added a manual preset backup exporter for DeepSeek-generated Matrix/VIP configurations and the current live wallpaper settings.",
                "The backup is a lightweight configuration document that can be saved through the system Files picker, including iCloud Drive, without CloudKit entitlements.",
                "Restored physical-device signing to the Personal Team-compatible path while keeping CloudKit entitlements available for simulator/future Developer Program validation."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (102)",
            date: "2026-06-10",
            changes: [
                "Made DeepSeek visual presets report their real Apple sync mode instead of silently falling back to temporary memory storage.",
                "Added an explicit local fallback path for AI presets with a visible warning when CloudKit provisioning is not available.",
                "Kept generated preset storage isolated in its own SwiftData store so it cannot collide with work-session persistence."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (101)",
            date: "2026-06-10",
            changes: [
                "Added a developer DeepSeek Lab for generating lightweight Matrix and VIP visual presets from prompts.",
                "Stored DeepSeek API keys in iOS Keychain instead of source code and saved generated preset JSON through SwiftData for Apple sync.",
                "Removed the visible VIP flicker experiment from the cell rendering path so future VIP experiments go through saved AI presets."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (100)",
            date: "2026-06-10",
            changes: [
                "Fixed media viewing so video pages only play when the video is the active full-screen item, preventing background video audio while viewing photos.",
                "Paused looping video thumbnails while the media viewer is open and kept silent loop previews for video thumbnails in room and cart media."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (99)",
            date: "2026-06-10",
            changes: [
                "Fixed setup selection so switching one cart between floors or buildings no longer deletes rooms already picked on another floor.",
                "Workday cart sections now keep all selected rooms for a cart and summarize multi-floor cart labels like A4/A5."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (98)",
            date: "2026-06-10",
            changes: [
                "Made the personal cart marker floor numbers larger and bolder while keeping them inside the compact marker buttons.",
                "Marked the currently selected floor in the marker picker so reopening a marker shows the active choice."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (97)",
            date: "2026-06-10",
            changes: [
                "Removed building letters from the personal cart marker buttons so the floor numbers fit clearly.",
                "Kept building A markers on the left of the counters and building B markers on the right, using position instead of repeated text."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (96)",
            date: "2026-06-10",
            changes: [
                "Moved building A personal cart markers to the left side of the room statistics and building B markers to the right side.",
                "Widened the marker buttons so floor labels are easier to read without colliding with the statistics or selection handle."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (95)",
            date: "2026-06-10",
            changes: [
                "Added four personal cart floor markers beside the summary counters: yellow and gray markers for building A and building B.",
                "Each marker opens a quick floor picker for floors 2-5 and persists the selected cart location in app settings.",
                "Added settings-store coverage for personal cart marker persistence and reset behavior."
            ]
        ),
    ]
}
