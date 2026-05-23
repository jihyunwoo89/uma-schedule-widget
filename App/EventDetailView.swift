import SwiftUI
import UmaCore

struct EventDetailView: View {
    let target: DetailTarget
    private let now = Date()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                switch target {
                case .champions(let cm):
                    raceDetail(card: EventCardFactory.championsCard(for: cm, now: now),
                               track: cm.track, phases: cm.phases)
                case .league(let loh):
                    raceDetail(card: EventCardFactory.leagueCard(for: loh, now: now),
                               track: loh.track, phases: loh.phases)
                case .pickup(let p):
                    PickupDetailBody(pickup: p, now: now)
                }
                disclaimer
            }
            .padding(16)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func raceDetail(card: EventCard, track: TrackCondition, phases: [EventPhase]) -> some View {
        // Hero
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                CategoryBadge(category: card.category)
                Spacer()
                DDayStack(targetDate: card.targetDate, now: now,
                          dateText: card.phaseLabel, ddaySize: 30, dateSize: 11)
            }
            BracketTitle(card.title, size: 26)
            RaceNameLine(grade: card.raceGrade, name: card.subtitle, size: 14)
            if let p = card.period {
                Text("\(L.string(.detailFieldPeriod)) · \(PeriodFormatter.range(p))")
                    .font(.system(size: 12)).foregroundStyle(WidgetColors.muted).padding(.top, 2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(card.category.accentColor.opacity(0.08)))

        // Track
        SectionLabel(.detailSectionTrack)
        TrackImageView(track: track).frame(height: 150).clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        Text(track.distanceLine).font(.system(size: 14, weight: .bold)).foregroundStyle(WidgetColors.title)
        let chips = track.conditionChips
        if !chips.isEmpty {
            ConditionChipsWrap(chips: chips)
        }

        // Phases
        if !phases.isEmpty {
            SectionLabel(.detailSectionPhases)
            PhaseTimeline(phases: phases, accent: card.category.accentColor, now: now)
        }
    }

    private var disclaimer: some View {
        Text(L.string(.legalDisclaimer))
            .font(.system(size: 10)).foregroundStyle(WidgetColors.muted)
            .padding(.top, 4)
    }
}

/// Uppercase muted section label.
struct SectionLabel: View {
    let key: L.Key
    init(_ key: L.Key) { self.key = key }
    var body: some View {
        Text(L.string(key)).font(.system(size: 11, weight: .bold))
            .foregroundStyle(WidgetColors.muted).textCase(.uppercase)
            .padding(.top, 6)
    }
}

/// Wrapping condition chips (방향·계절·날씨 등).
struct ConditionChipsWrap: View {
    let chips: [String]
    var body: some View {
        let rows = stride(from: 0, to: chips.count, by: 3).map { Array(chips[$0..<min($0+3, chips.count)]) }
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { c in
                        Text(c).font(.system(size: 11)).foregroundStyle(WidgetColors.subtitle)
                            .padding(.horizontal, 9).padding(.vertical, 4)
                            .background(Color.primary.opacity(0.05)).clipShape(Capsule())
                    }
                }
            }
        }
    }
}

/// Vertical phase list: done (filled) / current (filled + d-day) / future (hollow).
struct PhaseTimeline: View {
    let phases: [EventPhase]
    let accent: Color
    let now: Date
    var body: some View {
        let sorted = phases.sorted { $0.date < $1.date }
        VStack(spacing: 0) {
            ForEach(Array(sorted.enumerated()), id: \.offset) { idx, ph in
                let isCurrent = ph.date > now && (idx == 0 || sorted[idx-1].date <= now)
                HStack(spacing: 10) {
                    Circle()
                        .fill(ph.date <= now || isCurrent ? accent : Color.clear)
                        .frame(width: 9, height: 9)
                        .overlay(Circle().stroke(accent, lineWidth: 2))
                    Text(ph.label).font(.system(size: 13, weight: .semibold)).foregroundStyle(WidgetColors.title)
                    if isCurrent {
                        Text(CountdownFormatter.ddayLabel(days: CountdownFormatter.daysUntil(ph.date, from: now)))
                            .font(.system(size: 10, weight: .bold)).foregroundStyle(accent)
                    }
                    Spacer()
                    Text(PeriodFormatter.startShort(EventPeriod(start: ph.date, end: ph.date)))
                        .font(.system(size: 12)).foregroundStyle(WidgetColors.subtitle)
                }
                .padding(.vertical, 8)
                if idx < sorted.count - 1 { Divider() }
            }
        }
        .padding(.horizontal, 13)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(.secondarySystemGroupedBackground)))
    }
}

struct PickupDetailBody: View {
    let pickup: PickupPeriod
    let now: Date
    var body: some View {
        let card = EventCardFactory.pickupCard(for: pickup, now: now)
        VStack(alignment: .leading, spacing: 14) {
            // Hero
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    CategoryBadge(category: .gacha)
                    Spacer()
                    DDayStack(targetDate: card.targetDate, now: now, dateText: card.phaseLabel, ddaySize: 30, dateSize: 11)
                }
                Text("\(L.string(.detailFieldPeriod)) · \(PeriodFormatter.range(pickup.period))")
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(WidgetColors.raceName)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(EventCategory.gacha.accentColor.opacity(0.08)))

            // Trainees
            if !pickup.trainees.isEmpty {
                Text(L.string(.fieldTrainee)).font(.system(size: 13, weight: .heavy)).foregroundStyle(WidgetColors.title)
                VStack(spacing: 0) {
                    ForEach(Array(pickup.trainees.enumerated()), id: \.offset) { idx, t in
                        let parsed = PickupFormatter.trainee(t)
                        HStack(spacing: 8) {
                            if let stars = parsed.stars, let tier = RarityTier("\(stars)★") {
                                RarityBadge(text: "\(stars)★", tier: tier)
                            }
                            Text(parsed.name).font(.system(size: 14, weight: .semibold)).foregroundStyle(WidgetColors.raceName)
                            Spacer()
                        }.padding(.vertical, 9)
                        if idx < pickup.trainees.count - 1 { Divider() }
                    }
                }.padding(.horizontal, 13)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(.secondarySystemGroupedBackground)))
            }

            // Support cards
            if !pickup.supportCards.isEmpty {
                Text(L.string(.fieldSupport)).font(.system(size: 13, weight: .heavy)).foregroundStyle(WidgetColors.title)
                VStack(spacing: 0) {
                    ForEach(Array(pickup.supportCards.enumerated()), id: \.offset) { idx, s in
                        HStack(spacing: 8) {
                            if let tier = RarityTier(s.rarity) { RarityBadge(text: s.rarity, tier: tier) }
                            Text(s.name).font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(SupportType.color(forType: s.type) ?? WidgetColors.raceName)
                            Spacer()
                            SupportTypeIcon(type: s.type, size: 20)
                        }.padding(.vertical, 9)
                        if idx < pickup.supportCards.count - 1 { Divider() }
                    }
                }.padding(.horizontal, 13)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(.secondarySystemGroupedBackground)))
            }
        }
    }
}
