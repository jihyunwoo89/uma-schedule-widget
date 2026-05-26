import SwiftUI
import UmaCore

/// App root: shows the splash while the initial schedule loads, then the tab bar.
struct RootView: View {
    @Bindable var prefs: PrefsStore
    @State private var ready = false
    @State private var dataReady = false

    var body: some View {
        ZStack {
            if ready {
                TabView {
                    ScheduleListView()
                        .tabItem { Label(L.string(.tabSchedule), systemImage: "calendar") }
                    NavigationStack {
                        SettingsView(prefs: prefs)
                    }
                    .tabItem { Label(L.string(.tabSettings), systemImage: "gearshape") }
                }
                .transition(.opacity)
            } else {
                SplashView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: ready)
        .task { await bootstrap() }
    }

    /// Warm the schedule cache, holding the splash ≥1.0s and until data is ready,
    /// but never past a 3.0s cap (the fetch itself can take up to 15s on a stall).
    private func bootstrap() async {
        Task {
            _ = try? await ScheduleRepository.makeLive().current()
            dataReady = true
        }
        let start = Date()
        while true {
            let elapsed = Date().timeIntervalSince(start)
            if elapsed >= 3.0 { break }
            if elapsed >= 1.0 && dataReady { break }
            try? await Task.sleep(nanoseconds: 80_000_000)
        }
        ready = true
    }
}
