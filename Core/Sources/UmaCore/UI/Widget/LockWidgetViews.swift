import SwiftUI
import WidgetKit

public struct LockRectangularView: View {
    public let entry: WidgetEntry
    public init(entry: WidgetEntry) { self.entry = entry }
    @ViewBuilder
    public var body: some View {
        if case let .content(cards) = entry.state, let card = cards.first {
            VStack(alignment: .leading, spacing: 1) {
                Text(card.category == .gacha ? L.string(.categoryPickup) : "\(L.string(card.category.labelKey)) 「\(card.title)」")
                    .font(.system(size: 11, weight: .semibold)).lineLimit(1)
                Text(card.category == .gacha ? card.trainees.joined(separator: " · ") : (card.subtitle ?? ""))
                    .font(.system(size: 13, weight: .bold)).lineLimit(1)
                HStack(spacing: 4) {
                    Text(CountdownFormatter.ddayLabel(days: CountdownFormatter.daysUntil(card.targetDate, from: entry.date)))
                    Text(card.phaseLabel)
                }.font(.system(size: 11)).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(L.string(.stateIdleTitle)).font(.system(size: 12))
        }
    }
}

public struct LockCircularView: View {
    public let entry: WidgetEntry
    public init(entry: WidgetEntry) { self.entry = entry }
    @ViewBuilder
    public var body: some View {
        if case let .content(cards) = entry.state, let card = cards.first {
            let days = CountdownFormatter.daysUntil(card.targetDate, from: entry.date)
            VStack(spacing: 0) {
                Image(systemName: card.category.sfSymbol).font(.system(size: 11, weight: .bold))
                Text(days <= 0 ? "D" : "\(days)").font(.system(size: 18, weight: .heavy))
                Text(days <= 0 ? "DAY" : "일").font(.system(size: 8))
            }
        } else {
            Image(systemName: "calendar")
        }
    }
}
