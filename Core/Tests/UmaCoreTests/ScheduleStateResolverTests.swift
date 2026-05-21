import XCTest
@testable import UmaCore

final class ScheduleStateResolverTests: XCTestCase {
    private func d(_ t: TimeInterval) -> Date { Date(timeIntervalSince1970: t) }
    private func doc() -> ScheduleDocument {
        let track = TrackCondition(racecourse: "도쿄", distanceMeters: 2400, surface: .turf)
        let cm = ChampionsMeeting(id: "cm", name: "리브르", track: track, phases: [
            EventPhase(kind: .open, label: "오픈", date: d(100)),
            EventPhase(kind: .ended, label: "종료", date: d(500)),
        ])
        let loh = LeagueOfHeroes(id: "loh", season: "시즌3", track: track, phases: [
            EventPhase(kind: .open, label: "오픈", date: d(200)),
            EventPhase(kind: .ended, label: "종료", date: d(600)),
        ])
        let g = GachaBanner(id: "g", type: .trainee, featured: ["오구리 캡"], startDate: d(150), endDate: d(450))
        return ScheduleDocument(version: 1, updatedAt: d(0), server: "kr",
                                championsMeetings: [cm], leagueOfHeroes: [loh], gachaBanners: [g])
    }

    func test_majorAuto_returnsSingleNearerCard() {
        let state = ScheduleStateResolver.resolve(document: doc(), variant: .majorAuto, now: d(50))
        guard case let .content(cards) = state else { return XCTFail("expected content") }
        XCTAssertEqual(cards.count, 1)
        XCTAssertEqual(cards.first?.category, .championsMeeting)
    }

    func test_allSchedule_returnsThreeCardsInOrder() {
        let state = ScheduleStateResolver.resolve(document: doc(), variant: .allSchedule, now: d(50))
        guard case let .content(cards) = state else { return XCTFail("expected content") }
        XCTAssertEqual(cards.map(\.category), [.championsMeeting, .leagueOfHeroes, .gacha])
    }

    func test_pickupOnly_returnsGachaCard() {
        let state = ScheduleStateResolver.resolve(document: doc(), variant: .pickupOnly, now: d(200))
        guard case let .content(cards) = state else { return XCTFail("expected content") }
        XCTAssertEqual(cards.map(\.category), [.gacha])
    }

    func test_noEventsLeft_returnsIdle() {
        let state = ScheduleStateResolver.resolve(document: doc(), variant: .allSchedule, now: d(9999))
        XCTAssertEqual(state, .idle)
    }

    func test_championsOnly_returnsSingleChampionsCard() {
        let state = ScheduleStateResolver.resolve(document: doc(), variant: .championsOnly, now: d(50))
        guard case let .content(cards) = state else { return XCTFail("expected content") }
        XCTAssertEqual(cards.map(\.category), [.championsMeeting])
    }

    func test_championsLoH_returnsTwoCardsInOrder() {
        let state = ScheduleStateResolver.resolve(document: doc(), variant: .championsLoH, now: d(50))
        guard case let .content(cards) = state else { return XCTFail("expected content") }
        XCTAssertEqual(cards.map(\.category), [.championsMeeting, .leagueOfHeroes])
    }
}
