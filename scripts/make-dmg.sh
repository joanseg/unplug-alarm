#!/bin/bash
# Packs build/UnplugAlarm.app into build/UnplugAlarm.dmg: a window with the app next to an
# Applications shortcut over a background arrow, so users drag one onto the other. Signs the DMG with SIGN_IDENTITY.
set -euo pipefail
cd "$(dirname "$0")/.."

: "${SIGN_IDENTITY:?}"
NAME="Unplug Alarm"
STAGE=build/dmg
RW=build/UnplugAlarm-rw.dmg
DMG=build/UnplugAlarm.dmg

rm -rf "$STAGE" "$RW" "$DMG"
mkdir -p "$STAGE"
cp -R build/UnplugAlarm.app "$STAGE/$NAME.app"
ln -s /Applications "$STAGE/Applications"
mkdir "$STAGE/.background"
cp Resources/dmg-background.tiff "$STAGE/.background/background.tiff"

hdiutil create -quiet -volname "$NAME" -srcfolder "$STAGE" -fs HFS+ -format UDRW "$RW"
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "$RW" | awk '/Apple_HFS/ {print $1}')
# Window bounds include the ~32-point title bar on top of the 540×300 background (scripts/make-art.swift).
osascript <<EOF
tell application "Finder"
    tell disk "$NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {200, 200, 740, 532}
        set opts to icon view options of container window
        set arrangement of opts to not arranged
        set icon size of opts to 112
        set text size of opts to 13
        set background picture of opts to file ".background:background.tiff"
        set position of item "$NAME.app" of container window to {140, 125}
        set position of item "Applications" of container window to {400, 125}
        update without registering applications
        delay 1
        close
    end tell
end tell
EOF
sync
hdiutil detach -quiet "$DEVICE"
hdiutil convert -quiet "$RW" -format UDZO -o "$DMG"
rm "$RW"
codesign --force --timestamp --sign "$SIGN_IDENTITY" "$DMG"
echo "Built $DMG"
