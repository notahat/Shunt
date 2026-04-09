# Shunt

A macOS background utility that intercepts Cmd+Tab and activates keyboard navigation in the Dock (equivalent to pressing Fn+A / "Move focus to the Dock"). No Dock icon or window — only a menu bar icon with a Quit option.

## Building

```
xcodebuild -project Shunt.xcodeproj -scheme Shunt -configuration Debug build
```

The built app lands in `~/Library/Developer/Xcode/DerivedData/Shunt-*/Build/Products/Debug/Shunt.app`.

## Code formatting

Use SwiftFormat: `swiftformat Shunt/`

## Key technical decisions

**App Sandbox is disabled** in the entitlements file. Both CGEvent taps and cross-process AXUIElement access are incompatible with App Sandbox.

**LSUIElement = YES** in Info.plist suppresses the Dock icon. MenuBarExtra alone is not sufficient.

**CGEvent tap callback is a non-capturing closure.** Swift 6 requires C function pointer callbacks to be non-capturing closures or static methods. The closure captures nothing — it calls `DockActivator.activate()` directly. `MainActor.assumeIsolated` is safe here because the tap is registered on the main run loop.

**`kAXTrustedCheckOptionPrompt` is avoided** in favour of the raw string `"AXTrustedCheckOptionPrompt"` because the constant is declared as a mutable global, which causes a Swift 6 concurrency error.

**Permission polling:** If accessibility access isn't granted at launch, the app shows the system prompt and then polls `AXIsProcessTrusted()` every second. Once granted, the event tap starts automatically without requiring a restart.

**Dock activation uses AXUIElement only** (no Control+F3 fallback). The approach: find the Dock process by bundle ID `com.apple.dock`, get its AXUIElement, find the child with role `kAXListRole`, and set `kAXFocusedAttribute` on it. The fallback was removed to evaluate AXUIElement stability — add it back if needed.

## Known non-issues

- `"Unable to obtain a task name port right for pid …"` logged on quit — this is a kernel-level noise message, not a bug.
- `appintentsmetadataprocessor` warning during build — harmless Xcode boilerplate.

## Permissions required

Accessibility access must be granted in System Settings > Privacy & Security > Accessibility. The app prompts automatically on first launch.
