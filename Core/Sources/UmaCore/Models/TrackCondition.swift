import Foundation

public enum Surface: String, Codable, Sendable {
    case turf
    case dirt

    /// Korean display label. "잔디" (grass) for turf, "더트" for dirt.
    public var koLabel: String {
        switch self {
        case .turf: return "잔디"
        case .dirt: return "더트"
        }
    }
}

public struct TrackCondition: Codable, Hashable, Sendable {
    public var racecourse: String
    public var distanceMeters: Int
    public var surface: Surface
    public var direction: String?
    public var imageURL: URL?

    public init(racecourse: String, distanceMeters: Int, surface: Surface,
                direction: String? = nil, imageURL: URL? = nil) {
        self.racecourse = racecourse
        self.distanceMeters = distanceMeters
        self.surface = surface
        self.direction = direction
        self.imageURL = imageURL
    }

    /// One-line widget summary: "도쿄 · 잔디 2400m".
    public var summary: String {
        "\(racecourse) · \(surface.koLabel) \(distanceMeters)m"
    }
}
