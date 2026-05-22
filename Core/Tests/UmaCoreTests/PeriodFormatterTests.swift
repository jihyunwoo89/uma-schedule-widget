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
    func test_range_collapsesToSingleDateWhenStartEqualsEnd() {
        let p = EventPeriod(start: d("2026-05-22T00:00:00Z"), end: d("2026-05-22T23:00:00Z"), estimated: false)
        XCTAssertEqual(PeriodFormatter.range(p, calendar: cal), "5.22")
    }
    func test_startShort_estimatedAppendsLabel() {
        let p = EventPeriod(start: d("2026-07-14T00:00:00Z"), end: d("2026-07-20T00:00:00Z"), estimated: true)
        XCTAssertEqual(PeriodFormatter.startShort(p, calendar: cal), "7.14 (예상)")
    }
    func test_startShort_confirmed() {
        let p = EventPeriod(start: d("2026-06-07T00:00:00Z"), end: d("2026-06-09T00:00:00Z"), estimated: false)
        XCTAssertEqual(PeriodFormatter.startShort(p, calendar: cal), "6.7")
    }
    func test_slash_usesSlashAndNoEstimated() {
        let p = EventPeriod(start: d("2026-06-07T00:00:00Z"), end: d("2026-06-09T00:00:00Z"), estimated: true)
        XCTAssertEqual(PeriodFormatter.slash(p, calendar: cal), "6/7")
    }
}
