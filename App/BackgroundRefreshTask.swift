import Foundation
import BackgroundTasks
import WidgetKit
import UmaCore

/// Registers a periodic background fetch that refreshes the schedule cache + reloads widgets.
enum BackgroundRefreshTask {
    static let identifier = "com.damienjee.umaschedule.refresh"

    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            handle(task as! BGAppRefreshTask)
        }
        schedule()
    }

    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date().addingTimeInterval(6 * 3600)
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handle(_ task: BGAppRefreshTask) {
        schedule()
        let work = Task {
            _ = try? await ScheduleRepository.makeLive().current()
            WidgetCenter.shared.reloadAllTimelines()
            task.setTaskCompleted(success: true)
        }
        task.expirationHandler = { work.cancel() }
    }
}
