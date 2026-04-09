import ApplicationServices
import CoreGraphics

// Sets up a CGEvent tap to intercept Cmd+Tab system-wide. When detected, the event
// is swallowed and DockActivator is called instead. Enables and disables the tap
// in response to accessibility permission changes via AccessibilityMonitor.
@MainActor
final class EventTapManager {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var observers: [Any] = []

    func start(accessibilityGranted: Bool) {
        observers.append(NotificationCenter.default.addObserver(
            forName: .accessibilityGranted, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.setupEventTap() }
        })

        observers.append(NotificationCenter.default.addObserver(
            forName: .accessibilityRevoked, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.tearDownEventTap() }
        })

        if accessibilityGranted {
            setupEventTap()
        }
    }

    private func setupEventTap() {
        guard eventTap == nil else { return }

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

    private func tearDownEventTap() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }
}
