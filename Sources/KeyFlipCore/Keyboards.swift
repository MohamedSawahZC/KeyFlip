import Foundation
import IOKit
import IOKit.hid

public struct Keyboard: Identifiable, Hashable, Sendable {
    public let vendorID: Int
    public let productID: Int
    public let name: String

    public var id: String { "\(vendorID)-\(productID)" }
}

private let genericDesktopPage = 1
private let mouseUsage = 2
private let keyboardUsage = 6

public func connectedKeyboards() -> [Keyboard] {
    // 1) Gaming mice also expose a keyboard interface for macros, so collect mice to skip
    let mice = Set(externalHIDDevices(usage: mouseUsage).map(\.id))

    // 2) Keep keyboards that are not mice, one entry per vendor and product
    var seen = Set<String>()
    let keyboards = externalHIDDevices(usage: keyboardUsage).filter {
        !mice.contains($0.id) && seen.insert($0.id).inserted
    }

    // 3) Sort by name for a stable list
    return keyboards.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
}

private func externalHIDDevices(usage: Int) -> [Keyboard] {
    // 1) Find every HID service with this primary usage
    let matching: [String: Any] = [
        kIOHIDPrimaryUsagePageKey: genericDesktopPage,
        kIOHIDPrimaryUsageKey: usage,
    ]
    var iterator: io_iterator_t = 0
    guard IOServiceGetMatchingServices(kIOMainPortDefault, matching as CFDictionary, &iterator) == KERN_SUCCESS
    else { return [] }
    defer { IOObjectRelease(iterator) }

    // 2) Read the identity of each external device
    var devices: [Keyboard] = []
    while case let service = IOIteratorNext(iterator), service != 0 {
        defer { IOObjectRelease(service) }
        let builtIn = property(service, kIOHIDBuiltInKey) as? Bool ?? false
        guard !builtIn,
              let vendor = property(service, kIOHIDVendorIDKey) as? Int, vendor != 0,
              let product = property(service, kIOHIDProductIDKey) as? Int
        else { continue }
        devices.append(Keyboard(
            vendorID: vendor,
            productID: product,
            name: property(service, kIOHIDProductKey) as? String ?? "Keyboard"
        ))
    }
    return devices
}

private func property(_ service: io_service_t, _ key: String) -> Any? {
    IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
}
