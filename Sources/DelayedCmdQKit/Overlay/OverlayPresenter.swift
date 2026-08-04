import AppKit
import SwiftUI

/// Owns the overlay panel and drives the ring animation.
///
/// The fill is a single `.linear` SwiftUI animation over the hold duration rather
/// than a per-frame timer, so it renders at the display's native refresh rate and
/// stays in step with the countdown that actually triggers the quit.
@MainActor
final class OverlayPresenter {
    private let model = OverlayModel()
    private var panel: OverlayPanel?
    private var teardownWorkItem: DispatchWorkItem?

    func present(icon: NSImage?, duration: TimeInterval, glassOpacity: Double) {
        teardownWorkItem?.cancel()
        teardownWorkItem = nil

        let panel = existingPanel()
        model.icon = icon
        model.glassOpacity = glassOpacity
        // Reset without animation so the fill always starts from an empty ring.
        var reset = Transaction()
        reset.disablesAnimations = true
        withTransaction(reset) {
            model.progress = 0
            model.isVisible = false
        }

        panel.centerOnActiveScreen()
        panel.orderFrontRegardless()

        // Kick the animations one runloop pass later so SwiftUI has committed the
        // reset frame and animates from empty rather than from the previous fill.
        DispatchQueue.main.async { [model] in
            withAnimation(RingMetrics.appearAnimation) { model.isVisible = true }
            withAnimation(.linear(duration: duration)) { model.progress = 1 }
        }
    }

    func dismiss(completed: Bool) {
        guard let panel, panel.isVisible else { return }

        withAnimation(RingMetrics.disappearAnimation) {
            model.isVisible = false
            if !completed {
                // Unwind the partial fill so a cancelled hold reads as "nothing happened".
                model.progress = 0
            }
        }

        let workItem = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.teardownWorkItem = nil
                self.panel?.orderOut(nil)
                var reset = Transaction()
                reset.disablesAnimations = true
                withTransaction(reset) { self.model.progress = 0 }
            }
        }
        teardownWorkItem = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + RingMetrics.disappearDuration,
            execute: workItem
        )
    }

    private func existingPanel() -> OverlayPanel {
        if let panel { return panel }

        let size = NSSize(width: RingMetrics.canvas, height: RingMetrics.canvas)
        let panel = OverlayPanel(contentSize: size)
        let hosting = NSHostingView(rootView: ProgressRingView(model: model))
        hosting.frame = NSRect(origin: .zero, size: size)
        panel.contentView = hosting

        self.panel = panel
        return panel
    }
}
