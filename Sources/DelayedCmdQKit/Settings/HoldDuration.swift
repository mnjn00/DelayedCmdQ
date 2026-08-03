import Foundation

/// Policy for how long Cmd+Q must be held before the front app is asked to quit.
///
/// Kept free of actor isolation so the clamping rules stay usable from anywhere and
/// testable without a main-actor hop.
enum HoldDuration {
    static let range: ClosedRange<TimeInterval> = 0.3...5.0
    static let `default`: TimeInterval = 1.0
    static let step: TimeInterval = 0.1

    /// Clamps to the supported range and snaps to the slider step, so a stale or
    /// hand-edited defaults entry can never produce a zero-length or endless hold.
    static func normalized(_ value: TimeInterval) -> TimeInterval {
        guard value.isFinite else { return `default` }
        let clamped = min(max(value, range.lowerBound), range.upperBound)
        let stepped = (clamped / step).rounded() * step
        return (stepped * 100).rounded() / 100
    }

    static func text(_ value: TimeInterval) -> String {
        String(format: "%.1f초", value)
    }
}
