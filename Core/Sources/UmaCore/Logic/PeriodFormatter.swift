import Foundation

public enum PeriodFormatter {
    /// "M.D" of a date (e.g. "7.14").
    private static func md(_ date: Date, _ calendar: Calendar, sep: String = ".") -> String {
        let c = calendar.dateComponents([.month, .day], from: date)
        return "\(c.month ?? 0)\(sep)\(c.day ?? 0)"
    }

    private static func sameDay(_ a: Date, _ b: Date, _ calendar: Calendar) -> Bool {
        calendar.isDate(a, inSameDayAs: b)
    }

    /// "7.14 ~ 7.20" (+ " (예상)" when estimated). Collapses to a single "M.D" when start == end (same day).
    public static func range(_ p: EventPeriod, calendar: Calendar = .current) -> String {
        let base: String
        if sameDay(p.start, p.end, calendar) {
            base = md(p.start, calendar)
        } else {
            base = "\(md(p.start, calendar)) ~ \(md(p.end, calendar))"
        }
        return p.estimated ? base + " (예상)" : base
    }

    /// "M.D" of the start date, + " (예상)" when estimated. (Home-screen date under the D-day.)
    public static func startShort(_ p: EventPeriod, calendar: Calendar = .current) -> String {
        let base = md(p.start, calendar)
        return p.estimated ? base + " (예상)" : base
    }

    /// "M/D" of the start date (slash form, no 예상). Used on the lock-screen rectangular widget.
    public static func slash(_ p: EventPeriod, calendar: Calendar = .current) -> String {
        md(p.start, calendar, sep: "/")
    }
}
