# Apple-First Sync Plan

## Decision

The native Swift rewrite does not migrate the Flutter Firebase sync stack.
Firebase is treated as old-platform infrastructure, not as an architecture
reference for the Swift app.

The Swift app keeps a local-first domain/repository boundary. Apple sync will
be added behind that boundary after the domain model and input flow are stable.

## Official Apple Direction

- CloudKit private database is the target for per-user iCloud data. Apple
  documents `CKDatabase` as the API surface for private, public, and shared
  databases: https://developer.apple.com/documentation/cloudkit/ckdatabase
- For Core Data-backed apps, `NSPersistentCloudKitContainer` can mirror a local
  persistent store to CloudKit: https://developer.apple.com/documentation/coredata/nspersistentcloudkitcontainer
- Apple documents that `NSPersistentCloudKitContainer` uses local persistent
  history to export local saves and import remote changes:
  https://developer.apple.com/documentation/technotes/tn3163-understanding-the-synchronization-of-nspersistentcloudkitcontainer
- Apple also documents sync debugging through Xcode logs/sysdiagnose:
  https://developer.apple.com/documentation/technotes/tn3164-debugging-the-synchronization-of-nspersistentcloudkitcontainer

## Architecture

1. Keep domain logic independent from CloudKit.
   - Room catalog.
   - Cart binding and room selection.
   - Room status/timeline/schedule/VIP rules.
   - Notes/media metadata.
   - Workday snapshots and event history.

2. Keep local persistence as the source of immediate truth.
   - UI updates optimistically from local state.
   - Sync never directly drives SwiftUI screens.
   - Remote changes enter through a repository/importer.

3. Add Apple sync as an infrastructure adapter.
   - Preferred first candidate: SwiftData's managed CloudKit path, because
     SwiftData uses the same CloudKit machinery behind the scenes while keeping
     the repository boundary native.
   - Keep the persisted SwiftData model compatible with CloudKit: don't rely on
     local-only uniqueness constraints, and keep relationships optional so
     CloudKit can process related changes in its own order.
   - Current AI visual preset drafts are stored as lightweight JSON in a
     separate SwiftData store configured for private CloudKit sync through
     `iCloud.com.alex.oceankey.swift`.
   - The preset store must report its real storage mode. If CloudKit store
     creation fails, UI must show local fallback instead of implying that
     Apple sync is active.
   - As of 2026-06-10, physical-device signing is blocked because the local
     provisioning profile `iOS Team Provisioning Profile:
     com.alex.oceankey.swift` contains neither `aps-environment` nor
     `com.apple.developer.icloud-*` entitlements and does not support the
     `iCloud.com.alex.oceankey.swift` container.
   - Build 104 keeps real CloudKit entitlements limited to simulator/future
     validation so physical iPhone installs keep working with Alex's Personal
     Team profile. AI/live-wallpaper preset protection is therefore a manual
     Files export path for now: the app writes a lightweight JSON backup
     document with preset/config data, and Alex can save that document to
     iCloud Drive through the system exporter.
   - Runtime code must not create any CloudKit-backed SwiftData container on
     physical Personal Team builds. Until the paid Developer Program
     entitlements exist, simulator builds may keep validating the CloudKit path
     while installed iPhone builds go directly to local fallback instead of
     probing CloudKit and risking a startup trap.
   - To unblock real iPhone sync, enable iCloud/CloudKit and Push Notifications
     for App ID `com.alex.oceankey.swift`, attach/create container
     `iCloud.com.alex.oceankey.swift`, regenerate/download the development
     provisioning profile, then run the device build again with
     `-allowProvisioningUpdates`.
   - `SwiftDataWorkSessionRepository.SyncMode` is now the explicit boundary for
     that future switch; default app construction still uses `.localOnly`.
   - Merge/conflict rules are tracked in `Docs/AppleSyncConflictPolicy.md` and
     must be treated as the contract before enabling real iCloud sync.
   - Fallback candidate: direct CloudKit `CKRecord`/custom zones if event log
     ordering and conflict rules need explicit control.

4. Sync only lightweight domain data.
   - Room/cart state, timestamps, notes, settings, history entries, visual
     snapshots.
   - Local-only media files unless a later product decision changes this.
   - AI-generated live wallpaper and VIP effect presets are config/code
     payloads, not video files. Backups should store those lightweight
     definitions plus current background settings, not rendered media.

## Readiness Gate

Before implementing CloudKit:

- Domain commands are covered by tests.
- The first input screen creates the same work-session state as the summary
  screen consumes.
- Legacy JSON has been upgraded behind the repository boundary; SwiftData can
  import existing local JSON without losing current installs.
- SwiftData schema is CloudKit-ready at the model-shape level, and the app now
  requests CloudKit sync by default through the repository boundary.
- The repository can now accept a future private CloudKit container identifier
  through a sync-mode parameter, while tests keep this path isolated from real
  iCloud by forcing in-memory storage to local-only.
- `Docs/AppleSyncConflictPolicy.md` documents the two-iPhone conflict policy.
