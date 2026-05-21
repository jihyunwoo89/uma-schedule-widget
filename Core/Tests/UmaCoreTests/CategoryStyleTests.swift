import XCTest
@testable import UmaCore

final class CategoryStyleTests: XCTestCase {
    func test_sfSymbolPerCategory() {
        XCTAssertEqual(EventCategory.championsMeeting.sfSymbol, "trophy.fill")
        XCTAssertEqual(EventCategory.leagueOfHeroes.sfSymbol, "flag.checkered.2.crossed")
        XCTAssertEqual(EventCategory.gacha.sfSymbol, "sparkles")
    }
    func test_localizedLabelKey() {
        XCTAssertEqual(EventCategory.championsMeeting.labelKey, .categoryChampions)
        XCTAssertEqual(EventCategory.gacha.labelKey, .categoryPickup)
    }
}
