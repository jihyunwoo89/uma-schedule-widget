import WidgetKit
import UmaCore
import Foundation

/// One provider, parameterized by the widget's variant + detail level. Each Widget passes
/// its own (variant, detailLevel) so a single provider type drives all widgets.
struct ScheduleTimelineProvider: TimelineProvider {
    typealias Entry = WidgetEntry

    let variant: WidgetVariant
    let detailLevel: DetailLevel

    private static let prefsKey = "pref.user.v1"

    func placeholder(in context: Context) -> WidgetEntry {
        let prefs = AppGroupStore.shared().read(UserPrefs.self, forKey: Self.prefsKey)
        WidgetPreferenceApplier.apply(prefs)
        return WidgetEntry(date: Date(), state: .idle, detailLevel: detailLevel, fontTheme: prefs?.fontTheme ?? .system)
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        Task { completion(await currentEntry(date: Date())) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        Task {
            let entry = await currentEntry(date: Date())
            completion(Timeline(entries: [entry], policy: refreshPolicy(for: entry)))
        }
    }

    private func currentEntry(date: Date) async -> WidgetEntry {
        let prefs = AppGroupStore.shared().read(UserPrefs.self, forKey: Self.prefsKey)
        WidgetPreferenceApplier.apply(prefs)
        let fontTheme = prefs?.fontTheme ?? .system
        let repo = ScheduleRepository.makeLive()
        do {
            let doc = try await repo.current()
            let state = ScheduleStateResolver.resolve(document: doc, variant: variant, now: date)
            // Detailed widgets show a track image — pre-download it into the App Group cache
            // so the (synchronous) widget view can load it from disk.
            if detailLevel == .detailed,
               case let .content(cards) = state,
               let url = cards.first?.track?.imageURL {
                await TrackImageCache.shared().ensureCached(url) { try await URLSession.shared.data(from: $0).0 }
            }
            return WidgetEntry(date: date, state: state, detailLevel: detailLevel, fontTheme: fontTheme)
        } catch {
            return WidgetEntry(date: date, state: .noData, detailLevel: detailLevel, fontTheme: fontTheme)
        }
    }

    /// Refresh shortly after the nearest target date; otherwise 1h if within a day, else 6h.
    private func refreshPolicy(for entry: WidgetEntry) -> TimelineReloadPolicy {
        guard case let .content(cards) = entry.state,
              let nearest = cards.map(\.targetDate).min() else {
            return .after(Date().addingTimeInterval(6 * 3600))
        }
        let secs = nearest.timeIntervalSinceNow
        if secs > 0 && secs <= 60 { return .after(nearest.addingTimeInterval(60)) }
        if secs > 0 && secs <= 86_400 { return .after(Date().addingTimeInterval(3600)) }
        return .after(Date().addingTimeInterval(6 * 3600))
    }
}
