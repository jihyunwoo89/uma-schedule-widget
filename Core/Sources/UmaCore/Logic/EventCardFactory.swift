import Foundation

public enum EventCardFactory {

    /// The soonest non-ended Champions Meeting as a card, or nil if all are ended/empty.
    public static func championsCard(_ meetings: [ChampionsMeeting], now: Date) -> EventCard? {
        let candidate = meetings
            .map { ($0, $0.resolution(now: now)) }
            .filter { $0.1.status != .ended }
            .sorted { $0.1.targetDate < $1.1.targetDate }
            .first
        guard let (cm, r) = candidate else { return nil }
        return EventCard(
            category: .championsMeeting,
            title: cm.codeName,
            subtitle: cm.raceName,
            track: cm.track,
            period: cm.period,
            phaseLabel: phaseLabel(for: r),
            targetDate: r.targetDate,
            status: r.status,
            raceGrade: cm.raceGrade
        )
    }

    public static func leagueCard(_ leagues: [LeagueOfHeroes], now: Date) -> EventCard? {
        let candidate = leagues
            .map { ($0, $0.resolution(now: now)) }
            .filter { $0.1.status != .ended }
            .sorted { $0.1.targetDate < $1.1.targetDate }
            .first
        guard let (loh, r) = candidate else { return nil }
        let (grade, name) = GradeParse.leading(loh.raceName)
        return EventCard(
            category: .leagueOfHeroes,
            title: loh.round,
            subtitle: name,
            track: loh.track,
            period: loh.period,
            phaseLabel: phaseLabel(for: r),
            targetDate: r.targetDate,
            status: r.status,
            raceGrade: grade
        )
    }

    /// Active pickup (now within period) preferred; else the soonest upcoming.
    public static func pickupCard(_ pickups: [PickupPeriod], now: Date) -> EventCard? {
        let active = pickups
            .filter { now >= $0.period.start && now < $0.period.end }
            .sorted { $0.period.end < $1.period.end }
            .first
        if let p = active {
            return EventCard(category: .gacha, title: p.trainees.joined(separator: ", "),
                             period: p.period, phaseLabel: "종료까지", targetDate: p.period.end, status: .active,
                             trainees: p.trainees, supportCards: p.supportCards)
        }
        let upcoming = pickups
            .filter { $0.period.start > now }
            .sorted { $0.period.start < $1.period.start }
            .first
        if let p = upcoming {
            return EventCard(category: .gacha, title: p.trainees.joined(separator: ", "),
                             period: p.period, phaseLabel: "시작까지", targetDate: p.period.start, status: .upcoming,
                             trainees: p.trainees, supportCards: p.supportCards)
        }
        return nil
    }

    /// CM + LoH, nearer target wins; gacha excluded.
    public static func majorCard(_ doc: ScheduleDocument, now: Date) -> EventCard? {
        [championsCard(doc.championsMeetings, now: now), leagueCard(doc.leagueOfHeroes, now: now)]
            .compactMap { $0 }
            .min { $0.targetDate < $1.targetDate }
    }

    /// Phase label like "오픈까지" / "라운드1까지" / "진행중".
    private static func phaseLabel(for r: PhaseResolution) -> String {
        if let next = r.nextPhase, next.kind != .ended {
            return "\(next.label)까지"
        }
        return r.status == .active ? "진행중" : "종료까지"
    }
}
