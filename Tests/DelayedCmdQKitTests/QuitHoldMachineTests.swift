import Testing

@testable import DelayedCmdQKit

@Suite("Cmd+Q hold state machine")
struct QuitHoldMachineTests {
    /// Drives a machine to the moment just after a quit fired.
    private func machineAfterQuit(continuous: Bool) -> QuitHoldMachine {
        var machine = QuitHoldMachine()
        _ = machine.apply(.chordDown(canIntercept: true))
        _ = machine.apply(.holdCompleted(continuous: continuous))
        return machine
    }

    // MARK: - Starting a hold

    @Test("Pressing the chord swallows the key down and starts a hold")
    func startsHold() {
        var machine = QuitHoldMachine()
        let outcome = machine.apply(.chordDown(canIntercept: true))

        #expect(outcome == .init(swallow: true, effect: .beginHold))
        #expect(machine.state == .holding)
    }

    @Test("When interception is off the chord reaches the app untouched")
    func passesThroughWhenNotIntercepting() {
        var machine = QuitHoldMachine()
        let outcome = machine.apply(.chordDown(canIntercept: false))

        #expect(outcome == .init(swallow: false, effect: .none))
        #expect(machine.state == .idle)
    }

    @Test("Auto-repeat during a hold is absorbed without restarting it")
    func absorbsRepeatDuringHold() {
        var machine = QuitHoldMachine()
        _ = machine.apply(.chordDown(canIntercept: true))

        for _ in 0..<5 {
            #expect(machine.apply(.chordDown(canIntercept: true))
                == .init(swallow: true, effect: .none))
        }
        #expect(machine.state == .holding)
    }

    // MARK: - Cancelling

    @Test("Releasing Q early cancels the hold and swallows the key up")
    func releasingKeyCancels() {
        var machine = QuitHoldMachine()
        _ = machine.apply(.chordDown(canIntercept: true))

        #expect(machine.apply(.quitKeyUp) == .init(swallow: true, effect: .cancelHold))
        #expect(machine.state == .idle)
    }

    @Test("Releasing Command early cancels the hold but never eats the event")
    func releasingCommandCancels() {
        var machine = QuitHoldMachine()
        _ = machine.apply(.chordDown(canIntercept: true))

        #expect(machine.apply(.commandReleased) == .init(swallow: false, effect: .cancelHold))
        #expect(machine.state == .idle)
    }

    @Test("A disabled tap cancels an in-flight hold and resets")
    func tapInterruptionCancels() {
        var machine = QuitHoldMachine()
        _ = machine.apply(.chordDown(canIntercept: true))

        #expect(machine.apply(.tapInterrupted) == .init(swallow: false, effect: .cancelHold))
        #expect(machine.state == .idle)
    }

    // MARK: - Single-quit mode

    @Test("A completed hold latches so auto-repeat cannot quit a second app")
    func latchesAfterCompletion() {
        var machine = machineAfterQuit(continuous: false)
        #expect(machine.state == .latched)

        // The user is still physically holding Cmd+Q while the app tears down.
        for _ in 0..<10 {
            #expect(machine.apply(.chordDown(canIntercept: true))
                == .init(swallow: true, effect: .none))
            #expect(machine.state == .latched)
        }
    }

    @Test("Single-quit completion never starts watching for another target")
    func singleQuitDoesNotWatch() {
        var machine = QuitHoldMachine()
        _ = machine.apply(.chordDown(canIntercept: true))

        #expect(machine.apply(.holdCompleted(continuous: false))
            == .init(swallow: false, effect: .none))
    }

    @Test("The latch clears on release, and the next press starts a fresh hold")
    func latchClearsOnRelease() {
        var machine = machineAfterQuit(continuous: false)

        #expect(machine.apply(.quitKeyUp) == .init(swallow: true, effect: .none))
        #expect(machine.state == .idle)
        #expect(machine.apply(.chordDown(canIntercept: true))
            == .init(swallow: true, effect: .beginHold))
    }

    @Test("Releasing Command also clears the latch")
    func commandReleaseClearsLatch() {
        var machine = machineAfterQuit(continuous: false)

        #expect(machine.apply(.commandReleased) == .init(swallow: false, effect: .none))
        #expect(machine.state == .idle)
    }

    // MARK: - Continuous mode

    @Test("Continuous completion waits for the next app instead of re-arming blind")
    func continuousCompletionWaits() {
        var machine = QuitHoldMachine()
        _ = machine.apply(.chordDown(canIntercept: true))

        #expect(machine.apply(.holdCompleted(continuous: true))
            == .init(swallow: false, effect: .awaitNextTarget))
        #expect(machine.state == .awaitingNextTarget)
    }

    @Test("Auto-repeat while waiting is absorbed and does not re-arm")
    func absorbsRepeatWhileWaiting() {
        var machine = machineAfterQuit(continuous: true)

        for _ in 0..<10 {
            #expect(machine.apply(.chordDown(canIntercept: true))
                == .init(swallow: true, effect: .none))
            #expect(machine.state == .awaitingNextTarget)
        }
    }

    @Test("The next app to take focus gets its own full hold")
    func nextTargetStartsNewHold() {
        var machine = machineAfterQuit(continuous: true)

        #expect(machine.apply(.nextTargetAvailable) == .init(swallow: false, effect: .beginHold))
        #expect(machine.state == .holding)
    }

    @Test("Continuous mode can chain several quits while the chord stays down")
    func chainsQuits() {
        var machine = QuitHoldMachine()
        #expect(machine.apply(.chordDown(canIntercept: true)).effect == .beginHold)

        for _ in 0..<3 {
            #expect(machine.apply(.holdCompleted(continuous: true)).effect == .awaitNextTarget)
            #expect(machine.apply(.nextTargetAvailable).effect == .beginHold)
            #expect(machine.state == .holding)
        }

        #expect(machine.apply(.commandReleased) == .init(swallow: false, effect: .cancelHold))
        #expect(machine.state == .idle)
    }

    @Test("If focus never moves, the chain stops instead of retrying forever")
    func stopsWhenFocusDoesNotMove() {
        var machine = machineAfterQuit(continuous: true)

        #expect(machine.apply(.nextTargetUnavailable) == .init(swallow: false, effect: .none))
        #expect(machine.state == .latched)

        #expect(machine.apply(.chordDown(canIntercept: true))
            == .init(swallow: true, effect: .none))
    }

    @Test("Letting go while waiting tears the wait down")
    func releaseWhileWaitingCancels() {
        for release in [QuitHoldMachine.Input.quitKeyUp, .commandReleased, .tapInterrupted] {
            var machine = machineAfterQuit(continuous: true)
            #expect(machine.apply(release).effect == .cancelHold)
            #expect(machine.state == .idle)
        }
    }

    // MARK: - Invariants

    @Test("Stray inputs with nothing in flight are no-ops")
    func ignoresStrayInputs() {
        let inputs: [QuitHoldMachine.Input] = [
            .quitKeyUp, .commandReleased, .tapInterrupted,
            .holdCompleted(continuous: true), .holdCompleted(continuous: false),
            .nextTargetAvailable, .nextTargetUnavailable,
        ]

        for input in inputs {
            var machine = QuitHoldMachine()
            #expect(machine.apply(input) == .init(swallow: false, effect: .none))
            #expect(machine.state == .idle)
        }
    }

    @Test("beginHold is only ever emitted on the way into a hold")
    func beginHoldOnlyOnEntry() {
        let inputs: [QuitHoldMachine.Input] = [
            .quitKeyUp, .commandReleased, .tapInterrupted,
            .holdCompleted(continuous: true), .nextTargetAvailable,
            .chordDown(canIntercept: false),
        ]

        for input in inputs {
            var machine = QuitHoldMachine()
            #expect(machine.apply(input).effect != .beginHold)
            #expect(machine.state == .idle)
        }
    }

    /// A hold ends in one of two ways: the user lets go (`cancelHold`), or the
    /// countdown fires. Both must leave `.holding`, and neither may fire twice, or
    /// the overlay would be orphaned on screen or dismissed while still counting down.
    @Test("Hold entry and exit stay balanced across a long mixed session")
    func holdsAreBalanced() {
        let script: [QuitHoldMachine.Input] = [
            .chordDown(canIntercept: true), .quitKeyUp,
            .chordDown(canIntercept: true), .commandReleased,
            .chordDown(canIntercept: false),
            .chordDown(canIntercept: true), .chordDown(canIntercept: true),
            .holdCompleted(continuous: false), .chordDown(canIntercept: true), .quitKeyUp,
            .chordDown(canIntercept: true), .tapInterrupted,
            .quitKeyUp, .commandReleased,
            .chordDown(canIntercept: true), .holdCompleted(continuous: true),
            .chordDown(canIntercept: true), .nextTargetAvailable,
            .holdCompleted(continuous: true), .nextTargetUnavailable,
            .chordDown(canIntercept: true), .quitKeyUp,
            .chordDown(canIntercept: true), .holdCompleted(continuous: true), .commandReleased,
        ]

        var machine = QuitHoldMachine()
        var open = 0

        for input in script {
            let before = machine.state
            let effect = machine.apply(input).effect
            let after = machine.state

            switch (before == .holding, after == .holding) {
            case (false, true):
                #expect(effect == .beginHold)
                open += 1
            case (true, false):
                #expect(effect == .cancelHold || effect == .awaitNextTarget || effect == .none)
                open -= 1
            default:
                #expect(effect != .beginHold)
            }

            #expect(open == 0 || open == 1)
        }

        #expect(open == 0)
        #expect(machine.state == .idle)
    }

    @Test("Every state returns to idle once the chord is fully released")
    func releaseAlwaysReturnsToIdle() {
        let setups: [[QuitHoldMachine.Input]] = [
            [],
            [.chordDown(canIntercept: true)],
            [.chordDown(canIntercept: true), .holdCompleted(continuous: false)],
            [.chordDown(canIntercept: true), .holdCompleted(continuous: true)],
            [
                .chordDown(canIntercept: true), .holdCompleted(continuous: true),
                .nextTargetUnavailable,
            ],
        ]

        for setup in setups {
            var machine = QuitHoldMachine()
            for input in setup { _ = machine.apply(input) }

            _ = machine.apply(.quitKeyUp)
            _ = machine.apply(.commandReleased)
            #expect(machine.state == .idle)
        }
    }
}
