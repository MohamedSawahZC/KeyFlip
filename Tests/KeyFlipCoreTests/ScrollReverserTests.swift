import CoreGraphics
import XCTest
@testable import KeyFlipCore

final class ScrollReverserTests: XCTestCase {
    func testMouseWheelIsReversed() throws {
        // 1) A notched wheel scrolls three lines down
        let event = try XCTUnwrap(CGEvent(
            scrollWheelEvent2Source: nil, units: .line, wheelCount: 2, wheel1: 3, wheel2: -1, wheel3: 0
        ))
        let fixed = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
        let points = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)

        // 2) Reverse it
        ScrollReverser.reverseIfMouseWheel(event)

        // 3) Every delta flips sign
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventDeltaAxis1), -3)
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventDeltaAxis2), 1)
        XCTAssertEqual(event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1), -fixed)
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1), -points)
    }

    func testTrackpadScrollIsUntouched() throws {
        // 1) A continuous trackpad scroll
        let event = try XCTUnwrap(CGEvent(
            scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1, wheel1: 12, wheel2: 0, wheel3: 0
        ))
        event.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)

        // 2) Run it through the reverser
        ScrollReverser.reverseIfMouseWheel(event)

        // 3) The direction stays natural
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1), 12)
    }
}
