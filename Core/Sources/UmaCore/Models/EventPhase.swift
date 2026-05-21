import Foundation

public enum PhaseKind: String, Codable, Sendable {
    case open
    case round1
    case round2
    case ended
}

public struct EventPhase: Codable, Hashable, Sendable {
    public var kind: PhaseKind
    public var label: String
    public var date: Date

    public init(kind: PhaseKind, label: String, date: Date) {
        self.kind = kind
        self.label = label
        self.date = date
    }
}
