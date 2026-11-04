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

### From a release

> Signed and notarized releases are not published yet. Until then, build it from source (below).

When they are: download `UnplugAlarm.zip` from [Releases](https://github.com/joanseg/unplug-alarm/releases),
unzip it, and drag **Unplug Alarm** into `/Applications`.

### From source

You need Xcode (Swift 6.2+) and an Apple signing certificate.

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

## Using it with Amphetamine

[Amphetamine](https://apps.apple.com/us/app/amphetamine/id937984704?mt=12) is a free Mac App Store app that keeps your Mac
awake. The two apps work side by side, but they do different jobs:

- **Amphetamine** stops *idle* sleep and keeps the display on — useful while you work, present or download.
- **Unplug Alarm** stops *all* sleep, but only while armed — which is what lets the siren ring with the lid shut on battery.

We tested Amphetamine's closed-display mode on its own: with the lid closed, pulling the charger still put the Mac to
sleep instantly (macOS logs it as *Clamshell Sleep*), so the siren only went off once the lid was reopened. Amphetamine
is a sandboxed App Store app and can't switch system sleep off the way the helper does.

**If you use both:**

1. Keep using Amphetamine as usual for day-to-day keep-awake sessions.
2. When you step away, **Arm** Unplug Alarm and check it says **Lid closed: protected**. You don't need an Amphetamine
   session for the alarm.
3. Disarm when you're back. Unplug Alarm hands sleep back to macOS. Amphetamine's sessions are untouched, because it
   uses a different mechanism (power assertions, not `disablesleep`).

**If you decline the helper,** Amphetamine is the fallback: start a session with closed-display mode while armed. With
the lid open the alarm rings the moment the cable is pulled; with the lid closed it rings only once the lid is opened.

## Good to know

- **While armed, your Mac will not sleep** — not even in a bag. Disarm before packing it away.
- **Holding the power button** to force it off stops the alarm. It protects against grab-and-go, not against everything.
- The siren plays through whatever audio output is selected — headphones included.
- Logs: `log stream --level info --predicate 'subsystem == "unplug-alarm"'`.

## Uninstall

Quit the app, switch it off in **Login Items & Extensions**, and delete it. To check sleep is back on, run
`pmset -g | grep SleepDisabled` — it should say `0`. If it says `1`, run `sudo pmset disablesleep 0`.

## Project layout

```
Sources/UnplugAlarm/        menu-bar app: power monitor, siren, arm/disarm, helper client
Sources/UnplugAlarmHelper/  privileged helper: runs pmset, restores sleep when the app goes away
Sources/Shared/             XPC protocol shared by both
Resources/                  Info.plist and the helper's launchd plist
scripts/build-app.sh        builds and signs build/UnplugAlarm.app
```
