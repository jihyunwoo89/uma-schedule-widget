import SwiftUI
import UmaCore

/// App root: tab bar with Schedule + Settings.
struct RootView: View {
    @Bindable var prefs: PrefsStore

    var body: some View {
        TabView {
            ScheduleListView()
                .tabItem { Label(L.string(.tabSchedule), systemImage: "calendar") }
            NavigationStack {
                SettingsView(prefs: prefs)
            }
            .tabItem { Label(L.string(.tabSettings), systemImage: "gearshape") }
        }
    }
}
