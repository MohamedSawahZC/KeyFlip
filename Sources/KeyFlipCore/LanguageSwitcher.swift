import Carbon
import CoreGraphics

/// Spots Alt+Shift pressed and released on their own, the Windows language shortcut.
public struct ChordDetector {
    private static let chord: CGEventFlags = [.maskShift, .maskAlternate]
    private static let watched: CGEventFlags = [.maskShift, .maskAlternate, .maskControl, .maskCommand]

    private var armed = false

    public init() {}

    /// Returns true when the chord completes and the language should switch.
    public mutating func handle(type: CGEventType, flags: CGEventFlags) -> Bool {
        let held = flags.intersection(Self.watched)
        switch type {
        case .keyDown:
            armed = false
        case .flagsChanged where held == Self.chord:
            armed = true
        case .flagsChanged where held.isEmpty:
            defer { armed = false }
            return armed
        case .flagsChanged where !held.isSubset(of: Self.chord):
            armed = false
        default:
            break
        }
        return false
    }
}

public enum LanguageSwitcher {
    public static func makeTap() -> EventTap {
        var detector = ChordDetector()
        return EventTap(events: [.flagsChanged, .keyDown]) { type, event in
            if detector.handle(type: type, flags: event.flags) { selectNextInputSource() }
        }
    }

    public static func selectNextInputSource() {
        // 1) List the keyboard languages the user enabled
        let filter = [
            kTISPropertyInputSourceCategory: kTISCategoryKeyboardInputSource,
            kTISPropertyInputSourceIsSelectCapable: true,
        ] as CFDictionary
        guard let list = TISCreateInputSourceList(filter, false)?.takeRetainedValue() as? [TISInputSource],
              list.count > 1
        else { return }

        // 2) Select the one after the current language, wrapping around
        let currentID = currentInputSourceID()
        let index = list.firstIndex { sourceID($0) == currentID } ?? -1
        TISSelectInputSource(list[(index + 1) % list.count])
    }

    public static func currentInputSourceID() -> String? {
        TISCopyCurrentKeyboardInputSource().flatMap { sourceID($0.takeRetainedValue()) }
    }

    private static func sourceID(_ source: TISInputSource) -> String? {
        guard let raw = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { return nil }
        return Unmanaged<CFString>.fromOpaque(raw).takeUnretainedValue() as String
    }
}
