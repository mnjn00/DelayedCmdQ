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

@Suite("Glass opacity policy")
struct GlassOpacityTests {
    @Test("Values clamp into the readable range")
    func clamps() {
        #expect(GlassOpacity.normalized(0) == GlassOpacity.range.lowerBound)
        #expect(GlassOpacity.normalized(-3) == GlassOpacity.range.lowerBound)
        #expect(GlassOpacity.normalized(9) == GlassOpacity.range.upperBound)
    }

    @Test("Non-finite values fall back to the default")
    func rejectsNonFinite() {
        #expect(GlassOpacity.normalized(.nan) == GlassOpacity.default)
        #expect(GlassOpacity.normalized(.infinity) == GlassOpacity.default)
    }

    /// A fully transparent coin would leave the ring floating with no surface,
    /// which is the unreadable HUD the app exists to avoid.
    @Test("The floor never reaches full transparency")
    func neverFullyTransparent() {
        for raw in stride(from: -1.0, through: 2.0, by: 0.03) {
            let value = GlassOpacity.normalized(raw)
            #expect(value >= GlassOpacity.range.lowerBound)
            #expect(value > 0)
            #expect(value <= 1.0)
        }
    }

    @Test("Normalizing is idempotent")
    func isIdempotent() {
        for raw in stride(from: -1.0, through: 2.0, by: 0.03) {
            let once = GlassOpacity.normalized(raw)
            #expect(GlassOpacity.normalized(once) == once)
        }
    }

    @Test("Rendered as a whole percentage")
    func formatsAsPercent() {
        #expect(GlassOpacity.text(1.0) == "100%")
        #expect(GlassOpacity.text(0.2) == "20%")
        #expect(GlassOpacity.text(0.55) == "55%")
    }
}
