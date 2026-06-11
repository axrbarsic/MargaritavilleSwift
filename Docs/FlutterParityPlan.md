# Flutter Parity Plan

## Rule

The Flutter application in `/Users/alex/Developer/OceanKeyFlutterRun` is the
visual and behavioral reference while the native iOS rewrite is still catching
up. Do not edit the Flutter project during the port.

All validation for this track targets the physical iPhone. Do not use the iOS
Simulator unless explicitly allowed.

## Transfer Order

1. Main summary screen
   - Header count strip and left/right controls.
   - Cart header: `Тележка N` on the left, territory/building on the right.
   - Room cell status colors, spacing, typography, S/L/B task controls.
   - Right swipe action menu, one open menu by default.
   - Room timeline chips and schedule badge.

2. Room cell domain behavior
   - Open/yellow/red/blue/green/pink status rules.
   - Milestone timestamps: selected, opened, stripped, linen, balcony, done.
   - Scheduled room transition behavior.
   - VIP state and effects.
   - Cart selection rules: carts 1-10, A/B floors 2-5, duplicate-room blocking,
     and workday lock/unlock.

3. Notes and media
   - Text notes.
   - Voice notes with transcription.
   - Photo and video capture with local-only storage.
   - Full-screen vertical media viewer.

4. Cart details
   - Long press on cart header opens cart-specific details.
   - Cart notes, consumables, photo/video capture.
   - Completion markers and timestamps.

5. Settings and diagnostics
   - Developer diagnostics.
   - Build/version changelog.
   - Visual effect settings only after the native effect runtime is stable.

6. Persistence and sync
   - Local-first storage.
   - Apple-first sync evaluation through iCloud/CloudKit.
   - Firebase is not a Swift migration target.

## Current Native Checkpoint

- Native migration rule is now explicit: copy the product idea, workflow,
  domain rules, and visual contract from Flutter, but implement each feature
  using professional Swift/iOS architecture rather than mirroring Flutter widget
  structure or lifecycle.
- SpriteKit/GameplayKit effect host exists.
- App screens use a single SpriteKit Matrix wallpaper path; the older
  Canvas/Timeline fallback was removed so live-background work goes through one
  native runtime.
- Room cells now use the Flutter status palette.
- Room status colors now also pass through a native saturation setting so the
  whole main-screen palette can be made calmer or richer from Settings.
- Room cells support open state, S/L/B task toggles, VIP toggle, schedule toggle,
  timeline fields, schedule badge, and a right-swipe action menu.
- Only one action menu is open at a time by default; Settings now exposes the
  optional multi-menu behavior for cases where several expanded room menus are
  useful during work.
- Native state now uses SwiftData as the default local-first source of truth for
  the work session. Legacy Application Support JSON is only an import/fallback
  path for older local installs.
- Startup no longer performs work-session IO on the main thread: SwiftData or
  legacy JSON loading happens on a background queue, then the ready snapshot is
  applied to the Observation store on the main actor.
- Header settings opens a native Settings screen with developer/build info and
  local storage status.
- Room details text notes and voice-transcript drafts are now domain data and
  persist through the local work-session repository.
- Long press on a cart header opens a native cart details screen with persistent
  cart note, consumables, and media action slots.
- Cart consumables are real domain data now: towel/sheet rows support quantity,
  completion mark, timestamp, event history, and SwiftData persistence.
- Cart details media can capture local-only photos/videos through the native
  camera bridge, stores files in Application Support, shows vertical thumbnail
  previews, and opens a shared full-screen viewer.
- Room swipe menu now opens the same native local media capture flow for room
  photo/video attachments, including the same full-screen viewer.
- Settings now includes an in-app build changelog so installed builds can be
  identified without reading Git history.
- Deliberate visual exception: native Swift room cells use the taller first-test
  geometry (`76pt` tile height and wider `10pt` inter-cell spacing) because it
  looked better on iPhone than the tighter Flutter parity geometry.
- Settings can now switch room-cell geometry between the taller first-test Swift
  layout and the tighter Flutter-parity layout.
- Scheduled pink rooms now advance automatically to open/red on the main screen
  when the scheduled time has arrived, recording the opened timestamp and
  persisting the change locally.
