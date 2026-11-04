#!/bin/bash
# Builds and signs build/UnplugAlarm.app. Override the signing identity with SIGN_IDENTITY.
set -euo pipefail
cd "$(dirname "$0")/.."

IDENTITY="${SIGN_IDENTITY:-F9539815412E3E242E23C5483201CA6C9C6B3110}"
APP=build/UnplugAlarm.app

swift build -c release
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Library/LaunchDaemons"
cp .build/release/UnplugAlarm .build/release/UnplugAlarmHelper "$APP/Contents/MacOS/"
cp Resources/Info.plist "$APP/Contents/"
cp Resources/xyz.pesso.unplugalarm.helper.plist "$APP/Contents/Library/LaunchDaemons/"
codesign --force --options runtime --identifier xyz.pesso.unplugalarm.helper --sign "$IDENTITY" "$APP/Contents/MacOS/UnplugAlarmHelper"
codesign --force --options runtime --sign "$IDENTITY" "$APP"
codesign --verify --strict "$APP"
echo "Built $APP"
