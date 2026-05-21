import XCTest
import WidgetKit
@testable import UmaCore

final class WidgetEntryTests: XCTestCase {
    func test_roundTrip_contentState() throws {
        let card = EventCard(category: .gacha, title: "오구리 캡", track: nil,
                             phaseLabel: "종료까지", targetDate: Date(timeIntervalSince1970: 10), status: .active)
        let entry = WidgetEntry(date: Date(timeIntervalSince1970: 0), state: .content([card]),
                                detailLevel: .brief, fontTheme: .mono)
        let data = try JSONEncoder().encode(entry)
        XCTAssertEqual(try JSONDecoder().decode(WidgetEntry.self, from: data), entry)
    }

    func test_decode_missingDetailLevelDefaultsOverview() throws {
        let json = #"{"date":0,"state":{"idle":{}},"fontTheme":"system"}"#.data(using: .utf8)!
        let entry = try JSONDecoder().decode(WidgetEntry.self, from: json)
        XCTAssertEqual(entry.detailLevel, .overview)
    }
}
