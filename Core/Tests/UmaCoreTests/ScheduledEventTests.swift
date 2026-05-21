import XCTest
@testable import UmaCore

final class ScheduledEventTests: XCTestCase {
    private func d(_ t: TimeInterval) -> Date { Date(timeIntervalSince1970: t) }
    private func track() -> TrackCondition {
        TrackCondition(racecourse: "도쿄", surface: .turf, distanceMeters: 2400, distanceClass: .long)
    }
    private func period() -> EventPeriod { EventPeriod(start: d(100), end: d(400)) }
    private func cm() -> ChampionsMeeting {
        ChampionsMeeting(id: "x", codeName: "LIBRA", raceGrade: nil, raceName: "리브르", track: track(), period: period(),
            phases: [
                EventPhase(kind: .open,   label: "오픈",    date: d(100)),
                EventPhase(kind: .round1, label: "라운드1", date: d(200)),
                EventPhase(kind: .round2, label: "라운드2", date: d(300)),
                EventPhase(kind: .ended,  label: "종료",    date: d(400)),
            ])
    }

    func test_beforeOpen_nextPhaseIsOpen_statusUpcoming() {
        let r = cm().resolution(now: d(50))
        XCTAssertEqual(r.nextPhase?.kind, .open)
        XCTAssertEqual(r.status, .upcoming)
    }

    func test_betweenOpenAndRound1_nextPhaseIsRound1() {
        let r = cm().resolution(now: d(150))
        XCTAssertEqual(r.nextPhase?.kind, .round1)
        XCTAssertEqual(r.status, .active)
    }

    func test_afterEnded_statusEnded_noNextPhase() {
        let r = cm().resolution(now: d(500))
        XCTAssertNil(r.nextPhase)
        XCTAssertEqual(r.status, .ended)
    }

    func test_targetDate_isNextPhaseDate_whenUpcoming() {
        XCTAssertEqual(cm().resolution(now: d(150)).targetDate, d(200))
    }

    func test_targetDate_isEndDate_whenNoUpcomingPhaseButNotEnded() {
        XCTAssertEqual(cm().resolution(now: d(350)).targetDate, d(400))
    }

    func test_exactlyAtOpenDate_isActive_nextPhaseIsRound1() {
        let r = cm().resolution(now: d(100))
        XCTAssertEqual(r.status, .active)
        XCTAssertEqual(r.nextPhase?.kind, .round1)
    }

    func test_exactlyAtEndDate_isEnded() {
        XCTAssertEqual(cm().resolution(now: d(400)).status, .ended)
        XCTAssertNil(cm().resolution(now: d(400)).nextPhase)
    }

    func test_emptyPhases_isUpcoming_targetDateIsNow() {
        let empty = ChampionsMeeting(id: "e", codeName: "EMPTY", raceGrade: nil, raceName: "없음",
            track: track(), period: period(), phases: [])
        let now = d(123)
        let r = empty.resolution(now: now)
        XCTAssertEqual(r.status, .upcoming)
        XCTAssertNil(r.nextPhase)
        XCTAssertEqual(r.targetDate, now)
    }

    func test_unsortedPhases_areSortedBeforeResolving() {
        let unsorted = ChampionsMeeting(id: "u", codeName: "MIX", raceGrade: nil, raceName: "뒤섞임",
            track: track(), period: period(),
            phases: [
                EventPhase(kind: .ended,  label: "종료", date: d(400)),
                EventPhase(kind: .open,   label: "오픈", date: d(100)),
                EventPhase(kind: .round1, label: "라운드1", date: d(200)),
            ])
        XCTAssertEqual(unsorted.resolution(now: d(50)).nextPhase?.kind, .open)
    }
}
