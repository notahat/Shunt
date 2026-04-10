import AppKit
import ApplicationServices

/// Navigates the Dock via the accessibility API. On first call, enters keyboard
/// navigation mode and selects the Dock item adjacent to the frontmost application
/// in the given direction. On subsequent calls while an item is already selected,
/// advances or retreats through items, skipping separators.
@MainActor
enum DockNavigator {
    enum Direction { case forward, backward }

    static func navigate(direction: Direction = .forward) {
        guard let list = findDockList(),
              let listChildren = children(of: list)
        else { return }

        if let current = selectedChild(of: list),
           let next = nextSelectableItem(after: current, in: listChildren, direction: direction)
        {
            // Dock already active — advance to the next item.
            select(next, in: list)
        } else {
            // First activation — enter keyboard nav mode, then select one step
            // past the frontmost app in the given direction.
            enterKeyboardNavigation(in: list)
            if let frontmost = frontmostAppItem(in: listChildren),
               let start = nextSelectableItem(after: frontmost, in: listChildren, direction: direction)
            {
                select(start, in: list)
            }
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

    /// Returns the Dock item for the frontmost application, matched by name.
    /// Returns nil if the frontmost app has no corresponding Dock item.
    private static func frontmostAppItem(in children: [AXUIElement]) -> AXUIElement? {
        guard let appName = NSWorkspace.shared.frontmostApplication?.localizedName else { return nil }
        return children.first { title(of: $0) == appName }
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

    /// Focuses the Dock list to enter keyboard navigation mode.
    private static func enterKeyboardNavigation(in list: AXUIElement) {
        let result = AXUIElementSetAttributeValue(list, kAXFocusedAttribute as CFString, kCFBooleanTrue)
        if result != .success {
            print("AXUIElement focus failed (\(result.rawValue)).")
        }
    }

    /// Returns true if the element is a Dock separator. Separators have no title.
    private static func isSeparator(_ element: AXUIElement) -> Bool {
        (title(of: element) ?? "").isEmpty
    }

    /// Returns the AX children of an element, or nil if unavailable.
    private static func children(of element: AXUIElement) -> [AXUIElement]? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &ref) == .success else { return nil }
        return ref as? [AXUIElement]
    }

    /// Returns the title of an AX element, or nil if unavailable.
    private static func title(of element: AXUIElement) -> String? {
        var ref: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &ref)
        return ref as? String
    }

    /// Returns the AX role of an element, or nil if unavailable.
    private static func role(of element: AXUIElement) -> String? {
        var ref: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &ref)
        return ref as? String
    }
}
