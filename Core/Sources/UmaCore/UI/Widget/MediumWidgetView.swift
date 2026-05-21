import SwiftUI
import WidgetKit

public struct MediumWidgetView: View {
    public let entry: WidgetEntry
    public init(entry: WidgetEntry) { self.entry = entry }

    @ViewBuilder
    public var body: some View {
        switch entry.state {
        case .content(let cards):
            if cards.isEmpty {
                WidgetMessageView(titleKey: .stateIdleTitle, bodyKey: .stateIdleBody)
            } else if cards.count == 1, let card = cards.first, card.category == .gacha {
                pickupBig(card)
            } else if cards.count == 1, let card = cards.first {
                majorBig(card)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(cards.prefix(2).enumerated()), id: \.offset) { _, card in
                        EventCardRow(card: card, now: entry.date)
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        case .idle:   WidgetMessageView(titleKey: .stateIdleTitle, bodyKey: .stateIdleBody)
        case .noData: WidgetMessageView(titleKey: .stateNoDataTitle, bodyKey: .stateNoDataBody)
        }
    }

    /// Single major event (M1): bracket title + race subtitle + period + track summary + d-day.
    private func majorBig(_ card: EventCard) -> some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                CategoryBadge(category: card.category)
                BracketTitle(card.title, size: 20)
                if let s = card.subtitle { Text(s).font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary).lineLimit(1) }
                if let p = card.period { Text(PeriodFormatter.range(p)).font(.system(size: 11)).foregroundStyle(.secondary) }
                if let t = card.track { Text(t.summary).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1) }
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 2) {
                DDayBadge(targetDate: card.targetDate, now: entry.date)
                Text(card.phaseLabel).font(.system(size: 10)).foregroundStyle(.secondary)
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func pickupBig(_ card: EventCard) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                CategoryBadge(category: card.category)
                Spacer()
                if let p = card.period { Text(PeriodFormatter.range(p)).font(.system(size: 11)).foregroundStyle(.secondary) }
                DDayBadge(targetDate: card.targetDate, now: entry.date)
            }
            PickupLines(trainees: card.trainees, supports: card.supportCards)
            Spacer(minLength: 0)
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
