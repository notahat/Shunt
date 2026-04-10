import ApplicationServices
import Foundation

/// Notification names posted when accessibility permission status changes.
extension Notification.Name {
    static let accessibilityGranted = Notification.Name("ShuntAccessibilityGranted")
    static let accessibilityRevoked = Notification.Name("ShuntAccessibilityRevoked")
}

/// Continuously monitors accessibility permission status and posts notifications
/// when it changes. Shows the system permission prompt on first launch if access
/// hasn't been granted.
@MainActor
final class AccessibilityMonitor {
    private var timer: Timer?
    private(set) var isTrusted: Bool = false

    /// Checks the current permission state, prompts if needed, and begins polling.
    func start() {
        isTrusted = AXIsProcessTrusted()
        if !isTrusted {
            promptForPermission()
        }
        startPolling()
    }

    // MARK: - Private

    /// Shows the system accessibility permission prompt.
    private func promptForPermission() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    /// Polls AXIsProcessTrusted() every second and posts a notification if the status changes.
    /// Runs continuously (not just until permission is granted) so revocation is also detected.
    private func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                let trusted = AXIsProcessTrusted()
                guard trusted != self.isTrusted else { return }
                self.isTrusted = trusted
                NotificationCenter.default.post(
                    name: trusted ? .accessibilityGranted : .accessibilityRevoked,
                    object: nil
                )
            }
        }
    }
}
