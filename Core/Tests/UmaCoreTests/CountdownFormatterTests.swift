import XCTest
@testable import UmaCore

final class CountdownFormatterTests: XCTestCase {
    private var cal: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }
    private func d(_ s: String) -> Date {
        let f = ISO8601DateFormatter(); return f.date(from: s)!
    }

    func test_daysUntil_sameDay_isZero() {
        XCTAssertEqual(CountdownFormatter.daysUntil(d("2026-06-01T20:00:00Z"), from: d("2026-06-01T08:00:00Z"), calendar: cal), 0)
    }

    func test_daysUntil_nextDay_isOne() {
        XCTAssertEqual(CountdownFormatter.daysUntil(d("2026-06-02T01:00:00Z"), from: d("2026-06-01T23:00:00Z"), calendar: cal), 1)
    }

    func test_ddayLabel_today() {
        XCTAssertEqual(CountdownFormatter.ddayLabel(days: 0), "D-DAY")
    }

    func test_ddayLabel_future() {
        XCTAssertEqual(CountdownFormatter.ddayLabel(days: 5), "D-5")
    }
}
