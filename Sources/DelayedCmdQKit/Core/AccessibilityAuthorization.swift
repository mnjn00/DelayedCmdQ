import ApplicationServices
import AppKit
import Combine
import Foundation

/// Tracks whether the process is accessibility-trusted.
///
/// Granting the permission does not relaunch or notify the app, so the state is
/// polled while untrusted and the poll stops as soon as access appears.
@MainActor
final class AccessibilityAuthorization: ObservableObject {
    private static let settingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    )

    /// Literal value of `kAXTrustedCheckOptionPrompt`, which is imported as a mutable
    /// global and therefore cannot be read under strict concurrency.
    private static let promptOptionKey = "AXTrustedCheckOptionPrompt"

    @Published private(set) var isTrusted: Bool

    private var pollTimer: Timer?

    var onTrustGranted: () -> Void = {}

    init() {
        isTrusted = AXIsProcessTrusted()
    }

    isolated deinit {
        pollTimer?.invalidate()
    }

    /// Shows the system prompt once, then watches for the grant in the background.
    func request() {
        let options = [Self.promptOptionKey: true] as CFDictionary
        refresh(with: AXIsProcessTrustedWithOptions(options))
    }

    func refresh() {
        refresh(with: AXIsProcessTrusted())
    }

    func beginMonitoring() {
        refresh()
        guard !isTrusted, pollTimer == nil else { return }

        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
    }

    func openSystemSettings() {
        guard let url = Self.settingsURL else { return }
        NSWorkspace.shared.open(url)
    }

    private func refresh(with trusted: Bool) {
        guard trusted != isTrusted else { return }
        isTrusted = trusted

        if trusted {
            pollTimer?.invalidate()
            pollTimer = nil
            onTrustGranted()
        } else {
            beginMonitoring()
        }
    }
}
