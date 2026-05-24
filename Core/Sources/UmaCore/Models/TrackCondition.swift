import Foundation

public enum Surface: String, Codable, Hashable, Sendable {
    case turf, dirt
    public var koLabel: String { self == .turf ? "잔디" : "더트" }
}

public enum DistanceClass: String, Codable, Hashable, Sendable {
    case sprint, mile, medium, long
    public var koLabel: String {
        switch self {
        case .sprint: return "단거리"
        case .mile:   return "마일"
        case .medium: return "중거리"
        case .long:   return "장거리"
        }
    }
}

public enum Turn: String, Codable, Hashable, Sendable {
    case clockwise, counterclockwise, straight
    public var koLabel: String {
        switch self {
        case .clockwise:        return "시계(우)"
        case .counterclockwise: return "반시계(좌)"
        case .straight:         return "직선"
        }
    }
}

public struct TrackCondition: Codable, Hashable, Sendable {
    public var racecourse: String
    public var surface: Surface
    public var distanceMeters: Int
    public var distanceClass: DistanceClass
    public var turn: Turn?
    public var courseSide: String?
    public var season: String?
    public var weather: String?
    public var ground: String?
    public var timeOfDay: String?
    public var imageURL: URL?
    /// Bundled course-map asset name (`course_{id1}_{id2}`) from gametora, when available.
    public var courseMap: String?

    public init(racecourse: String, surface: Surface, distanceMeters: Int, distanceClass: DistanceClass,
                turn: Turn? = nil, courseSide: String? = nil, season: String? = nil, weather: String? = nil,
                ground: String? = nil, timeOfDay: String? = nil, imageURL: URL? = nil, courseMap: String? = nil) {
        self.racecourse = racecourse
        self.surface = surface
        self.distanceMeters = distanceMeters
        self.distanceClass = distanceClass
        self.turn = turn
        self.courseSide = courseSide
        self.season = season
        self.weather = weather
        self.ground = ground
        self.timeOfDay = timeOfDay
        self.imageURL = imageURL
        self.courseMap = courseMap
    }

    public var summary: String { "\(racecourse) · \(surface.koLabel) \(distanceMeters)m" }

    /// "한신 잔디 1600m" — racecourse + surface + meters, NO distance class. (DESIGN §8.6)
    public var distanceLine: String { "\(racecourse) \(surface.koLabel) \(distanceMeters)m" }

    public var conditionChips: [String] {
        var c: [String] = []
        if let turn { c.append(turn.koLabel) }
        if let courseSide { c.append(courseSide) }
        if let season { c.append(season) }
        if let weather { c.append(weather) }
        if let ground { c.append(ground) }
        if let timeOfDay { c.append(timeOfDay) }
        return c
    }
}
