import XCTest
@testable import UmaCore

final class EventCardFactoryTests: XCTestCase {
    private func d(_ t: TimeInterval) -> Date { Date(timeIntervalSince1970: t) }

    private func doc() -> ScheduleDocument {
        let track = TrackCondition(racecourse: "도쿄", distanceMeters: 2400, surface: .turf)
        let cm = ChampionsMeeting(id: "cm", name: "리브르", track: track, phases: [
            EventPhase(kind: .open, label: "오픈", date: d(100)),
            EventPhase(kind: .round1, label: "라운드1", date: d(300)),
            EventPhase(kind: .ended, label: "종료", date: d(500)),
        ])
        let loh = LeagueOfHeroes(id: "loh", season: "시즌3", track: track, phases: [
            EventPhase(kind: .open, label: "오픈", date: d(200)),
            EventPhase(kind: .ended, label: "종료", date: d(600)),
        ])
        let g1 = GachaBanner(id: "g1", type: .trainee, featured: ["오구리 캡"], startDate: d(150), endDate: d(450))
        return ScheduleDocument(version: 1, updatedAt: d(0), server: "kr",
                                championsMeetings: [cm], leagueOfHeroes: [loh], gachaBanners: [g1])
    }

    func test_championsCard_phaseLabelAndTarget() {
        let card = EventCardFactory.championsCard(doc().championsMeetings, now: d(50))!
        XCTAssertEqual(card.category, .championsMeeting)
        XCTAssertEqual(card.title, "리브르")
        XCTAssertEqual(card.phaseLabel, "오픈까지")
        XCTAssertEqual(card.targetDate, d(100))
        XCTAssertEqual(card.status, .upcoming)
        XCTAssertEqual(card.track?.racecourse, "도쿄")
    }

    func test_endedChampions_isSkipped_returnsNilWhenAllEnded() {
        let card = EventCardFactory.championsCard(doc().championsMeetings, now: d(999))
        XCTAssertNil(card)
    }

    func test_majorAuto_picksNearerOfCMandLoH() {
        let card = EventCardFactory.majorCard(doc(), now: d(50))!
        XCTAssertEqual(card.category, .championsMeeting)
    }

    func test_gachaCard_activeBannerShowsEndCountdownLabel() {
        let card = EventCardFactory.gachaCard(doc().gachaBanners, now: d(200))!
        XCTAssertEqual(card.category, .gacha)
        XCTAssertEqual(card.title, "오구리 캡")
        XCTAssertEqual(card.status, .active)
        XCTAssertEqual(card.phaseLabel, "종료까지")
        XCTAssertEqual(card.targetDate, d(450))
        XCTAssertNil(card.track)
    }

    func test_gachaCard_upcomingBannerShowsStartCountdown() {
        let card = EventCardFactory.gachaCard(doc().gachaBanners, now: d(100))!
        XCTAssertEqual(card.status, .upcoming)
        XCTAssertEqual(card.phaseLabel, "시작까지")
        XCTAssertEqual(card.targetDate, d(150))
    }

    func test_leagueCard_buildsFromSeasonAndTrack() {
        let card = EventCardFactory.leagueCard(doc().leagueOfHeroes, now: d(50))!
        XCTAssertEqual(card.category, .leagueOfHeroes)
        XCTAssertEqual(card.title, "시즌3")
        XCTAssertEqual(card.phaseLabel, "오픈까지")
        XCTAssertEqual(card.targetDate, d(200))
        XCTAssertEqual(card.status, .upcoming)
    }

    func test_championsCard_picksSoonestNonEndedAmongMany() {
        let track = TrackCondition(racecourse: "도쿄", distanceMeters: 2400, surface: .turf)
        let ended = ChampionsMeeting(id: "old", name: "지난미팅", track: track,
            phases: [EventPhase(kind: .ended, label: "종료", date: d(10))])
        let soon = ChampionsMeeting(id: "soon", name: "다음미팅", track: track,
            phases: [EventPhase(kind: .open, label: "오픈", date: d(200))])
        let later = ChampionsMeeting(id: "later", name: "나중미팅", track: track,
            phases: [EventPhase(kind: .open, label: "오픈", date: d(900))])
        let card = EventCardFactory.championsCard([ended, later, soon], now: d(100))!
        XCTAssertEqual(card.title, "다음미팅")
    }

    func test_majorCard_returnsNilWhenAllEnded() {
        let track = TrackCondition(racecourse: "도쿄", distanceMeters: 2400, surface: .turf)
        let endedDoc = ScheduleDocument(version: 1, updatedAt: d(0), server: "kr",
            championsMeetings: [ChampionsMeeting(id: "c", name: "끝", track: track,
                phases: [EventPhase(kind: .ended, label: "종료", date: d(10))])],
            leagueOfHeroes: [], gachaBanners: [])
        XCTAssertNil(EventCardFactory.majorCard(endedDoc, now: d(100)))
    }
}
