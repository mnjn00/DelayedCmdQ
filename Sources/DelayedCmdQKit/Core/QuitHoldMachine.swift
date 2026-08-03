/// State machine for one Cmd+Q hold, expressed in semantic inputs so it can be
/// exercised without an accessibility-trusted process or synthetic `CGEvent`s.
struct QuitHoldMachine {
    enum State: Equatable {
        /// Nothing pressed, or the chord has been fully released.
        case idle
        /// Cmd+Q is down and the ring is filling.
        case holding
        /// A quit fired in continuous mode and focus has not moved yet. The app that
        /// was just told to quit stays frontmost for a moment, so re-arming here would
        /// aim at a corpse; the coordinator waits for a genuinely new front app.
        case awaitingNextTarget
        /// A quit fired and no further one is wanted. Cmd+Q auto-repeats while the
        /// user is still pressing it, so key downs are absorbed until they let go;
        /// otherwise the repeat would immediately start another hold.
        case latched
    }

    enum Input {
        /// Cmd+Q key down. `canIntercept` is false when paused or when our own app
        /// is frontmost, in which case the chord must reach its destination.
        case chordDown(canIntercept: Bool)
        case quitKeyUp
        case commandReleased
        /// The countdown reached the configured duration. `continuous` is the user's
        /// "keep quitting while held" preference.
        case holdCompleted(continuous: Bool)
        /// A different application took focus after a continuous-mode quit.
        case nextTargetAvailable
        /// Focus never moved, so there is nothing left to quit.
        case nextTargetUnavailable
        /// The system disabled the tap, so key state can no longer be trusted.
        case tapInterrupted
    }

    enum Effect: Equatable {
        case none
        case beginHold
        /// Tear down whatever is in flight: the countdown, the overlay, and any
        /// pending wait for the next front application.
        case cancelHold
        /// Start watching for the next application to take focus.
        case awaitNextTarget
    }

    struct Outcome: Equatable {
        /// True when the event must be discarded instead of delivered.
        let swallow: Bool
        let effect: Effect
    }

    private(set) var state: State = .idle

    /// True while the chord is engaged and further key downs must be absorbed.
    private var absorbsRepeats: Bool {
        switch state {
        case .holding, .awaitingNextTarget, .latched: return true
        case .idle: return false
        }
    }

    mutating func apply(_ input: Input) -> Outcome {
        switch input {
        case .chordDown(let canIntercept):
            guard !absorbsRepeats else {
                // Auto-repeat: absorb it, but it is not a new hold.
                return Outcome(swallow: true, effect: .none)
            }
            guard canIntercept else { return Outcome(swallow: false, effect: .none) }
            state = .holding
            return Outcome(swallow: true, effect: .beginHold)

        case .quitKeyUp:
            // Swallowed whenever the matching key down never reached the app.
            let swallow = absorbsRepeats
            return Outcome(swallow: swallow, effect: release())

        case .commandReleased, .tapInterrupted:
            // Modifier changes and tap resets always reach the app; only the hold
            // is affected.
            return Outcome(swallow: false, effect: release())

        case .holdCompleted(let continuous):
            guard state == .holding else { return Outcome(swallow: false, effect: .none) }
            state = continuous ? .awaitingNextTarget : .latched
            return Outcome(swallow: false, effect: continuous ? .awaitNextTarget : .none)

        case .nextTargetAvailable:
            guard state == .awaitingNextTarget else {
                return Outcome(swallow: false, effect: .none)
            }
            state = .holding
            return Outcome(swallow: false, effect: .beginHold)

        case .nextTargetUnavailable:
            guard state == .awaitingNextTarget else {
                return Outcome(swallow: false, effect: .none)
            }
            state = .latched
            return Outcome(swallow: false, effect: .none)
        }
    }

    /// Returns to idle, cancelling in-flight work only when there was some.
    private mutating func release() -> Effect {
        let hadWorkInFlight = state == .holding || state == .awaitingNextTarget
        state = .idle
        return hadWorkInFlight ? .cancelHold : .none
    }
}
