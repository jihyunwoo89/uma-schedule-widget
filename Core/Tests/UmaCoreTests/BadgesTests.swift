import XCTest
@testable import UmaCore

final class BadgesTests: XCTestCase {
    func test_rarityTier_fromRarityStrings() {
        XCTAssertEqual(RarityTier("SSR"), .rainbow)
        XCTAssertEqual(RarityTier("SR"), .gold)
        XCTAssertEqual(RarityTier("R"), .silver)
    }
    func test_rarityTier_fromStarStrings() {
        XCTAssertEqual(RarityTier("3★"), .rainbow)
        XCTAssertEqual(RarityTier("2★"), .gold)
        XCTAssertEqual(RarityTier("1★"), .silver)
    }
    func test_rarityTier_fromBareDigits() {
        XCTAssertEqual(RarityTier("3"), .rainbow)
        XCTAssertEqual(RarityTier("2"), .gold)
        XCTAssertEqual(RarityTier("1"), .silver)
    }
    func test_rarityTier_unknownReturnsNil() {
        XCTAssertNil(RarityTier("UR"))
        XCTAssertNil(RarityTier(""))
        XCTAssertNil(RarityTier("4★"))
    }
}
