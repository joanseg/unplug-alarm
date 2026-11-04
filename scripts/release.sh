#!/bin/bash
# Builds, notarizes and staples the app, then publishes build/UnplugAlarm.zip as a GitHub release.
# Needs SIGN_IDENTITY (a Developer ID Application identity), ASC_KEY_ID and ASC_ISSUER_ID;
# the key itself is read from ~/.appstoreconnect/private_keys/AuthKey_<ASC_KEY_ID>.p8.
set -euo pipefail
cd "$(dirname "$0")/.."

: "${ASC_KEY_ID:?}" "${ASC_ISSUER_ID:?}"
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Resources/Info.plist)
ZIP=build/UnplugAlarm.zip

scripts/build-app.sh
ditto -c -k --keepParent build/UnplugAlarm.app "$ZIP"
xcrun notarytool submit "$ZIP" --wait \
    --key ~/.appstoreconnect/private_keys/AuthKey_"$ASC_KEY_ID".p8 --key-id "$ASC_KEY_ID" --issuer "$ASC_ISSUER_ID"
xcrun stapler staple build/UnplugAlarm.app
spctl --assess --type execute --verbose build/UnplugAlarm.app
rm "$ZIP" && ditto -c -k --keepParent build/UnplugAlarm.app "$ZIP"
gh release create "v$VERSION" "$ZIP" --title "Unplug Alarm $VERSION" --notes "Download UnplugAlarm.zip, unzip it and move Unplug Alarm to Applications. See the README for first-run steps."
