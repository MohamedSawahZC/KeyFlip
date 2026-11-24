public enum ModKey: String, CaseIterable, Identifiable, Hashable, Sendable {
    case capsLock, control, option, command, escape, noAction

    public var id: String { rawValue }

    public static let sources: [ModKey] = [.capsLock, .control, .option, .command]

    /// HID usages: left side first, right side second when the key has two.
    var usages: [UInt64] {
        switch self {
        case .capsLock: [0x700000039]
        case .control: [0x7000000E0, 0x7000000E4]
        case .option: [0x7000000E2, 0x7000000E6]
        case .command: [0x7000000E3, 0x7000000E7]
        case .escape: [0x700000029]
        case .noAction: [0]
        }
    }
}

public struct MapEntry: Hashable, Sendable {
    public let src: UInt64
    public let dst: UInt64

    public init(src: UInt64, dst: UInt64) {
        self.src = src
        self.dst = dst
    }
}

public struct Remap: Equatable, Sendable {
    private var targets: [ModKey: ModKey] = [:]

    public init() {}

    public static let identity = Remap()

    /// Alt and Win trade places, so the keys sit where a Mac keyboard has them.
    public static let altAsCommand = swapping(.option, .command)

    /// Ctrl and Win trade places, so Ctrl+C, Ctrl+V and Ctrl+A work like on Windows.
    public static let ctrlAsCommand = swapping(.control, .command)

    private static func swapping(_ first: ModKey, _ second: ModKey) -> Remap {
        var remap = Remap()
        remap[first] = second
        remap[second] = first
        return remap
    }

    public subscript(source: ModKey) -> ModKey {
        get { targets[source] ?? source }
        set { targets[source] = newValue == source ? nil : newValue }
    }

    public var isIdentity: Bool { targets.isEmpty }

    public func entries() -> [MapEntry] {
        ModKey.sources.flatMap { source -> [MapEntry] in
            let target = self[source]
            guard target != source else { return [] }
            return source.usages.enumerated().map { side, usage in
                MapEntry(src: usage, dst: target.usages[min(side, target.usages.count - 1)])
            }
        }
    }

    public init(entries: [MapEntry]) {
        for entry in entries {
            guard let source = ModKey.sources.first(where: { $0.usages.first == entry.src }),
                  let target = ModKey.allCases.first(where: { $0.usages.contains(entry.dst) })
            else { continue }
            self[source] = target
        }
    }

    public static func preferenceKey(vendorID: Int, productID: Int) -> String {
        "com.apple.keyboard.modifiermapping.\(vendorID)-\(productID)-0"
    }
}
