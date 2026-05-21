import XCTest
@testable import UmaCore

final class WidgetVariantTests: XCTestCase {
    func test_categoriesForVariant() {
        XCTAssertEqual(WidgetVariant.championsOnly.categories, [.championsMeeting])
        XCTAssertEqual(WidgetVariant.loHOnly.categories, [.leagueOfHeroes])
        XCTAssertEqual(WidgetVariant.pickupOnly.categories, [.gacha])
        XCTAssertEqual(WidgetVariant.championsLoH.categories, [.championsMeeting, .leagueOfHeroes])
        XCTAssertEqual(WidgetVariant.allSchedule.categories, [.championsMeeting, .leagueOfHeroes, .gacha])
    }

    func test_majorAutoVariantIsAutoSelect() {
        XCTAssertTrue(WidgetVariant.majorAuto.isMajorAuto)
        XCTAssertFalse(WidgetVariant.championsLoH.isMajorAuto)
    }
}
