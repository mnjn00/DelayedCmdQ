import Carbon.HIToolbox
import CoreGraphics
import Testing

@testable import DelayedCmdQKit

@Suite("Keyboard layout lookup")
@MainActor
struct KeyboardLayoutTests {
    @Test("The Q key resolves to a real key code")
    func resolvesQuitKey() {
        let layout = KeyboardLayout()
        #expect(layout.quitKeyCode < 128)
    }

    @Test("Lookups are stable across reads and survive invalidation")
    func cachesAndInvalidates() {
        let layout = KeyboardLayout()
        let first = layout.quitKeyCode
        #expect(layout.quitKeyCode == first)

        layout.invalidate()
        #expect(layout.quitKeyCode == first)
    }

    @Test("An unmapped character falls back rather than matching something else")
    func returnsNilForUnmappedCharacter() {
        #expect(KeyboardLayout.keyCode(producing: "\u{10FFFD}") == nil)
    }

    @Test("Distinct characters resolve to distinct keys")
    func distinctCharactersDiffer() throws {
        let q = try #require(KeyboardLayout.keyCode(producing: "q"))
        let w = try #require(KeyboardLayout.keyCode(producing: "w"))
        #expect(q != w)
    }
}
