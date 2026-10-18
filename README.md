# Locus

Free and open-source iPhone location teleport. Tap the map, search a place, or drive a route — Locus injects coordinates through Apple’s **developer location service** into `locationd`, so Maps and other apps see the spoofed GPS (not just a Wi‑Fi lookup that outdoor GPS will overwrite).

<p align="center">
  <img src="docs/screenshots/map.png" alt="Locus map with spoof pin" width="180" />
  <img src="docs/screenshots/spoofing.png" alt="Locus spoofing in 3D" width="180" />
  <img src="docs/screenshots/joystick.png" alt="Locus joystick controls" width="180" />
  <img src="docs/screenshots/route.png" alt="Locus route on map" width="180" />
</p>

## Features

- One-tap teleport (map pin or place search)
- Live joystick — walk / run / cycle / drive with light speed variation
- Walk/Drive routing on real roads & footpaths (MapKit)
- Draw a path or import / export GPX
- Background keep-alive + live status bar + drop alerts
- Favorites & recents, including named favorites from any map pin
- English and Simplified Chinese (follows the system/app language)
- Optional coordinate conversion before sending a location
- First-run setup walkthrough
- Fully on-device — no analytics, nothing uploaded

## Install

See [SETUP.md](SETUP.md) for full steps. Grab a prebuilt IPA from [Releases](https://github.com/ChrisMack32/Locus/releases), or build from source below.

Bundle ID: `com.chrismack.locus`

### LiveContainer

File pickers often don’t work inside LiveContainer. Use one of these:

1. Long-press **Locus** → **Settings** → enable **Fix File Picker**, then try Import again.
2. Share the pairing file **into LiveContainer → Locus**.
3. Copy the RPPairing plist contents → in Locus use **Paste RPPairing from clipboard** (setup or Settings).

## How it works

Locus uses the MIT-licensed [idevice](https://github.com/jkcoxson/idevice) FFI to talk to Apple’s DVT location simulation over an on-device developer tunnel (the same class of mechanism Xcode uses).

**iOS 27:** Settings → **Pair on this iPhone** advertises `_remotepairing-pairable-host._tcp`. Confirm the 6-digit code under Settings › Privacy & Security › Developer Mode › Pair with Host — no computer.

**iOS 18–26:** import an **RPPairing** file once from [idevice_pair](https://github.com/jkcoxson/idevice_pair/releases).

Also install **[LocalDevVPN](https://apps.apple.com/us/app/localdevvpn/id6755608044)** (loopback tunnel, default `10.7.0.1`), then sideload Locus.

Start a teleport on Wi‑Fi first; the session can keep working on cellular afterward.

### Pokémon GO & similar games

Locus spoofs location the same way Xcode’s developer tools do: it tells iOS “you’re here,” and other apps read that from the system. Apps that just trust GPS (Apple Maps, etc.) will follow it.

**Pokémon GO is different.** It runs its own location checks and often rejects developer / simulated GPS (e.g. “Failed to detect location”). That’s expected with this method, not a Locus bug, and there’s no supported fix for it in this app.

Tools like **iPogo** (and similar modified clients such as SpooferPro) work differently: they’re a **modified Pokémon GO app**, not a system-wide location spoof. Features live *inside* that altered game client, instead of feeding coordinates through iOS for every app. Locus never patches or replaces Pokémon GO; it only changes what the system reports. So those tools can appear to “work in Pokémon GO” while Locus correctly drives Maps but still gets blocked by Pokémon GO’s checks.

Locus is for system-level teleporting. It isn’t a Pokémon GO client or an anti-cheat bypass.

## Build

Building from source needs an Apple Developer account (free or paid) for code signing. The published IPA does **not** — just sideload it.

1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen) if needed: `brew install xcodegen`
2. Set your **Team ID** in `project.yml` (`DEVELOPMENT_TEAM`), *or* pick your team under Xcode → Signing & Capabilities after generating the project.
3. Generate and open:

```bash
xcodegen generate
open Locus.xcodeproj
```

Or build from the CLI (replace with your Team ID from [developer.apple.com/account](https://developer.apple.com/account) → Membership):

```bash
xcodegen generate
xcodebuild -project Locus.xcodeproj -scheme Locus -configuration Release \
  -destination 'generic/platform=iOS' DEVELOPMENT_TEAM=YOUR_TEAM_ID build
```

## License

MIT. `Vendor/idevice` contains the idevice FFI (MIT). Locus is an independent open-source project and is not affiliated with Mirage / Wapixel.

## Language and map favorites

Locus follows the iOS app language. Simplified Chinese uses the standard `zh-Hans`
localization, including `zh-CN` language preferences. You can select the app language
in iOS Settings when more than one preferred language is configured.

Tap the map to drop a pin, tap the pin and choose **Save Favorite**, or use the star
above the map. Confirm a name to save it; a blank name uses the coordinates. Saved
places remain available in **Places** after relaunch. Searching retains its existing
automatic favorite behavior.

## Coordinate conversion

**Settings → Coordinate conversion** defaults to **Off**. The choices are
WGS-84 → GCJ-02, WGS-84 → BD-09, and GCJ-02 → WGS-84. Select the direction based
on the coordinate source and receiving service, not the interface language.
GPS coordinates and map-provider coordinates are not interchangeable; see
[Baidu's coordinate type documentation](https://lbsyun.baidu.com/docs/webapi?title=mapadjustment%2Furi%2Fweb).
A map pin already expressed in GCJ-02 may need the inverse conversion for a GPS
service; adding another forward offset can worsen the error.

Conversion runs once at the location engine boundary for teleports, routes, joystick
updates and resends. Pins, favorites, recents and GPX retain their original numbers.
Stop the active session before changing the setting. The offline approximation uses
longitude 72.004–137.8347 and latitude 0.8293–55.8271 as a coarse coverage rectangle,
not a precise mainland boundary; keep conversion off in other regions and border
areas. This is not an automatic MapKit datum detector or a guarantee of device accuracy.

Run the standalone coordinate checks on macOS:

```sh
xcrun swiftc -module-cache-path /tmp/locus-swift-module-cache \
  Locus/Engine/CoordinateTransform.swift Tests/CoordinateTransformChecks.swift \
  -o /tmp/locus-coordinate-checks
/tmp/locus-coordinate-checks
```

On a paired iPhone with LocalDevVPN connected, verify a recognizable map pin using
Teleport and another location app, then check Stop, joystick movement, route playback,
background resends, and a saved favorite after relaunch. Compare conversion Off and the
appropriate direction separately. A successful build or conversion check does not
verify the developer tunnel or the receiving app's location update behavior.
