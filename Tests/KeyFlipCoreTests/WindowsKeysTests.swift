import CoreGraphics
import XCTest
@testable import KeyFlipCore

final class WindowsKeysTests: XCTestCase {
    private let arrowFlags: CGEventFlags = [.maskNumericPad, .maskSecondaryFn]

    private func translate(_ keyCode: CGKeyCode, _ flags: CGEventFlags = []) -> KeyStroke? {
        TextEditingKeys.translate(KeyStroke(keyCode: keyCode, flags: flags))
    }

    func testHomeAndEndJumpWithinTheLine() {
        XCTAssertEqual(translate(115, .maskSecondaryFn), KeyStroke(keyCode: 123, flags: arrowFlags.union(.maskCommand)))
        XCTAssertEqual(translate(119, .maskSecondaryFn), KeyStroke(keyCode: 124, flags: arrowFlags.union(.maskCommand)))
    }

    func testCtrlHomeAndEndJumpToDocumentEdges() {
        XCTAssertEqual(translate(115, .maskCommand), KeyStroke(keyCode: 126, flags: arrowFlags.union(.maskCommand)))
        XCTAssertEqual(translate(119, .maskCommand), KeyStroke(keyCode: 125, flags: arrowFlags.union(.maskCommand)))
    }

    func testCtrlArrowsMoveByWord() {
        // 1) Ctrl+Left arrives as Command+Left under the Ctrl is ⌘ layout
        let stroke = translate(123, arrowFlags.union(.maskCommand))

        // 2) It becomes Option+Left, the Mac word jump
        XCTAssertEqual(stroke, KeyStroke(keyCode: 123, flags: arrowFlags.union(.maskAlternate)))
    }

    func testShiftSurvivesSoSelectionWorks() {
        XCTAssertEqual(
            translate(115, [.maskShift, .maskSecondaryFn]),
            KeyStroke(keyCode: 123, flags: arrowFlags.union([.maskCommand, .maskShift]))
        )
    }

    func testCtrlBackspaceDeletesAWordWithoutArrowFlags() {
        XCTAssertEqual(translate(51, .maskCommand), KeyStroke(keyCode: 51, flags: .maskAlternate))
    }

    func testOtherKeysAreLeftAlone() {
        XCTAssertNil(translate(123, arrowFlags))
        XCTAssertNil(translate(0, .maskCommand))
        XCTAssertNil(translate(123, arrowFlags.union([.maskCommand, .maskAlternate])))
        XCTAssertNil(translate(115, .maskControl))
    }

    func testPrintScreenIsF13WithoutModifiers() {
        XCTAssertTrue(WindowsKeys.isPrintScreen(keyCode: 105, flags: .maskSecondaryFn))
        XCTAssertFalse(WindowsKeys.isPrintScreen(keyCode: 105, flags: .maskCommand))
        XCTAssertFalse(WindowsKeys.isPrintScreen(keyCode: 104, flags: []))
    }
}
