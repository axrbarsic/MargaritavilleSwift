# Flutter Parity Plan

## Rule

The Flutter application in `/Users/alex/Developer/OceanKeyFlutterRun` is the
visual and behavioral reference while the native iOS rewrite is still catching
up. Do not edit the Flutter project during the port.

All validation for this track targets the physical iPhone. Do not use the iOS
Simulator unless explicitly allowed.

## Transfer Order

1. Main summary screen
   - Header count strip and left/right controls.
   - Cart header: `Тележка N` on the left, territory/building on the right.
   - Room cell status colors, spacing, typography, S/L/B task controls.
   - Right swipe action menu, one open menu by default.
   - Room timeline chips and schedule badge.

2. Room cell domain behavior
   - Open/yellow/red/blue/green/pink status rules.
   - Milestone timestamps: selected, opened, stripped, linen, balcony, done.
   - Scheduled room transition behavior.
   - VIP state and effects.

3. Notes and media
   - Text notes.
   - Voice notes with transcription.
   - Photo and video capture with local-only storage.
   - Full-screen vertical media viewer.

4. Cart details
   - Long press on cart header opens cart-specific details.
   - Cart notes, consumables placeholder, photo/video capture.
   - Completion markers and timestamps.

5. Settings and diagnostics
   - Developer diagnostics.
   - Build/version changelog.
   - Visual effect settings only after the native effect runtime is stable.

6. Persistence and sync
   - Local-first storage.
   - Apple-first sync evaluation through iCloud/CloudKit.
   - Firebase bridge only if needed for migration.

## Current Native Checkpoint

- SpriteKit/GameplayKit effect host exists.
- Main screen uses a SpriteKit Matrix background.
- Room cells now use the Flutter status palette.
- Room cells support open state, S/L/B task toggles, VIP toggle, schedule toggle,
  timeline fields, schedule badge, and a right-swipe action menu.
- Only one action menu is open at a time.
- Native state now loads from and saves to a local JSON repository in Application
  Support. This is the first local-first source-of-truth layer for the Swift
  rewrite.
- Header settings opens a native Settings screen with developer/build info and
  local storage status.
- Room details text notes and voice-transcript drafts are now domain data and
  persist through the local work-session repository.
- Long press on a cart header opens a native cart details screen with persistent
  cart note, consumables placeholder, and media action slots.
- Cart details media can capture local-only photos/videos through the native
  camera bridge, stores files in Application Support, and shows vertical
  thumbnail previews.
- Room swipe menu now opens the same native local media capture flow for room
  photo/video attachments.
