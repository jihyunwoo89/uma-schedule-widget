import XCTest
@testable import UmaCore

final class LocalizationTests: XCTestCase {
    func test_everyKeyHasKoAndEnValue() {
        for key in L.Key.allCases {
            let ko = L.string(key, locale: Locale(identifier: "ko"))
            let en = L.string(key, locale: Locale(identifier: "en"))
            XCTAssertNotEqual(ko, key.rawValue, "missing ko for \(key.rawValue)")
            XCTAssertNotEqual(en, key.rawValue, "missing en for \(key.rawValue)")
        }
    }
}
