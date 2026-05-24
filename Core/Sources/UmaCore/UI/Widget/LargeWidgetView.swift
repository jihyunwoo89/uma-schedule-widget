import SwiftUI
import WidgetKit

public struct LargeWidgetView: View {
    public let entry: WidgetEntry
    public init(entry: WidgetEntry) { self.entry = entry }

    @ViewBuilder
    public var body: some View {
        switch entry.state {
        case .content(let cards):
            if entry.detailLevel == .detailed, let card = cards.first {
                hero(card)             // L1
            } else if cards.isEmpty {
                WidgetMessageView(titleKey: .stateIdleTitle, bodyKey: .stateIdleBody)
            } else {
                full(cards)            // L2
            }
        case .idle:   WidgetMessageView(titleKey: .stateIdleTitle, bodyKey: .stateIdleBody)
        case .noData: WidgetMessageView(titleKey: .stateNoDataTitle, bodyKey: .stateNoDataBody)
        }
    }

    // MARK: L1 — hero detail with big track image

    @ViewBuilder
    private func hero(_ card: EventCard) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                CategoryBadge(category: card.category)
                Spacer(minLength: 4)
                DDayStack(targetDate: card.targetDate, now: entry.date,
                          dateText: dateLabel(for: card), ddaySize: 26, dateSize: 11)
            }
            HStack(alignment: .firstTextBaseline, spacing: 11) {
                BracketTitle(card.title, size: 21)
                RaceNameLine(grade: card.raceGrade, name: card.subtitle, size: 13)
            }.padding(.top, 5)
            if let t = card.track {
                Text(t.distanceLine)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(WidgetColors.title)
                    .padding(.top, 6)
                let chips = t.conditionChips
                if !chips.isEmpty {
                    Text(chips.joined(separator: " · "))
                        .font(.system(size: 11))
                        .foregroundStyle(WidgetColors.cond)
                        .padding(.top, 1)
                }
                CourseLegend(style: .compact)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
                TrackImageView(track: t)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 6)
            } else {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: L2 — full schedule (top: CM | LoH ; bottom: pickup)

    @ViewBuilder
    private func full(_ cards: [EventCard]) -> some View {
        let cm = cards.first(.championsMeeting)
        let loh = cards.first(.leagueOfHeroes)
        let pickup = cards.first(.gacha)
        VStack(spacing: 0) {
            // Top half: two columns
            HStack(alignment: .top, spacing: 12) {
                column(cm)
                Rectangle().fill(Color.primary.opacity(0.10)).frame(width: 1)
                column(loh)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            Rectangle().fill(Color.primary.opacity(0.08)).frame(height: 1).padding(.vertical, 12)

            // Bottom half: pickup
            Group {
                if let p = pickup {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            CategoryBadge(category: .gacha)
                            Spacer(minLength: 4)
                            DDayStack(targetDate: p.targetDate, now: entry.date,
                                      dateText: dateLabel(for: p), ddaySize: 19, dateSize: 11)
                        }
                        PickupTwoColumn(trainees: p.trainees, supports: p.supportCards,
                                        supportNote: p.supportNote,
                                        headerSize: 12, lineSize: 11)
                        Spacer(minLength: 0)
                    }
                } else {
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.top, 3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// One top-half column for CM or LoH (short header). Graceful when nil.
    @ViewBuilder
    private func column(_ card: EventCard?) -> some View {
        if let card {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    CategoryBadge(category: card.category, short: true)
                    Spacer(minLength: 4)
                    DDayStack(targetDate: card.targetDate, now: entry.date,
                              dateText: dateLabel(for: card), ddaySize: 19, dateSize: 11)
                }
                BracketTitle(card.title, size: 16).padding(.top, 4)
                if let t = card.track {
                    Text(t.distanceLine)
                        .font(.system(size: 10))
                        .foregroundStyle(WidgetColors.title)
                        .padding(.top, 3)
                        .lineLimit(1)
                    let chips = t.conditionChips
                    if !chips.isEmpty {
                        Text(chips.joined(separator: "·"))
                            .font(.system(size: 9.5))
                            .foregroundStyle(WidgetColors.cond)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                RaceNameLine(grade: card.raceGrade, name: card.subtitle, size: 11)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else {
            Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
