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
