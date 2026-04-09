import SwiftUI

@main
struct ShuntApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Shunt", systemImage: "arrow.2.squarepath") {
            Button("Quit Shunt") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    let eventTapManager = EventTapManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        eventTapManager.start()
    }
}
