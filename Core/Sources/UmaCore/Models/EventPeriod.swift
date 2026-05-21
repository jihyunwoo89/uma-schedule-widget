import Foundation

public struct EventPeriod: Codable, Hashable, Sendable {
    public var start: Date
    public var end: Date
    public var estimated: Bool   // "(예상)" — KR date not yet official

    public init(start: Date, end: Date, estimated: Bool = false) {
        self.start = start
        self.end = end
        self.estimated = estimated
    }
}
