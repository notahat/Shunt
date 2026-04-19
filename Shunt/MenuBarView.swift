import ApplicationServices
import SwiftUI

/// The menu bar menu content.
struct MenuBarView: View {
    @State private var accessibilityGranted = false
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
        Button("Quit Shunt") {
            NSApplication.shared.terminate(nil)
        }
        .onAppear {
            // Checked on each menu open since accessibility can be granted or
            // revoked while Shunt is running but the menu is closed.
            accessibilityGranted = AXIsProcessTrusted()
        }
    }
}
