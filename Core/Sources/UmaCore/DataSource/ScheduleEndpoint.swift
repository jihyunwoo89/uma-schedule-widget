import Foundation

/// Remote schedule source — the schedule.json maintained from the Google Sheet and hosted
/// (free) on GitHub raw. Refresh it with: tools/ingestion `--from-sheet <csv url>` → push
/// schedule.json to the uma-schedule-data repo.
public enum ScheduleEndpoint {
    public static let url = URL(string: "https://raw.githubusercontent.com/jihyunwoo89/uma-schedule-data/main/schedule.json")!
}