- Native domain rules now cover room catalog, cart bindings, room selection,
  blocked duplicate rooms, workday lock/unlock, and summary cart rebuilding.
- Native first work setup screen now lets the user choose carts, A/B building,
  floor, and rooms before locking into the summary screen.
- Settings can unlock the workday and return to setup editing after the summary
  screen is already active.
- `WorkSessionStore` now lives in the work-session feature layer rather than
  Domain; Domain keeps room/catalog/selection/snapshot value rules only.
- Room-cell geometry now lives in the Design layer, not in domain or app
  bootstrap code.
- Local persistence now stores the work-session graph in SwiftData containing
  selection, carts, rooms, timestamps, notes, schedules, VIP, and media metadata,
  while still reading older cart-list/work-session JSON files for upgrade
  compatibility.
- Core room task invariants now require an open room before S/L/B changes, and
  ready status requires open plus all tasks.
- Native interaction feedback now mirrors the Flutter foundation: UIKit haptics,
  bundled click/pressed WAV sounds, ambient mixed audio, protected long-press
  room controls by default, and clean haptic feedback for right-swipe menus.
- Room long-press haptics are delayed so normal vertical scrolling across cells
  does not buzz or steal intent; right-swipe menu arming now requires a stronger
  horizontal gesture.
- Current Swift gesture rule: inactive tap/long-press recognizers must not stay
  attached to room controls, and vertical scroll must beat row-level
  swipe/tap/long-press interactions when the finger starts on a cell.
- The summary header puzzle handle is functional again: dragging the puzzle
  returns from the main screen to first-screen cart/room editing.
- Room scheduling now uses a native hour/minute/AM-PM sheet with 15-minute
  increments, pink schedule status priority, automatic due-time opening, and
  local iOS notifications.
- Room voice notes and cart notes now share native Russian speech-to-text
  transcription through file-based `AVAudioRecorder` capture followed by
  `SFSpeechURLRecognitionRequest`; Gemini is not part of the Swift voice path.
- Voice recording startup is hardened on real devices: Speech and microphone
  permission callbacks stay outside MainActor isolation, and recording cleanup
  no longer depends on live audio-tap lifecycle.
- Repeated voice recordings run through an explicit file-capture state machine,
  preventing overlapping live microphone taps during rapid start/stop cycles.
- Voice transcription is now split into an iOS-native `VoiceTranscriptionService`
  and `VoiceNoteViewModel`; the SwiftUI panel no longer owns AVFoundation or
  Speech lifecycle directly.
- Sync direction is Apple-first for the native rewrite. Firebase should not be
  used as the architecture reference for Swift sync.
- The SwiftData persistence schema now requests CloudKit private-database sync
  by default, with a persistent local fallback if iCloud is unavailable.
- Native global history foundation is in place: meaningful room, cart,
  selection, schedule, VIP, note, media, and automatic scheduled-open changes
  create timestamped history entries with lightweight visual snapshots of the
  main screen.
- Settings exposes the first native history viewer with timestamped cards and a
  compact visual snapshot preview that highlights the changed room when present.
- Lightweight live performance telemetry and Apple sync status remain runtime
  services, but Settings no longer shows passive diagnostic rows unless a row is
  an actual control.
- Room VIP state and scheduled room time now carry field-level update
  timestamps and persist them through SwiftData, closing another prerequisite
  for local-first Apple sync merges.
- Room open state and each S/L/B task state now also carry independent
  update timestamps, separate from the visible milestone timeline.
- Setup selections now carry sync metadata too: cart binding changes, selected
  rooms, deselected-room tombstones, and workday lock/unlock changes have
  timestamps and persist through SwiftData.
- A pure domain merge policy now exists for future Apple sync: field-level
  timestamps decide current state, milestone facts keep earliest timestamps,
  and history entries are unioned by ID.
- Real-device SwiftData migration now keeps older setup selection rows
  compatible with the new selected/deselected metadata flags.
- Native iOS connects the CloudKit entitlement draft to signing and declares
  remote notification background mode for SwiftData/CloudKit import/export.
