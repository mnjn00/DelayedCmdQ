import Carbon.HIToolbox
import CoreGraphics
import Foundation

/// Resolves the physical key code that currently produces a given character.
///
/// macOS routes command shortcuts through the *ASCII capable* keyboard layout, so
/// Cmd+Q lands on a different physical key on AZERTY than it does on QWERTY, while a
/// Korean or Japanese input source falls back to its ASCII companion. Looking the key
/// code up through `UCKeyTranslate` keeps the interceptor correct on every layout
/// instead of hard-coding `kVK_ANSI_Q`.
@MainActor
final class KeyboardLayout {
    static let shared = KeyboardLayout()

    private static let fallbackQuitKeyCode = CGKeyCode(kVK_ANSI_Q)

    private var cachedQuitKeyCode: CGKeyCode?
    private var inputSourceObserver: NSObjectProtocol?

    init() {
        inputSourceObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.cachedQuitKeyCode = nil }
        }
    }

    isolated deinit {
        if let inputSourceObserver {
            DistributedNotificationCenter.default().removeObserver(inputSourceObserver)
        }
    }

    /// Key code of the "Q" key for the active layout.
    var quitKeyCode: CGKeyCode {
        if let cachedQuitKeyCode { return cachedQuitKeyCode }
        let resolved = Self.keyCode(producing: "q") ?? Self.fallbackQuitKeyCode
        cachedQuitKeyCode = resolved
        return resolved
    }

    /// Drops the cached lookup so the next read re-reads the active input source.
    func invalidate() {
        cachedQuitKeyCode = nil
    }

    /// Scans every key code on the current ASCII-capable layout for `character`.
    static func keyCode(producing character: Character) -> CGKeyCode? {
        guard let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue(),
              let rawLayout = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
        else { return nil }

        let layoutData = Unmanaged<CFData>.fromOpaque(rawLayout).takeUnretainedValue() as Data
        let keyboardType = UInt32(LMGetKbdType())

        return layoutData.withUnsafeBytes { buffer -> CGKeyCode? in
            guard let base = buffer.baseAddress else { return nil }
            let layout = base.assumingMemoryBound(to: UCKeyboardLayout.self)

            for code in CGKeyCode(0)..<CGKeyCode(128) {
                guard let produced = translate(keyCode: code, layout: layout, keyboardType: keyboardType),
                      produced == character
                else { continue }
                return code
            }
            return nil
        }
    }

    private static func translate(
        keyCode: CGKeyCode,
        layout: UnsafePointer<UCKeyboardLayout>,
        keyboardType: UInt32
    ) -> Character? {
        var deadKeyState: UInt32 = 0
        var length = 0
        var characters = [UniChar](repeating: 0, count: 4)

        let status = UCKeyTranslate(
            layout,
            UInt16(keyCode),
            UInt16(kUCKeyActionDown),
            0,
            keyboardType,
            UInt32(kUCKeyTranslateNoDeadKeysMask),
            &deadKeyState,
            characters.count,
            &length,
            &characters
        )

        guard status == noErr, length > 0, let scalar = UnicodeScalar(characters[0]) else { return nil }
        return Character(scalar)
    }
}
