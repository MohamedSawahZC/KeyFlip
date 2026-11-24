import CoreGraphics

/// Flips notched mouse wheels while leaving trackpads and Magic Mouse on natural scrolling.
public enum ScrollReverser {
    public static func makeTap() -> EventTap {
        EventTap(events: [.scrollWheel]) { _, event in
            reverseIfMouseWheel(event)
            return event
        }
    }

    public static func reverseIfMouseWheel(_ event: CGEvent) {
        guard event.getIntegerValueField(.scrollWheelEventIsContinuous) == 0 else { return }

        // 1) Read every delta first, since writing one field can recompute the others
        let lines: [CGEventField] = [.scrollWheelEventDeltaAxis1, .scrollWheelEventDeltaAxis2]
        let points: [CGEventField] = [.scrollWheelEventPointDeltaAxis1, .scrollWheelEventPointDeltaAxis2]
        let fixed: [CGEventField] = [.scrollWheelEventFixedPtDeltaAxis1, .scrollWheelEventFixedPtDeltaAxis2]
        let integers = (lines + points).map { ($0, event.getIntegerValueField($0)) }
        let doubles = fixed.map { ($0, event.getDoubleValueField($0)) }

        // 2) Write them back with the sign flipped
        for (field, value) in integers { event.setIntegerValueField(field, value: -value) }
        for (field, value) in doubles { event.setDoubleValueField(field, value: -value) }
    }
}
