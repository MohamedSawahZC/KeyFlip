import ApplicationServices
import CoreGraphics

/// Flips notched mouse wheels while leaving trackpads and Magic Mouse on natural scrolling.
public final class ScrollReverser {
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?

    public init() {}

    public static var hasPermission: Bool { AXIsProcessTrusted() }

    public static func requestPermission() {
        let prompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        AXIsProcessTrustedWithOptions([prompt: true] as CFDictionary)
    }

    @discardableResult
    public func start() -> Bool {
        guard tap == nil else { return true }

        // 1) Intercept scroll events for this login session
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(1 << CGEventType.scrollWheel.rawValue),
            callback: handleScroll,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return false }

        // 2) Deliver them on the main run loop
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        self.tap = tap
        self.source = source
        return true
    }

    public func stop() {
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        tap = nil
        source = nil
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

    fileprivate func reenable() {
        if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
    }
}

private func handleScroll(
    proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let userInfo { Unmanaged<ScrollReverser>.fromOpaque(userInfo).takeUnretainedValue().reenable() }
    } else {
        ScrollReverser.reverseIfMouseWheel(event)
    }
    return Unmanaged.passUnretained(event)
}
