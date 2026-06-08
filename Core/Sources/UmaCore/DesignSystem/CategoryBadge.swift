import SwiftUI

public extension EventCategory {
    var sfSymbol: String {
        switch self {
        case .championsMeeting: return "trophy.fill"
        case .leagueOfHeroes:   return "flag.checkered.2.crossed"
        case .gacha:            return "sparkles"
        }
    }
    var accentHex: String {
        switch self {
        case .championsMeeting: return "#C79200"
        case .leagueOfHeroes:   return "#2F6FD6"
        case .gacha:            return "#C23E63"
        }
    }
    var labelKey: L.Key {
        switch self {
        case .championsMeeting: return .categoryChampions
        case .leagueOfHeroes:   return .categoryLoH
        case .gacha:            return .categoryPickup
        }
    }
    /// Short label key for tight spaces (Small, L2 columns).
    var shortLabelKey: L.Key {
        switch self {
        case .championsMeeting: return .categoryChampionsShort
        case .leagueOfHeroes:   return .categoryLoHShort
        case .gacha:            return .categoryPickupShort
        }
    }
    var accentColor: Color { Color(hex: accentHex) ?? .accentColor }
}

/// Category header: 7pt filled accent dot + accent-colored name (system 11, bold).
public struct CategoryBadge: View {
    public let category: EventCategory
    public var short: Bool

    public init(category: EventCategory, short: Bool = false) {
        self.category = category
        self.short = short
    }

    public var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(category.accentColor)
                .frame(width: 7, height: 7)
            Text(L.string(short ? category.shortLabelKey : category.labelKey))
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundStyle(category.accentColor)
        .lineLimit(1)
    }
}
