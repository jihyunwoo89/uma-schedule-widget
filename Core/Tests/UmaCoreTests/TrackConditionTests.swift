import XCTest
@testable import UmaCore

final class TrackConditionTests: XCTestCase {
    private func t() -> TrackCondition {
        TrackCondition(racecourse: "한신", surface: .turf, distanceMeters: 1600, distanceClass: .mile,
                       turn: .clockwise, courseSide: "외측", season: "봄", weather: "맑음", ground: "양호", timeOfDay: "낮")
    }
    func test_summary() { XCTAssertEqual(t().summary, "한신 · 잔디 1600m") }
    func test_distanceLine_hasNoDistanceClass() {
        XCTAssertEqual(t().distanceLine, "한신 잔디 1600m")
        let dirt = TrackCondition(racecourse: "오이", surface: .dirt, distanceMeters: 2000, distanceClass: .medium)
        XCTAssertEqual(dirt.distanceLine, "오이 더트 2000m")
    }
    func test_distanceClassLabel() {
        XCTAssertEqual(DistanceClass.sprint.koLabel, "단거리")
        XCTAssertEqual(DistanceClass.mile.koLabel, "마일")
        XCTAssertEqual(DistanceClass.long.koLabel, "장거리")
    }
    func test_turnLabel() {
        XCTAssertEqual(Turn.clockwise.koLabel, "시계(우)")
        XCTAssertEqual(Turn.counterclockwise.koLabel, "반시계(좌)")
        XCTAssertEqual(Turn.straight.koLabel, "직선")
    }
    func test_conditionChips_inOrder_skipsNils() {
        XCTAssertEqual(t().conditionChips, ["시계(우)", "외측", "봄", "맑음", "양호", "낮"])
        let bare = TrackCondition(racecourse: "도쿄", surface: .turf, distanceMeters: 2400, distanceClass: .long)
        XCTAssertEqual(bare.conditionChips, [])
    }
    func test_roundTrip() throws {
        XCTAssertEqual(try JSONDecoder().decode(TrackCondition.self, from: JSONEncoder().encode(t())), t())
    }
}
