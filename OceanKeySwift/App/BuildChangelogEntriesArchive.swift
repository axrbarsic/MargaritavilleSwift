import Foundation

extension BuildChangelog {
    static let archiveEntries = [
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
    ]
}
