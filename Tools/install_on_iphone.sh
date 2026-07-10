#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE_ID="${DEVICE_ID:-81B4DF0D-A9BE-5131-93C8-8247618F9428}"
# xcodebuild's own device identifier (ECID-based), distinct from devicectl's UUID
# above. A generic 'generic/platform=iOS' destination never registers a specific
# device with the developer portal, so a newly connected iPhone's UDID never
# lands in the auto-managed provisioning profile. Targeting the device explicitly
# here plus -allowProvisioningDeviceRegistration is what actually registers it.
XCODE_DEVICE_ID="${XCODE_DEVICE_ID:-00008150-001418301E68C01C}"
BUNDLE_ID="com.alex.margaritaville.swift"
PROJECT_PATH="MargaritavilleSwift.xcodeproj"
SCHEME="MargaritavilleSwift"
DERIVED_DATA=".build/DerivedDataDevice"
APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphoneos/MargaritavilleSwift.app"

cd "$ROOT_DIR"

echo "==> Generating Xcode project"
xcodegen generate

echo "==> Building for physical iPhone"
xcodebuild build \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "id=$XCODE_DEVICE_ID" \
  -derivedDataPath "$DERIVED_DATA" \
  -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration

echo "==> Built app metadata"
/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_PATH/Info.plist"
/usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' "$APP_PATH/Info.plist"
/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP_PATH/Info.plist"

echo "==> Devices"
xcrun devicectl list devices

echo "==> Installing on $DEVICE_ID"
xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH"

echo "==> Launching $BUNDLE_ID"
xcrun devicectl device process launch --device "$DEVICE_ID" --terminate-existing "$BUNDLE_ID"
