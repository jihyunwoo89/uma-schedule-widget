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

struct LockRectangularChampionsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LockRectangularChampionsWidget",
                            provider: ScheduleTimelineProvider(variant: .championsOnly, detailLevel: .overview)) { entry in
            LockRectangularView(entry: entry)
                .fontDesign(Typography.fontDesign(for: entry.fontTheme))
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName(Text("gallery.lock_rect_cm.title", bundle: .umaCore))
        .description(Text("gallery.lock_rect_cm.desc", bundle: .umaCore))
        .supportedFamilies([.accessoryRectangular])
    }
}

struct LockRectangularLoHWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LockRectangularLoHWidget",
                            provider: ScheduleTimelineProvider(variant: .loHOnly, detailLevel: .overview)) { entry in
            LockRectangularView(entry: entry)
                .fontDesign(Typography.fontDesign(for: entry.fontTheme))
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName(Text("gallery.lock_rect_loh.title", bundle: .umaCore))
        .description(Text("gallery.lock_rect_loh.desc", bundle: .umaCore))
        .supportedFamilies([.accessoryRectangular])
    }
}

struct LockRectangularPickupWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LockRectangularPickupWidget",
                            provider: ScheduleTimelineProvider(variant: .pickupOnly, detailLevel: .overview)) { entry in
            LockRectangularView(entry: entry)
                .fontDesign(Typography.fontDesign(for: entry.fontTheme))
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName(Text("gallery.lock_rect_pk.title", bundle: .umaCore))
        .description(Text("gallery.lock_rect_pk.desc", bundle: .umaCore))
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

struct LockCircularChampionsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LockCircularChampionsWidget",
                            provider: ScheduleTimelineProvider(variant: .championsOnly, detailLevel: .overview)) { entry in
            LockCircularView(entry: entry)
                .fontDesign(Typography.fontDesign(for: entry.fontTheme))
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName(Text("gallery.lock_circ_cm.title", bundle: .umaCore))
        .description(Text("gallery.lock_circ_cm.desc", bundle: .umaCore))
        .supportedFamilies([.accessoryCircular])
    }
}

struct LockCircularLoHWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LockCircularLoHWidget",
                            provider: ScheduleTimelineProvider(variant: .loHOnly, detailLevel: .overview)) { entry in
            LockCircularView(entry: entry)
                .fontDesign(Typography.fontDesign(for: entry.fontTheme))
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName(Text("gallery.lock_circ_loh.title", bundle: .umaCore))
        .description(Text("gallery.lock_circ_loh.desc", bundle: .umaCore))
        .supportedFamilies([.accessoryCircular])
    }
}

struct LockCircularPickupWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LockCircularPickupWidget",
                            provider: ScheduleTimelineProvider(variant: .pickupOnly, detailLevel: .overview)) { entry in
            LockCircularView(entry: entry)
                .fontDesign(Typography.fontDesign(for: entry.fontTheme))
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName(Text("gallery.lock_circ_pk.title", bundle: .umaCore))
        .description(Text("gallery.lock_circ_pk.desc", bundle: .umaCore))
        .supportedFamilies([.accessoryCircular])
    }
}

struct LockInlineWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LockInlineWidget",
                            provider: ScheduleTimelineProvider(variant: .majorAuto, detailLevel: .overview)) { entry in
            LockInlineView(entry: entry)
                .fontDesign(Typography.fontDesign(for: entry.fontTheme))
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName(Text("gallery.lock_inline.title", bundle: .umaCore))
        .description(Text("gallery.lock_inline.desc", bundle: .umaCore))
        .supportedFamilies([.accessoryInline])
    }
}
