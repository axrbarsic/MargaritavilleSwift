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
            version: "0.2.0 (90)",
            date: "2026-06-09",
            changes: [
                "Hid and force-disabled the unfinished VIP jelly depth experiment so it cannot remain active from saved settings.",
                "Started the performance audit by collapsing VIP jelly animation work to one frame clock per VIP cell instead of separate clocks for background, mask, and each label.",
                "Replaced per-label fake motion with a single Metal distortion pass that warps the rendered room number and S/L/B layer together."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (89)",
            date: "2026-06-09",
            changes: [
                "Added a Developer toggle for VIP jelly depth so the raised blob look can be compared on and off.",
                "Strengthened the VIP jelly depth lighting with a clear specular highlight, darker lower edge, and deeper status-colored body shadow.",
                "Made the room number and S/L/B controls move subtly with VIP jelly so the content follows the blob instead of staying rigid."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (88)",
            date: "2026-06-09",
            changes: [
                "Added native bevel depth to VIP jelly cells using inner highlights, inner shadows, and soft edge lighting.",
                "Kept depth, flicker, and shadow effects clipped to the same live jelly shape so the blob reads as the cell itself, not an overlay."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (87)",
            date: "2026-06-09",
            changes: [
                "Added selectable Broken TV background variants: Analog, Fine, Tear, Green, and Hard.",
                "Persisted the selected TV-static variant and included it in the background renderer configuration.",
                "Moved VIP flicker into the jelly cell renderer when VIP jelly is active, so flashes follow the blob shape instead of the old rectangle."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (86)",
            date: "2026-06-09",
            changes: [
                "Smoothed VIP jelly edges with cubic curves so the cell no longer catches angular polygon corners while wobbling.",
                "Clipped VIP flicker through the same jelly cell mask and replaced the diagonal light gradient with a uniform natural flash."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (85)",
            date: "2026-06-09",
            changes: [
                "Removed the VIP breathing experiment from active settings and replaced it with VIP jelly.",
                "Made VIP jelly deform the actual cell shape and mask instead of drawing a moving line inside a stable rectangle.",
                "Added per-room seeded multi-wave motion so VIP jelly cells do not move in the same short visible loop."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (84)",
            date: "2026-06-09",
            changes: [
                "Strengthened the VIP jelly effect so enabled VIP cells visibly pulse vertically and warp through the real cell size.",
                "Added animated jelly edge highlights to make the effect easier to see without bringing back the removed zebra or TV-static VIP modes."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (83)",
            date: "2026-06-09",
            changes: [
                "Removed the old VIP TV-static and VIP zebra experiments from active settings and room rendering.",
                "Reworked VIP breathing into a GPU distortion shader so VIP cells can jelly-warp instead of only stretching horizontally.",
                "Simplified Broken TV background controls to brightness and green tint, with stronger visible response."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (82)",
            date: "2026-06-09",
            changes: [
                "Added live controls for the Broken TV background: noise speed, grain size, brightness, and green tint.",
                "Added experimental VIP flicker and VIP breathing controls so VIP cells can pulse without using the coarse TV-static cell effect."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (81)",
            date: "2026-06-09",
            changes: [
                "Rebuilt the VIP TV-noise cell effect on the same Core Image random-noise renderer used by the full-screen TV background.",
                "Replaced the coarse Canvas block pattern with finer status-tinted static grain and matching scanlines inside VIP cells."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (80)",
            date: "2026-06-08",
            changes: [
                "Removed the TV-noise cell toggle from the Background settings so it can no longer read as a global all-cells mode.",
                "Kept TV noise only as a VIP experimental effect: regular cells never create the overlay."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (79)",
            date: "2026-06-08",
            changes: [
                "Changed the broken-TV cell effect into a VIP-only mode instead of applying it to every room cell.",
                "When the VIP TV mode is enabled, VIP cells use status-tinted TV static and the regular VIP zebra is suppressed to avoid stacked animated overlays."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (78)",
            date: "2026-06-08",
            changes: [
                "Optimized the broken-TV cell overlay after device testing showed heat and scrolling jank.",
                "Kept the cell TV static visually obvious while replacing per-pixel drawing with a bounded low-cost noise grid."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (77)",
            date: "2026-06-08",
            changes: [
                "Made the broken-TV cell overlay much more visible with high-contrast black, white, and status-tinted static.",
                "Raised the cell TV static cadence to 60 Hz and added stronger scanline/glitch bands so the effect reads like the full-screen TV background."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (76)",
            date: "2026-06-08",
            changes: [
                "Made the cell broken-TV experiment easier to find by showing it in Background settings as well as Developer experiments.",
                "Renamed the toggle to 'Сломанный ТВ в ячейках' so it clearly describes the visible cell effect."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (75)",
            date: "2026-06-08",
            changes: [
                "Added a Developer experiment that applies broken-TV static inside room cells instead of only as a full-screen background.",
                "Tinted the cell TV static from each room's current status color so yellow, red, green, blue, and scheduled cells keep their meaning.",
                "Kept the effect as a lightweight visible-cell overlay with deterministic per-room noise instead of creating a SpriteKit scene per cell."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (74)",
            date: "2026-06-08",
            changes: [
                "Replaced the black SpriteKit GLSL TV Static path with a native Core Image CIRandomGenerator background so the TV mode renders visibly on the iPhone.",
                "Kept TV Static as a regular background mode next to Off, Matrix, and Video, with scanline overlay for an analog television feel.",
                "Removed the unused SpriteKit TV shader scene from the active code path."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (73)",
            date: "2026-06-08",
            changes: [
                "Moved the broken-TV effect out of the Developer preview and into the regular background mode picker next to Off, Matrix, and Video.",
                "Made TV Static render as a full-screen SpriteKit background and write opaque shader fragments directly so it cannot appear as a black preview panel.",
                "Added persistence coverage for the TV Static background mode."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (72)",
            date: "2026-06-08",
            changes: [
                "Fixed the temporary broken-TV preview visibility by adapting ShaderKit's Dynamic Gray Noise output alpha to OceanKey's direct SKSpriteNode shader wrapper.",
                "Kept the ShaderKit noise algorithm intact while removing the dependency on ShaderKit's color-mix helper state.",
                "Restored video wallpaper matte blur as a real variable UIBlurEffect instead of the coarse gray material-step overlay."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (71)",
            date: "2026-06-08",
            changes: [
                "Added a temporary experimental Settings block for the first broken-TV visual candidate.",
                "Integrated ShaderKit's MIT Dynamic Gray Noise shader as a SpriteKit GPU preview instead of hand-rolling the TV static effect.",
                "Persisted the temporary TV noise toggle so the preview can be switched on and off while testing."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (70)",
            date: "2026-06-08",
            changes: [
                "Rebuilt the top setup-unlock puzzle swipe as one measured GeometryReader track so the dragged piece lands exactly in the settings-button socket.",
                "Fixed the room-cell puzzle swipe math so the piece center and socket center match exactly at commit instead of landing a few points off."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (69)",
            date: "2026-06-08",
            changes: [
                "Rebuilt video wallpaper playback around a stable AVPlayerLayer path so the main screen no longer starts black until Settings forces a redraw.",
                "Moved blur, green tint, brightness, and grid to lightweight overlay layers instead of per-frame Core Image video composition.",
                "Added tap-to-close behavior: when a room action menu is open, tapping the room cell closes it."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (68)",
            date: "2026-06-08",
            changes: [
                "Fixed room media badges so they depend only on actual local attachments and disappear after the last voice/photo/video item is deleted.",
                "Redesigned the room media marker as a compact native icon badge instead of a dark text chip.",
                "Cleaned the room swipe menu down to voice/media, VIP, and time; removed timeline chips from the expanded cell.",
                "Made VIP and time actions close the expanded room menu automatically, while voice/media keeps it open until the detail sheet is dismissed.",
                "Added puzzle-pull visuals to room and setup swipes, plus a Settings row showing whether Apple sync is active or the app is using local fallback.",
                "Reduced video-wallpaper heat by applying slider changes directly, quantizing the grid overlay, and capping the per-frame matte blur budget when blur, green tint, and grid are all enabled."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (67)",
            date: "2026-06-08",
            changes: [
                "Fixed real-device launch by creating the SwiftData Application Support store directory before CoreData/CloudKit opens default.store.",
                "Kept the CloudKit path, but made persistent local fallback safer so startup diagnostics cannot immediately crash the app.",
                "Defaulted the current physical-device build to local SwiftData until the Apple provisioning profile includes iCloud and Push capabilities."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (66)",
            date: "2026-06-08",
            changes: [
                "Cleaned Settings down to controls that actually change the app: appearance, background, work menu behavior, live cells, VIP zebra, reset, and build changelog.",
                "Removed Sync, Tools, migration notes, passive diagnostics rows, and old developer experiments from the Settings UI.",
                "Deleted rejected or inactive visual experiment code paths so stale saved flags cannot resurrect unused effects."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (65)",
            date: "2026-06-08",
            changes: [
                "Enabled the native Apple-first sync path by bootstrapping SwiftData with the private CloudKit container iCloud.com.alex.oceankey.swift.",
                "Connected the iCloud entitlements file and remote-notification background mode to the signed app target.",
                "Made the SwiftData schema CloudKit-compatible with defaulted fields and inverse relationships.",
                "Added a runtime iCloud account/status check in Settings and a safe persistent local fallback if CloudKit is unavailable."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (64)",
            date: "2026-06-08",
            changes: [
                "Fixed the room left-to-right swipe menu so the commit point lands near the B task zone instead of the unreachable physical edge.",
                "Changed the room swipe recognizer to run simultaneously with scrolling, reducing gesture conflicts while keeping the deliberate long pull.",
                "Added regression tests for the room swipe commit policy."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (63)",
            date: "2026-06-08",
            changes: [
                "Removed the experimental volume-cell look from the active app and hard-disabled its stale saved setting on load.",
                "Added VIP zebra sharpness control so the moving stripes can be made crisper and less blurred.",
                "Replaced the room media marker with a compact top-right icon badge instead of a dark text chip.",
                "Expanded video wallpaper tuning with stronger green range, wider brightness range, and a lightweight scanline/grid overlay.",
                "Tightened the room-cell and setup-unlock swipe thresholds to require a near-complete drag.",
                "Added delete actions for room and cart voice/photo/video attachments, including local file cleanup."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (62)",
            date: "2026-06-08",
            changes: [
                "Fixed voice-note playback by activating a playback audio session before playing saved local m4a bubbles.",
                "Brought cart details closer to room details: voice notes now save as playable audio bubbles, while photo/video media stays local.",
                "Added room-cell media indicators for text, voice, photo, and video attachments.",
                "Rebuilt photo/video viewing around AVPlayerLayer/UIKit containers and added looping silent video thumbnails.",
                "Extended video wallpaper controls with brightness and green tint, plus a playback watchdog that revives stalled loops.",
                "Cleaned Developer experiments down to live cells, volume cells, and VIP zebra controls; deprecated invisible SpriteKit overlays are no longer activated.",
                "Added visible moving diagonal VIP zebra stripes and tightened room/unlock swipe thresholds."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (61)",
            date: "2026-06-07",
            changes: [
                "Replaced the palette saturation slider with a fixed vivid palette switch matching the high-saturation screenshot style.",
                "Simplified the room swipe menu to one multimodal voice/media entry, VIP, and schedule, and removed the duplicate schedule chip from the expanded menu.",
                "Added a slow lamp-style expansion transition for the room swipe menu.",
                "Changed room voice notes into local audio bubbles with transcript text, timestamp, and playback.",
                "Hardened camera/video capture with availability checks and stable temporary video copying before saving."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (60)",
            date: "2026-06-07",
            changes: [
                "Removed the static green Metal Aurora background from the active app path so Matrix stays visible.",
                "Made Game Feel visually clearer: VIP cells get a shared SpriteKit glow/particle layer, and cell physics uses a stronger event spring.",
                "Changed room-cell and selection-unlock swipes to long pull-to-commit gestures with higher thresholds and staged haptic feedback."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (59)",
            date: "2026-06-07",
            changes: [
                "Reduced Developer clutter by keeping grouped experimental presets instead of separate micro-switches.",
                "Stopped hidden main-screen SpriteKit/background layers while Settings is open, so Developer scrolling does not compete with invisible effects underneath.",
                "Disabled the unfinished Metal Aurora renderer from the active UI so Matrix cannot be covered by the static green experimental background.",
                "Moved VIP animation off per-cell TimelineView into one shared overlay, with a more visible shared SpriteKit glow and particle pass for VIP cells.",
                "Reworked swipe commit thresholds: room menus now require a long left-to-right pull across most of the cell, and the selection unlock handle requires a long right-to-left pull instead of long press."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (58)",
            date: "2026-06-07",
            changes: [
                "Grouped the experimental switches into clearer Developer presets: Glass Lab, Game Feel Pack, Metal Aurora, and Assistant Object.",
                "VIP Particles now uses one shared SKEmitterNode overlay for all visible VIP cells, and the old per-cell animated VIP stripe was removed from the hot scrolling path.",
                "Settings now pauses the underlying main-screen background/effect layers while the sheet is open, and Metal Aurora no longer renders on top of Matrix/video at the same time.",
                "Sound and haptic experiments stay behind developer switches and keep the ambient mixed audio session so they do not interrupt other playback."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (57)",
            date: "2026-06-07",
            changes: [
                "Rebuilt video wallpaper matte blur again: the slider now drives a Core Image Gaussian blur inside AVVideoComposition, so the video frames themselves are blurred instead of only covered by a translucent material.",
                "Kept the video background muted and looped through AVQueuePlayer while moving the heavy visual work into the video composition path.",
                "Raised the matte tint response so blur changes are visually obvious when testing the slider on iPhone."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (56)",
            date: "2026-06-07",
            changes: [
                "Added the first native Metal-backed experimental background: Metal Aurora renders through MTKView and a fullscreen fragment shader.",
                "Added a Developer switch for Metal Aurora so the shader path can be tested without changing the default Matrix or video wallpaper modes.",
                "Extended the experimental settings model and tests so Liquid Glass, Glass VIP, and Metal Aurora persist and reset predictably."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (55)",
            date: "2026-06-07",
            changes: [
                "Rebuilt video wallpaper matte blur as a single native AVFoundation/UIKit composition with material blur and tint inside the player view.",
                "Reworked Settings into the Flutter-style category structure: Appearance, Work, Sync, Tools, and Developer, while keeping the implementation native SwiftUI.",
                "Added Developer experimental toggles for iOS 26 Liquid Glass settings surfaces and Glass VIP cells, with safe fallbacks on older iOS versions."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (54)",
            date: "2026-06-07",
            changes: [
                "Added native video wallpaper support: pick a video in Settings, copy it into local app storage, and render it as a muted looping AVQueuePlayer background.",
                "Added a video matte slider that applies a native blur/material layer over the looped video background.",
                "Expanded cart consumables so each cart can add custom supply rows in addition to the default towel and linen catalog."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (53)",
            date: "2026-06-07",
            changes: [
                "Fixed Matrix direction after mapping Flutter's top-left canvas coordinates into SpriteKit's bottom-left scene coordinates.",
                "Reworked native Matrix rendering to use cached SpriteKit glyph textures instead of thousands of live text nodes.",
                "Reduced Matrix per-frame work to movement, visibility, and rare glyph swaps, keeping the visual contract while using a native SpriteKit runtime."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (52)",
            date: "2026-06-07",
            changes: [
                "Rebuilt the native Matrix wallpaper around the Flutter Matrix visual contract: 80 random drops, the same glyph set, the same dark green background, the same head glow, and the same vignette.",
                "Removed the incorrect Matrix color control and replaced it with the Flutter-style speed slider.",
                "Matrix speed now uses the Flutter range and default: 0.08x to 3.0x, default 1.0x."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (51)",
            date: "2026-06-07",
            changes: [
                "Added an explicit app-background mode control in Settings: Off or Matrix.",
                "All main Swift screens now use one AppBackgroundView so Matrix visibility is controlled consistently instead of being hardwired per screen.",
                "Matrix controls stay visible but disabled when the background is off, making it clear how to enable the effect."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (50)",
            date: "2026-06-07",
            changes: [
                "Settings now uses native category navigation instead of one long mixed scroll.",
                "Appearance, Work, Data, and Developer settings are separated into focused sections to keep the Swift rewrite ready for more Flutter settings parity.",
                "Added dedicated SwiftUI category selector components so the Settings screen does not keep growing as one monolithic view."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (49)",
            date: "2026-06-07",
            changes: [
                "Added a native reset-to-defaults action in Settings with an iOS confirmation dialog.",
                "Reset now restores room geometry, long-press behavior, menu mode, palette saturation, and Matrix settings.",
                "Added a persistence regression test proving reset writes the default settings back to storage."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (48)",
            date: "2026-06-07",
            changes: [
                "Added a native Settings slider for main-screen room status palette saturation.",
                "Room cells now read their status colors through the shared theme API, so one setting adjusts pending, open, in-progress, ready, and scheduled colors together.",
                "Added persistence and clamp regression tests for the palette saturation setting."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (47)",
            date: "2026-06-07",
            changes: [
                "Added a native Settings toggle for summary action-menu mode.",
                "Room swipe menus now default to one open menu, while the optional multi-menu mode allows several expanded room menus at once.",
                "Moved the menu expansion rule into a tested presentation policy so gesture behavior stays predictable as Settings grows."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (46)",
            date: "2026-06-07",
            changes: [
                "Moved Matrix Rain to a single SpriteKit wallpaper path and removed the old Canvas/Timeline fallback implementation.",
                "Added persisted Matrix controls under the new app background settings section.",
                "Matrix wallpaper settings now flow through a shared environment configuration so all screens update the existing SpriteKit scene without recreating the engine.",
                "Started the native Settings refactor by moving reusable settings rows, panels, and slider controls into a separate component file."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (45)",
            date: "2026-06-07",
            changes: [
                "Settings now shows a real ProMotion diagnostic row based on the installed app's Info.plist opt-in and the physical display's maximum refresh rate.",
                "Settings now shows the current Apple sync state as local-only while the iCloud provisioning profile is not ready.",
                "Added regression tests for the runtime diagnostics label so 120 Hz status is not just hardcoded UI text."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (44)",
            date: "2026-06-07",
            changes: [
                "Prepared the native iCloud/CloudKit entitlement draft for the Apple-first sync path; activation is blocked until the Apple provisioning profile includes iCloud/Push capabilities.",
                "Reduced main-screen scroll gesture conflicts by removing inactive recognizers from room controls and making the room swipe menu require a deliberate horizontal gesture.",
                "Enabled the iPhone ProMotion Info.plist opt-in and tightened the frame telemetry display link toward the device's 120 Hz target."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (43)",
            date: "2026-06-07",
            changes: [
                "Fixed real-device SwiftData migration for existing setup selection records.",
                "New selected/deselected persistence flags are now backward-compatible with older installed builds; missing values are treated as active legacy selections.",
                "This prevents the installed app from falling back to in-memory storage after upgrading from earlier Swift builds."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (42)",
            date: "2026-06-07",
            changes: [
                "Added a pure domain WorkSessionMergePolicy for future Apple-first iCloud sync.",
                "The merge policy compares field-level timestamps for room state and setup selections, keeps earlier milestone facts, and unions append-only history.",
                "Added regression tests proving stale remote data does not overwrite newer local room state and newer deselection tombstones remove rooms from setup."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (41)",
            date: "2026-06-07",
            changes: [
                "Added sync metadata for setup selections: cart bindings, room selections, room deselection tombstones, and workday lock changes now carry timestamps.",
                "SwiftData now persists setup selection records with selected/deselected state instead of only storing the currently visible room set.",
                "Added regression coverage so removed room selections survive persistence as timestamped tombstones for future local-first iCloud merges."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (40)",
            date: "2026-06-07",
            changes: [
                "Added field-level update timestamps for the room open state and each S/L/B task state.",
                "Kept first-happened room milestones separate from last-updated sync metadata, so closing a room or removing a task can be merged correctly later.",
                "Persisted the new task/open timestamps through SwiftData and covered them with regression tests."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (39)",
            date: "2026-06-07",
            changes: [
                "Added field-level update timestamps for room VIP state and scheduled room time.",
                "SwiftData now persists those timestamps so future iCloud/CloudKit merges can compare individual room fields instead of whole-session snapshots.",
                "Added regression tests for VIP/schedule timestamp mutations and SwiftData round-trip persistence."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (38)",
            date: "2026-06-07",
            changes: [
                "Added a lightweight app-wide performance telemetry store for live FPS and slow-frame tracking.",
                "Settings now shows the current FPS target, recent slow frames, total slow frames, and worst recent frame time.",
                "Telemetry updates SwiftUI once per sampling window instead of invalidating screens on every display frame."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (37)",
            date: "2026-06-07",
            changes: [
                "Added an explicit SwiftData sync mode boundary for future Apple-first CloudKit sync.",
                "Kept the installed app local-only by default; iCloud remains disabled until entitlements, container setup, and conflict policy are ready.",
                "Added a repository test proving the CloudKit mode injection path still round-trips through isolated local test storage."
            ]
        ),
        BuildChangelogEntry(
            version: "0.2.0 (36)",
            date: "2026-06-07",
            changes: [
                "Added a shared native full-screen media viewer for room and cart attachments.",
                "Photos now open in a pinch-zoom viewer, and videos open through AVKit playback with automatic looping.",
                "Thumbnail taps now use the same viewer path for room media and cart media."
            ]
        ),
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
