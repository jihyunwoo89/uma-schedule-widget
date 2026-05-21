import WidgetKit
import SwiftUI
import UmaCore

private func container<V: View>(_ view: V) -> some View {
    view
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
}

// MARK: Large

struct L1MajorDetailWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "L1MajorDetailWidget",
                            provider: ScheduleTimelineProvider(variant: .majorAuto, detailLevel: .detailed)) { entry in
            container(LargeWidgetView(entry: entry).fontDesign(Typography.fontDesign(for: entry.fontTheme)))
        }
        .configurationDisplayName(Text("gallery.l1.title", bundle: .umaCore))
        .description(Text("gallery.l1.desc", bundle: .umaCore))
        .supportedFamilies([.systemLarge])
    }
}

struct L2AllScheduleWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "L2AllScheduleWidget",
                            provider: ScheduleTimelineProvider(variant: .allSchedule, detailLevel: .brief)) { entry in
            container(LargeWidgetView(entry: entry).fontDesign(Typography.fontDesign(for: entry.fontTheme)))
        }
        .configurationDisplayName(Text("gallery.l2.title", bundle: .umaCore))
        .description(Text("gallery.l2.desc", bundle: .umaCore))
        .supportedFamilies([.systemLarge])
    }
}

// MARK: Medium

struct M1MajorBriefWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "M1MajorBriefWidget",
                            provider: ScheduleTimelineProvider(variant: .majorAuto, detailLevel: .brief)) { entry in
            container(MediumWidgetView(entry: entry).fontDesign(Typography.fontDesign(for: entry.fontTheme)))
        }
        .configurationDisplayName(Text("gallery.m1.title", bundle: .umaCore))
        .description(Text("gallery.m1.desc", bundle: .umaCore))
        .supportedFamilies([.systemMedium])
    }
}

struct M2ChampionsLoHWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "M2ChampionsLoHWidget",
                            provider: ScheduleTimelineProvider(variant: .championsLoH, detailLevel: .brief)) { entry in
            container(MediumWidgetView(entry: entry).fontDesign(Typography.fontDesign(for: entry.fontTheme)))
        }
        .configurationDisplayName(Text("gallery.m2.title", bundle: .umaCore))
        .description(Text("gallery.m2.desc", bundle: .umaCore))
        .supportedFamilies([.systemMedium])
    }
}

struct M3PickupWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "M3PickupWidget",
                            provider: ScheduleTimelineProvider(variant: .pickupOnly, detailLevel: .brief)) { entry in
            container(MediumWidgetView(entry: entry).fontDesign(Typography.fontDesign(for: entry.fontTheme)))
        }
        .configurationDisplayName(Text("gallery.m3.title", bundle: .umaCore))
        .description(Text("gallery.m3.desc", bundle: .umaCore))
        .supportedFamilies([.systemMedium])
    }
}

// MARK: Small

struct S1MajorOverviewWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "S1MajorOverviewWidget",
                            provider: ScheduleTimelineProvider(variant: .majorAuto, detailLevel: .overview)) { entry in
            container(SmallWidgetView(entry: entry).fontDesign(Typography.fontDesign(for: entry.fontTheme)))
        }
        .configurationDisplayName(Text("gallery.s1.title", bundle: .umaCore))
        .description(Text("gallery.s1.desc", bundle: .umaCore))
        .supportedFamilies([.systemSmall])
    }
}

struct S2ChampionsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "S2ChampionsWidget",
                            provider: ScheduleTimelineProvider(variant: .championsOnly, detailLevel: .overview)) { entry in
            container(SmallWidgetView(entry: entry).fontDesign(Typography.fontDesign(for: entry.fontTheme)))
        }
        .configurationDisplayName(Text("gallery.s2.title", bundle: .umaCore))
        .description(Text("gallery.s2.desc", bundle: .umaCore))
        .supportedFamilies([.systemSmall])
    }
}

struct S3LoHWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "S3LoHWidget",
                            provider: ScheduleTimelineProvider(variant: .loHOnly, detailLevel: .overview)) { entry in
            container(SmallWidgetView(entry: entry).fontDesign(Typography.fontDesign(for: entry.fontTheme)))
        }
        .configurationDisplayName(Text("gallery.s3.title", bundle: .umaCore))
        .description(Text("gallery.s3.desc", bundle: .umaCore))
        .supportedFamilies([.systemSmall])
    }
}

struct S4PickupWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "S4PickupWidget",
                            provider: ScheduleTimelineProvider(variant: .pickupOnly, detailLevel: .overview)) { entry in
            container(SmallWidgetView(entry: entry).fontDesign(Typography.fontDesign(for: entry.fontTheme)))
        }
        .configurationDisplayName(Text("gallery.s4.title", bundle: .umaCore))
        .description(Text("gallery.s4.desc", bundle: .umaCore))
        .supportedFamilies([.systemSmall])
    }
}
