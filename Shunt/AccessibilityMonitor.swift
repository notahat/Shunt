import ApplicationServices
import Foundation

extension Notification.Name {
    static let accessibilityGranted = Notification.Name("ShuntAccessibilityGranted")
    static let accessibilityRevoked = Notification.Name("ShuntAccessibilityRevoked")
}

// Continuously monitors accessibility permission status and posts notifications
// when it changes. Shows the system permission prompt on first launch if access
// hasn't been granted.
@MainActor
final class AccessibilityMonitor {
    private var timer: Timer?
    private(set) var isTrusted: Bool = false

    func start() {
        isTrusted = AXIsProcessTrusted()

        if !isTrusted {
            let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }

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
