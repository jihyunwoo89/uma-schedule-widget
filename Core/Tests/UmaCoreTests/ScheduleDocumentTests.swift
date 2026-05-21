import XCTest
@testable import UmaCore

final class ScheduleDocumentTests: XCTestCase {
    func test_decodesFromJSONWithISO8601Dates() throws {
        let json = """
        {
          "version": 1,
          "updatedAt": "2026-05-20T00:00:00Z",
          "server": "kr",
          "championsMeetings": [],
          "leagueOfHeroes": [],
          "gachaBanners": []
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let doc = try decoder.decode(ScheduleDocument.self, from: json)
        XCTAssertEqual(doc.version, 1)
        XCTAssertEqual(doc.server, "kr")
        XCTAssertTrue(doc.championsMeetings.isEmpty)
    }

    func test_emptyDocumentHelper() {
        XCTAssertEqual(ScheduleDocument.empty.server, "kr")
    }
}
