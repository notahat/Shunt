import ApplicationServices
import ServiceManagement
import SwiftUI

/// App entry point. Owns the menu bar icon and delegates app lifecycle to AppDelegate.
@main
struct ShuntApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var accessibilityGranted = AXIsProcessTrusted()

    var body: some Scene {
        MenuBarExtra("Shunt", systemImage: "dock.arrow.down.rectangle") {
            // Only shown when accessibility permission hasn't been granted.
            if !accessibilityGranted {
                Button("Enable Accessibility Access…") {
                    openAccessibilitySettings()
                }
                Divider()
            }
            Toggle("Launch at Login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, enabled in
                    do {
                        if enabled {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        print("Failed to update launch at login: \(error)")
                        launchAtLogin = !enabled
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

/// Starts the accessibility monitor and event tap on launch.
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    let accessibilityMonitor = AccessibilityMonitor()
    let eventTapManager = EventTapManager()

    func applicationDidFinishLaunching(_: Notification) {
        accessibilityMonitor.start()
        eventTapManager.start(accessibilityGranted: accessibilityMonitor.isTrusted)
    }
}
