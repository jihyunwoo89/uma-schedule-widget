import Foundation

public enum CountdownFormatter {
    /// Whole calendar days between `origin` and `target` (start-of-day to start-of-day).
    public static func daysUntil(_ target: Date, from origin: Date, calendar: Calendar = .current) -> Int {
        let a = calendar.startOfDay(for: origin)
        let b = calendar.startOfDay(for: target)
        return calendar.dateComponents([.day], from: a, to: b).day ?? 0
    }

    /// "D-n" when the target is in the future, "D-DAY" on the day itself, and the
    /// localized "진행 중" once it has passed (event already started / running).
    public static func ddayLabel(days: Int) -> String {
        if days < 0 { return L.string(.commonInProgress) }
        return days == 0 ? "D-DAY" : "D-\(days)"
    }
}
