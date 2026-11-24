import CoreGraphics
import XCTest
@testable import KeyFlipCore

final class AppSwitchTranslatorTests: XCTestCase {
    private let tab: CGKeyCode = 48
    private let command: CGKeyCode = 55
    private let option: CGKeyCode = 58
    private var translator = AppSwitchTranslator()

    func testAltTabOpensTheSwitcherAsCommandTab() {
        // 1) Hold Alt, press Tab
        let output = translator.handle(type: .keyDown, keyCode: tab, flags: .maskAlternate)

        // 2) The Tab is replaced by Command down, then Command+Tab
        XCTAssertEqual(output, .init(passOriginal: false, post: [
            KeySpec(type: .flagsChanged, keyCode: command, flags: .maskCommand),
            KeySpec(type: .keyDown, keyCode: tab, flags: .maskCommand),
        ]))
    }

    func testSecondTabCyclesAndShiftGoesBack() {
        // 1) Start switching
        _ = translator.handle(type: .keyDown, keyCode: tab, flags: .maskAlternate)

        // 2) Alt+Shift+Tab becomes Command+Shift+Tab
        let output = translator.handle(type: .keyDown, keyCode: tab, flags: [.maskAlternate, .maskShift])
        XCTAssertEqual(output.post, [KeySpec(type: .keyDown, keyCode: tab, flags: [.maskCommand, .maskShift])])
        XCTAssertFalse(output.passOriginal)
    }

    func testShiftPressMidSwitchKeepsCommandHeld() {
        // 1) Start switching, then press Shift
        _ = translator.handle(type: .keyDown, keyCode: tab, flags: .maskAlternate)
        let output = translator.handle(type: .flagsChanged, keyCode: 56, flags: [.maskAlternate, .maskShift])

        // 2) The switcher still sees Command held
        XCTAssertEqual(output, .init(passOriginal: false, post: [
            KeySpec(type: .flagsChanged, keyCode: 56, flags: [.maskCommand, .maskShift]),
        ]))
    }

    func testReleasingAltPicksTheApp() {
        // 1) Start switching, then release Alt
        _ = translator.handle(type: .keyDown, keyCode: tab, flags: .maskAlternate)
        let output = translator.handle(type: .flagsChanged, keyCode: option, flags: [])

        // 2) Command is released and the real Alt release passes through
        XCTAssertEqual(output, .init(passOriginal: true, post: [
            KeySpec(type: .flagsChanged, keyCode: command, flags: []),
        ]))

        // 3) Later keys are left alone
        XCTAssertEqual(translator.handle(type: .keyDown, keyCode: tab, flags: []), .passThrough)
    }

    func testOtherShortcutsAreUntouched() {
        XCTAssertEqual(translator.handle(type: .keyDown, keyCode: tab, flags: .maskCommand), .passThrough)
        XCTAssertEqual(translator.handle(type: .keyDown, keyCode: tab, flags: [.maskAlternate, .maskControl]), .passThrough)
        XCTAssertEqual(translator.handle(type: .keyDown, keyCode: 0, flags: .maskAlternate), .passThrough)
    }
}
