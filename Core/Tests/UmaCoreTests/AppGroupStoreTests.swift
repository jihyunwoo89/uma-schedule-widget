import XCTest
@testable import UmaCore

final class AppGroupStoreTests: XCTestCase {
    private func makeStore(now: Date) -> AppGroupStore {
        let defaults = UserDefaults(suiteName: "test.\(UUID().uuidString)")!
        return AppGroupStore(defaults: defaults, clock: { now })
    }

    func test_readWithinTTL_returnsValue() throws {
        let t0 = Date(timeIntervalSince1970: 0)
        let store = makeStore(now: t0)
        try store.write([1, 2, 3], forKey: "k", ttl: 100)
        XCTAssertEqual(store.read([Int].self, forKey: "k"), [1, 2, 3])
    }

    func test_readPastTTL_returnsNil_butStaleReadReturnsValue() throws {
        let defaults = UserDefaults(suiteName: "test.\(UUID().uuidString)")!
        var now = Date(timeIntervalSince1970: 0)
        let store = AppGroupStore(defaults: defaults, clock: { now })
        try store.write(["x"], forKey: "k", ttl: 10)
        now = Date(timeIntervalSince1970: 50)
        XCTAssertNil(store.read([String].self, forKey: "k"))
        let stale = store.readAllowingStale([String].self, forKey: "k")
        XCTAssertEqual(stale?.value, ["x"])
        XCTAssertTrue(stale?.isStale ?? false)
    }
}
