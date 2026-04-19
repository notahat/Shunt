import SwiftUI

/// App entry point. Owns the menu bar icon and settings window.
@main
struct ShuntApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    /// False when running inside an Xcode preview, so the menu bar icon doesn't appear.
    @State private var showMenuBarExtra = !ProcessInfo.processInfo.isRunningInXcodePreview

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

    /// Starts the accessibility monitor and event tap on launch.
    /// Skipped when running inside an Xcode preview.
    func applicationDidFinishLaunching(_: Notification) {
        guard !ProcessInfo.processInfo.isRunningInXcodePreview else { return }
        accessibilityMonitor.start()
        cmdTabInterceptor.start(accessibilityGranted: accessibilityMonitor.isTrusted) { direction in
            switch self.switcherMode() {
            case .dock: DockNavigator.navigate(direction: direction)
            case .raycast: RaycastNavigator.activate()
            }
        }
    }

    /// Reads the current switcher mode from user defaults, defaulting to .dock.
    private func switcherMode() -> SwitcherMode {
        UserDefaults.standard.string(forKey: SwitcherMode.defaultsKey)
            .flatMap(SwitcherMode.init(rawValue:)) ?? .dock
    }
}

private extension ProcessInfo {
    /// True when running inside an Xcode preview.
    var isRunningInXcodePreview: Bool {
        environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}
