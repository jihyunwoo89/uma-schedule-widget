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
                gacha(card)            // M3
            } else if cards.count == 1, let card = cards.first {
                majorBig(card)         // M1
            } else {
                twoRows(Array(cards.prefix(2)))  // M2
            }
        case .idle:   WidgetMessageView(titleKey: .stateIdleTitle, bodyKey: .stateIdleBody)
        case .noData: WidgetMessageView(titleKey: .stateNoDataTitle, bodyKey: .stateNoDataBody)
        }
    }

    /// M1: left column (header / 「title」 / race name / track 2 lines) + right big D-day stack.
    private func majorBig(_ card: EventCard) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                CategoryBadge(category: card.category)
                BracketTitle(card.title, size: 20).padding(.top, 5)
                RaceNameLine(grade: card.raceGrade, name: card.subtitle, size: 12).padding(.top, 2)
                if let t = card.track {
                    TrackLines(track: t, distanceSize: 11, condSize: 11, spacing: 1).padding(.top, 8)
                }
            }
            Spacer(minLength: 4)
            DDayStack(targetDate: card.targetDate, now: entry.date,
                      dateText: dateLabel(for: card), ddaySize: 32, dateSize: 11)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    /// M2: two stacked rows (CM / LoH) with a hairline divider between.
    private func twoRows(_ cards: [EventCard]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                row(card)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if index < cards.count - 1 {
                    Rectangle().fill(Color.primary.opacity(0.08)).frame(height: 1)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func row(_ card: EventCard) -> some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                CategoryBadge(category: card.category)
                HStack(spacing: 6) {
                    BracketTitle(card.title, size: 16)
                    RaceNameLine(grade: card.raceGrade, name: card.subtitle, size: 12)
                }
                if let t = card.track {
                    Text(conditionSummary(t))
                        .font(.system(size: 10.5))
                        .foregroundStyle(WidgetColors.cond)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }
            Spacer(minLength: 4)
            DDayStack(targetDate: card.targetDate, now: entry.date,
                      dateText: dateLabel(for: card), ddaySize: 22, dateSize: 11)
        }
    }

    /// "한신 잔디 1600m · 시계(우)·봄·맑음·양호·낮" single-line summary.
    private func conditionSummary(_ t: TrackCondition) -> String {
        let chips = t.conditionChips
        return chips.isEmpty ? t.distanceLine : "\(t.distanceLine) · \(chips.joined(separator: "·"))"
    }

    /// M3: header + right big D-day stack, then 2-column pickup.
    private func gacha(_ card: EventCard) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                CategoryBadge(category: card.category)
                Spacer(minLength: 4)
                DDayStack(targetDate: card.targetDate, now: entry.date,
                          dateText: dateLabel(for: card), ddaySize: 22, dateSize: 11)
            }
            PickupTwoColumn(trainees: card.trainees, supports: card.supportCards,
                            headerSize: 12.5, lineSize: 11.5)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
