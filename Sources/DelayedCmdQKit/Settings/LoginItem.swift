import Foundation
import ServiceManagement

/// Thin wrapper over `SMAppService` so the settings view can bind to a Bool.
///
/// Registration only works from a signed app bundle; running the bare SPM binary
/// throws, which is reported instead of silently flipping the toggle back.
@MainActor
final class LoginItem: ObservableObject {
    @Published private(set) var isEnabled: Bool
    @Published private(set) var lastError: String?

    private let service = SMAppService.mainApp

    init() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    func refresh() {
        isEnabled = service.status == .enabled
        if service.status != .requiresApproval {
            lastError = nil
        }
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
        refresh()
    }
}
