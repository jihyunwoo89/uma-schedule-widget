import XCTest
@testable import UmaCore

final class EventsTests: XCTestCase {
    private let track = TrackCondition(racecourse: "도쿄", distanceMeters: 2400, surface: .turf)

    func test_championsMeeting_roundTrip() throws {
        let cm = ChampionsMeeting(
            id: "cm-2026-06", name: "리브르(LIBRA)", track: track,
            phases: [EventPhase(kind: .round1, label: "라운드1", date: Date(timeIntervalSince1970: 100))]
        )
        let data = try JSONEncoder().encode(cm)
        XCTAssertEqual(try JSONDecoder().decode(ChampionsMeeting.self, from: data), cm)
    }

    func test_leagueOfHeroes_roundTrip() throws {
        let loh = LeagueOfHeroes(
            id: "loh-2026-s3", season: "시즌 3", track: track,
            phases: [EventPhase(kind: .round1, label: "본선", date: Date(timeIntervalSince1970: 200))]
        )
        let data = try JSONEncoder().encode(loh)
        XCTAssertEqual(try JSONDecoder().decode(LeagueOfHeroes.self, from: data), loh)
    }

    func test_gachaBanner_roundTrip() throws {
        let b = GachaBanner(id: "g1", type: .trainee, featured: ["오구리 캡"],
                            startDate: Date(timeIntervalSince1970: 0),
                            endDate: Date(timeIntervalSince1970: 1000))
        let data = try JSONEncoder().encode(b)
        XCTAssertEqual(try JSONDecoder().decode(GachaBanner.self, from: data), b)
    }

    func test_bannerType_rawValues() {
        XCTAssertEqual(BannerType.trainee.rawValue, "trainee")
        XCTAssertEqual(BannerType.supportCard.rawValue, "supportCard")
    }
}
