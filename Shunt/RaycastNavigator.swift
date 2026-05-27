import AppKit

/// Activates Raycast's window switcher via its deep link URL.
///
/// This is one of two switcher strategies — the other is DockNavigator.
/// Supports both Raycast and Raycast Beta, preferring the beta when installed
/// since installing it is an explicit user choice.
///
/// If the deep link URLs stop working, copy them fresh from Raycast by
/// searching for "Switch Windows", then pressing Shift+Cmd+C.
@MainActor
enum RaycastNavigator {
    private static let betaBundleID = "com.raycast-x.macos"

    private static let stableSwitchWindowsURL = URL(string: "raycast://extensions/raycast/navigation/switch-windows")!
    private static let betaSwitchWindowsURL = URL(string: "raycast-x://extensions/raycast/navigation/switch-windows")!

    /// Whether Raycast Beta is installed. Resolved once via Launch Services and
    /// cached, because the lookup can be slow enough on a fresh machine to
    /// exceed the CGEvent tap deadline and cause macOS to disable the tap.
    /// Call `prewarm()` at startup to pay this cost off the hot path. Installing
    /// Raycast Beta after Shunt has launched requires a Shunt restart to pick up.
    private static let hasBeta: Bool = {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: betaBundleID) != nil
    }()

    /// Resolves the cached beta check now, so the first Cmd+Tab doesn't pay
    /// for it. Safe to call multiple times; subsequent calls are no-ops.
    static func prewarm() {
        _ = hasBeta
    }

    /// Opens the Raycast window switcher. Has no effect if Raycast is not installed.
    ///
    /// Prefers Raycast Beta when installed since installing it is an explicit
    /// user choice; otherwise falls through to the stable URL unconditionally
    /// (we don't probe for the stable bundle ID, since that lookup could return
    /// nil even when Raycast was installed, leaving the user with no switcher).
    static func activate() {
        NSWorkspace.shared.open(hasBeta ? betaSwitchWindowsURL : stableSwitchWindowsURL)
    }
}
