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
        case .championsMeeting: return "#E8B923"
        case .leagueOfHeroes:   return "#3F8EFC"
        case .gacha:            return "#E0567A"
        }
    }
    var labelKey: L.Key {
        switch self {
        case .championsMeeting: return .categoryChampions
        case .leagueOfHeroes:   return .categoryLoH
        case .gacha:            return .categoryPickup
        }
    }
    var accentColor: Color { Color(hex: accentHex) ?? .accentColor }
}

/// Small pill: category icon + localized name.
public struct CategoryBadge: View {
    public let category: EventCategory
    public init(category: EventCategory) { self.category = category }

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.sfSymbol).font(.system(size: 10, weight: .bold))
            Text(L.string(category.labelKey)).font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(category.accentColor)
    }
}
