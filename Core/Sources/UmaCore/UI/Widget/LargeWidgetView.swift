import SwiftUI
import WidgetKit

/// systemLarge renderer. Two modes driven by detailLevel:
///   .detailed (L1) → single hero card with track image + d-day
///   else      (L2) → up to three stacked EventCardRows with dividers between them
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
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        case .idle:   WidgetMessageView(titleKey: .stateIdleTitle, bodyKey: .stateIdleBody)
        case .noData: WidgetMessageView(titleKey: .stateNoDataTitle, bodyKey: .stateNoDataBody)
        }
    }

    private func hero(_ card: EventCard) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                CategoryBadge(category: card.category)
                Spacer()
                DDayBadge(targetDate: card.targetDate, now: entry.date)
            }
            Text(card.title).font(.system(size: 22, weight: .bold)).lineLimit(1)
            if let track = card.track {
                TrackImageView(track: track).frame(height: 130)
                Text(track.summary).font(.system(size: 13)).foregroundStyle(.secondary)
            }
            Text(card.phaseLabel).font(.system(size: 13, weight: .medium))
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
