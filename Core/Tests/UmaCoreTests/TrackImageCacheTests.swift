import XCTest
@testable import UmaCore

final class TrackImageCacheTests: XCTestCase {
    func test_fileName_isStableHashOfURL() {
        let url = URL(string: "https://x/tokyo.png")!
        XCTAssertEqual(TrackImageCache.fileName(for: url), TrackImageCache.fileName(for: url))
        XCTAssertFalse(TrackImageCache.fileName(for: url).isEmpty)
    }

    func test_storeAndLoadData() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let cache = TrackImageCache(directory: dir)
        let url = URL(string: "https://x/tokyo.png")!
        let bytes = Data([1, 2, 3, 4])
        try cache.store(bytes, for: url)
        XCTAssertEqual(cache.data(for: url), bytes)
        XCTAssertNil(cache.data(for: URL(string: "https://x/other.png")!))
    }
}
