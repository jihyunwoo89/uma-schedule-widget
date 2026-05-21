import XCTest
@testable import UmaCore

final class ScheduleFallbackTests: XCTestCase {
    func test_loadsBundledDocument() throws {
        let doc = try ScheduleFallback.production.load()
        XCTAssertEqual(doc.server, "kr")
        XCTAssertFalse(doc.championsMeetings.isEmpty)
        XCTAssertFalse(doc.gachaBanners.isEmpty)
    }
}
