import Foundation

public struct ChampionsMeeting: Codable, Hashable, Sendable {
    public var id: String
    public var name: String
    public var track: TrackCondition
    public var phases: [EventPhase]

    public init(id: String, name: String, track: TrackCondition, phases: [EventPhase]) {
        self.id = id; self.name = name; self.track = track; self.phases = phases
    }
}

public struct LeagueOfHeroes: Codable, Hashable, Sendable {
    public var id: String
    public var season: String
    public var track: TrackCondition
    public var phases: [EventPhase]

    public init(id: String, season: String, track: TrackCondition, phases: [EventPhase]) {
        self.id = id; self.season = season; self.track = track; self.phases = phases
    }
}

public enum BannerType: String, Codable, Sendable {
    case trainee
    case supportCard
}

public struct GachaBanner: Codable, Hashable, Sendable {
    public var id: String
    public var type: BannerType
    public var featured: [String]
    public var startDate: Date
    public var endDate: Date

    public init(id: String, type: BannerType, featured: [String], startDate: Date, endDate: Date) {
        self.id = id; self.type = type; self.featured = featured
        self.startDate = startDate; self.endDate = endDate
    }
}
