import AppKit

/// Activates Raycast's window switcher via its deep link URL.
///
/// This is one of two switcher strategies — the other is DockNavigator.
/// If the deep link URL stops working, copy it fresh from Raycast by
/// searching for "Switch Windows", then pressing Shift+Cmd+C.
@MainActor
enum RaycastNavigator {
    private static let switchWindowsURL = URL(string: "raycast://extensions/raycast/navigation/switch-windows")!

    /// Opens the Raycast window switcher. Has no effect if Raycast is not installed.
    static func activate() {
        NSWorkspace.shared.open(switchWindowsURL)
    }
}
