import Foundation

public enum WidgetVariant: String, Codable, Sendable {
    case majorAuto      // 챔미·LoH 중 임박 자동 전환 (L1/M1/S1, lock)
    case allSchedule    // 챔미+LoH+픽업 전체 (L2)
    case championsLoH   // 챔미+LoH 동시 (M2)
    case championsOnly  // 챔미만 (S2)
    case loHOnly        // LoH만 (S3)
    case pickupOnly     // 픽업만 (M3/S4)

    /// `true` for variants that auto-pick the nearer of CM/LoH instead of listing fixed categories.
    public var isMajorAuto: Bool { self == .majorAuto }

    /// Fixed category set for non-auto variants, used to assemble cards in order.
    /// Ignored for `.majorAuto` (the resolver branches on `isMajorAuto` first and never
    /// reads this); the value returned for `.majorAuto` is not meaningful — don't rely on it.
    public var categories: [EventCategory] {
        switch self {
        case .majorAuto:     return [.championsMeeting, .leagueOfHeroes]
        case .allSchedule:   return [.championsMeeting, .leagueOfHeroes, .gacha]
        case .championsLoH:  return [.championsMeeting, .leagueOfHeroes]
        case .championsOnly: return [.championsMeeting]
        case .loHOnly:       return [.leagueOfHeroes]
        case .pickupOnly:    return [.gacha]
        }
    }
}
