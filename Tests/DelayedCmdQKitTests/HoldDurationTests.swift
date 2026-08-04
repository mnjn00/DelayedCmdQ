import Foundation
import Testing

@testable import DelayedCmdQKit

@Suite("Hold duration policy")
struct HoldDurationTests {
    @Test("Values below the minimum clamp up")
    func clampsLowValues() {
        #expect(HoldDuration.normalized(0) == HoldDuration.range.lowerBound)
        #expect(HoldDuration.normalized(-4) == HoldDuration.range.lowerBound)
    }

    @Test("Values above the maximum clamp down")
    func clampsHighValues() {
        #expect(HoldDuration.normalized(90) == HoldDuration.range.upperBound)
    }

    @Test("Non-finite values fall back to the default")
    func rejectsNonFinite() {
        #expect(HoldDuration.normalized(.nan) == HoldDuration.default)
        #expect(HoldDuration.normalized(.infinity) == HoldDuration.default)
        #expect(HoldDuration.normalized(-.infinity) == HoldDuration.default)
    }

    @Test("In-range values snap to the slider step")
    func snapsToStep() {
        #expect(HoldDuration.normalized(1.24) == 1.2)
        #expect(HoldDuration.normalized(1.26) == 1.3)
        #expect(HoldDuration.normalized(2.0) == 2.0)
    }

    @Test("Normalizing is idempotent across the whole range")
    func isIdempotent() {
        for raw in stride(from: -1.0, through: 6.0, by: 0.07) {
            let once = HoldDuration.normalized(raw)
            #expect(HoldDuration.normalized(once) == once)
        }
    }

    @Test("Every normalized value is a usable hold length")
    func staysWithinRange() {
        for raw in stride(from: -1.0, through: 6.0, by: 0.07) {
            #expect(HoldDuration.range.contains(HoldDuration.normalized(raw)))
        }
    }

    @Test("The default is itself a valid setting")
    func defaultIsValid() {
        #expect(HoldDuration.normalized(HoldDuration.default) == HoldDuration.default)
        #expect(HoldDuration.range.contains(HoldDuration.default))
    }
}
