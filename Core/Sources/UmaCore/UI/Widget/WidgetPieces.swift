import SwiftUI
import WidgetKit

// MARK: - Shared color tokens (DESIGN §2)

enum WidgetColors {
    static let title    = Color(hex: "#1B1E24") ?? .primary   // 제목 / D-day
    static let raceName = Color(hex: "#2B2F36") ?? .primary    // 레이스명 (bold)
    static let subtitle = Color(hex: "#5B616B") ?? .secondary  // 부제
    static let cond     = Color(hex: "#7B818B") ?? .secondary  // 마장 조건 줄
    static let muted    = Color(hex: "#9AA0A8") ?? .secondary  // 날짜/라벨
    static let star     = Color(hex: "#E8A11A") ?? .yellow
}

// MARK: - D-day

/// Big D-day text. Used standalone where layout drives spacing.
public struct DDayBadge: View {
    public let targetDate: Date
    public let now: Date
    public var size: CGFloat
    public init(targetDate: Date, now: Date, size: CGFloat = 20) {
        self.targetDate = targetDate; self.now = now; self.size = size
    }
    public var body: some View {
        Text(CountdownFormatter.ddayLabel(days: CountdownFormatter.daysUntil(targetDate, from: now)))
            .font(Typography.systemFont(size: size, weight: .heavy))
            .foregroundStyle(WidgetColors.title)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}

/// Right-aligned trailing stack: big D-day + a small date/label below. (DESIGN §8.7)
public struct DDayStack: View {
    public let targetDate: Date
    public let now: Date
    public let dateText: String
    public var ddaySize: CGFloat
    public var dateSize: CGFloat
    public init(targetDate: Date, now: Date, dateText: String,
                ddaySize: CGFloat = 20, dateSize: CGFloat = 9) {
        self.targetDate = targetDate; self.now = now; self.dateText = dateText
        self.ddaySize = ddaySize; self.dateSize = dateSize
    }
    public var body: some View {
        VStack(alignment: .trailing, spacing: 1) {
            DDayBadge(targetDate: targetDate, now: now, size: ddaySize)
            if !dateText.isEmpty {
                Text(dateText)
                    .font(.system(size: dateSize))
                    .foregroundStyle(WidgetColors.muted)
                    .lineLimit(1)
            }
        }
    }
}

/// Resolves the small date line below a D-day: start date (with 예상) or the phase label.
func dateLabel(for card: EventCard) -> String {
    if let p = card.period { return PeriodFormatter.startShort(p) }
    return card.phaseLabel
}

// MARK: - Title / race name

/// 「title」 in corner brackets — the big event identifier.
public struct BracketTitle: View {
    public let text: String
    public let size: CGFloat
    public init(_ text: String, size: CGFloat) { self.text = text; self.size = size }
    public var body: some View {
        Text("「\(text)」")
            .font(Typography.systemFont(size: size, weight: .heavy))
            .foregroundStyle(WidgetColors.title)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}

/// Race-name line: optional GradeBadge + bold race name.
public struct RaceNameLine: View {
    public let grade: String?
    public let name: String?
    public var size: CGFloat
    public init(grade: String?, name: String?, size: CGFloat = 12) {
        self.grade = grade; self.name = name; self.size = size
    }
    public var body: some View {
        if name != nil || grade != nil {
            HStack(spacing: 5) {
                if let g = grade { GradeBadge(grade: g) }
                if let n = name {
                    Text(n)
                        .font(.system(size: size, weight: .bold))
                        .foregroundStyle(WidgetColors.raceName)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
    }
}

// MARK: - Track lines

/// Distance line + condition chips line. (DESIGN §8.6)
public struct TrackLines: View {
    public let track: TrackCondition
    public var distanceSize: CGFloat
    public var condSize: CGFloat
    public var spacing: CGFloat
    public init(track: TrackCondition, distanceSize: CGFloat = 12, condSize: CGFloat = 11, spacing: CGFloat = 1) {
        self.track = track; self.distanceSize = distanceSize; self.condSize = condSize; self.spacing = spacing
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            Text(track.distanceLine)
                .font(.system(size: distanceSize, weight: .semibold))
                .foregroundStyle(WidgetColors.raceName)
                .lineLimit(1)
            let chips = track.conditionChips
            if !chips.isEmpty {
                Text(chips.joined(separator: " · "))
                    .font(.system(size: condSize))
                    .foregroundStyle(WidgetColors.cond)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
    }
}

// MARK: - Pickup lines

/// One trainee line: [N★ rarity badge] + name. No badge when no stars.
public struct TraineeLine: View {
    public let raw: String
    public var size: CGFloat
    public init(raw: String, size: CGFloat = 11.5) { self.raw = raw; self.size = size }
    public var body: some View {
        let parsed = PickupFormatter.trainee(raw)
        HStack(spacing: 5) {
            if let stars = parsed.stars, let tier = RarityTier("\(stars)★") {
                RarityBadge(text: "\(stars)★", tier: tier)
            }
            Text(parsed.name)
                .font(.system(size: size))
                .foregroundStyle(WidgetColors.raceName)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

/// One support line: [rarity badge] + name (type color) + type icon.
public struct SupportLine: View {
    public let pick: SupportCardPick
    public var size: CGFloat
    public init(pick: SupportCardPick, size: CGFloat = 11.5) { self.pick = pick; self.size = size }
    public var body: some View {
        HStack(spacing: 5) {
            if let tier = RarityTier(pick.rarity) {
                RarityBadge(text: pick.rarity, tier: tier)
            }
            Text(pick.name)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(SupportType.color(forType: pick.type) ?? WidgetColors.raceName)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            SupportTypeIcon(type: pick.type, size: size + 1.5)
        }
    }
}

/// Pickup header (육성 우마무스메 / 서포트 카드).
public struct PickupHeader: View {
    public let key: L.Key
    public var size: CGFloat
    public init(_ key: L.Key, size: CGFloat = 12.5) { self.key = key; self.size = size }
    public var body: some View {
        Text(L.string(key))
            .font(.system(size: size, weight: .heavy))
            .foregroundStyle(Color(hex: "#3A3F47") ?? .primary)
            .lineLimit(1)
    }
}

/// Stacked pickup block: trainee header + lines, then support header + lines.
public struct PickupBlock: View {
    public let trainees: [String]
    public let supports: [SupportCardPick]
    public var headerSize: CGFloat
    public var lineSize: CGFloat
    public var spacing: CGFloat
    public init(trainees: [String], supports: [SupportCardPick],
                headerSize: CGFloat = 12.5, lineSize: CGFloat = 11.5, spacing: CGFloat = 3) {
        self.trainees = trainees; self.supports = supports
        self.headerSize = headerSize; self.lineSize = lineSize; self.spacing = spacing
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            if !trainees.isEmpty {
                PickupHeader(.fieldTrainee, size: headerSize)
                ForEach(Array(trainees.enumerated()), id: \.offset) { _, t in
                    TraineeLine(raw: t, size: lineSize)
                }
            }
            if !supports.isEmpty {
                PickupHeader(.fieldSupport, size: headerSize)
                    .padding(.top, trainees.isEmpty ? 0 : 2)
                ForEach(Array(supports.enumerated()), id: \.offset) { _, s in
                    SupportLine(pick: s, size: lineSize)
                }
            }
        }
    }
}

/// Two-column pickup block: 육성 우마무스메 | divider | 서포트 카드. (M3, L2 bottom)
public struct PickupTwoColumn: View {
    public let trainees: [String]
    public let supports: [SupportCardPick]
    public var headerSize: CGFloat
    public var lineSize: CGFloat
    public init(trainees: [String], supports: [SupportCardPick],
                headerSize: CGFloat = 12.5, lineSize: CGFloat = 11.5) {
        self.trainees = trainees; self.supports = supports
        self.headerSize = headerSize; self.lineSize = lineSize
    }
    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                PickupHeader(.fieldTrainee, size: headerSize)
                ForEach(Array(trainees.enumerated()), id: \.offset) { _, t in
                    TraineeLine(raw: t, size: lineSize)
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(width: 1)
            VStack(alignment: .leading, spacing: 3) {
                PickupHeader(.fieldSupport, size: headerSize)
                ForEach(Array(supports.enumerated()), id: \.offset) { _, s in
                    SupportLine(pick: s, size: lineSize)
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Compact row (app list / multi-event medium)

/// One compact row: category header + 「title」/race (or pickup block) on the left, D-day stack on the right.
public struct EventCardRow: View {
    public let card: EventCard
    public let now: Date
    public init(card: EventCard, now: Date) { self.card = card; self.now = now }
    public var body: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                CategoryBadge(category: card.category)
                if card.category == .gacha {
                    PickupBlock(trainees: card.trainees, supports: card.supportCards,
                                headerSize: 12, lineSize: 11, spacing: 2)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        BracketTitle(card.title, size: 16)
                        RaceNameLine(grade: card.raceGrade, name: card.subtitle, size: 12)
                    }
                    if let t = card.track { TrackLines(track: t, distanceSize: 11, condSize: 10) }
                }
            }
            Spacer(minLength: 4)
            DDayStack(targetDate: card.targetDate, now: now,
                      dateText: dateLabel(for: card), ddaySize: 20, dateSize: 10)
        }
    }
}

// MARK: - Message (idle / no data)

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

// MARK: - Card selection helper

extension Array where Element == EventCard {
    func first(_ category: EventCategory) -> EventCard? { first { $0.category == category } }
}
