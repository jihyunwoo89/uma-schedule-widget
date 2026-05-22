import XCTest
@testable import UmaCore

final class EventCardFactoryTests: XCTestCase {
    private func d(_ t: TimeInterval) -> Date { Date(timeIntervalSince1970: t) }

    private func doc() -> ScheduleDocument {
        let track = TrackCondition(racecourse: "도쿄", surface: .turf, distanceMeters: 2400, distanceClass: .long)
        let period = EventPeriod(start: d(0), end: d(600))
        let cm = ChampionsMeeting(id: "cm", codeName: "LIBRA", raceGrade: "G1", raceName: "리브르",
            track: track, period: period, phases: [
            EventPhase(kind: .open, label: "오픈", date: d(100)),
            EventPhase(kind: .round1, label: "라운드1", date: d(300)),
            EventPhase(kind: .ended, label: "종료", date: d(500)),
        ])
        let loh = LeagueOfHeroes(id: "loh", round: "시즌3", raceName: "스프린트",
            track: track, period: period, phases: [
            EventPhase(kind: .open, label: "오픈", date: d(200)),
            EventPhase(kind: .ended, label: "종료", date: d(600)),
        ])
        let pickup = PickupPeriod(id: "p1", period: EventPeriod(start: d(150), end: d(450)),
            trainees: ["오구리 캡"], supportCards: [])
        return ScheduleDocument(version: 2, updatedAt: d(0), server: "kr",
                                championsMeetings: [cm], leagueOfHeroes: [loh], pickups: [pickup])
    }

    func test_championsCard_phaseLabelAndTarget() {
        let card = EventCardFactory.championsCard(doc().championsMeetings, now: d(50))!
        XCTAssertEqual(card.category, .championsMeeting)
        XCTAssertEqual(card.title, "LIBRA")
        XCTAssertEqual(card.phaseLabel, "오픈까지")
        XCTAssertEqual(card.targetDate, d(100))
        XCTAssertEqual(card.status, .upcoming)
        XCTAssertEqual(card.track?.racecourse, "도쿄")
    }

    func test_championsCard_gradeMovesToRaceGradeAndSubtitleHasNoGrade() {
        let card = EventCardFactory.championsCard(doc().championsMeetings, now: d(50))!
        XCTAssertEqual(card.raceGrade, "G1")
        XCTAssertEqual(card.subtitle, "리브르")  // grade NOT joined into subtitle
    }

    func test_leagueCard_parsesLeadingGradeFromRaceName() {
        let track = TrackCondition(racecourse: "나카야마", surface: .turf, distanceMeters: 1200, distanceClass: .sprint)
        let period = EventPeriod(start: d(0), end: d(600))
        let loh = LeagueOfHeroes(id: "loh2", round: "10회차", raceName: "G1 스프린터즈 S",
            track: track, period: period,
            phases: [EventPhase(kind: .open, label: "오픈", date: d(200))])
        let card = EventCardFactory.leagueCard([loh], now: d(50))!
        XCTAssertEqual(card.raceGrade, "G1")
        XCTAssertEqual(card.subtitle, "스프린터즈 S")
    }

    func test_leagueCard_noGradeKeepsFullRaceName() {
        let card = EventCardFactory.leagueCard(doc().leagueOfHeroes, now: d(50))!
        XCTAssertNil(card.raceGrade)
        XCTAssertEqual(card.subtitle, "스프린트")
    }

    func test_endedChampions_isSkipped_returnsNilWhenAllEnded() {
        let card = EventCardFactory.championsCard(doc().championsMeetings, now: d(999))
        XCTAssertNil(card)
    }

    func test_majorAuto_picksNearerOfCMandLoH() {
        let card = EventCardFactory.majorCard(doc(), now: d(50))!
        XCTAssertEqual(card.category, .championsMeeting)
    }

    func test_pickupCard_activeBannerShowsEndCountdownLabel() {
        let card = EventCardFactory.pickupCard(doc().pickups, now: d(200))!
        XCTAssertEqual(card.category, .gacha)
        XCTAssertEqual(card.title, "오구리 캡")
        XCTAssertEqual(card.status, .active)
        XCTAssertEqual(card.phaseLabel, "종료까지")
        XCTAssertEqual(card.targetDate, d(450))
        XCTAssertNil(card.track)
    }

    func test_pickupCard_upcomingBannerShowsStartCountdown() {
        let card = EventCardFactory.pickupCard(doc().pickups, now: d(100))!
        XCTAssertEqual(card.status, .upcoming)
        XCTAssertEqual(card.phaseLabel, "시작까지")
        XCTAssertEqual(card.targetDate, d(150))
    }

    func test_leagueCard_buildsFromRoundAndTrack() {
        let card = EventCardFactory.leagueCard(doc().leagueOfHeroes, now: d(50))!
        XCTAssertEqual(card.category, .leagueOfHeroes)
        XCTAssertEqual(card.title, "시즌3")
        XCTAssertEqual(card.phaseLabel, "오픈까지")
        XCTAssertEqual(card.targetDate, d(200))
        XCTAssertEqual(card.status, .upcoming)
    }

