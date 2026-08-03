import CoreGraphics
import Testing

@testable import DelayedCmdQKit

@Suite("Cmd+Q chord matching")
struct QuitShortcutTests {
    private let quitKeyCode: CGKeyCode = 12

    @Test("Command alone on the Q key matches")
    func matchesCommandQ() {
        #expect(
            QuitShortcut.matches(keyCode: 12, flags: [.maskCommand], quitKeyCode: quitKeyCode)
        )
    }

    @Test("Irrelevant modifiers do not block the match")
    func ignoresIrrelevantModifiers() {
        let flags: CGEventFlags = [.maskCommand, .maskAlphaShift, .maskNonCoalesced]
        #expect(QuitShortcut.matches(keyCode: 12, flags: flags, quitKeyCode: quitKeyCode))
    }

    @Test(
        "Chords that mean something else in macOS pass through",
        arguments: [
            CGEventFlags([.maskCommand, .maskShift]),
            CGEventFlags([.maskCommand, .maskAlternate]),
            CGEventFlags([.maskCommand, .maskControl]),
            CGEventFlags([.maskShift]),
            CGEventFlags([]),
        ]
    )
    func rejectsOtherChords(flags: CGEventFlags) {
        #expect(!QuitShortcut.matches(keyCode: 12, flags: flags, quitKeyCode: quitKeyCode))
    }

    @Test("A different key with Command does not match")
    func rejectsOtherKeys() {
        #expect(
            !QuitShortcut.matches(keyCode: 13, flags: [.maskCommand], quitKeyCode: quitKeyCode)
        )
    }

    @Test("Losing Command ends the hold")
    func detectsCommandRelease() {
        #expect(QuitShortcut.releasesCommand([]))
        #expect(QuitShortcut.releasesCommand([.maskShift]))
        #expect(!QuitShortcut.releasesCommand([.maskCommand]))
        #expect(!QuitShortcut.releasesCommand([.maskCommand, .maskShift]))
    }
}
