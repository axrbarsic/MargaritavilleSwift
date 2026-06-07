# OceanKeySwift Agent Instructions

## Language And Context

- Always answer Alex in Russian unless he explicitly asks otherwise.
- This repository is the native iOS rewrite of OceanKey.
- The Flutter reference app is `/Users/alex/Developer/OceanKeyFlutterRun`.
- Do not edit the Flutter app while porting unless Alex explicitly asks.
- Android and Web are frozen for this migration track until Alex changes that.

## Global Goal

The primary goal is full practical migration of OceanKey from Flutter to native
Swift/iOS, not completion of one isolated subtask.

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
- For build/install checks, use:

```sh
xcodegen generate
xcodebuild -project OceanKeySwift.xcodeproj -scheme OceanKeySwift -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath .build/DerivedDataDevice -allowProvisioningUpdates build
xcrun devicectl device install app --device 85E776B1-9069-5E68-BC3A-3BCAA4AAB870 .build/DerivedDataDevice/Build/Products/Debug-iphoneos/OceanKeySwift.app
xcrun devicectl device process launch --device 85E776B1-9069-5E68-BC3A-3BCAA4AAB870 com.alex.oceankey.swift
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

