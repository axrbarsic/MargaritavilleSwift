# MargaritavilleSwift Agent Instructions

## Session Role

- This repository session is the hands-on owner and executor of assigned
  MargaritavilleSwift checkpoints, not the command center.
- Build the technical plan, inspect and edit the product, write and run tests,
  build, install, and return only the evidence proportionate to the assigned
  checkpoint and its concrete risk.
- Do not hand normal implementation, tests, build, installation, or QA back to
  the command center. If externally blocked, exhaust safe in-session paths and
  report the exact missing user/system action.
- Preserve dirty state and stay inside the bounded checkpoint assigned by the
  command center. Do not commit or push unless Alex explicitly authorizes it.

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

## Bounded Checkpoint And Cost Discipline

- Work only on the bounded checkpoint assigned by Alex or the command center.
  After installing and reporting that checkpoint, stop for Alex's feedback; do
  not automatically begin the next migration gap.
- Default to install-first acceptance on Alex's physical iPhone. For visual or
  UX tuning, Alex's direct evaluation of the installed build is the primary QA.
- Use the cheapest sufficient gate. Reuse valid prior test results and signed
  artifacts when the relevant source has not changed.
- Do not add a UI-test harness, run multiple simulators/devices, perform
  quartile/pixel measurements, collect redundant screenshots, repeat passing
  tests, or run a full regression unless Alex explicitly asks or a concrete
  crash, data-loss, security, payment, or platform-compatibility risk requires
  it.
- Do not turn visual polish into an autonomous investigation. Build/install/
  launch, report the exact path for Alex to inspect, and wait for feedback.
- Before any verification step beyond a targeted test plus physical
  build/install/launch, state the specific risk it covers. If no specific risk
  can be named, skip it.
- After two failed attempts from the same causal class, stop patching and report
  the system boundary or blocker instead of starting a broader test campaign.

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

If Alex gives a small visual or UX request, handle only that request, install it,
report, and stop until Alex responds.

## Verification Rules

- Use the physical iPhone by default. Do not use the iOS Simulator unless Alex
  explicitly allows it.
- For a normal visual checkpoint, the default completion gate is: relevant
  targeted test only when needed, successful device build or reuse of a valid
  signed artifact, install over the existing app without deleting data, launch,
  and Alex's visual verdict. Do not substitute simulator evidence for this path.
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
- Every build installed for Alex must have its own in-app changelog entry tied
  to the exact build number and date, even when the checkpoint is primarily a
  fix rather than a new feature.
- Write every new changelog title and bullet only in Russian. Briefly state what
  was added, changed, and fixed in user-facing language; do not leave English
  release notes for new builds.
- Before device installation, verify that the artifact build number and the
  newest changelog entry match. A build without its Russian changelog entry is
  not ready to install.
- Commit or push only when Alex explicitly authorizes it.

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
5. Report the installed checkpoint and stop for Alex's feedback.
6. Commit, push, or continue to another migration gap only after explicit
   authorization from Alex.
