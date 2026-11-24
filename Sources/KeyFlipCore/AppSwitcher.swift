import CoreGraphics

public struct KeySpec: Equatable {
    public let type: CGEventType
    public let keyCode: CGKeyCode
    public let flags: CGEventFlags
}

/// Turns a Windows-style Alt+Tab into the Mac Command+Tab app switcher.
public struct AppSwitchTranslator {
    public struct Output: Equatable {
        public let passOriginal: Bool
        public let post: [KeySpec]

        public static let passThrough = Output(passOriginal: true, post: [])
    }

    private static let tab: CGKeyCode = 48
    private static let command: CGKeyCode = 55
    private static let shortcutModifiers: CGEventFlags = [.maskAlternate, .maskCommand, .maskControl]

    private var switching = false

    public init() {}

    public mutating func handle(type: CGEventType, keyCode: CGKeyCode, flags: CGEventFlags) -> Output {
        let held = flags.intersection(Self.shortcutModifiers)
        switch type {
        case .keyDown where !switching && keyCode == Self.tab && held == .maskAlternate:
            switching = true
            return Output(passOriginal: false, post: [
                KeySpec(type: .flagsChanged, keyCode: Self.command, flags: Self.asCommand(flags)),
                KeySpec(type: .keyDown, keyCode: keyCode, flags: Self.asCommand(flags)),
            ])
        case .keyDown where switching, .keyUp where switching:
            return Output(passOriginal: false, post: [KeySpec(type: type, keyCode: keyCode, flags: Self.asCommand(flags))])
        case .flagsChanged where switching && !flags.contains(.maskAlternate):
            switching = false
            return Output(passOriginal: true, post: [
                KeySpec(type: .flagsChanged, keyCode: Self.command, flags: flags.subtracting(.maskCommand)),
            ])
        case .flagsChanged where switching:
            return Output(passOriginal: false, post: [KeySpec(type: type, keyCode: keyCode, flags: Self.asCommand(flags))])
        default:
            return .passThrough
        }
    }

    private static func asCommand(_ flags: CGEventFlags) -> CGEventFlags {
        flags.subtracting(.maskAlternate).union(.maskCommand)
    }
}

public enum AppSwitcher {
    public static func makeTap() -> EventTap {
        var translator = AppSwitchTranslator()
        return EventTap(events: [.keyDown, .keyUp, .flagsChanged]) { type, event in
            guard !EventTap.isOwnEvent(event) else { return event }
            let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
            let output = translator.handle(type: type, keyCode: keyCode, flags: event.flags)
            output.post.forEach(EventTap.post)
            return output.passOriginal ? event : nil
        }
    }
}