    func test_championsCard_picksSoonestNonEndedAmongMany() {
        let track = TrackCondition(racecourse: "도쿄", surface: .turf, distanceMeters: 2400, distanceClass: .long)
        let period = EventPeriod(start: d(0), end: d(1000))
        let ended = ChampionsMeeting(id: "old", codeName: "OLD", raceGrade: nil, raceName: "지난미팅",
            track: track, period: period,
            phases: [EventPhase(kind: .ended, label: "종료", date: d(10))])
        let soon = ChampionsMeeting(id: "soon", codeName: "SOON", raceGrade: nil, raceName: "다음미팅",
            track: track, period: period,
            phases: [EventPhase(kind: .open, label: "오픈", date: d(200))])
        let later = ChampionsMeeting(id: "later", codeName: "LATER", raceGrade: nil, raceName: "나중미팅",
            track: track, period: period,
            phases: [EventPhase(kind: .open, label: "오픈", date: d(900))])
        let card = EventCardFactory.championsCard([ended, later, soon], now: d(100))!
        XCTAssertEqual(card.title, "SOON")
    }

    func test_majorCard_returnsNilWhenAllEnded() {
        let track = TrackCondition(racecourse: "도쿄", surface: .turf, distanceMeters: 2400, distanceClass: .long)
        let period = EventPeriod(start: d(0), end: d(10))
        let endedDoc = ScheduleDocument(version: 2, updatedAt: d(0), server: "kr",
            championsMeetings: [ChampionsMeeting(id: "c", codeName: "END", raceGrade: nil, raceName: "끝",
                track: track, period: period,
                phases: [EventPhase(kind: .ended, label: "종료", date: d(10))])],
            leagueOfHeroes: [], pickups: [])
        XCTAssertNil(EventCardFactory.majorCard(endedDoc, now: d(100)))
    }

    func test_championsCard_forItem_mapsFields() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let track = TrackCondition(racecourse: "한신", surface: .turf, distanceMeters: 1600, distanceClass: .mile, turn: .clockwise, season: "봄")
        let period = EventPeriod(start: now.addingTimeInterval(86400), end: now.addingTimeInterval(2*86400), estimated: true)
        let cm = ChampionsMeeting(id: "cm1", codeName: "MILE", raceGrade: "G1", raceName: "벚꽃상",
                                  track: track, period: period,
                                  phases: [EventPhase(kind: .open, label: "오픈", date: now.addingTimeInterval(86400))])
        let card = EventCardFactory.championsCard(for: cm, now: now)
        XCTAssertEqual(card.title, "MILE")
        XCTAssertEqual(card.subtitle, "벚꽃상")
        XCTAssertEqual(card.raceGrade, "G1")
        XCTAssertEqual(card.category, .championsMeeting)
        XCTAssertEqual(card.track?.racecourse, "한신")
    }

    func test_leagueCard_forItem_parsesGradeFromRaceName() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let track = TrackCondition(racecourse: "나카야마", surface: .turf, distanceMeters: 1200, distanceClass: .sprint)
        let period = EventPeriod(start: now.addingTimeInterval(86400), end: now.addingTimeInterval(2*86400))
        let loh = LeagueOfHeroes(id: "loh1", round: "10회차", raceName: "G1 스프린터즈 스테이크스",
                                 track: track, period: period,
                                 phases: [EventPhase(kind: .open, label: "오픈", date: now.addingTimeInterval(86400))])
        let card = EventCardFactory.leagueCard(for: loh, now: now)
        XCTAssertEqual(card.title, "10회차")
        XCTAssertEqual(card.raceGrade, "G1")
        XCTAssertEqual(card.subtitle, "스프린터즈 스테이크스")
    }

    func test_pickupCard_forItem_upcomingVsActive() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let upcoming = PickupPeriod(id: "p1", period: EventPeriod(start: now.addingTimeInterval(86400), end: now.addingTimeInterval(3*86400)),
                                    trainees: ["오르페브르 3★"], supportCards: [])
        let upCard = EventCardFactory.pickupCard(for: upcoming, now: now)
        XCTAssertEqual(upCard.status, .upcoming)
        XCTAssertEqual(upCard.phaseLabel, "시작까지")
        XCTAssertEqual(upCard.targetDate, upcoming.period.start)

        let active = PickupPeriod(id: "p2", period: EventPeriod(start: now.addingTimeInterval(-86400), end: now.addingTimeInterval(86400)),
                                  trainees: ["푸리오소 3★"], supportCards: [])
        let actCard = EventCardFactory.pickupCard(for: active, now: now)
        XCTAssertEqual(actCard.status, .active)
        XCTAssertEqual(actCard.phaseLabel, "종료까지")
        XCTAssertEqual(actCard.targetDate, active.period.end)
    }
}
