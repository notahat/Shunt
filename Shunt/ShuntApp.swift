import ApplicationServices
import ServiceManagement
import SwiftUI

@main
struct ShuntApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var accessibilityGranted = AXIsProcessTrusted()

    var body: some Scene {
        MenuBarExtra("Shunt", systemImage: "dock.arrow.down.rectangle") {
            if !accessibilityGranted {
                Button("Enable Accessibility Access…") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
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
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    let accessibilityMonitor = AccessibilityMonitor()
    let eventTapManager = EventTapManager()

    func applicationDidFinishLaunching(_: Notification) {
        accessibilityMonitor.start()
        eventTapManager.start(accessibilityGranted: accessibilityMonitor.isTrusted)
    }
}
