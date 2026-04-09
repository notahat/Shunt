import ServiceManagement
import SwiftUI

@main
struct ShuntApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some Scene {
        MenuBarExtra("Shunt", systemImage: "dock.arrow.down.rectangle") {
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
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    let eventTapManager = EventTapManager()

    func applicationDidFinishLaunching(_: Notification) {
        eventTapManager.start()
    }
}
