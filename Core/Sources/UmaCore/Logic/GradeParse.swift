import Foundation

/// Parses a leading race-grade token (`G1`/`G2`/`G3`/`OP`) off a race name.
public enum GradeParse {
    /// If `s` starts with a grade token (optionally followed by whitespace), returns the
    /// normalized token ("G1"/"G2"/"G3"/"OP") plus the remaining trimmed name.
    /// Otherwise returns `(nil, s.trimmed)`. The token must be a standalone prefix
    /// (followed by whitespace or end-of-string), so "G1100상" is not treated as G1.
    public static func leading(_ s: String) -> (grade: String?, rest: String) {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        let upper = trimmed.uppercased()
        for token in ["G1", "G2", "G3", "OP"] {
            guard upper.hasPrefix(token) else { continue }
            let after = trimmed.index(trimmed.startIndex, offsetBy: token.count)
            if after == trimmed.endIndex || trimmed[after] == " " {
                let rest = String(trimmed[after...]).trimmingCharacters(in: .whitespacesAndNewlines)
                return (token, rest)
            }
        }
        return (nil, trimmed)
    }
}
