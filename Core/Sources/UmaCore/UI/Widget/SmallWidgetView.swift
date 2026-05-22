import SwiftUI
import WidgetKit

public struct SmallWidgetView: View {
    public let entry: WidgetEntry
    public init(entry: WidgetEntry) { self.entry = entry }

    @ViewBuilder
    public var body: some View {
        switch entry.state {
        case .content(let cards):
            if let card = cards.first {
                if card.category == .gacha { gacha(card) } else { major(card) }
            } else { empty }
        case .idle:   WidgetMessageView(titleKey: .stateIdleTitle, bodyKey: .stateIdleBody)
        case .noData: WidgetMessageView(titleKey: .stateNoDataTitle, bodyKey: .stateNoDataBody)
        }
    }
    private var empty: some View { WidgetMessageView(titleKey: .stateIdleTitle, bodyKey: .stateIdleBody) }

    /// S1 (auto major) / S2 (CM) / S3 (LoH). (DESIGN §8.9)
    @ViewBuilder
    private func major(_ card: EventCard) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                CategoryBadge(category: card.category, short: true)
                Spacer(minLength: 4)
                DDayStack(targetDate: card.targetDate, now: entry.date,
                          dateText: dateLabel(for: card), ddaySize: 15, dateSize: 9)
            }
            BracketTitle(card.title, size: 18).padding(.top, 5)
            RaceNameLine(grade: card.raceGrade, name: card.subtitle, size: 11).padding(.top, 1)
            if let t = card.track {
                TrackLines(track: t, distanceSize: 10, condSize: 10, spacing: 0).padding(.top, 11)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    /// S4 (pickup). Compact, single-line entries. (DESIGN §8.9)
    @ViewBuilder
    private func gacha(_ card: EventCard) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                CategoryBadge(category: card.category, short: true)
                Spacer(minLength: 4)
                DDayStack(targetDate: card.targetDate, now: entry.date,
                          dateText: dateLabel(for: card), ddaySize: 15, dateSize: 9)
            }
            PickupBlock(trainees: Array(card.trainees.prefix(2)),
                        supports: Array(card.supportCards.prefix(2)),
                        headerSize: 10.5, lineSize: 10.5, spacing: 2)
                .padding(.top, 5)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
