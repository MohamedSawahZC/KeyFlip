import CoreGraphics
import XCTest
@testable import KeyFlipCore

final class MouseTweaksTests: XCTestCase {
    private func wheelEvent(lines: Int32) throws -> CGEvent {
        try XCTUnwrap(CGEvent(
            scrollWheelEvent2Source: nil, units: .line, wheelCount: 2, wheel1: lines, wheel2: -1, wheel3: 0
        ))
    }

    func testMouseWheelIsReversed() throws {
        // 1) A notched wheel scrolls three lines down
        let event = try wheelEvent(lines: 3)
        let fixed = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
        let points = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)

        // 2) Reverse it
        MouseTweaks.transformWheel(event, reverse: true, speed: 1)

        // 3) Every delta flips sign
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventDeltaAxis1), -3)
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventDeltaAxis2), 1)
        XCTAssertEqual(event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1), -fixed)
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1), -points)
    }

    func testSpeedScalesEveryDelta() throws {
        // 1) One line at double speed
        let event = try wheelEvent(lines: 1)
        let points = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)
        MouseTweaks.transformWheel(event, reverse: false, speed: 2)

        // 2) Lines and points double
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventDeltaAxis1), 2)
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1), points * 2)
    }

    func testOneLineTickNeverRoundsToZero() throws {
        // 1) One line at a speed that rounds down
        let event = try wheelEvent(lines: 1)
        MouseTweaks.transformWheel(event, reverse: true, speed: 1.2)

        // 2) It still scrolls one line, reversed
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventDeltaAxis1), -1)
    }

    func testTrackpadScrollIsUntouched() throws {
        // 1) A continuous trackpad scroll
        let event = try XCTUnwrap(CGEvent(
            scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1, wheel1: 12, wheel2: 0, wheel3: 0
        ))
        event.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)

        // 2) Run it through with every tweak on
        MouseTweaks.transformWheel(event, reverse: true, speed: 3)

        // 3) The direction and speed stay natural
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1), 12)
    }

    func testSideButtonsMapToBackAndForward() {
        XCTAssertEqual(MouseTweaks.navigationKey(forButton: 3), 33)
        XCTAssertEqual(MouseTweaks.navigationKey(forButton: 4), 30)
        XCTAssertNil(MouseTweaks.navigationKey(forButton: 2))
    }
}
