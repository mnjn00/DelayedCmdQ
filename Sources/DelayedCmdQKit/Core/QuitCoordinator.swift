import AppKit
import Foundation

/// Wires the key monitor, the countdown and the overlay together.
///
/// The target application is captured when the hold begins so a Space switch or a
/// focus change midway through cannot redirect the quit at somebody else.
@MainActor
final class QuitCoordinator {
    private let settings: AppSettings
    private let authorization: AccessibilityAuthorization
    private let monitor: QuitKeyMonitor
    private let countdown: QuitCountdown
    private let overlay: OverlayPresenter
    private let frontmostWatcher: FrontmostApplicationWatcher

    private var targetApplication: NSRunningApplication?
    private var lastQuitApplication: NSRunningApplication?
    /// Set by the focus watcher so a continuous-mode re-arm uses the app it actually
    /// saw activate, rather than re-reading a `frontmostApplication` that may still
    /// be catching up.
    private var pendingTarget: NSRunningApplication?

    init(
        settings: AppSettings,
        authorization: AccessibilityAuthorization,
        monitor: QuitKeyMonitor = QuitKeyMonitor(),
        countdown: QuitCountdown = QuitCountdown(),
        overlay: OverlayPresenter = OverlayPresenter(),
        frontmostWatcher: FrontmostApplicationWatcher = FrontmostApplicationWatcher()
    ) {
        self.settings = settings
        self.authorization = authorization
        self.monitor = monitor
        self.countdown = countdown
        self.overlay = overlay
        self.frontmostWatcher = frontmostWatcher

        monitor.shouldIntercept = { [weak self] in self?.shouldIntercept() ?? false }
        monitor.onHoldBegan = { [weak self] in self?.beginHold() }
        monitor.onHoldEnded = { [weak self] in self?.cancelHold() }
        monitor.onAwaitNextTarget = { [weak self] in self?.awaitNextTarget() }
    }

    private(set) var lastStartError: Error?

    var isActive: Bool { monitor.isRunning }

    /// Starts intercepting when trusted; a failure here is surfaced in the menu and
    /// in Settings rather than thrown, because it is a permission state, not a bug.
    func start() {
        guard authorization.isTrusted else { return }
        do {
            try monitor.start()
            lastStartError = nil
        } catch {
            lastStartError = error
        }
    }

    func stop() {
        cancelHold()
        monitor.stop()
    }

    // MARK: - Hold lifecycle

    private func shouldIntercept() -> Bool {
        guard !settings.isPaused else { return false }

        guard let frontmost = NSWorkspace.shared.frontmostApplication else { return false }
        // Never swallow our own Cmd+Q; the Settings window must stay quittable.
        guard frontmost.processIdentifier != ProcessInfo.processInfo.processIdentifier else {
            return false
        }
        return true
    }

    private func beginHold() {
        let target = pendingTarget ?? NSWorkspace.shared.frontmostApplication
        pendingTarget = nil
        targetApplication = target

        overlay.present(
            icon: settings.showsApplicationIcon ? target?.icon : nil,
            duration: settings.holdDuration,
            glassOpacity: settings.glassOpacity
        )
        countdown.start(duration: settings.holdDuration) { [weak self] in
            self?.completeHold()
        }
    }

    private func cancelHold() {
        countdown.cancel()
        frontmostWatcher.cancel()
        targetApplication = nil
        lastQuitApplication = nil
        pendingTarget = nil
        overlay.dismiss(completed: false)
    }

    private func completeHold() {
        let target = targetApplication
        targetApplication = nil
        lastQuitApplication = target
        overlay.dismiss(completed: true)

        // Feed the machine before terminating, so continuous mode is already watching
        // for the focus change that the terminate is about to cause.
        monitor.noteHoldCompleted(continuous: settings.allowsContinuousQuit)

        guard let target, !target.isTerminated else { return }
        target.terminate()
    }

    /// Continuous mode: wait for focus to reach a different app, then run another
    /// full hold against it. Nothing quits without the ring filling again.
    private func awaitNextTarget() {
        frontmostWatcher.start(excluding: lastQuitApplication) { [weak self] application in
            guard let self else { return }
            // Both settings can change during the wait; honour the current values.
            guard self.settings.allowsContinuousQuit, !self.settings.isPaused else {
                self.monitor.noteNextTargetUnavailable()
                return
            }
            self.pendingTarget = application
            self.monitor.noteNextTargetAvailable()
        } onTimeout: { [weak self] in
            self?.monitor.noteNextTargetUnavailable()
        }
    }
}
