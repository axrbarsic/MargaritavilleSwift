#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE_ID="${DEVICE_ID:-85E776B1-9069-5E68-BC3A-3BCAA4AAB870}"
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
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$DERIVED_DATA" \
  -allowProvisioningUpdates

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
