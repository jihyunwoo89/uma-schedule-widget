import SwiftUI
import WidgetKit

public struct LockRectangularView: View {
    public let entry: WidgetEntry
    public init(entry: WidgetEntry) { self.entry = entry }

    @ViewBuilder
    public var body: some View {
        if case let .content(cards) = entry.state, let card = cards.first {
            HStack(spacing: 10) {
                Image("ic_horseshoe", bundle: .module)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42, height: 42)
                Rectangle()
                    .fill(Color.primary.opacity(0.3))
                    .frame(width: 1, height: 44)
                VStack(alignment: .leading, spacing: 1) {
                    Text(L.string(card.category.labelKey))
                        .font(.uma(11, weight: .semibold))
                        .lineLimit(1)
                    Text("「\(line2(card))」")
                        .font(.uma(17, weight: .heavy))
                        .lineLimit(1)
                    Text(line3(card))
                        .font(.uma(12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(L.string(.stateIdleTitle)).font(.uma(12))
        }
    }

    /// Line 2 = 「코드명」 for CM/LoH; first trainee name for gacha.
    private func line2(_ card: EventCard) -> String {
        if card.category == .gacha {
            if let first = card.trainees.first {
                return PickupFormatter.trainee(first).name
            }
            return L.string(.categoryPickup)
        }
        return card.title
    }

    /// Line 3 = "D-17 · 6/7" (D-day + slash date).
    private func line3(_ card: EventCard) -> String {
        let dday = CountdownFormatter.ddayLabel(days: CountdownFormatter.daysUntil(card.targetDate, from: entry.date))
        if let p = card.period {
            return "\(dday) · \(PeriodFormatter.slash(p))"
        }
        return "\(dday) · \(card.phaseLabel)"
    }
}

public struct LockCircularView: View {
    public let entry: WidgetEntry
    public init(entry: WidgetEntry) { self.entry = entry }

    /// Countdown window (days) the ring fills over — fuller ring = closer to the event.
    private static let windowDays = 90.0

    @ViewBuilder
    public var body: some View {
        if case let .content(cards) = entry.state, let card = cards.first {
            let days = max(0, CountdownFormatter.daysUntil(card.targetDate, from: entry.date))
            let progress = min(1.0, max(0.0, (Self.windowDays - Double(days)) / Self.windowDays))
            Gauge(value: progress) {
                Text(L.string(card.category.shortLabelKey))
            } currentValueLabel: {
                Text("\(days)")
            }
            .gaugeStyle(.accessoryCircular)
        } else {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "calendar")
            }
        }
    }
}

/// accessoryInline — single line next to the clock (system monochrome).
public struct LockInlineView: View {
    public let entry: WidgetEntry
    public init(entry: WidgetEntry) { self.entry = entry }

    @ViewBuilder
    public var body: some View {
        if case let .content(cards) = entry.state, let card = cards.first {
            let dday = CountdownFormatter.ddayLabel(days: CountdownFormatter.daysUntil(card.targetDate, from: entry.date))
            let head = card.category == .gacha
                ? L.string(.categoryPickup)
                : "\(L.string(card.category.shortLabelKey)) 「\(card.title)」"
            Label {
                Text("\(head) · \(dday)")
            } icon: {
                Image(systemName: card.category.sfSymbol)
            }
        } else {
            Text(L.string(.stateIdleTitle))
        }
    }
}
