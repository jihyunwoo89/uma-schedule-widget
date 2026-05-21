import Foundation

public struct ScheduleDocument: Codable, Hashable, Sendable {
    public var version: Int
    public var updatedAt: Date
    public var sourcePostNo: Int?
    public var server: String
    public var championsMeetings: [ChampionsMeeting]
    public var leagueOfHeroes: [LeagueOfHeroes]
    public var pickups: [PickupPeriod]

    public init(version: Int = 2, updatedAt: Date, sourcePostNo: Int? = nil, server: String,
                championsMeetings: [ChampionsMeeting], leagueOfHeroes: [LeagueOfHeroes], pickups: [PickupPeriod]) {
        self.version = version
        self.updatedAt = updatedAt
        self.sourcePostNo = sourcePostNo
        self.server = server
        self.championsMeetings = championsMeetings
        self.leagueOfHeroes = leagueOfHeroes
        self.pickups = pickups
    }

    public static let empty = ScheduleDocument(
        version: 2, updatedAt: Date(timeIntervalSince1970: 0), server: "kr",
        championsMeetings: [], leagueOfHeroes: [], pickups: []
    )
}
