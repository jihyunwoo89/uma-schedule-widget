import XCTest
@testable import UmaCore

final class RemoteScheduleClientTests: XCTestCase {
    func test_fetch_decodesDocument() async throws {
        let json = """
        {"version":2,"updatedAt":"2026-05-20T00:00:00Z","server":"kr",
         "championsMeetings":[],"leagueOfHeroes":[],"gachaBanners":[]}
        """.data(using: .utf8)!
        let client = RemoteScheduleClient(transport: { _ in (json, 200) })
        let doc = try await client.fetch()
        XCTAssertEqual(doc.version, 2)
    }

    func test_fetch_non200Throws() async {
        let client = RemoteScheduleClient(transport: { _ in (Data(), 503) })
        do { _ = try await client.fetch(); XCTFail("should throw") }
        catch { /* expected */ }
    }
}
