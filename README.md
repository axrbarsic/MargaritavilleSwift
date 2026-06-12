# MargaritavilleSwift

Standalone native SwiftUI/iOS app for the Margaritaville housekeeping workflow.

This repository is intentionally separate from OceanKeySwift. The two hotel
apps should not be mixed into one codebase unless that becomes an explicit
product decision later.

## What It Does

- Tracks rooms, carts, room work states, notes, media, schedules, and history
  for a hotel housekeeping workflow.
- Uses SwiftUI, Observation, SwiftData, AVFoundation, Speech,
  UserNotifications, SpriteKit, and Apple-native app infrastructure.
- Keeps state local-first while the CloudKit/iCloud sync path is still gated by
  signing and provisioning capabilities.

## Requirements

- macOS with Xcode installed.
- XcodeGen (`brew install xcodegen`).
- An Apple ID for local device signing.

A paid Apple Developer Program membership is not required to build and install
the app on your own iPhone through Xcode's Personal Team signing. App Store,
TestFlight, Push Notifications, and some iCloud/CloudKit capabilities require a
paid Apple Developer Program account.

## Build

```sh
xcodegen generate
xcodebuild build \
  -project MargaritavilleSwift.xcodeproj \
  -scheme MargaritavilleSwift \
  -configuration Debug \
  -destination 'generic/platform=iOS'
```

To install on your own iPhone from Xcode, open `MargaritavilleSwift.xcodeproj`,
select your Apple ID team, and change the bundle identifier from
`com.alex.margaritaville.swift` to one that belongs to you.

## Tests

```sh
xcodegen generate
xcodebuild test \
  -project MargaritavilleSwift.xcodeproj \
  -scheme MargaritavilleSwift \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'
```

## Repository Notes

- OceanKeySwift is a separate Washington/OceanKey app and should remain in its
  own repository.
- Do not commit local secrets, provisioning profiles, or personal signing files.

## License

MIT. See `LICENSE`.
