import SwiftUI
import WidgetKit

public struct SmallWidgetView: View {
    public let entry: WidgetEntry
    public init(entry: WidgetEntry) { self.entry = entry }

    @ViewBuilder
    public var body: some View {
        switch entry.state {
        case .content(let cards):
            if let card = cards.first { single(card) } else { empty }
        case .idle:   WidgetMessageView(titleKey: .stateIdleTitle, bodyKey: .stateIdleBody)
        case .noData: WidgetMessageView(titleKey: .stateNoDataTitle, bodyKey: .stateNoDataBody)
        }
    }
    private var empty: some View { WidgetMessageView(titleKey: .stateIdleTitle, bodyKey: .stateIdleBody) }

    @ViewBuilder
    private func single(_ card: EventCard) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            CategoryBadge(category: card.category)
            if card.category == .gacha {
                PickupLines(trainees: card.trainees, supports: card.supportCards, compact: true)
                Spacer(minLength: 0)
                DDayBadge(targetDate: card.targetDate, now: entry.date)
                Text(card.phaseLabel).font(.system(size: 10)).foregroundStyle(.secondary)
            } else {
                BracketTitle(card.title, size: 22)
                if let s = card.subtitle { Text(s).font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary).lineLimit(1) }
                if let t = card.track { Text(t.summary).font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(1) }
                Spacer(minLength: 0)
                DDayBadge(targetDate: card.targetDate, now: entry.date)
                Text(card.phaseLabel).font(.system(size: 10)).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
