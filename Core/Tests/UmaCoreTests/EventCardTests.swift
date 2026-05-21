import XCTest
@testable import UmaCore

final class EventCardTests: XCTestCase {
    func test_roundTrip() throws {
        let card = EventCard(
            category: .championsMeeting, title: "리브르(LIBRA)",
            track: TrackCondition(racecourse: "도쿄", distanceMeters: 2400, surface: .turf),
            phaseLabel: "라운드1까지", targetDate: Date(timeIntervalSince1970: 5000), status: .upcoming
        )
        let data = try JSONEncoder().encode(card)
        XCTAssertEqual(try JSONDecoder().decode(EventCard.self, from: data), card)
    }

    func test_categoryRawValues() {
        XCTAssertEqual(EventCategory.championsMeeting.rawValue, "championsMeeting")
        XCTAssertEqual(EventCategory.leagueOfHeroes.rawValue, "leagueOfHeroes")
        XCTAssertEqual(EventCategory.gacha.rawValue, "gacha")
    }
}
