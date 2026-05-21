import XCTest
import SwiftUI
@testable import UmaCore

final class ColorHexTests: XCTestCase {
    func test_parsesSixDigitHex() {
        XCTAssertNotNil(Color(hex: "#1E88E5"))
        XCTAssertNotNil(Color(hex: "1E88E5"))
    }
    func test_invalidHexReturnsNil() {
        XCTAssertNil(Color(hex: "xyz"))
    }
    func test_fontDesignMapping() {
        XCTAssertEqual(Typography.fontDesign(for: .mono), .monospaced)
        XCTAssertEqual(Typography.fontDesign(for: .serif), .serif)
    }
}
