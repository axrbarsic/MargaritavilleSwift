# Margaritaville Split Status

Date: 2026-06-11

## Current State

- Main OceanKeySwift is restored separately in `/Users/alex/Developer/OceanKeySwift`.
- Margaritaville has its own worktree in `/Users/alex/Developer/MargaritavilleSwift`.
- Margaritaville bundle id is `com.alex.margaritaville.swift`.
- The app boots directly into Margaritaville and does not show the hotel picker.
- The summary header keeps the OceanKey structure: settings button, center stats, edit-entry handle.

## Verified

- `xcodegen generate` succeeds.
- Simulator unit tests pass with `xcodebuild test`.
- XcodeBuildMCP simulator build/install/launch succeeds for `com.alex.margaritaville.swift`.

## Current External Blockers

- Physical iPhone currently reports `unavailable` through `xcrun devicectl list devices`.
- Device build for the new bundle id fails before app compilation with:
  - `No Accounts: Add a new account in Accounts settings.`
  - `No profiles for 'com.alex.margaritaville.swift' were found`
- Local provisioning profiles exist for old OceanKey/RoomManager identifiers, but not for `com.alex.margaritaville.swift`.
- Retrying with `-allowProvisioningDeviceRegistration` still fails with `No Accounts`.
- Do not use an old OceanKey bundle id as a shortcut; that would break the separate-app goal.

## Next Action

When Xcode can see the Apple account and iPhone is available, run:

```sh
Tools/install_on_iphone.sh
```
