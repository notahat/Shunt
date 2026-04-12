import ApplicationServices
import CoreGraphics

/// Intercepts Cmd+Tab and Cmd+Shift+Tab system-wide and triggers Dock navigation
/// instead. Enables and disables the underlying CGEvent tap in response to
/// accessibility permission changes via AccessibilityMonitor.
@MainActor
final class CmdTabInterceptor {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var observers: [Any] = []

    /// Held in a static so the non-capturing callback closure can re-enable the tap.
    private nonisolated(unsafe) static var tapForCallback: CFMachPort?

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
        let newTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { _, type, event, _ in CmdTabInterceptor.handleEvent(type, event) },
            userInfo: nil
        )

        guard let newTap else {
            print("Failed to create event tap.")
            return
        }

        eventTap = newTap
        CmdTabInterceptor.tapForCallback = newTap
        runLoopSource = CFMachPortCreateRunLoopSource(nil, newTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: newTap, enable: true)
    }

    /// Disables and removes the CGEvent tap from the run loop.
    private func tearDownEventTap() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            eventTap = nil
            CmdTabInterceptor.tapForCallback = nil
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            runLoopSource = nil
        }
    }

    private static func handleEvent(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        switch type {
        case .keyDown:
            guard let direction = cycleDirection(for: event) else {
                return Unmanaged.passUnretained(event)
            }
            MainActor.assumeIsolated {
                DockNavigator.navigate(direction: direction)
            }
            return nil
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let tap = tapForCallback {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return nil
        default:
            return Unmanaged.passUnretained(event)
        }
    }

    private static let tabKeyCode: Int64 = 48

    /// Returns the Dock cycling direction if the event is Cmd+Tab or Cmd+Shift+Tab,
    /// or nil if the event should be passed through unchanged.
    private static func cycleDirection(for event: CGEvent) -> DockNavigator.Direction? {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        guard keyCode == tabKeyCode,
              flags.contains(.maskCommand),
              !flags.contains(.maskAlternate),
              !flags.contains(.maskControl)
        else { return nil }
        return flags.contains(.maskShift) ? .backward : .forward
    }
}
