import XCTest
import SwiftUI
@testable import UmaCore

final class SurfaceStyleTests: XCTestCase {
    func test_surfaceTrackColorHex() {
        XCTAssertEqual(Surface.turf.trackHex, "#3FA56B")
        XCTAssertEqual(Surface.dirt.trackHex, "#9C6B3F")
    }
}
