import XCTest
@testable import UmaCore

/// Regression: courseMap must survive the real decode path (ScheduleFallback /
/// .iso8601, synthesized Codable) and be carried through EventCardFactory into
/// the EventCard that TrackImageView renders.
final class CourseMapDecodeTests: XCTestCase {

    func test_fallbackDecodesCourseMap() throws {
        let doc = try ScheduleFallback.production.load()
        let cm = try XCTUnwrap(doc.championsMeetings.first, "fallback has a CM")
        XCTAssertNotNil(cm.track.courseMap, "decoded CM track should carry courseMap")
        XCTAssertTrue(cm.track.courseMap?.hasPrefix("course_") ?? false)
    }

    func test_eventCardCarriesCourseMap() throws {
        let doc = try ScheduleFallback.production.load()
        let cm = try XCTUnwrap(doc.championsMeetings.first)
        let card = EventCardFactory.championsCard(for: cm, now: Date(timeIntervalSince1970: 0))
        XCTAssertEqual(card.track?.courseMap, cm.track.courseMap,
                       "EventCardFactory must preserve track.courseMap")
    }

    func test_bundledImageExistsForFallbackCourseMap() throws {
        #if canImport(UIKit)
        let doc = try ScheduleFallback.production.load()
        let name = try XCTUnwrap(doc.championsMeetings.first?.track.courseMap)
        XCTAssertNotNil(UIImage(named: name, in: .module, compatibleWith: nil),
                        "bundled image \(name) should load from UmaCore module bundle")
        #endif
    }
}
