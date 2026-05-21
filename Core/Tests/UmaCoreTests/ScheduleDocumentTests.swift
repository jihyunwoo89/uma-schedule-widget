import XCTest
@testable import UmaCore

final class ScheduleDocumentTests: XCTestCase {
    func test_decodesV2() throws {
        let json = """
        {"version":2,"updatedAt":"2026-05-20T00:00:00Z","sourcePostNo":1850737,"server":"kr",
         "championsMeetings":[],"leagueOfHeroes":[],"pickups":[]}
        """.data(using: .utf8)!
        let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601
        let doc = try d.decode(ScheduleDocument.self, from: json)
        XCTAssertEqual(doc.version, 2)
        XCTAssertEqual(doc.sourcePostNo, 1850737)
        XCTAssertTrue(doc.pickups.isEmpty)
    }
    func test_empty() { XCTAssertEqual(ScheduleDocument.empty.version, 2) }
}
