import Foundation
import WidgetKit

public enum WidgetState: Codable, Hashable, Sendable {
    case content([EventCard])   // variant/사이즈에 맞는 1~3개 카드
    case idle                   // 예정 이벤트 없음
    case noData                 // 원격/번들 모두 실패
}

public struct WidgetEntry: TimelineEntry, Codable, Hashable, Sendable {
    public let date: Date
    public let state: WidgetState
    public let detailLevel: DetailLevel
    public let fontTheme: FontTheme

    public init(date: Date, state: WidgetState, detailLevel: DetailLevel = .overview, fontTheme: FontTheme = .system) {
        self.date = date
        self.state = state
        self.detailLevel = detailLevel
        self.fontTheme = fontTheme
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.date = try c.decode(Date.self, forKey: .date)
        self.state = try c.decode(WidgetState.self, forKey: .state)
        self.detailLevel = try c.decodeIfPresent(DetailLevel.self, forKey: .detailLevel) ?? .overview
        self.fontTheme = try c.decodeIfPresent(FontTheme.self, forKey: .fontTheme) ?? .system
    }
}
