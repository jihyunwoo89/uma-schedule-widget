import Foundation

public enum CountdownFormatter {
    /// Whole calendar days between `origin` and `target` (start-of-day to start-of-day).
    public static func daysUntil(_ target: Date, from origin: Date, calendar: Calendar = .current) -> Int {
        let a = calendar.startOfDay(for: origin)
        let b = calendar.startOfDay(for: target)
        return calendar.dateComponents([.day], from: a, to: b).day ?? 0
    }

    /// "D-DAY" when 0, "D-n" otherwise. (Negative clamps to D-DAY.)
    public static func ddayLabel(days: Int) -> String {
        days <= 0 ? "D-DAY" : "D-\(days)"
    }
}
