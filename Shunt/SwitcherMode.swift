/// The strategy used when Cmd+Tab is pressed.
enum SwitcherMode: String, CaseIterable {
    /// The UserDefaults key used to persist the selected mode.
    static let defaultsKey = "switcherMode"

    /// Navigate the Dock using the accessibility API.
    case dock

    /// Open the Raycast window switcher.
    case raycast
}
