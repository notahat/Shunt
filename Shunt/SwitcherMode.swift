/// The strategy used when Cmd+Tab is pressed.
enum SwitcherMode: String, CaseIterable {
    /// Navigate the Dock using the accessibility API.
    case dock

    /// Open the Raycast window switcher.
    case raycast
}
