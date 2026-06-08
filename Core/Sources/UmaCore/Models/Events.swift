import Foundation

public struct ChampionsMeeting: Codable, Hashable, Sendable {
    public var id: String
    public var codeName: String
    public var raceGrade: String?
    public var raceName: String
    public var track: TrackCondition
    public var period: EventPeriod
    public var phases: [EventPhase]

    public init(id: String, codeName: String, raceGrade: String?, raceName: String,
                track: TrackCondition, period: EventPeriod, phases: [EventPhase]) {
        self.id = id
        self.codeName = codeName
        self.raceGrade = raceGrade
        self.raceName = raceName
        self.track = track
        self.period = period
        self.phases = phases
    }
}

public struct LeagueOfHeroes: Codable, Hashable, Sendable {
    public var id: String
    public var round: String
    public var raceName: String
    public var track: TrackCondition
    public var period: EventPeriod
    public var phases: [EventPhase]

    public init(id: String, round: String, raceName: String,
                track: TrackCondition, period: EventPeriod, phases: [EventPhase]) {
        self.id = id
        self.round = round
        self.raceName = raceName
        self.track = track
        self.period = period
        self.phases = phases
    }
}

public struct SupportCardPick: Codable, Hashable, Sendable {
    public var rarity: String
    public var name: String
    public var type: String
    public init(rarity: String, name: String, type: String) {
        self.rarity = rarity; self.name = name; self.type = type
    }
}

public struct PickupPeriod: Codable, Hashable, Sendable {
    public var id: String
    public var period: EventPeriod
    public var trainees: [String]
    public var supportCards: [SupportCardPick]
    /// Free-text support note used when there are no concrete support cards (e.g. "셀렉트 픽업").
    public var supportNote: String?
    public init(id: String, period: EventPeriod, trainees: [String],
                supportCards: [SupportCardPick], supportNote: String? = nil) {
        self.id = id; self.period = period; self.trainees = trainees
        self.supportCards = supportCards; self.supportNote = supportNote
    }
}
