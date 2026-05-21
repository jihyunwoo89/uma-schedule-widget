import Foundation

public enum EventCategory: String, Codable, Hashable, Sendable {
    case championsMeeting
    case leagueOfHeroes
    case gacha
}

public enum EventStatus: String, Codable, Hashable, Sendable {
    case upcoming
    case active
    case ended
}

public enum DetailLevel: String, Codable, Hashable, Sendable {
    case overview
    case brief
    case detailed
}

public struct EventCard: Codable, Hashable, Sendable {
    public var category: EventCategory
    public var title: String
    public var track: TrackCondition?
    public var phaseLabel: String
    public var targetDate: Date
    public var status: EventStatus

    public init(category: EventCategory, title: String, track: TrackCondition?,
                phaseLabel: String, targetDate: Date, status: EventStatus) {
        self.category = category
        self.title = title
        self.track = track
        self.phaseLabel = phaseLabel
        self.targetDate = targetDate
        self.status = status
    }
}
