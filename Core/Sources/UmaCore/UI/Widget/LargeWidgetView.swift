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
                hero(card)
            } else if cards.isEmpty {
                WidgetMessageView(titleKey: .stateIdleTitle, bodyKey: .stateIdleBody)
            } else {
                let shown = Array(cards.prefix(3))
                VStack(spacing: 12) {
                    ForEach(Array(shown.enumerated()), id: \.offset) { index, card in
                        EventCardRow(card: card, now: entry.date)
                        if index < shown.count - 1 { Divider() }
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        case .idle:   WidgetMessageView(titleKey: .stateIdleTitle, bodyKey: .stateIdleBody)
        case .noData: WidgetMessageView(titleKey: .stateNoDataTitle, bodyKey: .stateNoDataBody)
        }
    }

    @ViewBuilder
    private func hero(_ card: EventCard) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { CategoryBadge(category: card.category); Spacer(); DDayBadge(targetDate: card.targetDate, now: entry.date) }
            BracketTitle(card.title, size: 26)
            if let s = card.subtitle { Text(s).font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary) }
            if let p = card.period { Text(PeriodFormatter.range(p)).font(.system(size: 12)).foregroundStyle(.secondary) }
            if let t = card.track {
                TrackImageView(track: t).frame(height: 92)
                Text(t.summary).font(.system(size: 12)).foregroundStyle(.secondary)
                ConditionChips(t.conditionChips)
            }
            Spacer(minLength: 0)
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
