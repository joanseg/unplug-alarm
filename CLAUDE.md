# CLAUDE.md

macOS menu-bar app (SwiftPM, no Xcode project) that sounds a siren when the charger is pulled, with a privileged
helper that runs `pmset disablesleep` while armed so it also works with the lid closed. See README.md.

⚠️ **This repo is public.** Never commit signing identities, API key IDs, issuer IDs, `.p8` keys or emails.
Those live only in the git-ignored `release.env` at the repo root.

## Build and run (development)

```sh
source release.env && SIGN_IDENTITY="$DEV_SIGN_IDENTITY" scripts/build-app.sh
pkill -f 'MacOS/UnplugAlarm$'; sleep 1; open build/UnplugAlarm.app
```

- Without the `sleep 1`, `open` fails with `-600` because the old copy is still exiting.
- Don't run the app via a `!` command or `swift run` in Claude's shell — it gets killed or duplicated. Launch it detached.
- Logs: `log stream --level info --predicate 'subsystem == "unplug-alarm" OR process == "UnplugAlarmHelper"'`.
- Check sleep state: `pmset -g | grep SleepDisabled` (`1` only while armed).

## Release

When asked to "release a new version":

1. Make sure the work is committed and pushed and `release.env` exists (if missing, ask the owner — it is not in git).
2. Run `scripts/release.sh <version>` with the next version (current one: `Resources/Info.plist`
   `CFBundleShortVersionString`; `gh release list` shows what's published). It bumps and pushes the version,
   builds with the Developer ID identity, notarizes with the App Store Connect key, staples, and creates GitHub
   release `v<version>` with `UnplugAlarm.dmg` (app and DMG are each notarized). Takes a few minutes.
3. Confirm: `curl -sIL https://github.com/joanseg/unplug-alarm/releases/latest/download/UnplugAlarm.dmg` returns 200.

## Gotchas

- `scripts/make-dmg.sh` lays out the DMG window by scripting Finder (needs Automation permission for Finder). Eject any
  mounted "Unplug Alarm" volume first, or Finder targets the wrong disk. Art comes from `swift scripts/make-art.swift`.
- **The helper is tied to the app's path.** Moving the app, or switching its signature (development ↔ Developer ID),
  can require re-approving it in System Settings → Login Items. Symptom: menu says "Lid closed: not protected".
- The helper accepts only clients signed by team `35XAX3CSKK` with bundle ID `xyz.pesso.unplugalarm`
  (`Sources/UnplugAlarmHelper/main.swift`).
- Creating Developer ID certificates needs the team's Account Holder in person; the API key gets 403.
- An App Store Connect `403 PLA_NOT_ACCEPTED` means the Account Holder must accept the new agreement at
  developer.apple.com.
- `IOPMSetSystemPowerSetting` is not in the public SDK headers, which is why the helper shells out to `/usr/bin/pmset`.
