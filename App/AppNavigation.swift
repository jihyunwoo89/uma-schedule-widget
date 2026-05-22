import Foundation
import UmaCore

/// Navigation value for the detail screen — carries the domain model so detail can show phases.
enum DetailTarget: Hashable {
    case champions(ChampionsMeeting)
    case league(LeagueOfHeroes)
    case pickup(PickupPeriod)
}

/// A list row: the display card + where tapping goes.
struct ScheduleItem: Identifiable {
    let id: String
    let card: EventCard
    let target: DetailTarget
}
