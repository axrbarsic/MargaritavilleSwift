# Shared Foundation Plan

Date: 2026-06-13

## Goal

OceanKeySwift and MargaritavilleSwift must stay fully independent installed apps,
with separate bundle IDs, signing, storage, CloudKit containers, work sessions,
and app-specific screens. They should still be able to reuse high-quality
foundation work such as live wallpapers, VIP effects, audio/haptics, media
viewers, settings controls, diagnostics, and other platform services without
manual copy-paste.

## Decision

The long-term architecture should be:

```text
Shared Swift Packages
  - shared contracts, domain primitives where truly common
  - design tokens and reusable controls
  - effects runtime, wallpapers, VIP effects
  - interaction feedback, audio/haptics
  - media services and viewers
  - diagnostics/performance infrastructure

OceanKeySwift app shell
  - bundle id, signing, storage root, CloudKit container
  - OceanKey hotel profile and S/L/B workflow
  - long rectangular room-cell layout policy
  - OceanKey-specific settings defaults and copy

MargaritavilleSwift app shell
  - bundle id, signing, storage root, CloudKit container
  - Margaritaville hotel profile and simple-cycle workflow
  - 4-column square room-tile layout policy
  - Margaritaville-specific settings defaults and copy
```

Use local Swift Package Manager packages as the sharing boundary first. This is
the native Xcode/Swift path for reusable modules, works locally before any
remote repo split, and can later be moved to a private Git repo if needed.

## Decision Rubric

Classify a feature as shared only when the answer is "yes" to all durable
questions:

1. Can it run without knowing the app bundle ID, display name, hotel ID, storage
   directory, CloudKit container, or signing profile?
2. Can both apps describe their differences through value contracts or policies
   instead of `if app == ...` branches inside shared code?
3. Does sharing reduce duplication without forcing both apps into the same
   screen flow, room layout, workflow state machine, or copy?
4. Can it be tested with at least one OceanKey-shaped case and one
   Margaritaville-shaped case?

If any answer is "no", keep it in the app shell or expose a smaller shared
contract first.

## Portability Classes

Every new feature must be classified before implementation:

- `shared-foundation`: portable by default. Examples: Matrix/TV/video wallpaper
  engines, VIP effect renderer, haptics/audio service, media viewer, performance
  telemetry.
- `shared-parameterized`: shared implementation with app-specific policy.
  Examples: room-cell visual effect that needs separate geometry adapters for
  OceanKey full-width bars and Margaritaville square tiles.
- `app-specific`: must not auto-port. Examples: hotel catalog, room workflow,
  cart setup rules, storage identifiers, bundle IDs, CloudKit containers,
  notification copy, app name, screen structure.
- `candidate`: unclear. The agent must ask Alex before making it shared.

## Automation Rule

When a feature is `shared-foundation` or `shared-parameterized`, implement it in
the shared package and expose app-specific knobs through small value contracts:

```swift
struct RoomVisualSurface {
    var shape: RoomTileShape
    var sizeClass: RoomTileSizeClass
    var status: RoomStatus
    var isVIP: Bool
}

protocol RoomVisualPolicy {
    func surface(for room: RoomCell) -> RoomVisualSurface
}
```

The effect or control reads the shared surface contract, not an OceanKey or
Margaritaville view directly. That is what lets one effect travel to both apps
without forcing both apps to have the same cell geometry.

## Guardrails

- The highest priority is app isolation. Automatic sharing is allowed only
  through an explicit shared package boundary, never through file copying
  between app targets.
- Dangerous runtime identity values are app-shell only: bundle IDs, signing
  fallback IDs, CloudKit containers, Application Support directory names,
  notification prefixes, URL/UTType identifiers, app display names, and hotel
  IDs must never live in shared packages.
- If a feature can affect persistence, signing, sync, notifications, or app
  identity, classify it as `app-specific` unless there is a deliberate shared
  contract and test coverage for both apps.
- Shared packages must not import either app target.
- App targets may import shared packages and provide adapters/policies.
- Shared code must not know app bundle IDs, storage paths, hotel IDs, or
  CloudKit containers.
- App-specific identity must flow through an `AppIdentity` or equivalent app
  shell object.
- New shared effects need tests or previews for at least:
  - OceanKey rectangular room surface.
  - Margaritaville square room surface.
- Visual UI work must use the global `mobile-ui-visual-qa` workflow with
  simulator screenshots before/after when practical.

## Practical Migration Order

1. Finish hardening Margaritaville as an independent app shell.
2. Create a sibling local package, for example:

```text
/Users/alex/Developer/OceanKeySharedFoundation
  Package.swift
  Sources/
    OceanKeyCore/
    OceanKeyDesign/
    OceanKeyEffects/
    OceanKeyInteraction/
    OceanKeyMedia/
    OceanKeyDiagnostics/
  Tests/
```

3. Move leaf modules first: diagnostics, feedback, simple design tokens, media
   viewer helpers.
4. Move visual effects next behind geometry/status contracts.
5. Keep domain workflows in app shells until they have a truly shared contract.
6. Wire both `project.yml` files to the same local package path.
7. Add a CI/local guard that fails if shared packages import app targets or if
   app-specific identifiers appear in shared sources.

## References

- Shared foundation audit: `Docs/SharedFoundationAudit.md`
- Apple local packages:
  https://developer.apple.com/documentation/xcode/organizing-your-code-with-local-packages
- Swift Package Manager:
  https://docs.swift.org/swiftpm/documentation/packagemanagerdocs/
- Apple multiple projects/dependencies:
  https://developer.apple.com/documentation/xcode/managing-multiple-projects-and-their-dependencies
- XcodeGen project specification:
  https://github.com/yonaskolb/XcodeGen

## Local Guard

Run `Tools/verify_independence.sh` before committing independence or shared
foundation changes. The guard is intentionally conservative around dangerous
runtime identifiers and now expects the local app target, scheme, and test
module to be `MargaritavilleSwift`.

## Agent Rule

When Alex asks for a new visual/effect/frontend feature, the agent must state
which portability class it chose. If the class is `candidate`, ask whether the
feature is shared or app-only before implementation.

Ask Alex before implementation when a feature could plausibly belong to either
one app or the shared foundation and the choice affects future reuse,
persistence, sync, app identity, screen flow, or workflow rules. Do not ask for
obvious cases: clearly generic platform services can be shared through the
package boundary, and clearly hotel-specific behavior stays in the app shell.
