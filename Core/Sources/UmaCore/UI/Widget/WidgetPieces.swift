import SwiftUI
import WidgetKit

/// Big "D-5" / "D-DAY" label, themed.
public struct DDayBadge: View {
    public let targetDate: Date
    public let now: Date
    public init(targetDate: Date, now: Date) { self.targetDate = targetDate; self.now = now }
    public var body: some View {
        let days = CountdownFormatter.daysUntil(targetDate, from: now)
        Text(CountdownFormatter.ddayLabel(days: days))
            .font(Typography.systemFont(size: 20, weight: .heavy))
    }
}

/// One compact row: category badge, title, phase label, d-day. Used in multi-card widgets.
public struct EventCardRow: View {
    public let card: EventCard
    public let now: Date
    public init(card: EventCard, now: Date) { self.card = card; self.now = now }

    public var body: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                CategoryBadge(category: card.category)
                Text(card.title).font(.system(size: 14, weight: .semibold)).lineLimit(1)
                if let track = card.track {
                    Text(track.summary).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1)
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

/// Centered placeholder for idle / noData states.
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
