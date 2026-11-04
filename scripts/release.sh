#!/bin/bash
# Usage: scripts/release.sh <version>   e.g. scripts/release.sh 0.2.0
# Sets the version, commits and pushes it, then builds, notarizes, staples and publishes
# build/UnplugAlarm.zip as GitHub release v<version>.
# Reads SIGN_IDENTITY, ASC_KEY_ID and ASC_ISSUER_ID from the git-ignored release.env;
# the API key itself lives in ~/.appstoreconnect/private_keys/AuthKey_<ASC_KEY_ID>.p8.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:?Usage: scripts/release.sh <version>}"
source release.env
export SIGN_IDENTITY
: "${ASC_KEY_ID:?}" "${ASC_ISSUER_ID:?}"
ZIP=build/UnplugAlarm.zip

BUILD=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" Resources/Info.plist)
/usr/libexec/PlistBuddy -c "Set CFBundleShortVersionString $VERSION" -c "Set CFBundleVersion $((BUILD + 1))" Resources/Info.plist
git commit -m "Release $VERSION" -- Resources/Info.plist
git push

scripts/build-app.sh
ditto -c -k --keepParent build/UnplugAlarm.app "$ZIP"
xcrun notarytool submit "$ZIP" --wait \
    --key ~/.appstoreconnect/private_keys/AuthKey_"$ASC_KEY_ID".p8 --key-id "$ASC_KEY_ID" --issuer "$ASC_ISSUER_ID"
xcrun stapler staple build/UnplugAlarm.app
spctl --assess --type execute --verbose build/UnplugAlarm.app
rm "$ZIP" && ditto -c -k --keepParent build/UnplugAlarm.app "$ZIP"
gh release create "v$VERSION" "$ZIP" --title "Unplug Alarm $VERSION" --notes "Download UnplugAlarm.zip, unzip it and move Unplug Alarm to Applications. See the README for first-run steps."
