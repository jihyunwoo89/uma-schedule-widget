import XCTest
@testable import UmaCore

final class EventsTests: XCTestCase {
    private let track = TrackCondition(racecourse: "한신", surface: .turf, distanceMeters: 1600, distanceClass: .mile)
    private func period() -> EventPeriod { EventPeriod(start: Date(timeIntervalSince1970: 100), end: Date(timeIntervalSince1970: 200), estimated: true) }

    func test_championsMeeting_roundTrip() throws {
        let cm = ChampionsMeeting(id: "cm", codeName: "LONG", raceGrade: "G1", raceName: "벚꽃상",
                                  track: track, period: period(),
                                  phases: [EventPhase(kind: .open, label: "오픈", date: Date(timeIntervalSince1970: 100))])
        XCTAssertEqual(try JSONDecoder().decode(ChampionsMeeting.self, from: JSONEncoder().encode(cm)), cm)
    }
    func test_leagueOfHeroes_roundTrip() throws {
        let loh = LeagueOfHeroes(id: "loh", round: "10회차", raceName: "스프린터즈 스테이크스",
                                 track: track, period: period(),
                                 phases: [EventPhase(kind: .open, label: "오픈", date: Date(timeIntervalSince1970: 100))])
        XCTAssertEqual(try JSONDecoder().decode(LeagueOfHeroes.self, from: JSONEncoder().encode(loh)), loh)
    }
    func test_pickupPeriod_roundTrip() throws {
        let p = PickupPeriod(id: "p", period: period(),
                             trainees: ["오르페브르", "푸리오소"],
                             supportCards: [SupportCardPick(rarity: "SSR", name: "아몬드 아이", type: "스피드")])
        XCTAssertEqual(try JSONDecoder().decode(PickupPeriod.self, from: JSONEncoder().encode(p)), p)
    }
}
