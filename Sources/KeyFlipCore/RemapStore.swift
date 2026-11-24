import Foundation

public enum RemapError: LocalizedError {
    case hidutilFailed(String)

    public var errorDescription: String? {
        switch self {
        case .hidutilFailed(let output): "Could not apply the mapping: \(output)"
        }
    }
}

private let srcKey = "HIDKeyboardModifierMappingSrc"
private let dstKey = "HIDKeyboardModifierMappingDst"
private let hidutilPath = "/usr/bin/hidutil"

public func savedRemap(for keyboard: Keyboard) -> Remap {
    let key = Remap.preferenceKey(vendorID: keyboard.vendorID, productID: keyboard.productID)
    let value = CFPreferencesCopyValue(
        key as CFString, kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost
    )
    let dicts = value as? [[String: Any]] ?? []
    return Remap(entries: dicts.compactMap { dict in
        guard let src = (dict[srcKey] as? NSNumber)?.uint64Value,
              let dst = (dict[dstKey] as? NSNumber)?.uint64Value
        else { return nil }
        return MapEntry(src: src, dst: dst)
    })
}

public func apply(_ remap: Remap, to keyboard: Keyboard) throws {
    let entries = remap.entries()

    // 1) Save where System Settings keeps it, so it survives reboot and replug
    let key = Remap.preferenceKey(vendorID: keyboard.vendorID, productID: keyboard.productID)
    let stored: [[String: Int64]]? = remap.isIdentity ? nil : entries.map {
        [srcKey: Int64($0.src), dstKey: Int64($0.dst)]
    }
    CFPreferencesSetValue(
        key as CFString, stored as CFPropertyList?,
        kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost
    )
    CFPreferencesSynchronize(kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)

    // 2) Apply it to the connected keyboard right away
    try applyLive(remap, to: keyboard)
}

/// Changes the connected keyboard for this session only, leaving the saved mapping alone.
public func applyLive(_ remap: Remap, to keyboard: Keyboard) throws {
    let matching = #"{"VendorID":\#(keyboard.vendorID),"ProductID":\#(keyboard.productID)}"#
    let mapping = remap.entries()
        .map { #"{"\#(srcKey)":\#($0.src),"\#(dstKey)":\#($0.dst)}"# }
        .joined(separator: ",")
    try runHidutil(["property", "--matching", matching, "--set", #"{"UserKeyMapping":[\#(mapping)]}"#])
}

private func runHidutil(_ arguments: [String]) throws {
    let process = Process()
    let pipe = Pipe()
    process.executableURL = URL(fileURLWithPath: hidutilPath)
    process.arguments = arguments
    process.standardOutput = pipe
    process.standardError = pipe
    try process.run()
    let output = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
    process.waitUntilExit()
    guard process.terminationStatus == 0 else { throw RemapError.hidutilFailed(output) }
}
