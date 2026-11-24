import XCTest
@testable import KeyFlipCore

final class RemapTests: XCTestCase {
    private func pairs(_ remap: Remap) -> Set<[UInt64]> {
        Set(remap.entries().map { [$0.src, $0.dst] })
    }

    func testIdentityWritesNothing() {
        XCTAssertEqual(Remap.identity.entries(), [])
    }

    func testWindowsPresetSwapsAltAndWinOnBothSides() {
        XCTAssertEqual(pairs(.windows), [
            [0x7000000E2, 0x7000000E3], [0x7000000E3, 0x7000000E2],
            [0x7000000E6, 0x7000000E7], [0x7000000E7, 0x7000000E6],
        ])
    }

    func testCapsLockToEscape() {
        // 1) Map Caps Lock to Escape
        var remap = Remap.identity
        remap[.capsLock] = .escape

        // 2) Only the Caps Lock entry is written
        XCTAssertEqual(remap.entries(), [MapEntry(src: 0x700000039, dst: 0x700000029)])
    }

    func testSidedSourceToUnsidedTargetMapsBothSides() {
        // 1) Disable Control
        var remap = Remap.identity
        remap[.control] = .noAction

        // 2) Left and right Control both go to no action
        XCTAssertEqual(pairs(remap), [[0x7000000E0, 0], [0x7000000E4, 0]])
    }

    func testEntriesRoundTrip() {
        // 1) Build a mixed remap
        var remap = Remap.windows
        remap[.capsLock] = .control
        remap[.control] = .noAction

        // 2) Reading the entries back gives the same remap
        XCTAssertEqual(Remap(entries: remap.entries()), remap)
    }

    func testPreferenceKey() {
        XCTAssertEqual(
            Remap.preferenceKey(vendorID: 9610, productID: 315),
            "com.apple.keyboard.modifiermapping.9610-315-0"
        )
    }
}
