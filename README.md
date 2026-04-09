# Shunt

A macOS background utility that replaces the Cmd+Tab application switcher with the Dock. Press Cmd+Tab and the Dock receives keyboard focus — navigate with arrow keys, select with Return.

Runs invisibly with no Dock icon or window. A menu bar icon provides access to settings and quitting.

## Requirements

- macOS Tahoe or later
- Accessibility permission (the app will prompt on first launch)

## Installation

Build the app and copy it to `/Applications`. Enable "Launch at Login" from the menu bar icon on first run.

## How it works

Shunt installs a system-wide CGEvent tap that intercepts Cmd+Tab before it reaches the OS. Instead of the default app switcher, it uses the accessibility API to set keyboard focus on the Dock, equivalent to pressing Fn+A ("Move Focus to the Dock").

## To-dos

- [ ] Tap health monitoring — detect when the system disables the event tap (`tapDisabledByTimeout` / `tapDisabledByUserInput`) and re-enable it automatically
