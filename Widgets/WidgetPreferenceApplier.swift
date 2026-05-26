import Foundation
import UmaCore

/// The widget runs in its own process and doesn't inherit the app's static state — every
/// timeline entry re-applies user prefs so views render with the chosen font + language.
enum WidgetPreferenceApplier {
    static func apply(_ prefs: UserPrefs?) {
        Typography.currentTheme = .system  // font setting removed — always system font (ignore any stale saved theme)
        switch prefs?.localeOverride ?? .system {
        case .system: L.currentLocale = nil
        case .ko:     L.currentLocale = Locale(identifier: "ko")
        case .en:     L.currentLocale = Locale(identifier: "en")
        }
    }
}
