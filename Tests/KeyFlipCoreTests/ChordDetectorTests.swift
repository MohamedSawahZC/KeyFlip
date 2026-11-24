import CoreGraphics
import XCTest
@testable import KeyFlipCore

final class ChordDetectorTests: XCTestCase {
    private var detector = ChordDetector()

    private func flags(_ value: CGEventFlags) -> Bool {
        detector.handle(type: .flagsChanged, flags: value)
    }

    func testAltShiftPressAndReleaseFiresOnce() {
        // 1) Press Shift, then Alt, then release both
        let results = [
            flags(.maskShift),
            flags([.maskShift, .maskAlternate]),
            flags(.maskShift),
            flags([]),
        ]

        // 2) It fires only on the final release
        XCTAssertEqual(results, [false, false, false, true])
    }

    func testAltShiftWithALetterDoesNotFire() {
        // 1) Hold Alt+Shift and type a key, as in a real shortcut
        _ = flags([.maskShift, .maskAlternate])
        _ = detector.handle(type: .keyDown, flags: [.maskShift, .maskAlternate])

        // 2) Releasing does not switch language
        XCTAssertFalse(flags([]))
    }

    func testAddingCommandCancels() {
        // 1) Alt+Shift, then Command joins in
        _ = flags([.maskShift, .maskAlternate])
        _ = flags([.maskShift, .maskAlternate, .maskCommand])

        // 2) Releasing does not switch language
        XCTAssertFalse(flags([]))
    }

    func testShiftAloneDoesNotFire() {
        _ = flags(.maskShift)
        XCTAssertFalse(flags([]))
    }
}
