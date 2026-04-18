import ApplicationServices
import ServiceManagement
import SwiftUI

/// App entry point. Owns the menu bar icon and delegates app lifecycle to AppDelegate.
@main
struct ShuntApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var openAtLogin = SMAppService.mainApp.status == .enabled
    @State private var accessibilityGranted = AXIsProcessTrusted()
    @State private var useRaycastSwitcher = UserDefaults.standard.bool(forKey: "useRaycastSwitcher")

    var body: some Scene {
        MenuBarExtra("Shunt", systemImage: "dock.arrow.down.rectangle") {
            Button("About Shunt") {
                NSWorkspace.shared.open(URL(string: "https://github.com/notahat/Shunt")!)
            }
            Divider()
            // Only shown when accessibility permission hasn't been granted.
            if !accessibilityGranted {
                Button("Enable Accessibility Access…") {
                    openAccessibilitySettings()
                }
                Divider()
            }
            Toggle("Use Raycast Window Switcher", isOn: $useRaycastSwitcher)
                .onChange(of: useRaycastSwitcher) { _, enabled in
                    UserDefaults.standard.set(enabled, forKey: "useRaycastSwitcher")
                    CmdTabInterceptor.useRaycastSwitcher = enabled
                }
            Toggle("Open at Login", isOn: $openAtLogin)
                .onChange(of: openAtLogin) { _, enabled in
                    do {
                        if enabled {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        print("Failed to update launch at login: \(error)")
                        openAtLogin = !enabled
                    }
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

    /// Opens System Settings to the Accessibility privacy page.
    private func openAccessibilitySettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
}

/// Starts the accessibility monitor and Cmd+Tab interceptor on launch.
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    let accessibilityMonitor = AccessibilityMonitor()
    let cmdTabInterceptor = CmdTabInterceptor()

    /// Starts the accessibility monitor and event tap on launch.
    func applicationDidFinishLaunching(_: Notification) {
        accessibilityMonitor.start()
        cmdTabInterceptor.start(accessibilityGranted: accessibilityMonitor.isTrusted)
        CmdTabInterceptor.useRaycastSwitcher = UserDefaults.standard.bool(forKey: "useRaycastSwitcher")
    }
}
