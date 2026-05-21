import SwiftUI
import WidgetKit

public struct DDayBadge: View {
    public let targetDate: Date
    public let now: Date
    public init(targetDate: Date, now: Date) { self.targetDate = targetDate; self.now = now }
    public var body: some View {
        Text(CountdownFormatter.ddayLabel(days: CountdownFormatter.daysUntil(targetDate, from: now)))
            .font(Typography.systemFont(size: 20, weight: .heavy))
    }
}

/// 「title」 in corner brackets — the big event identifier.
public struct BracketTitle: View {
    public let text: String
    public let size: CGFloat
    public init(_ text: String, size: CGFloat) { self.text = text; self.size = size }
    public var body: some View {
        Text("「\(text)」").font(Typography.systemFont(size: size, weight: .heavy)).lineLimit(1)
    }
}

/// Wrapping condition chips (Large detailed). Up to 3 per row.
public struct ConditionChips: View {
    public let chips: [String]
    public init(_ chips: [String]) { self.chips = chips }
    public var body: some View {
        let rows = stride(from: 0, to: chips.count, by: 3).map { Array(chips[$0..<min($0+3, chips.count)]) }
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 4) {
                    ForEach(row, id: \.self) { chip in
                        Text(chip).font(.system(size: 10))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.primary.opacity(0.06)).clipShape(Capsule())
                    }
                }
            }
        }
    }
}

/// Pickup trainee + support lines (full names). Used in M3, S4, L2.
public struct PickupLines: View {
    public let trainees: [String]
    public let supports: [SupportCardPick]
    public let compact: Bool
    public init(trainees: [String], supports: [SupportCardPick], compact: Bool = false) {
        self.trainees = trainees; self.supports = supports; self.compact = compact
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: compact ? 1 : 3) {
            if !trainees.isEmpty {
                Text("\(L.string(.fieldTrainee))  \(trainees.joined(separator: " · "))")
                    .font(.system(size: compact ? 9.5 : 11, weight: .semibold)).lineLimit(1)
            }
            if !compact && !supports.isEmpty {
                Text(L.string(.fieldSupport)).font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
            }
            ForEach(Array(supports.enumerated()), id: \.offset) { _, s in
                (Text("\(s.rarity) ").font(.system(size: compact ? 9.5 : 11, weight: .bold)).foregroundColor(EventCategory.gacha.accentColor)
                 + Text(s.name).font(.system(size: compact ? 9.5 : 11))
                 + Text(" <\(s.type)>").font(.system(size: compact ? 9.5 : 11)).foregroundColor(EventCategory.leagueOfHeroes.accentColor))
                    .lineLimit(1)
            }
        }
    }
}

/// One compact row for multi-card widgets: badge + bracket title + subtitle, d-day on the right.
public struct EventCardRow: View {
    public let card: EventCard
    public let now: Date
    public init(card: EventCard, now: Date) { self.card = card; self.now = now }
    public var body: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                CategoryBadge(category: card.category)
                if card.category == .gacha {
                    PickupLines(trainees: card.trainees, supports: card.supportCards, compact: true)
                } else {
                    BracketTitle(card.title, size: 15)
                    if let s = card.subtitle { Text(s).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1) }
                    if let t = card.track { Text(t.summary).font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(1) }
                }
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 2) {
                DDayBadge(targetDate: card.targetDate, now: now)
                Text(card.phaseLabel).font(.system(size: 10)).foregroundStyle(.secondary)
            }
        }
    }
}

public struct WidgetMessageView: View {
    public let titleKey: L.Key
    public let bodyKey: L.Key
    public init(titleKey: L.Key, bodyKey: L.Key) { self.titleKey = titleKey; self.bodyKey = bodyKey }
    public var body: some View {
        VStack(spacing: 4) {
            Text(L.string(titleKey)).font(.system(size: 14, weight: .semibold))
            Text(L.string(bodyKey)).font(.system(size: 11)).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
