import AppKit
import CoreGraphics

public struct KeyStroke: Equatable {
    public let keyCode: CGKeyCode
    public let flags: CGEventFlags

    public init(keyCode: CGKeyCode, flags: CGEventFlags) {
        self.keyCode = keyCode
        self.flags = flags
    }
}

/// Windows text navigation on a Mac. Windows Ctrl arrives as ⌘ under the Ctrl is ⌘ layout.
public enum TextEditingKeys {
    private static let home: CGKeyCode = 115
    private static let end: CGKeyCode = 119
    private static let left: CGKeyCode = 123
    private static let right: CGKeyCode = 124
    private static let down: CGKeyCode = 125
    private static let up: CGKeyCode = 126
    private static let backspace: CGKeyCode = 51
    private static let forwardDelete: CGKeyCode = 117

    private static let modifiers: CGEventFlags = [.maskCommand, .maskAlternate, .maskControl]
    private static let arrowFlags: CGEventFlags = [.maskNumericPad, .maskSecondaryFn]

    public static func translate(_ stroke: KeyStroke) -> KeyStroke? {
        // 1) Only plain keys or Windows Ctrl (⌘) combos qualify; Shift rides along
        let held = stroke.flags.intersection(modifiers)
        guard held.isEmpty || held == .maskCommand else { return nil }
        guard let (keyCode, modifier) = target(for: stroke.keyCode, ctrl: !held.isEmpty) else { return nil }

        // 2) Swap in the Mac key and modifier, with the flags arrow keys always carry
        let isArrow = (left...up).contains(keyCode)
        let kept = stroke.flags.subtracting(modifiers.union(arrowFlags))
        return KeyStroke(keyCode: keyCode, flags: kept.union(modifier).union(isArrow ? arrowFlags : []))
    }

    private static func target(for keyCode: CGKeyCode, ctrl: Bool) -> (CGKeyCode, CGEventFlags)? {
        switch (keyCode, ctrl) {
        case (home, false): (left, .maskCommand)
        case (end, false): (right, .maskCommand)
        case (home, true): (up, .maskCommand)
        case (end, true): (down, .maskCommand)
        case (left, true), (right, true), (up, true), (down, true): (keyCode, .maskAlternate)
        case (backspace, true), (forwardDelete, true): (keyCode, .maskAlternate)
        default: nil
        }
    }
}

public struct WindowsKeysOptions: Sendable {
    public var textEditing: Bool
    public var printScreen: Bool

    public init(textEditing: Bool, printScreen: Bool) {
        self.textEditing = textEditing
        self.printScreen = printScreen
    }

    public var changesAnything: Bool { textEditing || printScreen }
}

public enum WindowsKeys {
    /// Windows keyboards send Print Screen as F13.
    private static let printScreenKey: CGKeyCode = 105
    private static let screenshotApp = URL(fileURLWithPath: "/System/Applications/Utilities/Screenshot.app")

    public static func isPrintScreen(keyCode: CGKeyCode, flags: CGEventFlags) -> Bool {
        keyCode == printScreenKey && flags.intersection([.maskCommand, .maskAlternate, .maskControl, .maskShift]).isEmpty
    }

    public static func makeTap(options: @escaping () -> WindowsKeysOptions) -> EventTap {
        EventTap(events: [.keyDown, .keyUp]) { type, event in
            guard !EventTap.isOwnEvent(event) else { return event }
            let current = options()
            let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))

            // 1) Print Screen opens the Screenshot toolbar and is swallowed
            if current.printScreen && isPrintScreen(keyCode: keyCode, flags: event.flags) {
                if type == .keyDown { NSWorkspace.shared.openApplication(at: screenshotApp, configuration: .init()) }
                return nil
            }

            // 2) Text keys are rewritten in place
            if current.textEditing, let stroke = TextEditingKeys.translate(KeyStroke(keyCode: keyCode, flags: event.flags)) {
                event.setIntegerValueField(.keyboardEventKeycode, value: Int64(stroke.keyCode))
                event.flags = stroke.flags
            }
            return event
        }
    }
}
