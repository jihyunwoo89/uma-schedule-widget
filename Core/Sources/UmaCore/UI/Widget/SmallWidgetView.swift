import SwiftUI
import WidgetKit

/// systemSmall renderer. Shows the first card (overview): badge, title, d-day, phase.
/// Used by S1 (majorAuto), S2 (champions), S3 (loH), S4 (pickup) — variant only changes
/// which card the resolver placed in `entry.state`.
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

    private func single(_ card: EventCard) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            CategoryBadge(category: card.category)
            Text(card.title).font(.system(size: 16, weight: .bold)).lineLimit(2)
            Spacer(minLength: 0)
            DDayBadge(targetDate: card.targetDate, now: entry.date)
            Text(card.phaseLabel).font(.system(size: 11)).foregroundStyle(.secondary)
            if let track = card.track {
                Text(track.summary).font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
