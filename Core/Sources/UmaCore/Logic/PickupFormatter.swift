import Foundation

/// Parses trainee pickup strings like "발렌타인 애스턴 마짱 3★" into (stars, name).
public enum PickupFormatter {
    /// Finds an `N★` token anywhere in `raw` (e.g. "3★"), returning its digit and the name with
    /// the token removed and whitespace collapsed/trimmed. Examples:
    /// - "발렌타인 애스턴 마짱 3★" → (3, "발렌타인 애스턴 마짱")
    /// - "천장시 3★ 택 1" → (3, "천장시 택 1")
    /// - "이름" (no token) → (nil, "이름")
    public static func trainee(_ raw: String) -> (stars: Int?, name: String) {
        let pattern = #"(\d)\s*★"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return (nil, raw.trimmingCharacters(in: .whitespaces))
        }
        let range = NSRange(raw.startIndex..<raw.endIndex, in: raw)
        guard let match = regex.firstMatch(in: raw, range: range),
              let digitRange = Range(match.range(at: 1), in: raw),
              let stars = Int(raw[digitRange]) else {
            return (nil, collapse(raw))
        }
        // Remove the whole "N★" token, then collapse whitespace.
        let stripped = regex.stringByReplacingMatches(in: raw, range: range, withTemplate: " ")
        return (stars, collapse(stripped))
    }

    /// Collapses runs of whitespace into single spaces and trims the ends.
    private static func collapse(_ s: String) -> String {
        s.split(whereSeparator: { $0 == " " || $0 == "\t" || $0 == "\n" })
            .joined(separator: " ")
    }
}
