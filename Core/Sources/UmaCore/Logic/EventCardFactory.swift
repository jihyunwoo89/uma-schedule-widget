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
            title: cm.name,
            track: cm.track,
            phaseLabel: phaseLabel(for: r),
            targetDate: r.targetDate,
            status: r.status
        )
    }

    public static func leagueCard(_ leagues: [LeagueOfHeroes], now: Date) -> EventCard? {
        let candidate = leagues
            .map { ($0, $0.resolution(now: now)) }
            .filter { $0.1.status != .ended }
            .sorted { $0.1.targetDate < $1.1.targetDate }
            .first
        guard let (loh, r) = candidate else { return nil }
        return EventCard(
            category: .leagueOfHeroes,
            title: loh.season,
            track: loh.track,
            phaseLabel: phaseLabel(for: r),
            targetDate: r.targetDate,
            status: r.status
        )
    }

    /// Active banner (now within start..end) preferred; else the soonest upcoming.
    public static func gachaCard(_ banners: [GachaBanner], now: Date) -> EventCard? {
        let active = banners
            .filter { now >= $0.startDate && now < $0.endDate }
            .sorted { $0.endDate < $1.endDate }
            .first
        if let b = active {
            return EventCard(category: .gacha, title: b.featured.joined(separator: ", "),
                             track: nil, phaseLabel: "종료까지", targetDate: b.endDate, status: .active)
        }
        let upcoming = banners
            .filter { $0.startDate > now }
            .sorted { $0.startDate < $1.startDate }
            .first
        if let b = upcoming {
            return EventCard(category: .gacha, title: b.featured.joined(separator: ", "),
                             track: nil, phaseLabel: "시작까지", targetDate: b.startDate, status: .upcoming)
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
