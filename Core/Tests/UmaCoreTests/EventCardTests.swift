import XCTest
@testable import UmaCore

final class EventCardTests: XCTestCase {
    func test_roundTrip() throws {
        let card = EventCard(
            category: .championsMeeting, title: "LONG", subtitle: "G1 벚꽃상",
            track: TrackCondition(racecourse: "한신", surface: .turf, distanceMeters: 1600, distanceClass: .mile),
            period: EventPeriod(start: Date(timeIntervalSince1970: 100), end: Date(timeIntervalSince1970: 200), estimated: true),
            phaseLabel: "오픈까지", targetDate: Date(timeIntervalSince1970: 100), status: .upcoming,
            trainees: [], supportCards: [])
        XCTAssertEqual(try JSONDecoder().decode(EventCard.self, from: JSONEncoder().encode(card)), card)
    }
}
