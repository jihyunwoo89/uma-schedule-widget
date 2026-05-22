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
                        .font(.system(size: 11, weight: .semibold))
                        .lineLimit(1)
                    Text("「\(line2(card))」")
                        .font(.system(size: 17, weight: .heavy))
                        .lineLimit(1)
                    Text(line3(card))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(L.string(.stateIdleTitle)).font(.system(size: 12))
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

    @ViewBuilder
    public var body: some View {
        if case let .content(cards) = entry.state, let card = cards.first {
            let days = CountdownFormatter.daysUntil(card.targetDate, from: entry.date)
            ZStack {
                AccessoryWidgetBackground()
                Circle().stroke(Color.primary.opacity(0.28), lineWidth: 3)
                VStack(spacing: 0) {
                    Text(L.string(card.category.shortLabelKey))
                        .font(.system(size: 9.5, weight: .bold))
                        .lineLimit(1)
                    Text(days <= 0 ? "0" : "\(days)")
                        .font(.system(size: 21, weight: .heavy))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text("D-DAY")
                        .font(.system(size: 8))
                        .opacity(0.85)
                }
            }
        } else {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "calendar")
            }
        }
    }
}
