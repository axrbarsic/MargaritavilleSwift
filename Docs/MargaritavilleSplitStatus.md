# Margaritaville Split Status

Date: 2026-06-12

## Current State

- Main OceanKeySwift is restored separately in `/Users/alex/Developer/OceanKeySwift`.
- Margaritaville has its own worktree in `/Users/alex/Developer/MargaritavilleSwift`.
- Margaritaville bundle id is `com.alex.margaritaville.swift`.
- The local Xcode target, scheme, and test module are `MargaritavilleSwift`.
- The app boots directly into Margaritaville and does not show the hotel picker.
- The summary header keeps the OceanKey structure: settings button, center stats, edit-entry button.

## Verified

- `xcodegen generate` succeeds.
- Simulator unit tests pass with `xcodebuild test` on scheme `MargaritavilleSwift`.
- Generic iOS device build succeeds for permanent bundle id `com.alex.margaritaville.swift`.
- `Tools/install_on_iphone.sh` installs build `21` on Alex's iPhone 16 Pro Max
  with bundle id `com.alex.margaritaville.swift` and display name
  `Margaritaville`. The latest launch attempt was blocked only because the
  physical iPhone was locked; signing and installation succeeded.
- Simulator launch shows the live Matrix wallpaper behind the first screen instead of a black override.

## Current External Blockers

- No current blocker for basic debug install with the permanent bundle id.
- iCloud/CloudKit/Push capability activation is still blocked until the
  `com.alex.margaritaville.swift` provisioning profile includes those
  entitlements and the `iCloud.com.alex.margaritaville.swift` container.
- Do not use an old OceanKey bundle id as a shortcut; that would break the
  separate-app goal.

## Verified Signing Fallback

- A temporary debug build succeeds when overriding the bundle id to the existing
  profile `AXR.OCEANKEY`:

```sh
xcodebuild build \
  -project MargaritavilleSwift.xcodeproj \
  -scheme MargaritavilleSwift \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  -derivedDataPath .build/DerivedDataDeviceFallback \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=J6MW4855LU \
  PRODUCT_BUNDLE_IDENTIFIER=AXR.OCEANKEY
```

- The built app still displays as `Margaritaville`, but its bundle id is
  `AXR.OCEANKEY`.
- This is only a fallback for temporary device testing. The intended permanent
  bundle id remains `com.alex.margaritaville.swift`.

## Next Action

For the next physical install, run:

```sh
Tools/install_on_iphone.sh
```
