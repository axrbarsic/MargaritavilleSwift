# MargaritavilleSwift Agent Instructions

## Language And Context

- Always answer Alex in Russian unless he explicitly asks otherwise.
- This worktree is the separate native iOS Margaritaville app split out of
  OceanKeySwift.
- The local app target, scheme, and test module are `MargaritavilleSwift`.
- The main Washington/OceanKey app lives in `/Users/alex/Developer/OceanKeySwift`
  and must remain separate from this worktree.
- The Flutter reference app is `/Users/alex/Developer/OceanKeyFlutterRun`.
- Do not edit the Flutter app while porting unless Alex explicitly asks.
- Android and Web are frozen for this migration track until Alex changes that.

## Global Goal

The primary goal is a stable standalone Margaritaville iOS app, not completion
of one isolated subtask.

Do not stop just because one subgoal is complete. After finishing a coherent
piece, immediately continue to the next highest-priority migration gap unless:

- Alex explicitly says to pause or stop.
- A real blocker requires Alex's action, such as unlocking a device, signing in,
  approving a certificate/account prompt, or providing a missing secret.
- The current turn must end because a build/install/commit checkpoint has been
  reached and no safe next step can be taken without user feedback.

## Critical Path Order

Keep moving through this order:

1. Main screen parity and room-cell behavior.
2. Domain model parity: statuses, timestamps, scheduled transitions, VIP, carts.
3. Local-first persistence and event history.
4. Notes, voice transcription, photo/video capture, and viewers.
5. Cart details, consumables, completion marks, and timestamps.
6. Settings, diagnostics, build changelog, and performance telemetry.
7. Apple-first sync design and implementation through CloudKit/iCloud.
8. Production cutover from Flutter only after the Swift app is stable.

If Alex gives a small visual or UX request, handle it, then return to this
critical path automatically.

## Verification Rules

- Use the physical iPhone by default. Do not use the iOS Simulator unless Alex
  explicitly allows it.
- Current physical device target:
  `85E776B1-9069-5E68-BC3A-3BCAA4AAB870`.
- Bundle identifier:
  `com.alex.margaritaville.swift`.
- If physical-device build fails with `No Accounts` or missing profile for
  `com.alex.margaritaville.swift`, do not swap to an old OceanKey bundle id.
  That is a signing/provisioning blocker, not an app-code blocker.
- For build/install checks, use:

```sh
xcodegen generate
xcodebuild -project MargaritavilleSwift.xcodeproj -scheme MargaritavilleSwift -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath .build/DerivedDataDevice -allowProvisioningUpdates build
xcrun devicectl device install app --device 85E776B1-9069-5E68-BC3A-3BCAA4AAB870 .build/DerivedDataDevice/Build/Products/Debug-iphoneos/MargaritavilleSwift.app
xcrun devicectl device process launch --device 85E776B1-9069-5E68-BC3A-3BCAA4AAB870 --terminate-existing com.alex.margaritaville.swift
```

## Build Number Discipline

- Increment `CURRENT_PROJECT_VERSION` in `project.yml` for every installed build.
- Keep the in-app changelog updated when the user-facing behavior changes.
- Commit each coherent migration block separately.
- If a Git remote exists, push after committed checkpoints. If no remote exists,
  state that clearly.

## Architecture Rules

- Prefer feature-first modular Swift files. Keep files below 300 lines when
  practical and under 400 lines unless there is a strong reason.
- Keep domain logic out of SwiftUI views.
- Shared resource-heavy behavior must go through shared runtime/services, not
  ad hoc per-view loops.
- Local-first data is the source of truth. Cloud sync must not overwrite newer
  local edits with stale remote snapshots.
- Media files are local-only by default unless Alex explicitly changes that.
- For shared OceanKeySwift/MargaritavilleSwift foundation work, follow
  `Docs/SharedFoundationPlan.md`: classify each new visual/effect/frontend
  feature as `shared-foundation`, `shared-parameterized`, `app-specific`, or
  `candidate`. Ask Alex before sharing `candidate` features or when a boundary
  choice could affect future reuse, persistence, sync, app identity, screen
  routing, or workflow rules. Do not ask for obvious one-sided cases. Never let
  shared code depend on app bundle IDs, storage paths, hotel IDs, or
  target-specific screens.

## Port The Idea, Not The Code (Flutter → Swift)

The Flutter app is a reference for BEHAVIOR and domain rules (what the user sees
and does), NOT a code or architecture template. Port the idea; implement it the
idiomatic Swift/iOS way. A literal Flutter port is technical debt and must be
re-thought, not copied.

For every node ask "how is this done correctly in Swift/iOS", not "how was it in
Flutter". Concrete port anti-patterns → native replacement:

- State: do NOT recreate ChangeNotifier/setState or manual notify — use
  Observation (`@Observable`/`@Bindable`).
- Storage: do NOT mirror SharedPreferences + a hand-rolled JSON snapshot
  rewritten in full on every change — use SwiftData (incremental, off-main);
  settings via `@AppStorage` or an idiomatic store.
- Concurrency: do NOT port Future/completion chains — use async/await + Swift
  Concurrency; no blocking IO on the main thread.
- Callbacks: do NOT reproduce Flutter callback-hell (dozens of onX closures
  threaded through layers) — use small `@Observable` ViewModels with actions and
  Environment.
- Audio/camera/speech: do NOT host low-level engines inside views — use native
  services; for record/transcribe prefer the file path (`AVAudioRecorder` →
  `SFSpeechURLRecognitionRequest`), not a live `AVAudioEngine` tap.
- Models: value types (`struct`) for the domain; UI geometry/style lives in
  presentation, not in domain models.
- Sync: do NOT model it after Firebase — Apple-first (CloudKit), local-first,
  idempotent.
- Effects: go through the shared runtime/service (SpriteKit host), not ad hoc per
  view.

If a node was already ported literally, re-think it by these rules while keeping
user-visible behavior and domain parity, and cover it with tests.

## Current Intent

When the user says "continue", "go to the final goal", "do everything", or
similar, interpret that as:

1. Inspect current `Docs/MigrationPlan.md`, `Docs/FlutterParityPlan.md`, and
   `git status`.
2. Pick the next missing item from the critical path.
3. Implement it.
4. Build and install on the physical iPhone when app code changed.
5. Commit the checkpoint.
6. Continue to the next migration gap if no blocker or explicit pause exists.
