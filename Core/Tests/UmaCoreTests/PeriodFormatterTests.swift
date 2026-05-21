import XCTest
@testable import UmaCore

final class PeriodFormatterTests: XCTestCase {
    private var cal: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }
    private func d(_ s: String) -> Date { ISO8601DateFormatter().date(from: s)! }

    func test_range_estimated() {
        let p = EventPeriod(start: d("2026-07-14T00:00:00Z"), end: d("2026-07-20T00:00:00Z"), estimated: true)
        XCTAssertEqual(PeriodFormatter.range(p, calendar: cal), "7.14 ~ 7.20 (예상)")
    }
    func test_range_confirmed() {
        let p = EventPeriod(start: d("2026-06-15T00:00:00Z"), end: d("2026-06-21T00:00:00Z"), estimated: false)
        XCTAssertEqual(PeriodFormatter.range(p, calendar: cal), "6.15 ~ 6.21")
    }
}
