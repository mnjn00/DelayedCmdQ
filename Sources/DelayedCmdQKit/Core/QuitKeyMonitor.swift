import AppKit
import CoreGraphics
import Foundation

/// User-facing wording lives in `Localization.eventTapFailure`; this stays in
/// English because it is what ends up in a crash log or a bug report.
enum QuitKeyMonitorError: LocalizedError {
    case tapCreationFailed

    var errorDescription: String? {
        switch self {
        case .tapCreationFailed:
            return "Could not create the keyboard event tap."
        }
    }
}

/// Swallows Cmd+Q at the session event tap and reports hold start/end.
///
/// The tap runs in `.defaultTap` mode so the key down can be discarded entirely;
/// the front app never learns the shortcut was pressed unless the hold completes
/// and `QuitCoordinator` terminates it explicitly. All hold bookkeeping lives in
/// `QuitHoldMachine`; this type only translates events into its inputs.
@MainActor
final class QuitKeyMonitor {
    /// Asked before swallowing anything, so pause / self-quit can opt out.
    var shouldIntercept: () -> Bool = { true }
    /// Cmd+Q went down while it was not already held.
    var onHoldBegan: () -> Void = {}
    /// Q or Command came back up, or the tap reset, before the hold resolved.
    var onHoldEnded: () -> Void = {}
    /// A continuous-mode quit fired; start watching for the next front application.
    var onAwaitNextTarget: () -> Void = {}

    private(set) var isRunning = false
    private var machine = QuitHoldMachine()
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    func start() throws {
        guard !isRunning else { return }

        let mask =
            (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: quitKeyMonitorCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            throw QuitKeyMonitorError.tapCreationFailed
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        self.tap = tap
        self.runLoopSource = source
        isRunning = true
    }

    func stop() {
        guard isRunning else { return }

        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }

        tap = nil
        runLoopSource = nil
        isRunning = false
        perform(.tapInterrupted)
    }

    /// Records that the countdown finished. The auto-repeating chord stays absorbed
    /// until the user lets go; in continuous mode the next front application is
    /// picked up and given its own full hold.
    func noteHoldCompleted(continuous: Bool) {
        perform(.holdCompleted(continuous: continuous))
    }

    func noteNextTargetAvailable() {
        perform(.nextTargetAvailable)
    }

    func noteNextTargetUnavailable() {
        perform(.nextTargetUnavailable)
    }

    // MARK: - Event handling

    /// Returns true when the event should be discarded instead of delivered.
    fileprivate func handle(type: CGEventType, event: CGEvent) -> Bool {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            // The system drops taps that run long or that the user disabled; both are
            // recoverable and silently fatal if not re-armed here.
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return perform(.tapInterrupted)

        case .flagsChanged:
            guard QuitShortcut.releasesCommand(event.flags) else { return false }
            return perform(.commandReleased)

        case .keyDown:
            guard isQuitChord(event) else { return false }
            return perform(.chordDown(canIntercept: shouldIntercept()))

        case .keyUp:
            guard event.keyCode == Int64(KeyboardLayout.shared.quitKeyCode) else { return false }
            return perform(.quitKeyUp)

        default:
            return false
        }
    }

    @discardableResult
    private func perform(_ input: QuitHoldMachine.Input) -> Bool {
        let outcome = machine.apply(input)

        switch outcome.effect {
        case .none: break
        case .beginHold: onHoldBegan()
        case .cancelHold: onHoldEnded()
        case .awaitNextTarget: onAwaitNextTarget()
        }

        return outcome.swallow
    }

    private func isQuitChord(_ event: CGEvent) -> Bool {
        QuitShortcut.matches(
            keyCode: event.keyCode,
            flags: event.flags,
            quitKeyCode: KeyboardLayout.shared.quitKeyCode
        )
    }
}

private extension CGEvent {
    var keyCode: Int64 { getIntegerValueField(.keyboardEventKeycode) }
}

/// C callback trampoline. The run loop source lives on the main run loop, so the
/// callback is always delivered on the main thread.
///
/// `CGEvent` is not `Sendable`, so the event crosses into the isolated closure as an
/// opaque pointer and only the discard decision comes back out.
private let quitKeyMonitorCallback: CGEventTapCallBack = { _, type, event, userInfo in
    let passThrough = Unmanaged.passUnretained(event)
    guard let userInfo else { return passThrough }

    // Both pointers are already main-thread confined: the tap's run loop source is
    // installed on the main run loop, and the event is owned by this call frame.
    nonisolated(unsafe) let monitorPointer = userInfo
    nonisolated(unsafe) let eventPointer = passThrough.toOpaque()

    let shouldSwallow = MainActor.assumeIsolated { () -> Bool in
        let monitor = Unmanaged<QuitKeyMonitor>.fromOpaque(monitorPointer).takeUnretainedValue()
        let event = Unmanaged<CGEvent>.fromOpaque(eventPointer).takeUnretainedValue()
        return monitor.handle(type: type, event: event)
    }

    return shouldSwallow ? nil : passThrough
}
