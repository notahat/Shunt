import AppKit
import ApplicationServices

/// Activates keyboard navigation in the Dock via the accessibility API. On first
/// call, focuses the Dock's AXList to begin keyboard navigation — the Dock selects
/// the current app's icon. On subsequent calls while an item is already selected,
/// advances or retreats through items, skipping separators.
@MainActor
enum DockActivator {
    enum Direction { case forward, backward }

    static func activate(direction: Direction = .forward) {
        guard let list = findDockList() else { return }

        if let current = selectedChild(of: list),
           let children = children(of: list),
           let next = nextSelectableItem(after: current, in: children, direction: direction)
        {
            select(next, in: list)
        } else {
            beginKeyboardNavigation(in: list)
        }
    }

    // MARK: - Private

    /// Navigates the Dock's AX tree to find the AXList element that contains the app icons.
    private static func findDockList() -> AXUIElement? {
        guard let dock = NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.apple.dock"
        ).first else {
            print("Dock process not found.")
            return nil
        }
        let app = AXUIElementCreateApplication(dock.processIdentifier)
        guard let appChildren = children(of: app) else {
            print("Could not get Dock children.")
            return nil
        }
        guard let list = appChildren.first(where: { role(of: $0) == kAXListRole as String }) else {
            print("Could not find Dock list element.")
            return nil
        }
        return list
    }

    /// Returns the currently selected item in the Dock list, if any.
    private static func selectedChild(of list: AXUIElement) -> AXUIElement? {
        var ref: CFTypeRef?
        AXUIElementCopyAttributeValue(list, kAXSelectedChildrenAttribute as CFString, &ref)
        return (ref as? [AXUIElement])?.first
    }

    /// Returns the next item after the current one in the given direction, skipping separators.
    private static func nextSelectableItem(after current: AXUIElement, in children: [AXUIElement], direction: Direction) -> AXUIElement? {
        guard let currentIndex = children.firstIndex(where: { CFEqual($0, current) }) else { return nil }
        let count = children.count
        let step = direction == .forward ? 1 : count - 1
        var nextIndex = (currentIndex + step) % count
        while isSeparator(children[nextIndex]), nextIndex != currentIndex {
            nextIndex = (nextIndex + step) % count
        }
        return children[nextIndex]
    }

    /// Sets the selected item in the Dock list, moving the visual highlight.
    private static func select(_ item: AXUIElement, in list: AXUIElement) {
        let result = AXUIElementSetAttributeValue(list, kAXSelectedChildrenAttribute as CFString, [item] as CFArray)
        if result != .success {
            print("AXUIElement selection failed (\(result.rawValue)).")
        }
    }

    /// Focuses the Dock list to start keyboard navigation. The Dock will select
    /// the current app's icon and display the keyboard focus indicator.
    private static func beginKeyboardNavigation(in list: AXUIElement) {
        let result = AXUIElementSetAttributeValue(list, kAXFocusedAttribute as CFString, kCFBooleanTrue)
        if result != .success {
            print("AXUIElement focus failed (\(result.rawValue)).")
        }
    }

    /// Returns true if the element is a Dock separator. Separators have no title.
    private static func isSeparator(_ element: AXUIElement) -> Bool {
        var ref: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &ref)
        return (ref as? String ?? "").isEmpty
    }

    /// Returns the AX children of an element, or nil if unavailable.
    private static func children(of element: AXUIElement) -> [AXUIElement]? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &ref) == .success else { return nil }
        return ref as? [AXUIElement]
    }

    /// Returns the AX role of an element, or nil if unavailable.
    private static func role(of element: AXUIElement) -> String? {
        var ref: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &ref)
        return ref as? String
    }
}
