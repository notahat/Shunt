import CoreGraphics
import ApplicationServices

@MainActor
final class EventTapManager {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var permissionTimer: Timer?

    func start() {
        if AXIsProcessTrusted() {
            setupEventTap()
        } else {
            // Show the system prompt, then poll until the user grants access.
            let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
            permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    if AXIsProcessTrusted() {
                        self.permissionTimer?.invalidate()
                        self.permissionTimer = nil
                        self.setupEventTap()
                    }
                }
            }
        }
    }

    private func setupEventTap() {
        let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { _, type, event, _ in
                guard type == .keyDown else {
                    return Unmanaged.passUnretained(event)
                }

                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                let flags = event.flags

                let isCmdTab = keyCode == 48
                    && flags.contains(.maskCommand)
                    && !flags.contains(.maskAlternate)
                    && !flags.contains(.maskControl)
                    && !flags.contains(.maskShift)

                guard isCmdTab else {
                    return Unmanaged.passUnretained(event)
                }

                // The callback runs on the main run loop.
                MainActor.assumeIsolated {
                    DockActivator.activate()
                }

                return nil
            },
            userInfo: nil
        )

        guard let tap else {
            print("Failed to create event tap.")
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(nil, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }
}
