import Foundation

public enum PeriodFormatter {
    /// "7.14 ~ 7.20" (+ " (예상)" when estimated).
    public static func range(_ p: EventPeriod, calendar: Calendar = .current) -> String {
        let md: (Date) -> String = { date in
            let c = calendar.dateComponents([.month, .day], from: date)
            return "\(c.month ?? 0).\(c.day ?? 0)"
        }
        let base = "\(md(p.start)) ~ \(md(p.end))"
        return p.estimated ? base + " (예상)" : base
    }
}
