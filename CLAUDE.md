# Shunt

A macOS background utility that intercepts Cmd+Tab and Cmd+Shift+Tab and
either activates keyboard navigation in the Dock or opens the Raycast window
switcher, depending on the user's preference. No Dock icon — a menu bar icon
gives access to settings (switcher choice, open at login) and quit.

## Building

```
xcodebuild -project Shunt.xcodeproj -scheme Shunt -configuration Debug build
```

The built app lands in `~/Library/Developer/Xcode/DerivedData/Shunt-*/Build/Products/Debug/Shunt.app`.

## Code formatting

Use SwiftFormat: `swiftformat Shunt/`

## Architecture diagram

`ARCHITECTURE.md` contains a Mermaid dependency diagram. Keep it up to date
when making code changes. Each node shows the component name (in `<b>` tags)
and a one-line description of its responsibility. Each arrow label forms a
readable sentence with its endpoints: "A [label] B". Solid arrows are direct
code dependencies; dashed arrows are indirect `NotificationCenter` relationships.

## Key technical decisions

**App Sandbox is disabled** in the entitlements file. Both CGEvent taps and
cross-process AXUIElement access are incompatible with App Sandbox.

**LSUIElement = YES** in Info.plist suppresses the Dock icon. MenuBarExtra
alone is not sufficient.

**CGEvent tap callback is a non-capturing closure.** Swift 6 requires C
function pointer callbacks to be non-capturing closures or static methods. The
callback calls `CmdTabInterceptor.handleEvent`, a static method, which in turn
calls `onCmdTabForCallback` — a `nonisolated(unsafe) static` set by `AppDelegate`
at startup via `start(accessibilityGranted:onCmdTab:)`. `MainActor.assumeIsolated`
is safe here because the tap is registered on the main run loop.

**`CmdTabInterceptor` is decoupled from the navigators.** It calls a handler
closure passed in at startup; it knows nothing about `DockNavigator` or
`RaycastNavigator`. `AppDelegate` owns the wiring — it provides the closure
that reads `SwitcherMode` from `UserDefaults` and calls the right navigator.

**`kAXTrustedCheckOptionPrompt` is avoided** in favour of the raw string
`"AXTrustedCheckOptionPrompt"` because the constant is declared as a mutable
global, which causes a Swift 6 concurrency error.

**Permission polling:** If accessibility access isn't granted at launch, the
app shows the system prompt and then polls `AXIsProcessTrusted()` every second.
Once granted, the event tap starts automatically without requiring a restart.

**`DockNavigator` uses AXUIElement only** (no Control+F3 fallback). The
approach: find the Dock process by bundle ID `com.apple.dock`, get its
AXUIElement, find the child with role `kAXListRole`, set `kAXFocusedAttribute`
to enter keyboard navigation mode, then use `kAXSelectedChildrenAttribute` to
move the selection. The fallback was removed to evaluate AXUIElement stability —
add it back if needed.

**`SwitcherMode.defaultsKey`** is the single source of truth for the
UserDefaults key. Both `@AppStorage` in `SettingsView` and the `UserDefaults`
read in `AppDelegate` reference this constant.

## Code style

- **Readability at the callsite over DRY.** Don't extract helpers just to
  remove repetition — only extract when it makes the calling code clearer.
  Short methods that each do one obvious thing are fine as-is.
- **Explicit over implicit.** Use `_ =` for discarded return values, concrete
  types over `Any`, and `switch` over arithmetic tricks when branching on cases.
- **No theoretical edge cases.** Only add guards or bounds checks for scenarios
  that can realistically occur.
- **Don't swap one workaround for another.** If a hack is unavoidable and
  already well-commented, leave it rather than replacing it with something
  equally opaque.
- **All classes, methods, and properties should have documentation comments**
  (Swift `///` style).
- **Comments explain why, not what.**

## Known non-issues

- `"Unable to obtain a task name port right for pid …"` logged on quit — this
  is a kernel-level noise message, not a bug.
- `appintentsmetadataprocessor` warning during build — harmless Xcode
  boilerplate.

## Permissions required

Accessibility access must be granted in System Settings > Privacy & Security >
Accessibility. The app prompts automatically on first launch.
