import Foundation

public struct CachedValue<Value> {
    public let value: Value
    public let isStale: Bool
}

public final class AppGroupStore: @unchecked Sendable {
    public static let suiteName = "group.com.damienjee.umaschedule"

    private let defaults: UserDefaults
    private let clock: @Sendable () -> Date
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(defaults: UserDefaults, clock: @escaping @Sendable () -> Date = Date.init) {
        self.defaults = defaults
        self.clock = clock
    }

    public static func shared() -> AppGroupStore {
        let suite = UserDefaults(suiteName: suiteName) ?? .standard
        return AppGroupStore(defaults: suite)
    }

    private struct Envelope<T: Codable>: Codable {
        let value: T
        let writtenAt: Date
        let ttl: TimeInterval
    }

    public func write<T: Codable>(_ value: T, forKey key: String, ttl: TimeInterval) throws {
        let envelope = Envelope(value: value, writtenAt: clock(), ttl: ttl)
        defaults.set(try encoder.encode(envelope), forKey: key)
    }

    public func read<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key),
              let envelope = try? decoder.decode(Envelope<T>.self, from: data) else { return nil }
        let age = clock().timeIntervalSince(envelope.writtenAt)
        return age <= envelope.ttl ? envelope.value : nil
    }

    public func readAllowingStale<T: Codable>(_ type: T.Type, forKey key: String) -> CachedValue<T>? {
        guard let data = defaults.data(forKey: key),
              let envelope = try? decoder.decode(Envelope<T>.self, from: data) else { return nil }
        let age = clock().timeIntervalSince(envelope.writtenAt)
        return CachedValue(value: envelope.value, isStale: age > envelope.ttl)
    }

    public func remove(forKey key: String) { defaults.removeObject(forKey: key) }
}
