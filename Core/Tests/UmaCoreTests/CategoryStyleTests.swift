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
    func test_shortLabelKey() {
        XCTAssertEqual(EventCategory.championsMeeting.shortLabelKey, .categoryChampionsShort)
        XCTAssertEqual(EventCategory.leagueOfHeroes.shortLabelKey, .categoryLoHShort)
        XCTAssertEqual(EventCategory.gacha.shortLabelKey, .categoryPickupShort)
    }
    func test_accentHex_finalizedValues() {
        XCTAssertEqual(EventCategory.championsMeeting.accentHex, "#C79200")
        XCTAssertEqual(EventCategory.leagueOfHeroes.accentHex, "#2F6FD6")
        XCTAssertEqual(EventCategory.gacha.accentHex, "#C23E63")
    }
    func test_supportType_assetAndColorMapping() {
        XCTAssertEqual(SupportType.assetName(forType: "근성"), "ic_guts")
        XCTAssertEqual(SupportType.assetName(forType: "지능"), "ic_wisdom")
        XCTAssertEqual(SupportType.assetName(forType: "스피드"), "ic_speed")
        XCTAssertNil(SupportType.assetName(forType: "없는타입"))
        XCTAssertNotNil(SupportType.color(forType: "근성"))
        XCTAssertNil(SupportType.color(forType: "없는타입"))
    }
}
