import XCTest
@testable import UmaCore

final class UserPrefsTests: XCTestCase {
    func test_default_showsAllCategoriesInDefaultOrder() {
        let p = UserPrefs.default
        XCTAssertEqual(p.categoryOrder, [.championsMeeting, .leagueOfHeroes, .gacha])
        XCTAssertEqual(p.fontTheme, .system)
        XCTAssertEqual(p.localeOverride, .system)
        XCTAssertTrue(p.notifyBeforePhase)
    }

    func test_backwardCompatDecode_missingFieldsUseDefaults() throws {
        let json = "{}".data(using: .utf8)!
        let p = try JSONDecoder().decode(UserPrefs.self, from: json)
        XCTAssertEqual(p.categoryOrder, [.championsMeeting, .leagueOfHeroes, .gacha])
        XCTAssertEqual(p.fontTheme, .system)
    }

    func test_roundTrip() throws {
        var p = UserPrefs.default
        p.fontTheme = .mono
        p.localeOverride = .ko
        p.categoryOrder = [.gacha, .championsMeeting, .leagueOfHeroes]
        let data = try JSONEncoder().encode(p)
        XCTAssertEqual(try JSONDecoder().decode(UserPrefs.self, from: data), p)
    }
}
