import CoreGraphics

public struct MouseOptions: Sendable {
    public var reverseWheel: Bool
    public var wheelSpeed: Double
    public var sideButtonsNavigate: Bool

    public init(reverseWheel: Bool, wheelSpeed: Double, sideButtonsNavigate: Bool) {
        self.reverseWheel = reverseWheel
        self.wheelSpeed = wheelSpeed
        self.sideButtonsNavigate = sideButtonsNavigate
    }

    public var changesAnything: Bool { reverseWheel || wheelSpeed != 1 || sideButtonsNavigate }
}

/// Mouse wheel direction and speed, and back/forward side buttons. Trackpads and Magic Mouse are untouched.
public enum MouseTweaks {
    private static let backButton: Int64 = 3
    private static let forwardButton: Int64 = 4
    private static let leftBracket: CGKeyCode = 33
    private static let rightBracket: CGKeyCode = 30

    public static func makeTap(options: @escaping () -> MouseOptions) -> EventTap {
        EventTap(events: [.scrollWheel, .otherMouseDown, .otherMouseUp]) { type, event in
            let current = options()
            switch type {
            case .scrollWheel:
                transformWheel(event, reverse: current.reverseWheel, speed: current.wheelSpeed)
                return event
            case .otherMouseDown, .otherMouseUp:
                guard current.sideButtonsNavigate,
                      let key = navigationKey(forButton: event.getIntegerValueField(.mouseEventButtonNumber))
                else { return event }
                if type == .otherMouseDown {
                    EventTap.post(KeySpec(type: .keyDown, keyCode: key, flags: .maskCommand))
                    EventTap.post(KeySpec(type: .keyUp, keyCode: key, flags: .maskCommand))
                }
                return nil
            default:
                return event
            }
        }
    }

    /// Back is ⌘[ and forward is ⌘], which browsers, Finder and most apps understand.
    public static func navigationKey(forButton button: Int64) -> CGKeyCode? {
        switch button {
        case backButton: leftBracket
        case forwardButton: rightBracket
        default: nil
        }
    }

    public static func transformWheel(_ event: CGEvent, reverse: Bool, speed: Double) {
        guard event.getIntegerValueField(.scrollWheelEventIsContinuous) == 0, reverse || speed != 1 else { return }
        let factor = (reverse ? -1 : 1) * speed

        // 1) Read every delta first, since writing one field can recompute the others
        let lines: [CGEventField] = [.scrollWheelEventDeltaAxis1, .scrollWheelEventDeltaAxis2]
        let points: [CGEventField] = [.scrollWheelEventPointDeltaAxis1, .scrollWheelEventPointDeltaAxis2]
        let fixed: [CGEventField] = [.scrollWheelEventFixedPtDeltaAxis1, .scrollWheelEventFixedPtDeltaAxis2]
        let integers = (lines + points).map { ($0, event.getIntegerValueField($0)) }
        let doubles = fixed.map { ($0, event.getDoubleValueField($0)) }

        // 2) Write them back scaled, never letting a real tick round to zero
        for (field, value) in integers { event.setIntegerValueField(field, value: scaled(value, by: factor)) }
        for (field, value) in doubles { event.setDoubleValueField(field, value: value * factor) }
    }

    private static func scaled(_ value: Int64, by factor: Double) -> Int64 {
        guard value != 0 else { return 0 }
        let result = Int64((Double(value) * factor).rounded())
        return result == 0 ? (factor < 0 ? -value.signum() : value.signum()) : result
    }
}
