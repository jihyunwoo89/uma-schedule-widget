import Foundation

public enum ScheduleStateResolver {

    /// Build the widget state for a variant from the schedule document at `now`.
    public static func resolve(document: ScheduleDocument, variant: WidgetVariant, now: Date) -> WidgetState {
        let cards: [EventCard]
        if variant.isMajorAuto {
            cards = [EventCardFactory.majorCard(document, now: now)].compactMap { $0 }
        } else {
            cards = variant.categories.compactMap { card(for: $0, document: document, now: now) }
        }
        return cards.isEmpty ? .idle : .content(cards)
    }

    private static func card(for category: EventCategory, document: ScheduleDocument, now: Date) -> EventCard? {
        switch category {
        case .championsMeeting: return EventCardFactory.championsCard(document.championsMeetings, now: now)
        case .leagueOfHeroes:   return EventCardFactory.leagueCard(document.leagueOfHeroes, now: now)
        case .gacha:            return EventCardFactory.gachaCard(document.gachaBanners, now: now)
        }
    }
}
