import SwiftUI
import UmaCore

/// Big "next event" card for the top of each category list.
struct ScheduleHeroCard: View {
    let card: EventCard
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                CategoryBadge(category: card.category)
                Spacer(minLength: 4)
                DDayStack(targetDate: card.targetDate, now: Date(),
                          dateText: card.period.map { PeriodFormatter.startShort($0) } ?? card.phaseLabel,
                          ddaySize: 24, dateSize: 11)
            }
            if card.category == .gacha {
                PickupBlock(trainees: card.trainees, supports: card.supportCards, supportNote: card.supportNote, headerSize: 12.5, lineSize: 12, spacing: 3)
            } else {
                BracketTitle(card.title, size: 20)
                RaceNameLine(grade: card.raceGrade, name: card.subtitle, size: 13)
                if let t = card.track { TrackLines(track: t, distanceSize: 12, condSize: 11) }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(card.category.accentColor.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(card.category.accentColor.opacity(0.20), lineWidth: 1)
        )
    }
}

/// Smaller uniform card for subsequent upcoming events.
struct ScheduleRowCard: View {
    let card: EventCard
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                if card.category == .gacha {
                    Text(card.trainees.map { PickupFormatter.trainee($0).name }.joined(separator: " · "))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(WidgetColors.raceName)
                        .lineLimit(2)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        BracketTitle(card.title, size: 15)
                        RaceNameLine(grade: card.raceGrade, name: card.subtitle, size: 12)
                    }
                    if let t = card.track {
                        Text(t.distanceLine).font(.system(size: 11)).foregroundStyle(WidgetColors.title).lineLimit(1)
                    }
                }
            }
            Spacer(minLength: 4)
            DDayStack(targetDate: card.targetDate, now: Date(),
                      dateText: card.period.map { PeriodFormatter.startShort($0) } ?? "",
                      ddaySize: 17, dateSize: 10)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}
