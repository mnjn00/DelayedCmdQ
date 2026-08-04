import Foundation

/// How solid the glass coin behind the ring is drawn.
///
/// The floor is well above zero on purpose: at full transparency the ring would be
/// left floating with no surface, which is exactly the unreadable HUD this app is
/// meant to avoid.
enum GlassOpacity {
    static let range: ClosedRange<Double> = 0.2...1.0
    static let `default`: Double = 1.0
    static let step: Double = 0.05

    static func normalized(_ value: Double) -> Double {
        guard value.isFinite else { return `default` }
        let clamped = min(max(value, range.lowerBound), range.upperBound)
        let stepped = (clamped / step).rounded() * step
        return (stepped * 100).rounded() / 100
    }

    /// Rendered as a percentage, which reads the same in every language we ship.
    static func text(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }
}
