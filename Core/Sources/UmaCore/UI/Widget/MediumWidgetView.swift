import SwiftUI
import WidgetKit

/// systemMedium renderer. Shows up to two cards as stacked rows (brief detail).
/// Used by M1 (majorAuto, 1 card), M2 (championsLoH, 2 cards), M3 (pickupOnly, 1 card).
public struct MediumWidgetView: View {
    public let entry: WidgetEntry
    public init(entry: WidgetEntry) { self.entry = entry }

    @ViewBuilder
    public var body: some View {
        switch entry.state {
        case .content(let cards):
            if cards.isEmpty {
                WidgetMessageView(titleKey: .stateIdleTitle, bodyKey: .stateIdleBody)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(cards.prefix(2).enumerated()), id: \.offset) { _, card in
                        EventCardRow(card: card, now: entry.date)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        case .idle:   WidgetMessageView(titleKey: .stateIdleTitle, bodyKey: .stateIdleBody)
        case .noData: WidgetMessageView(titleKey: .stateNoDataTitle, bodyKey: .stateNoDataBody)
        }
    }
}
