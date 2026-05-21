import Foundation

public struct ScheduleDocument: Codable, Hashable, Sendable {
    public var version: Int
    public var updatedAt: Date
    public var server: String
    public var championsMeetings: [ChampionsMeeting]
    public var leagueOfHeroes: [LeagueOfHeroes]
    public var gachaBanners: [GachaBanner]

    public init(version: Int, updatedAt: Date, server: String,
                championsMeetings: [ChampionsMeeting], leagueOfHeroes: [LeagueOfHeroes],
                gachaBanners: [GachaBanner]) {
        self.version = version
        self.updatedAt = updatedAt
        self.server = server
        self.championsMeetings = championsMeetings
        self.leagueOfHeroes = leagueOfHeroes
        self.gachaBanners = gachaBanners
    }

    public static let empty = ScheduleDocument(
        version: 1, updatedAt: Date(timeIntervalSince1970: 0), server: "kr",
        championsMeetings: [], leagueOfHeroes: [], gachaBanners: []
    )
}
