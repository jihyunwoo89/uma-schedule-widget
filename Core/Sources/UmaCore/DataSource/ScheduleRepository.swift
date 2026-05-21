import Foundation

public final class ScheduleRepository: @unchecked Sendable {
    public static let cacheKey = "cache.schedule.v1"
    /// Schedule changes day-to-day at most; 6h keeps it fresh without chasing.
    public static let ttl: TimeInterval = 6 * 3600

    private let client: RemoteScheduleClient
    private let store: AppGroupStore
    private let fallback: ScheduleProviding
    private let clock: @Sendable () -> Date

    public init(client: RemoteScheduleClient, store: AppGroupStore,
                fallback: ScheduleProviding, clock: @escaping @Sendable () -> Date = Date.init) {
        self.client = client
        self.store = store
        self.fallback = fallback
        self.clock = clock
    }

    public static func makeLive() -> ScheduleRepository {
        ScheduleRepository(client: .live(), store: .shared(), fallback: ScheduleFallback.production)
    }

    public func current() async throws -> ScheduleDocument {
        if let cached = store.readAllowingStale(ScheduleDocument.self, forKey: Self.cacheKey), !cached.isStale {
            return cached.value
        }
        do {
            let doc = try await client.fetch()
            try? store.write(doc, forKey: Self.cacheKey, ttl: Self.ttl)
            return doc
        } catch {
            if let stale = store.readAllowingStale(ScheduleDocument.self, forKey: Self.cacheKey) {
                return stale.value
            }
            return try fallback.load()
        }
    }
}
