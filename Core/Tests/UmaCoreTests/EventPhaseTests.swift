import XCTest
@testable import UmaCore

final class EventPhaseTests: XCTestCase {
    func test_codableRoundTrip() throws {
        let p = EventPhase(kind: .round1, label: "라운드1", date: Date(timeIntervalSince1970: 1_700_000_000))
        let data = try JSONEncoder().encode(p)
        let back = try JSONDecoder().decode(EventPhase.self, from: data)
        XCTAssertEqual(p, back)
    }

    func test_phaseKind_decodesFromRawString() throws {
        let json = #"{"kind":"round2","label":"결승","date":0}"#.data(using: .utf8)!
        let p = try JSONDecoder().decode(EventPhase.self, from: json)
        XCTAssertEqual(p.kind, .round2)
    }
}
