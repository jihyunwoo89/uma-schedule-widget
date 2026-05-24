import SwiftUI
import UmaCore

struct ScheduleListView: View {
    @State private var document: ScheduleDocument?
    @State private var loadFailed = false
    @State private var category: EventCategory = .championsMeeting
    private let now = Date()

    var body: some View {
        NavigationStack {
            Group {
                if let doc = document {
                    listContent(doc)
                } else if loadFailed {
                    WidgetMessageView(titleKey: .stateNoDataTitle, bodyKey: .stateNoDataBody)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(L.string(.tabSchedule))
            .navigationDestination(for: DetailTarget.self) { EventDetailView(target: $0) }
            .task { if document == nil { await load() } }
            .refreshable { await load() }
        }
    }

    @ViewBuilder
    private func listContent(_ doc: ScheduleDocument) -> some View {
        ScrollView {
            Picker("", selection: $category) {
                Text(L.string(.categoryChampions)).tag(EventCategory.championsMeeting)
                Text(L.string(.categoryLoH)).tag(EventCategory.leagueOfHeroes)
                Text(L.string(.categoryPickup)).tag(EventCategory.gacha)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16).padding(.top, 6)

            let items = items(for: category, doc: doc)
            if items.isEmpty {
                Text(L.string(.stateIdleTitle))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity).padding(.top, 40)
            } else {
                LazyVStack(spacing: 10) {
                    NavigationLink(value: items[0].target) {
                        ScheduleHeroCard(card: items[0].card)
                    }.buttonStyle(.plain)

                    if items.count > 1 {
                        HStack {
                            Text(L.string(.scheduleSectionUpcoming))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(WidgetColors.muted)
                                .textCase(.uppercase)
                            Spacer()
                        }.padding(.top, 4).padding(.horizontal, 2)
                        ForEach(items.dropFirst()) { item in
                            NavigationLink(value: item.target) {
                                ScheduleRowCard(card: item.card)
                            }.buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.top, 6).padding(.bottom, 16)
            }
        }
    }

    private func items(for category: EventCategory, doc: ScheduleDocument) -> [ScheduleItem] {
        switch category {
        case .championsMeeting:
            return EventCardFactory.upcomingChampions(doc.championsMeetings, now: now).map {
                ScheduleItem(id: $0.id, card: EventCardFactory.championsCard(for: $0, now: now), target: .champions($0))
            }
        case .leagueOfHeroes:
            return EventCardFactory.upcomingLeagues(doc.leagueOfHeroes, now: now).map {
                ScheduleItem(id: $0.id, card: EventCardFactory.leagueCard(for: $0, now: now), target: .league($0))
            }
        case .gacha:
            return EventCardFactory.upcomingPickups(doc.pickups, now: now).map {
                ScheduleItem(id: $0.id, card: EventCardFactory.pickupCard(for: $0, now: now), target: .pickup($0))
            }
        }
    }

    private func load() async {
        do {
            document = try await ScheduleRepository.makeLive().current()
            loadFailed = false
        } catch { loadFailed = true }
    }
}
