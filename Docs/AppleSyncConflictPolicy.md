# Apple Sync Conflict Policy

## Goal

Native iCloud sync must be local-first and idempotent. A local edit on one
iPhone should appear on another iPhone quickly, but an older cloud import must
not erase fresher local room or cart work.

## Unit Of Merge

Merge small domain records, not one whole-day blob:

- Workday selection lock state.
- Cart binding and selected room membership.
- Room fields: opened state, S/L/B tasks, VIP flag, scheduled time.
- Room timeline milestones: selected, opened, stripped, linen, balcony, done.
- Room notes, voice transcript, and local media metadata.
- Cart notes, consumables, and local media metadata.
- Event history entries.

Local media files stay device-local unless a later product decision changes
that. Sync may move media metadata, but not photo/video bytes.

## Ordering

Every mutable domain field needs an update timestamp. Merge compares the field's
timestamp, not only the containing cart or work-session timestamp.

Current native coverage includes room open state, S/L/B task state, VIP state,
and scheduled room time as explicit field-timestamped values, alongside
existing room milestone, note, media, cart note, and cart consumable timestamps.
Setup selection coverage now includes cart binding timestamps, room selection
timestamps, deselection tombstones, and workday lock timestamps.
The native domain now includes `WorkSessionMergePolicy`, which exercises these
rules before the CloudKit adapter exists.
SwiftData migration keeps legacy setup selection rows active when their new
selected/deselected flag is absent, preventing upgrade-time data loss.
The repo now connects the CloudKit entitlement for
`iCloud.com.alex.margaritaville.swift`, declares `remote-notification` background
mode, and prepares a separate AI visual preset SwiftData store for private
CloudKit sync. Physical iPhone signing is blocked until the
`com.alex.margaritaville.swift` development provisioning profile includes iCloud,
CloudKit, Push Notifications, and the `iCloud.com.alex.margaritaville.swift`
container. Local-first remains the behavioral rule: if CloudKit cannot open on a
simulator, iCloud-signed profile, or signed-out device, the app must expose that
fallback clearly instead of pretending data is already online.

Default rule:

- Newer field timestamp wins.
- Equal timestamp keeps the local value, so repeated imports are idempotent.
- Missing remote timestamp never overwrites a local timestamped field.
- Unknown remote fields are ignored until the app version knows how to read
  them.

## Milestones

Room timeline milestones are facts. Do not delete a milestone just because a
remote snapshot is missing it.

Default rule:

- If one side has a milestone and the other does not, keep the existing
  milestone.
- If both sides have the same milestone, keep the earlier timestamp for
  "first happened" events such as selected/opened/stripped/linen/balcony/done.
- A status rollback must be represented by a new explicit command, not by
  removing old milestone facts during merge.

## Room Status

Room visual status is derived from fields after merge:

- Scheduled time has priority until it becomes due.
- Ready requires opened plus all S/L/B tasks.
- In-progress requires any S/L/B task.
- Open requires opened.
- Pending is the fallback.

Merge should not store a separate color/status field that can drift from the
rules above.

## Event History

History entries are append-only and identified by stable event IDs.

Default rule:

- Union by event ID.
- Preserve happened-at timestamps.
- Keep lightweight visual snapshots for reading history on the move.
- Never use history replay as the only source of current room state; current
  state is merged from the domain records above.

## Safety Gate

Before enabling iCloud for installed builds:

- The app must have field-level timestamps for every mutable synced field.
- Cloud imports must enter through the repository boundary, not directly into
  SwiftUI views.
- Two-device tests must cover same-room edits, schedule due transitions, cart
  consumables, notes, and history union.
- The fallback path must keep the app usable local-only if iCloud is disabled,
  unavailable, or signed out.
