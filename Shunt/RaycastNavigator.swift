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

    /// Opens the Raycast window switcher. Has no effect if Raycast is not installed.
    ///
    /// We only probe for Raycast Beta's bundle ID and fall through to the stable
    /// URL otherwise. Probing for the stable bundle ID too added latency to the
    /// CGEvent tap callback and could occasionally return nil even when Raycast
    /// was installed, leaving the user with no switcher at all.
    static func activate() {
        let workspace = NSWorkspace.shared
        if workspace.urlForApplication(withBundleIdentifier: betaBundleID) != nil {
            workspace.open(betaSwitchWindowsURL)
        } else {
            workspace.open(stableSwitchWindowsURL)
        }
    }
}
