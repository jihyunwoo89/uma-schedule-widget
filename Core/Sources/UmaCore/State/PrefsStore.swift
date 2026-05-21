import Foundation
import Observation

@Observable
public final class PrefsStore {
    public static let key = "pref.user.v1"
    public static let ttl: TimeInterval = .greatestFiniteMagnitude

    public private(set) var prefs: UserPrefs

    @ObservationIgnored private let store: AppGroupStore
    @ObservationIgnored private let reloadWidgets: () -> Void

    public init(store: AppGroupStore = .shared(), reloadWidgets: @escaping () -> Void = {}) {
        self.store = store
        self.reloadWidgets = reloadWidgets
        self.prefs = store.read(UserPrefs.self, forKey: Self.key) ?? .default
    }

    public func save(_ updated: UserPrefs) {
        prefs = updated
        try? store.write(updated, forKey: Self.key, ttl: Self.ttl)
        reloadWidgets()
    }

    public func update(_ mutate: (inout UserPrefs) -> Void) {
        var current = prefs
        mutate(&current)
        save(current)
    }
}
