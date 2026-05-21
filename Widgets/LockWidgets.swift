import WidgetKit
import SwiftUI
import UmaCore

struct LockRectangularWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LockRectangularWidget",
                            provider: ScheduleTimelineProvider(variant: .majorAuto, detailLevel: .overview)) { entry in
            LockRectangularView(entry: entry)
                .fontDesign(Typography.fontDesign(for: entry.fontTheme))
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName(Text("gallery.lock_rect.title", bundle: .umaCore))
        .description(Text("gallery.lock_rect.desc", bundle: .umaCore))
        .supportedFamilies([.accessoryRectangular])
    }
}

struct LockCircularWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LockCircularWidget",
                            provider: ScheduleTimelineProvider(variant: .majorAuto, detailLevel: .overview)) { entry in
            LockCircularView(entry: entry)
                .fontDesign(Typography.fontDesign(for: entry.fontTheme))
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName(Text("gallery.lock_circ.title", bundle: .umaCore))
        .description(Text("gallery.lock_circ.desc", bundle: .umaCore))
        .supportedFamilies([.accessoryCircular])
    }
}
