import XCTest
@testable import UmaCore

final class ScheduledEventTests: XCTestCase {
    private func d(_ t: TimeInterval) -> Date { Date(timeIntervalSince1970: t) }
    private func cm() -> ChampionsMeeting {
        ChampionsMeeting(id: "x", name: "리브르", track: TrackCondition(racecourse: "도쿄", distanceMeters: 2400, surface: .turf),
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
}
