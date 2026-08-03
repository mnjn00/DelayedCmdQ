import Foundation

/// A single-shot, cancellable deadline.
///
/// The ring animation is driven by SwiftUI at the display refresh rate rather than
/// by this timer; the countdown only owns the moment the quit actually fires, which
/// keeps the two from fighting over a shared progress value.
@MainActor
final class QuitCountdown {
    private var workItem: DispatchWorkItem?

    var isRunning: Bool { workItem != nil }

    func start(duration: TimeInterval, onComplete: @escaping () -> Void) {
        cancel()

        let item = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated {
                guard let self, self.workItem != nil else { return }
                self.workItem = nil
                onComplete()
            }
        }
        workItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: item)
    }

    func cancel() {
        workItem?.cancel()
        workItem = nil
    }
}
