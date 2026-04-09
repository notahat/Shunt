import AppKit
import ApplicationServices

@MainActor
enum DockActivator {
    static func activate() {
        guard let dock = NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.apple.dock"
        ).first else {
            print("Dock process not found.")
            return
        }

        let dockElement = AXUIElementCreateApplication(dock.processIdentifier)

        var childrenRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(dockElement, kAXChildrenAttribute as CFString, &childrenRef) == .success,
              let children = childrenRef as? [AXUIElement] else {
            print("Could not get Dock children; falling back to Control+F3.")
            postControlF3()
            return
        }

        guard let list = children.first(where: { element in
            var roleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)
            return (roleRef as? String) == kAXListRole as String
        }) else {
            print("Could not find Dock list element; falling back to Control+F3.")
            postControlF3()
            return
        }

        let result = AXUIElementSetAttributeValue(list, kAXFocusedAttribute as CFString, kCFBooleanTrue)
        if result != .success {
            print("AXUIElement focus failed (\(result.rawValue)); falling back to Control+F3.")
            postControlF3()
        }
    }

    private static func postControlF3() {
        // keyCode 99 = F3, .maskSecondaryFn simulates the Fn modifier
        let source = CGEventSource(stateID: .hidSystemState)
        if let down = CGEvent(keyboardEventSource: source, virtualKey: 99, keyDown: true) {
            down.flags = .maskSecondaryFn
            down.post(tap: .cgSessionEventTap)
        }
        if let up = CGEvent(keyboardEventSource: source, virtualKey: 99, keyDown: false) {
            up.flags = .maskSecondaryFn
            up.post(tap: .cgSessionEventTap)
        }
    }
}
