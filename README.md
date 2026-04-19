# Shunt

Replaces the ⌘-tab app switcher. You can select from having ⌘-tab:
- Give the dock keyboard focus. Use ⌘-tab and ⌘⇧-tab to navigate, return to launch, escape to dismiss.
- Open the Raycast window switcher.

Runs quietly in the background with no Dock icon. A menu bar icon gives access to settings and lets you quit.

## Requirements

MacOS Tahoe or later.

## Installation

**Option 1: Homebrew**

```
brew install notahat/tap/shunt
```

**Option 2: Direct download**

1. Download `Shunt.zip` from the [latest release](https://github.com/notahat/Shunt/releases/latest)
2. Unzip and move `Shunt.app` to your Applications folder

Then open Shunt — MacOS will ask for Accessibility permission, which it needs to intercept Cmd+Tab. Open Settings from the menu bar icon to enable "Open at Login" and choose your preferred window switcher.

## Privacy

Shunt requires Accessibility access to intercept Cmd+Tab system-wide and to move keyboard focus to the Dock. MacOS requires Accessibility permission for both.

Shunt does not read the content of other windows, record keystrokes, or transmit any data anywhere. It only acts on Cmd+Tab and Cmd+Shift+Tab, and only to move focus to the Dock or open Raycast.

If you'd prefer not to take that on trust, the full source is here. The key files are `Shunt/CmdTabInterceptor.swift` (keyboard interception), `Shunt/DockNavigator.swift` (Dock interaction), and `Shunt/RaycastNavigator.swift` (Raycast integration).

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

Run `./release.sh <version>` (e.g. `./release.sh 1.2.0`). The script archives and signs the app with your Developer ID certificate, notarizes it with Apple, staples the notarization ticket, publishes a GitHub release, and updates the Homebrew tap. See the comments at the top of the script for one-time setup prerequisites.

To upgrade to the new version via Homebrew:

```
brew update && brew upgrade shunt
```
