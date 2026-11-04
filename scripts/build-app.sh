#!/bin/bash
# Builds and signs build/UnplugAlarm.app with the identity in SIGN_IDENTITY.
set -euo pipefail
cd "$(dirname "$0")/.."

IDENTITY="${SIGN_IDENTITY:?Set SIGN_IDENTITY to a codesigning identity (see README)}"
APP=build/UnplugAlarm.app

swift build -c release
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Library/LaunchDaemons"
cp .build/release/UnplugAlarm .build/release/UnplugAlarmHelper "$APP/Contents/MacOS/"
cp Resources/Info.plist "$APP/Contents/"
cp Resources/AppIcon.icns "$APP/Contents/Resources/"
cp Resources/xyz.pesso.unplugalarm.helper.plist "$APP/Contents/Library/LaunchDaemons/"
codesign --force --timestamp --options runtime --identifier xyz.pesso.unplugalarm.helper --sign "$IDENTITY" "$APP/Contents/MacOS/UnplugAlarmHelper"
codesign --force --timestamp --options runtime --sign "$IDENTITY" "$APP"
codesign --verify --strict "$APP"
echo "Built $APP"
