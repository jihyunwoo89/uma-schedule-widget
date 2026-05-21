import XCTest
@testable import UmaCore

final class PrefsStoreTests: XCTestCase {
    func test_savePersistsAndReloads() {
        let suite = "test.\(UUID().uuidString)"
        let store = AppGroupStore(defaults: UserDefaults(suiteName: suite)!)
        let prefs = PrefsStore(store: store)
        var p = prefs.prefs
        p.fontTheme = .serif
        prefs.save(p)
        let reloaded = PrefsStore(store: store)
        XCTAssertEqual(reloaded.prefs.fontTheme, .serif)
    }

    func test_defaultsWhenEmpty() {
        let store = AppGroupStore(defaults: UserDefaults(suiteName: "test.\(UUID().uuidString)")!)
        XCTAssertEqual(PrefsStore(store: store).prefs, UserPrefs.default)
    }
}
