import WidgetKit
import SwiftUI

@main
struct UmaWidgetBundle: WidgetBundle {
    var body: some Widget {
        LockRectangularWidget()
        LockCircularWidget()
        LockCircularChampionsWidget()
        LockCircularLoHWidget()
        LockCircularPickupWidget()
        LockInlineWidget()
        L1MajorDetailWidget()
        L2AllScheduleWidget()
        M1MajorBriefWidget()
        M2ChampionsLoHWidget()
        M3PickupWidget()
        S1MajorOverviewWidget()
        S2ChampionsWidget()
        S3LoHWidget()
        S4PickupWidget()
    }
}
