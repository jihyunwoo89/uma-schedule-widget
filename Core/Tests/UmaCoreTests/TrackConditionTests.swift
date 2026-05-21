import XCTest
@testable import UmaCore

final class TrackConditionTests: XCTestCase {
    func test_summary_formatsCourseSurfaceDistance() {
        let t = TrackCondition(racecourse: "도쿄", distanceMeters: 2400, surface: .turf, direction: "좌", imageURL: nil)
        XCTAssertEqual(t.summary, "도쿄 · 잔디 2400m")
    }

    func test_summary_dirtUsesDirtLabel() {
        let t = TrackCondition(racecourse: "오이", distanceMeters: 2000, surface: .dirt, direction: nil, imageURL: nil)
        XCTAssertEqual(t.summary, "오이 · 더트 2000m")
    }

    func test_codableRoundTrip() throws {
        let t = TrackCondition(racecourse: "한신", distanceMeters: 1600, surface: .turf, direction: "우",
                               imageURL: URL(string: "https://x/y.png"))
        let data = try JSONEncoder().encode(t)
        let back = try JSONDecoder().decode(TrackCondition.self, from: data)
        XCTAssertEqual(t, back)
    }
}
