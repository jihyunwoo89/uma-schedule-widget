import SwiftUI
import WidgetKit
import UmaCore

@main
struct UmaScheduleApp: App {
    @State private var prefs = PrefsStore(reloadWidgets: { WidgetCenter.shared.reloadAllTimelines() })

    init() {
        AppFonts.registerIfNeeded()
        BackgroundRefreshTask.register()
    }

    var body: some Scene {
        WindowGroup {
            RootView(prefs: prefs)
                .onAppear { WidgetPreferenceApplierApp.apply(prefs.prefs) }
        }
    }
}

/// App-side mirror of the widget's preference applier (sets Typography + L locale for app UI).
enum WidgetPreferenceApplierApp {
    static func apply(_ prefs: UserPrefs) {
        Typography.currentTheme = prefs.fontTheme
        switch prefs.localeOverride {
        case .system: L.currentLocale = nil
        case .ko:     L.currentLocale = Locale(identifier: "ko")
        case .en:     L.currentLocale = Locale(identifier: "en")
        }
    }
}
