import Foundation

/// Remote schedule source. The JSON file is hand-maintained and hosted (GitHub raw by
/// default). Update this URL when the hosting location is finalized.
public enum ScheduleEndpoint {
    public static let url = URL(string: "https://raw.githubusercontent.com/damienjee/uma-schedule-data/main/schedule.json")!
}
