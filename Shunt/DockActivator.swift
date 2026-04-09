import AppKit
import ApplicationServices

// Activates keyboard navigation in the Dock via the accessibility API, equivalent
// to pressing Fn+A / "Move focus to the Dock". Finds the Dock's AXList element
// and sets focus on it.
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
              let children = childrenRef as? [AXUIElement]
        else {
            print("Could not get Dock children.")
            return
        }

        guard let list = children.first(where: { element in
            var roleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)
            return (roleRef as? String) == kAXListRole as String
        }) else {
            print("Could not find Dock list element.")
            return
        }

        let result = AXUIElementSetAttributeValue(list, kAXFocusedAttribute as CFString, kCFBooleanTrue)
        if result != .success {
            print("AXUIElement focus failed (\(result.rawValue)).")
        }
    }
}