- Native iOS now also declares the ProMotion Info.plist opt-in so supported
  iPhones can request frame rates above the system default; Matrix/SpriteKit
  and telemetry target the device maximum rather than assuming 60 Hz.
- Settings now has a dedicated app-background section with a persisted Matrix
  speed slider. The slider updates the shared SpriteKit scene
  configuration instead of recreating the wallpaper engine.
- Settings now also has a native work-behavior toggle for the summary
  swipe-menu mode. The expansion rule is tested separately from SwiftUI views so
  default single-menu behavior and optional multi-menu behavior cannot drift.
- Settings exposes a native palette saturation slider for all room status colors
  at once, replacing the old piecemeal color controls with one immediate global
  adjustment.
- Settings now includes a native reset-to-defaults action with confirmation,
  restoring appearance, workflow, palette, and Matrix settings as one coherent
  settings snapshot.
- Settings now has native category navigation for Appearance, Work, Data, and
  Developer areas, matching the product intent of the Flutter categorized
  settings screen without copying its widget architecture.
- App background settings now expose an explicit `Off / Matrix` mode selector,
  and all primary Swift screens read the same background mode through a shared
  native `AppBackgroundView`.
- Native Matrix Rain now follows the Flutter Matrix visual contract: 80 random
  drops, the same glyph set, dark green background, head glow, vignette, and
  Flutter-style speed range.
- Native Matrix rendering keeps that visual contract but uses SpriteKit-native
  cached glyph textures and bottom-left scene coordinate mapping, not a literal
  Flutter painter port.
- Video wallpaper is now native iOS: Settings can import one local video,
  persist it in Application Support, and render it as a muted loop through
  `AVQueuePlayer`/`AVPlayerLooper` with a matte blur control.
- Video wallpaper matte blur now lives inside the native player container:
  `AVPlayerLayer` stays the video source while one UIKit material/tint layer
  provides the matte finish without remounting the background.
- Video wallpaper controls now include blur, brightness, and green tint. The
  native player container has a lightweight watchdog that resumes or rebuilds
  the loop if AV playback stalls after app/background transitions.
- Cart consumables now support custom per-cart rows on top of the default
  towel/linen catalog, with quantity, completion state, timestamps, history,
  and SwiftData persistence.
- Settings now follows the Flutter category idea as native SwiftUI but is
  intentionally trimmed to active controls only: Appearance, Background, Work,
  and Developer.
- Developer experiments were simplified again after real-device testing:
  deprecated invisible/heavy overlays and the rejected glossy volume-cell effect
  were removed from Settings/state, while the active test controls are live
  spring cells and adjustable moving VIP zebra stripes with sharpness.
- Room and cart voice notes now share playable local audio bubbles, while room
  cells show compact top-right indicators when text, voice, photo, or video
  data exists. Room/cart attachments can be deleted and their local files are
  cleaned up.
- Video wallpaper controls now include stronger green tint, wider brightness,
  matte blur, scanline/grid overlay, and the playback watchdog.
- OceanKeySwift now has first-class hotel profiles instead of one hard-coded
  property: the current OceanKey workflow remains the default S/L/B full-width
  room flow, while Margaritaville can be selected from a startup hotel chooser
  or Settings.
- Work-session persistence is isolated per hotel through separate SwiftData
  store files. The existing OceanKey store is migrated forward from the legacy
  default store path so Margaritaville data cannot overwrite current-hotel data.
- Margaritaville has the first simple-cycle summary: 4-column square room grid,
  yellow -> red -> green room taps, purple scheduled rooms, live status chips,
  progress label, and visible current-status/scheduled time on every tile.
- Margaritaville green rooms are protected from accidental reset: the normal
  status action stops at green, and yellow reset is an explicit menu action.
- Margaritaville catalog editing is now native: Settings can add/remove room
  numbers, infer the correct building/floor from the room number, persist the
  override in the Margaritaville SwiftData store, and block deleting rooms that
  are already in the active workday.
- Margaritaville square summary tiles now expose voice/media, VIP, schedule,
  and reset through a native context menu, and the grid reuses compact media
  and VIP indicators.
- Margaritaville setup shows selected rooms from other buildings/floors of the
  same cart as compact chips, making multi-territory cart selection visible
  while the main grid is focused on one territory.
