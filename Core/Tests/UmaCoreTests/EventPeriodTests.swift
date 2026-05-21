import XCTest
@testable import UmaCore

final class EventPeriodTests: XCTestCase {
    func test_roundTrip() throws {
        let p = EventPeriod(start: Date(timeIntervalSince1970: 0), end: Date(timeIntervalSince1970: 86400), estimated: true)
        XCTAssertEqual(try JSONDecoder().decode(EventPeriod.self, from: JSONEncoder().encode(p)), p)
    }
}
