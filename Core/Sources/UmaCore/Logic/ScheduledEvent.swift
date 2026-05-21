import Foundation

/// The result of evaluating a phased event at a moment in time.
public struct PhaseResolution: Equatable, Sendable {
    public let nextPhase: EventPhase?   // first phase with date > now (nil after the last)
    public let status: EventStatus
    public let targetDate: Date         // the date the d-day counts toward
}

/// Anything with an ordered `phases` array. Provides next-phase / status / target-date.
public protocol ScheduledEvent {
    var phases: [EventPhase] { get }
}

public extension ScheduledEvent {
    func resolution(now: Date) -> PhaseResolution {
        let sorted = phases.sorted { $0.date < $1.date }
        let next = sorted.first { $0.date > now }
        let firstStart = sorted.first?.date
        let endDate = sorted.last?.date

        let status: EventStatus
        if let end = endDate, now >= end {
            status = .ended
        } else if let start = firstStart, now >= start {
            status = .active
        } else {
            status = .upcoming
        }

        // Target the next upcoming phase; if none remain but not ended, target the end.
        let target = next?.date ?? endDate ?? now
        return PhaseResolution(nextPhase: next, status: status, targetDate: target)
    }
}

extension ChampionsMeeting: ScheduledEvent {}
extension LeagueOfHeroes: ScheduledEvent {}
