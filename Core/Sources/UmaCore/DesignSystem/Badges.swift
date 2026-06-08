import SwiftUI

/// Race-grade badge (G1/G2/G3/OP). Renders nothing for unknown grades. (DESIGN §8.2)
public struct GradeBadge: View {
    public let grade: String
    public init(grade: String) { self.grade = grade }

    private var spec: (label: String, hex: String)? {
        switch grade.uppercased() {
        case "G1": return ("G I",   "#3E7BE0")
        case "G2": return ("G II",  "#E1499A")
        case "G3": return ("G III", "#3FA85F")
        case "OP": return ("OP",    "#F2A521")
        default:   return nil
        }
    }

    @ViewBuilder
    public var body: some View {
        if let spec {
            Text(spec.label)
                .font(.system(size: 9.5, weight: .heavy))
                .foregroundStyle(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 2.5)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color(hex: spec.hex) ?? .blue)
                )
        } else {
            EmptyView()
        }
    }
}

/// Rarity tier for the pickup rarity badge (trainee stars / support card rarity).
public enum RarityTier: Sendable {
    case rainbow, gold, silver

    /// Maps "SSR"/"3★"/"3" → rainbow, "SR"/"2★"/"2" → gold, "R"/"1★"/"1" → silver.
    public init?(_ s: String) {
        switch s.trimmingCharacters(in: .whitespaces).uppercased() {
        case "SSR", "3★", "3": self = .rainbow
        case "SR", "2★", "2":  self = .gold
        case "R", "1★", "1":   self = .silver
        default: return nil
        }
    }

    /// 3-stop diagonal gradient (135°, topLeading → bottomTrailing). (DESIGN §8.3)
    var gradient: LinearGradient {
        let stops: [Color]
        switch self {
        case .rainbow: stops = [Color(hex: "#FF9DC0")!, Color(hex: "#8ED0FF")!, Color(hex: "#B6E673")!]
        case .gold:    stops = [Color(hex: "#FFFFFF")!, Color(hex: "#E6B23E")!, Color(hex: "#E6B23E")!]
        case .silver:  stops = [Color(hex: "#FFFFFF")!, Color(hex: "#C2CAD4")!, Color(hex: "#C2CAD4")!]
        }
        return LinearGradient(
            gradient: Gradient(stops: [
                .init(color: stops[0], location: 0.0),
                .init(color: stops[1], location: 0.5),
                .init(color: stops[2], location: 1.0),
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

/// Rarity badge: brown text over a 3-stop diagonal gradient. (DESIGN §8.3)
public struct RarityBadge: View {
    public let text: String
    public let tier: RarityTier
    public init(text: String, tier: RarityTier) { self.text = text; self.tier = tier }

    public var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .heavy))
            .foregroundStyle(Color(hex: "#5C3A18") ?? .brown)
            .padding(.horizontal, 5)
            .padding(.vertical, 2.5)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(tier.gradient)
            )
    }
}
