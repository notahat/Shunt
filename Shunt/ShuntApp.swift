import SwiftUI

/// App entry point. Owns the menu bar icon and settings window.
@main
struct ShuntApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    /// False when running inside an Xcode preview, so the menu bar icon doesn't appear.
    @State private var showMenuBarExtra =
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1"

    var body: some Scene {
        MenuBarExtra("Shunt", systemImage: "dock.arrow.down.rectangle", isInserted: $showMenuBarExtra) {
            MenuBarView()
        }
        Window("Shunt Settings", id: "settings") {
            SettingsView()
        }
        .windowResizability(.contentSize)
    }
}

/// Starts the accessibility monitor and Cmd+Tab interceptor on launch.
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    let accessibilityMonitor = AccessibilityMonitor()
    let cmdTabInterceptor = CmdTabInterceptor()

    /// Prevents the app from quitting when the settings window is closed.
    /// Without this, adding the Window scene causes macOS to quit the app
    /// when it thinks the last window has closed.
    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        false
    }

    /// Starts the accessibility monitor and event tap on launch, and restores
    /// the saved switcher mode. Skipped when running inside an Xcode preview.
    func applicationDidFinishLaunching(_: Notification) {
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }
        accessibilityMonitor.start()
        cmdTabInterceptor.start(accessibilityGranted: accessibilityMonitor.isTrusted)
        let savedMode = UserDefaults.standard.string(forKey: "switcherMode")
            .flatMap(SwitcherMode.init(rawValue:)) ?? .dock
        CmdTabInterceptor.switcherMode = savedMode
    }
}
