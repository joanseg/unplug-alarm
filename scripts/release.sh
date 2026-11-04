#!/bin/bash
# Usage: scripts/release.sh <version>   e.g. scripts/release.sh 0.2.0
# Sets the version, commits and pushes it, then builds and notarizes the app, packs it into
# build/UnplugAlarm.dmg, notarizes that too, and publishes it as GitHub release v<version>.
# Reads SIGN_IDENTITY, ASC_KEY_ID and ASC_ISSUER_ID from the git-ignored release.env;
# the API key itself lives in ~/.appstoreconnect/private_keys/AuthKey_<ASC_KEY_ID>.p8.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:?Usage: scripts/release.sh <version>}"
source release.env
export SIGN_IDENTITY
: "${ASC_KEY_ID:?}" "${ASC_ISSUER_ID:?}"
ZIP=build/UnplugAlarm.zip
DMG=build/UnplugAlarm.dmg
notarize() {
    xcrun notarytool submit "$1" --wait \
        --key ~/.appstoreconnect/private_keys/AuthKey_"$ASC_KEY_ID".p8 --key-id "$ASC_KEY_ID" --issuer "$ASC_ISSUER_ID"
}

BUILD=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" Resources/Info.plist)
/usr/libexec/PlistBuddy -c "Set CFBundleShortVersionString $VERSION" -c "Set CFBundleVersion $((BUILD + 1))" Resources/Info.plist
git commit -m "Release $VERSION" -- Resources/Info.plist
git push

scripts/build-app.sh
ditto -c -k --keepParent build/UnplugAlarm.app "$ZIP"
notarize "$ZIP"
xcrun stapler staple build/UnplugAlarm.app
spctl --assess --type execute --verbose build/UnplugAlarm.app

scripts/make-dmg.sh
notarize "$DMG"
xcrun stapler staple "$DMG"
spctl --assess --type open --context context:primary-signature --verbose "$DMG"
SHA=$(shasum -a 256 "$DMG" | cut -d' ' -f1)
gh release create "v$VERSION" "$DMG" --title "Unplug Alarm $VERSION" --notes "Download UnplugAlarm.dmg, open it and drag Unplug Alarm into Applications. See the README for first-run steps.

SHA-256 of UnplugAlarm.dmg: \`$SHA\`"
