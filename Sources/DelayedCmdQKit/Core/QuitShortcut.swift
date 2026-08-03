import CoreGraphics

/// Pure matching rules for the Cmd+Q chord, split out from the event tap so the
/// logic can be exercised without an accessibility-trusted process.
enum QuitShortcut {
    /// Modifiers that must be evaluated exactly; everything else (caps lock, fn,
    /// numeric pad, non-coalesced markers) is irrelevant to the chord.
    static let significantModifiers: CGEventFlags = [
        .maskCommand, .maskShift, .maskControl, .maskAlternate,
    ]

    /// True when `flags` is Command and nothing else that would change the meaning.
    ///
    /// Cmd+Shift+Q is the system log-out shortcut and Cmd+Option+Q is force-quit
    /// adjacent, so both must pass straight through untouched.
    static func matchesModifiers(_ flags: CGEventFlags) -> Bool {
        flags.intersection(significantModifiers) == .maskCommand
    }

    /// True when the event is the Cmd+Q chord for the supplied layout key code.
    static func matches(keyCode: Int64, flags: CGEventFlags, quitKeyCode: CGKeyCode) -> Bool {
        keyCode == Int64(quitKeyCode) && matchesModifiers(flags)
    }

    /// True once Command is no longer held, which ends any in-flight hold.
    static func releasesCommand(_ flags: CGEventFlags) -> Bool {
        !flags.contains(.maskCommand)
    }
}
