import XCTest
@testable import UmaCore

final class ScheduleRepositoryTests: XCTestCase {
    private func store(now: Date) -> AppGroupStore {
        AppGroupStore(defaults: UserDefaults(suiteName: "test.\(UUID().uuidString)")!, clock: { now })
    }
    private func doc(version: Int) -> ScheduleDocument {
        ScheduleDocument(version: version, updatedAt: Date(timeIntervalSince1970: 0), server: "kr",
                         championsMeetings: [], leagueOfHeroes: [], gachaBanners: [])
    }
    private struct StubFallback: ScheduleProviding {
        let document: ScheduleDocument
        func load() throws -> ScheduleDocument { document }
    }

    func test_freshNetwork_isCachedAndReturned() async throws {
        let now = Date(timeIntervalSince1970: 0)
        let s = store(now: now)
        let client = RemoteScheduleClient(transport: { _ in
            (try! JSONEncoder.iso.encode(self.doc(version: 7)), 200)
        })
        let repo = ScheduleRepository(client: client, store: s, fallback: StubFallback(document: doc(version: 0)), clock: { now })
        let result = try await repo.current()
        XCTAssertEqual(result.version, 7)
        let repo2 = ScheduleRepository(client: RemoteScheduleClient(transport: { _ in (Data(), 500) }),
                                       store: s, fallback: StubFallback(document: doc(version: 0)), clock: { now })
        let cachedVersion = try await repo2.current().version
        XCTAssertEqual(cachedVersion, 7)
    }

    func test_networkFails_servesStaleCache() async throws {
        var now = Date(timeIntervalSince1970: 0)
        let s = AppGroupStore(defaults: UserDefaults(suiteName: "test.\(UUID().uuidString)")!, clock: { now })
        let okClient = RemoteScheduleClient(transport: { _ in (try! JSONEncoder.iso.encode(self.doc(version: 3)), 200) })
        _ = try await ScheduleRepository(client: okClient, store: s, fallback: StubFallback(document: doc(version: 0)), clock: { now }).current()
        now = Date(timeIntervalSince1970: ScheduleRepository.ttl + 10)
        let failRepo = ScheduleRepository(client: RemoteScheduleClient(transport: { _ in throw RemoteScheduleError.badStatus(500) }),
                                          store: s, fallback: StubFallback(document: doc(version: 99)), clock: { now })
        let failVersion = try await failRepo.current().version
        XCTAssertEqual(failVersion, 3)
    }

    func test_noCacheAndNetworkFails_usesBundleFallback() async throws {
        let now = Date(timeIntervalSince1970: 0)
        let s = store(now: now)
        let repo = ScheduleRepository(client: RemoteScheduleClient(transport: { _ in throw RemoteScheduleError.badStatus(500) }),
                                      store: s, fallback: StubFallback(document: doc(version: 42)), clock: { now })
        let fallbackVersion = try await repo.current().version
        XCTAssertEqual(fallbackVersion, 42)
    }
}

extension JSONEncoder {
    static var iso: JSONEncoder { let e = JSONEncoder(); e.dateEncodingStrategy = .iso8601; return e }
}
