import Foundation

public enum AppLocale: String, Codable, CaseIterable, Sendable {
    case system, ko, en
}

public enum FontTheme: String, Codable, CaseIterable, Sendable {
    case system, rounded, mono, serif
}

public struct UserPrefs: Hashable, Codable, Sendable {
    public var categoryOrder: [EventCategory]
    public var notifyBeforePhase: Bool
    public var localeOverride: AppLocale
    public var fontTheme: FontTheme

    public init(categoryOrder: [EventCategory] = [.championsMeeting, .leagueOfHeroes, .gacha],
                notifyBeforePhase: Bool = true,
                localeOverride: AppLocale = .system,
                fontTheme: FontTheme = .system) {
        self.categoryOrder = categoryOrder
        self.notifyBeforePhase = notifyBeforePhase
        self.localeOverride = localeOverride
        self.fontTheme = fontTheme
    }

    public static let `default` = UserPrefs()

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.categoryOrder = try c.decodeIfPresent([EventCategory].self, forKey: .categoryOrder)
            ?? [.championsMeeting, .leagueOfHeroes, .gacha]
        self.notifyBeforePhase = try c.decodeIfPresent(Bool.self, forKey: .notifyBeforePhase) ?? true
        self.localeOverride = try c.decodeIfPresent(AppLocale.self, forKey: .localeOverride) ?? .system
        self.fontTheme = try c.decodeIfPresent(FontTheme.self, forKey: .fontTheme) ?? .system
    }
}
