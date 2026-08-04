import AppKit
import Combine
import Foundation

/// Render state for the overlay ring.
@MainActor
final class OverlayModel: ObservableObject {
    /// 0...1 fill of the ring. Animated by SwiftUI, never stepped by a timer.
    @Published var progress: Double = 0
    /// Drives the scale/opacity transition of the whole HUD.
    @Published var isVisible: Bool = false
    /// Icon of the app that will be quit, or nil when the preference is off.
    @Published var icon: NSImage?
    /// How solid the glass coin is drawn.
    @Published var glassOpacity: Double = GlassOpacity.default
}
