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
- Main screen uses a SpriteKit Matrix background.
- Room cells now use the Flutter status palette.
- Room cells support open state, S/L/B task toggles, VIP toggle, schedule toggle,
  timeline fields, schedule badge, and a right-swipe action menu.
- Only one action menu is open at a time.
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
- The SwiftData persistence schema is shaped for future CloudKit compatibility,
  while the installed app remains local-only until iCloud sync is intentionally
  enabled.
- Native global history foundation is in place: meaningful room, cart,
  selection, schedule, VIP, note, media, and automatic scheduled-open changes
  create timestamped history entries with lightweight visual snapshots of the
  main screen.
- Settings exposes the first native history viewer with timestamped cards and a
  compact visual snapshot preview that highlights the changed room when present.
- Settings now exposes lightweight live performance telemetry: FPS target,
  current FPS, recent slow frames, total slow frames, and recent worst frame
  time.
- Settings now also exposes runtime diagnostics for ProMotion opt-in and the
  current Apple sync state, so installed builds show whether 120 Hz and iCloud
  are actually active rather than implied.
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
- Native iOS has a CloudKit entitlement draft for the Apple-first sync
  direction, but it is not active in signing until the Apple provisioning
  profile includes iCloud/Push capabilities.
- Native iOS now also declares the ProMotion Info.plist opt-in so supported
  iPhones can request frame rates above the system default; Matrix/SpriteKit
  and telemetry target the device maximum rather than assuming 60 Hz.
