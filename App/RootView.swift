import SwiftUI
import WidgetKit
import UmaCore

/// App home: shows a live preview of each category's next event (so the app is useful on
/// its own) plus a link to Settings. Data comes from the same ScheduleRepository the widget
/// uses; loaded once on appear.
struct RootView: View {
    @Bindable var prefs: PrefsStore
    @State private var document: ScheduleDocument?
    @State private var loadFailed = false

    var body: some View {
        NavigationStack {
            List {
                if let doc = document {
                    ForEach(prefs.prefs.categoryOrder, id: \.self) { category in
                        Section(L.string(category.labelKey)) {
                            if let card = card(for: category, doc: doc) {
                                EventCardRow(card: card, now: Date()).padding(.vertical, 4)
                            } else {
                                Text(L.string(.stateIdleTitle)).foregroundStyle(.secondary)
                            }
                        }
                    }
                } else if loadFailed {
                    Text(L.string(.stateNoDataTitle))
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("우마 스케줄")
            .toolbar {
                ToolbarItem {
                    NavigationLink {
                        SettingsView(prefs: prefs)
                    } label: { Image(systemName: "gearshape") }
                }
            }
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private func card(for category: EventCategory, doc: ScheduleDocument) -> EventCard? {
        switch category {
        case .championsMeeting: return EventCardFactory.championsCard(doc.championsMeetings, now: Date())
        case .leagueOfHeroes:   return EventCardFactory.leagueCard(doc.leagueOfHeroes, now: Date())
        case .gacha:            return EventCardFactory.pickupCard(doc.pickups, now: Date())
        }
    }

    private func load() async {
        do {
            document = try await ScheduleRepository.makeLive().current()
            loadFailed = false
            WidgetCenter.shared.reloadAllTimelines()
        } catch { loadFailed = true }
    }
}
