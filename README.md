# Unplug Alarm

A tiny macOS menu-bar app that sounds a loud siren when someone pulls your MacBook's charger.
Arm it in a café, a library or a co-working space. If someone unplugs the Mac to walk off with it,
it wails until you disarm it with Touch ID or your password — **even with the lid closed.**

## How it works

- **Detects the cable.** macOS notifies the app the moment the Mac switches from AC power to battery.
- **Rings loudly.** A generated siren loops at the volume you pick; the system volume is set to it and unmuted when it fires.
- **Only you can stop it.** Disarming asks for Touch ID or your Mac password. Plugging the cable back in does not stop it.
- **Works with the lid closed.** On battery, macOS normally sleeps the instant the lid is shut. While armed, a small helper
  switches system sleep off (`pmset disablesleep 1`) and switches it back on when you disarm or quit, or if the app crashes.

## Requirements

- macOS 15 (Sequoia) or later
- A MacBook (it needs a battery to notice the charger going away)

## Install

1. Download **UnplugAlarm.dmg** from the [latest release](https://github.com/joanseg/unplug-alarm/releases/latest).
2. Open it. In the window that appears, drag **Unplug Alarm** onto the **Applications** folder — do this *before* the
   first run, because the helper is tied to where the app lives. Then eject the disk image.
3. Open Unplug Alarm from Applications. macOS asks *"Unplug Alarm is an app downloaded from the internet. Are you sure
   you want to open it?"* — click **Open**. The app is signed with Developer ID and notarized by Apple.
4. A padlock appears in the menu bar. That's the app; it has no window and no Dock icon.

Then follow **First run: approve the helper** below.

**Updating:** quit the app, replace it in Applications with the new version, and open it again.

### From source

For developers. You need Xcode (Swift 6.2+) and an Apple signing certificate.

```sh
git clone https://github.com/joanseg/unplug-alarm.git
cd unplug-alarm
SIGN_IDENTITY="Apple Development: Your Name (XXXXXXXXXX)" scripts/build-app.sh
open build/UnplugAlarm.app
```

List your signing identities with `security find-identity -v -p codesigning`.

The helper only accepts the app signed by this project's team. If you sign with your own certificate, replace the team ID
`35XAX3CSKK` in `Sources/UnplugAlarmHelper/main.swift` with yours.

## First run: approve the helper

Keeping the Mac awake with the lid closed needs system-level access, so macOS asks you once:

1. Click the padlock in the menu bar and choose **Arm**.
2. macOS opens **System Settings → General → Login Items & Extensions**. Under *Allow in the Background*,
   switch **Unplug Alarm** on and confirm with your password or Touch ID.
3. Back in the menu, choose **Disarm…**, then **Arm** again. The menu now says **Lid closed: protected**.

You only do this once. No Terminal, no `sudo`.

## Everyday use

| You want to… | Do this |
|---|---|
| Pick how loud it is | **Alarm Volume** → 10–100% (only while disarmed, so nobody can turn it down) |
| Arm it | Plug in the charger → **Arm**. The icon becomes a shield. |
| Leave your Mac | Close the lid if you like — first check the menu says **Lid closed: protected**. |
| Come back | Open the lid → **Disarm…** → Touch ID or password. |
| Stop the siren | **Silence and Disarm…** → Touch ID or password. |

**Icons:** open padlock = disarmed · shield = armed · ringing bell = alarm going off.

**Arm** is greyed out on battery — plug in first. **Quit** is greyed out while armed.

## Good to know

- **While armed, your Mac will not sleep** — not even in a bag. Disarm before packing it away.
- **Holding the power button** to force it off stops the alarm. It protects against grab-and-go, not against everything.
- The siren plays through whatever audio output is selected — headphones included.
- Logs: `log stream --level info --predicate 'subsystem == "unplug-alarm"'`.

## Uninstall

Quit the app, switch it off in **Login Items & Extensions**, and delete it. To check sleep is back on, run
`pmset -g | grep SleepDisabled` — it should say `0`. If it says `1`, run `sudo pmset disablesleep 0`.

## Releasing

`scripts/release.sh <version>` (e.g. `scripts/release.sh 0.2.0`) sets the version, commits and pushes it, then
builds, notarizes, staples and publishes `UnplugAlarm.dmg` as GitHub release `v<version>`. It reads `SIGN_IDENTITY`
(a Developer ID Application identity), `ASC_KEY_ID` and `ASC_ISSUER_ID` from a git-ignored `release.env` at the repo root.

## Project layout

```
Sources/UnplugAlarm/        menu-bar app: power monitor, siren, arm/disarm, helper client
Sources/UnplugAlarmHelper/  privileged helper: runs pmset, restores sleep when the app goes away
Sources/Shared/             XPC protocol shared by both
Resources/                  Info.plist, the helper's launchd plist, app icon, disk image background
scripts/build-app.sh        builds and signs build/UnplugAlarm.app
scripts/make-dmg.sh         packs the app into a drag-to-Applications disk image
scripts/make-art.swift      regenerates the app icon and the disk image background
scripts/release.sh          notarizes and publishes a GitHub release
```

## License

[MIT](LICENSE) © 2026 Joan S.
