# Shared Foundation Audit

Date: 2026-06-13

Scope: `/Users/alex/Developer/OceanKeySwift` and
`/Users/alex/Developer/MargaritavilleSwift`.

## Executive Summary

The two apps are in the right shape for shared foundation work: they are separate
repos with separate remotes, but many modules have the same feature boundaries
and names. The safe path is not to merge the apps. The safe path is to extract a
third local Swift package and let each app import it through explicit adapters.

The main future conflict risk is not duplicated code. The main risk is shared
code accidentally owning app identity, persistence identity, sync identity, or
hotel workflow policy. Those must remain in each app shell.

## How To Decide

I classify code by asking what would break if the same module were imported by
both apps tomorrow.

- If the code only needs platform capability, generic domain state, or a small
  value contract, it can be shared.
- If the code needs app identity, hotel identity, room catalog policy, workflow
  policy, storage path, signing, CloudKit, notifications, or screen routing, it
  stays app-specific.
- If the code is visually similar but geometry or behavior differs, it becomes
  `shared-parameterized`: common renderer or service, app-specific policy.
- If the answer is unclear, it is `candidate` and must not be moved until both
  apps have used the pattern at least once.

## Current Shared-Foundation Candidates

These modules are good first extraction candidates because they are already
parallel across both apps and are mostly platform/service code:

- `Infrastructure/Diagnostics/RuntimeDiagnostics.swift`
- `Infrastructure/Performance/PerformanceTelemetryStore.swift`
- `Infrastructure/Interaction/HoldActionTarget.swift`
- `Infrastructure/Interaction/InteractionFeedbackService.swift`
- `Infrastructure/Speech/VoiceTranscriptionContracts.swift`
- `Infrastructure/Speech/VoiceTranscriptionService.swift`
- `Features/Media/CameraCaptureView.swift`
- `Features/Media/MediaThumbnailView.swift`
- `Features/Media/MediaViewerScreen.swift`
- `Features/Notes/VoiceNoteBubble.swift`
- `Features/Notes/VoiceNoteViewModel.swift`
- `Features/Notes/VoiceTranscriptionPanel.swift`
- `Effects/SpriteKit/MatrixRainConfiguration.swift`
- `Effects/SpriteKit/MatrixRainConfigurationEnvironment.swift`
- `Effects/SpriteKit/MatrixRainSpriteScene.swift`
- `Effects/SpriteKit/SpriteKitEffectView.swift`
- `Effects/VIPJellyContentWarp.metal`

Extraction requirement: replace hard-coded logger subsystems, storage roots, and
display copy with injected `AppIdentity`/policy values before moving.

## Shared-Parameterized Candidates

These are worth sharing, but only behind contracts because the two apps have
different geometry, workflows, and summary layouts:

- `Design/OceanKeyTheme.swift`
- `Design/RoomCellGeometry.swift`
- `Domain/CartConsumables.swift`
- `Domain/RoomModels.swift`
- `Domain/RoomScheduleSelection.swift`
- `Domain/WorkSessionHistory.swift`
- `Domain/WorkSessionMergePolicy.swift`
- `Domain/WorkSessionSelection.swift`
- `Domain/WorkSessionSnapshot.swift`
- `Data/PersistentWorkSessionMapper*.swift`
- `Data/SwiftDataWorkSessionRepository.swift`
- `Data/LocalMediaFileStore.swift`
- `Data/BackgroundVideoFileStore.swift`
- `Data/AIVisualPresetStore.swift`
- `Features/CartDetails/*`
- `Features/History/WorkSessionHistoryScreen.swift`
- `Features/RoomDetails/*`
- `Features/Summary/RoomMediaIndicator.swift`
- `Features/Summary/RoomActionPuzzlePullOverlay.swift`
- `Features/Summary/RoomActionMenuLampTransition.swift`
- `Features/Summary/SummaryActionMenuExpansion.swift`
- `Features/Summary/SummarySelectionPuzzleHandle.swift`
- `Features/Summary/SummarySwipeCommitPolicy.swift`

Extraction requirement: define app-provided policies for workflow kind,
room-surface geometry, status palette, route titles, and persistence identity.

## App-Specific: Do Not Share Directly

These must stay in the app shells:

- `project.yml`, `.entitlements`, `Info.plist`, install scripts, signing IDs.
- `App/*SwiftApp.swift` and `App/AppRootView.swift`.
- `App/AppBuildInfo.swift`, build changelog entries, and display names.
- `App/AppSettingsStore*` until settings keys are namespaced by app identity.
- `Data/*PresetBackupDocument.swift` because exported document names and app
  labels differ.
- `Infrastructure/Secrets/KeychainSecretStore.swift` defaults until the service
  is injected per app.
- `Infrastructure/Notifications/ScheduleNotificationService.swift` defaults
  until notification titles and identifiers are injected per app.
- `Infrastructure/Sync/AppleSyncConfiguration.swift` and entitlement decisions.
- `Domain/RoomCatalog.swift` and hotel room catalogs.
- Margaritaville-only: `Domain/HotelProfile.swift`,
  `Domain/HousekeeperCatalog.swift`, `Domain/RoomCatalogOverride.swift`,
  `Domain/RoomDayCategory*.swift`, `Features/WorkSetup/*`,
  `Features/Summary/Margaritaville*`, and consumables summary ticker/report UI.
- OceanKey-only: S/L/B room workflow presentation and OceanKey-specific
  DeepSeek activation rows currently hidden from Settings.

## Never Put In Shared Packages

- `com.alex.oceankey.swift`
- `com.alex.margaritaville.swift`
- `AXR.OCEANKEY`
- `iCloud.com.alex.oceankey.swift`
- `iCloud.com.alex.margaritaville.swift`
- Application Support folder names such as `OceanKeySwift`.
- Keychain service names.
- Backup document identifiers and exported filenames.
- Notification identifiers and user-facing notification copy.
- Hotel IDs, hotel names, room catalog contents, or setup screen routing.

## Near-Term Extraction Order

1. Create `/Users/alex/Developer/OceanKeySharedFoundation` as a local Swift
   package.
2. Move diagnostics and performance telemetry first.
3. Move interaction feedback after app identity injection replaces hard-coded
   logger subsystem usage.
4. Move media capture/viewer helpers.
5. Move voice note service/contracts.
6. Move Matrix/SpriteKit effects behind a small rendering contract.
7. Only then consider domain model extraction, starting with value types and
   merge-policy tests.

## Current Hygiene Findings

- OceanKeySwift did not have a local `SharedFoundationPlan.md`; this audit adds
  one so both apps carry the same architecture rule.
- Margaritaville already has `Tools/verify_independence.sh`; OceanKey needs the
  same guard on its side.
- Margaritaville had ignored Vim swap files in the working tree; they were
  untracked generated files and should not be kept around.
- The apps must remain separate clones/remotes. Linked worktrees or shared git
  state are explicitly forbidden for this pair.
