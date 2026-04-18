import ApplicationServices
import SwiftUI

/// The menu bar menu content.
struct MenuBarView: View {
    @State private var accessibilityGranted = AXIsProcessTrusted()
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("About Shunt") {
            NSWorkspace.shared.open(URL(string: "https://github.com/notahat/Shunt")!)
        }
        Divider()
        // Only shown when accessibility permission hasn't been granted.
        if !accessibilityGranted {
            Button("Enable Accessibility Access…") {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
            Divider()
        }
        Button("Settings…") {
            openWindow(id: "settings")
            NSApp.activate(ignoringOtherApps: true)
        }
        Divider()
        // onReceive must be attached to a view that's always in the menu,
        // regardless of whether the accessibility warning is showing.
        Button("Quit Shunt") {
            NSApplication.shared.terminate(nil)
        }
        .onReceive(NotificationCenter.default.publisher(for: .accessibilityGranted)) { _ in
            accessibilityGranted = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .accessibilityRevoked)) { _ in
            accessibilityGranted = false
        }
    }
}
