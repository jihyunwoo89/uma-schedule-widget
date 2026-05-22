import Foundation

public enum EventCategory: String, Codable, Hashable, Sendable {
    case championsMeeting, leagueOfHeroes, gacha
}
public enum EventStatus: String, Codable, Hashable, Sendable {
    case upcoming, active, ended
}
public enum DetailLevel: String, Codable, Hashable, Sendable {
    case overview, brief, detailed
}

public struct EventCard: Codable, Hashable, Sendable {
    public var category: EventCategory
    public var title: String
    public var subtitle: String?
    public var track: TrackCondition?
    public var period: EventPeriod?
    public var phaseLabel: String
    public var targetDate: Date
    public var status: EventStatus
    public var raceGrade: String?
    public var trainees: [String]
    public var supportCards: [SupportCardPick]

    public init(category: EventCategory, title: String, subtitle: String? = nil,
                track: TrackCondition? = nil, period: EventPeriod? = nil,
                phaseLabel: String, targetDate: Date, status: EventStatus,
                raceGrade: String? = nil,
                trainees: [String] = [], supportCards: [SupportCardPick] = []) {
        self.category = category
        self.title = title
        self.subtitle = subtitle
        self.track = track
        self.period = period
        self.phaseLabel = phaseLabel
        self.targetDate = targetDate
        self.status = status
        self.raceGrade = raceGrade
        self.trainees = trainees
        self.supportCards = supportCards
    }
}
