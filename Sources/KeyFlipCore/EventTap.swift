import ApplicationServices
import CoreGraphics

/// Watches system-wide input events on the main run loop. Needs Accessibility access.
public final class EventTap {
    /// Returns the event to deliver, or nil to drop it.
    public typealias Handler = (CGEventType, CGEvent) -> CGEvent?

    private let mask: CGEventMask
    private let handler: Handler
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?

    public init(events: [CGEventType], handler: @escaping Handler) {
        mask = events.reduce(0) { $0 | CGEventMask(1 << $1.rawValue) }
        self.handler = handler
    }

    public static var hasPermission: Bool { AXIsProcessTrusted() }

    public static func requestPermission() {
        let prompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        AXIsProcessTrustedWithOptions([prompt: true] as CFDictionary)
    }

    @discardableResult
    public func start() -> Bool {
        guard tap == nil else { return true }

        // 1) Intercept the events for this login session
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: dispatchEvent,
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

    fileprivate func receive(_ type: CGEventType, _ event: CGEvent) -> CGEvent? {
        guard type == .tapDisabledByTimeout || type == .tapDisabledByUserInput else { return handler(type, event) }
        if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
        return event
    }
}

private func dispatchEvent(
    proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else { return Unmanaged.passUnretained(event) }
    let delivered = Unmanaged<EventTap>.fromOpaque(userInfo).takeUnretainedValue().receive(type, event)
    return delivered.map { Unmanaged.passUnretained($0) }
}
