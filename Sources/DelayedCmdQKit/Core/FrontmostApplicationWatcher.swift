import AppKit
import Foundation

/// Waits for focus to land on an application other than the one just quit.
///
/// `terminate()` is asynchronous: the dying app stays frontmost while it tears down,
/// and it may not go away at all if it puts up an unsaved-changes sheet. So the next
/// target is whatever *actually* takes focus, and giving up is a normal outcome.
@MainActor
final class FrontmostApplicationWatcher {
    /// How long to wait before deciding focus is not going to move. Long enough for a
    /// slow app to tear down, short enough that a held key does not feel stuck.
    static let defaultTimeout: TimeInterval = 3.0

    private var observer: NSObjectProtocol?
    private var timeoutWorkItem: DispatchWorkItem?
    private var excludedIdentifier: pid_t?
    private var onAvailable: ((NSRunningApplication) -> Void)?
    private var onTimeout: (() -> Void)?

    var isWatching: Bool { observer != nil }

    /// - Parameters:
    ///   - excluding: the application just told to quit; focus returning to it does
    ///     not count, which is what stops a refused quit from looping.
    ///   - onAvailable: called at most once, with the new front application.
    ///   - onTimeout: called at most once, if focus never moved.
    func start(
        excluding: NSRunningApplication?,
        timeout: TimeInterval = FrontmostApplicationWatcher.defaultTimeout,
        onAvailable: @escaping (NSRunningApplication) -> Void,
        onTimeout: @escaping () -> Void
    ) {
        cancel()

        excludedIdentifier = excluding?.processIdentifier
        self.onAvailable = onAvailable
        self.onTimeout = onTimeout

        // The notification block is `@Sendable`, so only the process identifier —
        // never the notification or the application object — crosses back to the
        // main actor.
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let key = NSWorkspace.applicationUserInfoKey
            let identifier = (notification.userInfo?[key] as? NSRunningApplication)?
                .processIdentifier

            MainActor.assumeIsolated {
                self?.handleActivation(of: identifier)
            }
        }

        // Focus may already have moved between the quit and this call.
        if let current = NSWorkspace.shared.frontmostApplication, isEligible(current) {
            deliver(current)
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated {
                guard let self, self.timeoutWorkItem != nil else { return }
                let callback = self.onTimeout
                self.cancel()
                callback?()
            }
        }
        timeoutWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: workItem)
    }

    func cancel() {
        if let observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        observer = nil
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
        excludedIdentifier = nil
        onAvailable = nil
        onTimeout = nil
    }

    isolated deinit {
        cancel()
    }

    private func handleActivation(of identifier: pid_t?) {
        guard let identifier,
              let app = NSRunningApplication(processIdentifier: identifier),
              isEligible(app)
        else { return }

        deliver(app)
    }

    /// Tears the watch down *before* firing, so a callback that immediately starts a
    /// new watch is not cancelled by this one.
    private func deliver(_ app: NSRunningApplication) {
        let callback = onAvailable
        cancel()
        callback?(app)
    }

    private func isEligible(_ app: NSRunningApplication) -> Bool {
        guard !app.isTerminated else { return false }
        guard app.processIdentifier != excludedIdentifier else { return false }
        // Never aim at ourselves; our own Settings window must stay quittable.
        return app.processIdentifier != ProcessInfo.processInfo.processIdentifier
    }
}
