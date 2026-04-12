# Shunt

Replaces the Cmd+Tab app switcher with the Dock. Press Cmd+Tab and the Dock gets keyboard focus — navigate with arrow keys, launch with Return, or press Escape to dismiss. Cmd+Shift+Tab cycles backward.

Runs quietly in the background with no Dock icon. A menu bar icon lets you enable Launch at Login and quit.

## Requirements

MacOS Tahoe or later.

## Installation

1. Download `Shunt.zip` from the [latest release](https://github.com/notahat/Shunt/releases/latest)
2. Unzip and move `Shunt.app` to your Applications folder
3. Open Shunt — MacOS will ask for Accessibility permission, which it needs to intercept Cmd+Tab
4. Enable "Launch at Login" from the menu bar icon so it starts automatically

## Privacy

Shunt requires Accessibility access to intercept Cmd+Tab system-wide and to move keyboard focus to the Dock. MacOS requires Accessibility permission for both — there's no narrower entitlement available.

Shunt does not read the content of other windows, record keystrokes, or transmit any data anywhere. It only acts on Cmd+Tab and Cmd+Shift+Tab, and only to move focus to the Dock.

If you'd prefer not to take that on trust, the full source is here. The key files are `Shunt/CmdTabInterceptor.swift` (keyboard interception) and `Shunt/DockNavigator.swift` (Dock interaction).

---

## For developers

### How it works

Shunt installs a system-wide CGEvent tap to intercept Cmd+Tab and Cmd+Shift+Tab before they reach the OS. When detected, it uses the MacOS accessibility API to set keyboard focus on the Dock — the same effect as pressing Control+F3 ("Move Focus to the Dock"). Because CGEvent taps and cross-process accessibility access both require it, App Sandbox is disabled.

### Building

```
xcodebuild -project Shunt.xcodeproj -scheme Shunt -configuration Debug build
```

Run `swiftformat Shunt/` to format code (Swift 6 rules, configured in `.swiftformat`).

### Releasing

Run `./release.sh <version>` (e.g. `./release.sh 1.2.0`). The script archives and signs the app with your Developer ID certificate, notarizes it with Apple, staples the notarization ticket, and publishes a GitHub release. See the comments at the top of the script for one-time setup prerequisites.
