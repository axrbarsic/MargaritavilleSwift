# OceanKey Native iOS Migration Plan

## Decision

OceanKeySwift is a separate native iOS rewrite track for OceanKey. The Flutter
application remains the working fallback until the native app reaches practical
feature parity.

Android and Web are frozen for now. New work should optimize for iPhone first:
SwiftUI, native iOS performance tools, Apple platform storage, and real-device
verification.

## Current Baseline

- Project path: `/Users/alex/Developer/OceanKeySwift`
- App name: `OceanKey Swift`
- Bundle identifier: `com.alex.oceankey.swift`
- Minimum iOS: 17.0
- UI foundation: SwiftUI
- State foundation: Observation
- Visual effects foundation: SpriteKit + GameplayKit hosted inside SwiftUI
- Matrix wallpaper: a single SpriteKit scene is the active native background
  path, with persisted color-richness configuration flowing through SwiftUI
  environment into the existing `SKView`.
- Summary action-menu behavior: one expanded menu is the default, while optional
  multi-menu mode is handled through Settings and a tested presentation policy.
- Room status palette: status fills go through a shared native theme API with a
  persisted saturation factor, instead of hardcoding final colors in each cell.
- Interaction feedback: UIKit feedback generators plus bundled local WAV sounds
  through an ambient mixed audio session
- Notifications: local UserNotifications for due scheduled room openings
- Speech: native `AVAudioRecorder` file capture followed by
  `SFSpeechURLRecognitionRequest` Russian voice-to-text for local room/cart
  notes. Live `AVAudioEngine` taps are intentionally not part of the Swift voice
  path.
- Local persistence: SwiftData is the default local-first work-session store;
  legacy JSON exists only as an import/fallback path for older installs.
- Event history: room/cart/selection/status/note/media/schedule changes append
  timestamped domain history entries. Each entry carries a lightweight visual
  snapshot of the main screen state, and Settings can already open a compact
  native history viewer.
- iCloud readiness: the SwiftData persistence schema avoids local-only
  assumptions that would block CloudKit later; the active store remains
  explicitly local-only until sync is enabled as a separate infrastructure
  adapter.
- Startup loading: saved work-session state is fetched off the main thread and
  applied on the main actor, so first render is not blocked by SwiftData or
  legacy JSON IO.
- Performance telemetry: a lightweight app-wide CADisplayLink sampler tracks
  current FPS, slow frames, and worst recent frame without invalidating SwiftUI
  on every display tick.
- ProMotion readiness: the app opts out of the iPhone minimum-frame-duration
  cap and requests the physical display's maximum cadence for SpriteKit and
  telemetry, with 120 Hz as the supported-device target.
- Settings surfaces runtime diagnostics for ProMotion opt-in and Apple sync
  readiness, so device builds expose whether these platform capabilities are
  active or blocked.
- Sync metadata: room VIP state and scheduled room time now carry field-level
  update timestamps in domain data and SwiftData persistence, so future
  CloudKit conflict resolution can merge individual fields.
- Room open state and each S/L/B task state also carry last-updated timestamps,
  separate from first-happened milestone facts shown in the room timeline.
- Work setup state now has timestamp metadata for cart bindings, room
  selections, deselected-room tombstones, and workday lock changes.
- A pure domain merge policy now covers the future Apple sync boundary before a
  CloudKit adapter is wired: current fields use newest timestamp, milestones
  preserve earliest facts, and history remains append-only.
- Installed-device SwiftData migration is guarded for older setup selection
  records: missing selected/deselected flags are treated as active legacy rows.
- A native iCloud/CloudKit entitlement draft exists for container
  `iCloud.com.alex.oceankey.swift`, but activation is currently blocked by the
  installed Apple Development provisioning profile, which does not yet include
  iCloud/Push capabilities.
- Physical iPhone install is active through the local Apple Development profile
  for `com.alex.oceankey.swift`
- Project generation: XcodeGen through `project.yml`
- Migration rule: Flutter is a product and behavior reference, not an
  architecture template. Native Swift work should preserve the user-visible
  idea and domain rules while using Apple-native lifecycle, services, ViewModel
  boundaries, and platform APIs.

The bundle identifier is intentionally different from the existing Flutter app
so the native app can be installed side by side when a provisioning profile is
available.

## Migration Phases

1. Native shell and summary screen
   - Build a small but real SwiftUI shell.
   - Port the main room list screen first.
   - Keep visual effects behind the shared SpriteKit effects host, not inside
     ad hoc SwiftUI view code.

2. Domain parity
   - Port room status, task buttons, VIP state, timers, cart sections, and room
     history as domain data before adding complex UI.
   - Keep domain logic testable without SwiftUI.
   - Keep tactile/audio interaction behavior behind a shared native feedback
     service, not scattered across SwiftUI views.
   - Keep presentation stores such as `WorkSessionStore` outside `Domain`;
     domain files should stay value-model/rule oriented.

3. Local-first persistence
   - Keep SwiftData as the native local repository and source of truth.
   - Store room state, milestone timestamps, notes, cart notes, and local media
     metadata.
   - Store work-session history as append-style SwiftData records with visual
     main-screen snapshots, not as a replacement full JSON rewrite loop.
   - Keep legacy JSON reads only for upgrade/fallback compatibility.
   - Keep media files local by default.

4. Apple-first sync
   - Evaluate CloudKit/iCloud as the primary iPhone-to-iPhone sync path.
   - Preserve idempotent local-first behavior: local edits must not disappear
     because an older cloud snapshot arrives.
   - Do not migrate or model the Swift sync architecture after Firebase.

5. Notes and media
   - Port voice notes with transcription.
   - Port photo and video capture with native AVFoundation/PhotosUI paths.
   - Build thumbnail and full-screen preview flows for vertical media first.
   - Keep cart consumables as cart-specific domain data with quantities,
     completion timestamps, and history events.
   - Keep recorder and capture lifecycles in native services; SwiftUI panels
     should render state and call small ViewModel actions, not own low-level
     audio/video engines.

6. Diagnostics and performance
   - Keep frame/performance telemetry from the start.
   - Treat 120 Hz smoothness as the target on supported iPhones.
   - Keep vertical scrolling higher priority than row-level gestures; room
     swipe menus must require a clearly horizontal gesture.
   - Keep summary menu expansion rules outside heavy SwiftUI views so Settings
     can alter behavior without creating new gesture conflicts.
   - Keep visual palette controls routed through the shared design layer, not
     directly inside row views.
   - Keep background effects behind shared SpriteKit/runtime configuration;
     settings sliders must update the existing effect rather than remounting it.
   - Test on real devices before considering visual effects done.

7. Cutover
   - Install OceanKeySwift side by side while Flutter remains production-safe.
   - Move the production bundle identifier only after the native app is stable
     enough to replace the Flutter app.

## Agent Continuation Rule

The migration is the global goal. A single finished subtask is only a checkpoint,
not a stopping point. After each coherent build/install/commit checkpoint, the
agent should continue to the next highest-priority migration gap unless Alex
explicitly pauses the work or a real external blocker requires his action.

Project-level execution details are captured in `AGENTS.md`.

## Signing Note

The current Mac can build, install, test, and launch `com.alex.oceankey.swift`
on Alex's physical iPhone through the local Apple Development signing setup.
