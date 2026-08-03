<div align="center">

<img src="docs/images/icon.png" width="112" alt="Delayed Cmd+Q">

# Delayed Cmd+Q

**A mistyped ⌘Q shouldn't cost you your work.**

Hold ⌘Q instead of tapping it. A ring fills clockwise while you hold —<br>
let go early and nothing happens.

[![Platform](https://img.shields.io/badge/macOS-14%2B-000000?logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![Release](https://img.shields.io/github/v/release/mnjn00/DelayedCmdQ?color=brightgreen)](https://github.com/mnjn00/DelayedCmdQ/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/mnjn00/DelayedCmdQ/total?color=orange)](https://github.com/mnjn00/DelayedCmdQ/releases)

**English** · [한국어](README.ko.md) · [日本語](README.ja.md) · [简体中文](README.zh-Hans.md)

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/demo-dark.gif">
  <img src="docs/images/demo-light.gif" width="440" alt="A ring filling clockwise while ⌘Q is held">
</picture>

</div>

---

## Why

⌘Q sits directly below ⌘Tab and one key away from ⌘W. Hit it by accident and the app
is gone — along with whatever wasn't saved.

Delayed Cmd+Q intercepts the shortcut before any app sees it. Quitting now takes a
deliberate press-and-hold, and the ring shows exactly how much longer you have to
commit. Release early and the keystroke is discarded entirely; the app never even
learns it was pressed.

## Features

- **Hold to quit** — ⌘Q must be held for a duration you choose
- **Minimal HUD** — an outline-only ring that fills clockwise from twelve o'clock
- **Adjustable delay** — 0.3 to 5.0 seconds, with a live preview in Settings
- **Optional chaining** — keep holding to move on to the next app, or stop after the first
- **Layout aware** — correct on AZERTY, QWERTZ and while typing in Korean or Japanese
- **Stays out of the way** — menu bar only, no Dock icon, pause any time
- **Leaves other shortcuts alone** — ⌘⇧Q (log out) and ⌘⌥Q pass straight through

<div align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/ring-dark.png">
  <img src="docs/images/ring-light.png" width="620" alt="The ring at 0, 25, 50, 75 and 100 percent">
</picture>
</div>

## Install

### Download

1. Grab **`DelayedCmdQ.zip`** from the [latest release](https://github.com/mnjn00/DelayedCmdQ/releases/latest).
2. Unzip it and move `DelayedCmdQ.app` to `/Applications`.
3. Remove the download quarantine flag:

```bash
xattr -dr com.apple.quarantine /Applications/DelayedCmdQ.app
```

> [!NOTE]
> Step 3 is needed because the app is ad-hoc signed rather than notarized — there is
> no paid Apple Developer account behind it. Without it macOS reports the app as
> damaged. If you would rather not run that command, [build from source](#build-from-source)
> instead; the result is identical.

### Build from source

Requires macOS 14+ and Xcode 26 (Swift 6).

```bash
git clone https://github.com/mnjn00/DelayedCmdQ.git
cd DelayedCmdQ
./Scripts/build-app.sh
cp -R build/DelayedCmdQ.app /Applications/
```

Pass `UNIVERSAL=1` to build an Intel + Apple Silicon universal binary.

## First run

Intercepting ⌘Q requires **Accessibility** access.

1. Launch the app. It asks for permission and opens its Settings window.
2. Go to **System Settings → Privacy & Security → Accessibility**.
3. Enable **Delayed Cmd+Q**.

It starts working the moment you grant access — no relaunch needed. The app lives in
the menu bar; there is no Dock icon.

> [!IMPORTANT]
> If you rebuild from source, the ad-hoc signature changes and macOS resets the
> permission. Remove the old entry with `−` in the Accessibility list and add the new
> build.

## Settings

Open from the menu bar icon, or press <kbd>⌘</kbd><kbd>,</kbd>.

| Setting | Description | Default |
| --- | --- | --- |
| **Delay** | How long ⌘Q must be held | `1.0s` |
| **Allow continuous quit** | Keep quitting the next app while held | Off |
| **Pause** | Restore normal ⌘Q behaviour | Off |
| **Launch at login** | Register as a login item | Off |
| **Show app icon** | Draw the target app's icon inside the ring | On |

Click the ring at the top of the Settings window to preview the current delay.

### Continuous quit

With this **off** (the default), nothing further happens once the first app quits, no
matter how long you keep holding.

With it **on**, the app waits for focus to actually land on a different application,
then starts a fresh ring for it. Every quit still requires a full hold, so one
keystroke never wipes out a stack of apps at once. If focus doesn't move within three
seconds — an unsaved-changes dialog, for instance — the chain simply stops.

## Under the hood

```
Sources/DelayedCmdQKit/
  App/         App delegate, menu bar item, main menu, settings window
  Core/        Event tap, hold state machine, countdown, permissions, keyboard layout
  Overlay/     Overlay panel and the progress ring view
  Settings/    Preferences model and settings screen
```

Three pieces carry the behaviour:

- **`QuitKeyMonitor`** attaches to the session event tap in `.defaultTap` mode and
  discards the ⌘Q key down outright. The front app is never told the shortcut was
  pressed; if the hold completes, `QuitCoordinator` asks it to quit explicitly.
- **`QuitHoldMachine`** is a pure value type holding every state transition of a hold.
  It takes semantic inputs rather than events, so the whole lifecycle is testable
  without an accessibility-trusted process or synthetic `CGEvent`s.
- **`KeyboardLayout`** resolves Q's key code through `UCKeyTranslate` against the
  current ASCII-capable layout, which is what macOS itself uses for command
  shortcuts — so it stays correct where Q is not physically where QWERTY puts it.

### Development

```bash
swift build     # compile
swift test      # run the test suite
```

The event tap and the overlay need system permissions and a screen, so they aren't
unit tested. The hold state machine, shortcut matching, delay policy and settings
persistence all are.

## Thanks to

Inspired by [qblocker](https://github.com/steve228uk/qblocker), which pioneered this
idea on macOS.

## License

[MIT](LICENSE) © mnjn00
