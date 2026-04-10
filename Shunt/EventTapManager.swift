import ApplicationServices
import CoreGraphics

/// Sets up a CGEvent tap to intercept Cmd+Tab and Cmd+Shift+Tab system-wide. When
/// detected, the event is swallowed and DockActivator is called instead. Enables
/// and disables the tap in response to accessibility permission changes via
/// AccessibilityMonitor.
@MainActor
final class EventTapManager {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var observers: [Any] = []

    /// Registers for accessibility notifications and sets up the event tap
    /// immediately if accessibility access is already granted.
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

    // MARK: - Private

    /// Installs the CGEvent tap on the main run loop.
    private func setupEventTap() {
        guard eventTap == nil else { return }

        let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { _, type, event, _ in
                guard type == .keyDown,
                      let direction = EventTapManager.cycleDirection(for: event)
                else {
                    return Unmanaged.passUnretained(event)
                }
                MainActor.assumeIsolated {
                    DockNavigator.navigate(direction: direction)
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

    /// Disables and removes the CGEvent tap from the run loop.
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

    /// Returns the Dock cycling direction if the event is Cmd+Tab or Cmd+Shift+Tab,
    /// or nil if the event should be passed through unchanged.
    private static func cycleDirection(for event: CGEvent) -> DockNavigator.Direction? {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        guard keyCode == 48,
              flags.contains(.maskCommand),
              !flags.contains(.maskAlternate),
              !flags.contains(.maskControl)
        else { return nil }
        return flags.contains(.maskShift) ? .backward : .forward
    }
}
