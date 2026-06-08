import Foundation

public enum L {
    nonisolated(unsafe) public static var currentLocale: Locale? = nil

    public enum Key: String, CaseIterable, Sendable {
        // Categories
        case categoryChampions = "category.champions"
        case categoryLoH       = "category.loh"
        case categoryPickup    = "category.pickup"
        case categoryChampionsShort = "category.champions.short"
        case categoryLoHShort       = "category.loh.short"
        case categoryPickupShort    = "category.pickup.short"

        // Widget states
        case stateIdleTitle   = "state.idle.title"
        case stateIdleBody    = "state.idle.body"
        case stateNoDataTitle = "state.nodata.title"
        case stateNoDataBody  = "state.nodata.body"

        // Settings
        case settingsTitle              = "settings.title"
        case settingsSectionCategories  = "settings.section.categories"
        case settingsSectionFont        = "settings.section.font"
        case settingsSectionLanguage    = "settings.section.language"
        case settingsSectionNotify      = "settings.section.notify"
        case settingsRowNotifyBefore    = "settings.row.notify_before"
        case settingsValueFontSystem    = "settings.value.font.system"
        case settingsValueFontRounded   = "settings.value.font.rounded"
        case settingsValueFontMono      = "settings.value.font.mono"
        case settingsValueFontSerif     = "settings.value.font.serif"
        case settingsValueLanguageSystem = "settings.value.language.system"
        case settingsValueLanguageKo    = "settings.value.language.ko"
        case settingsValueLanguageEn    = "settings.value.language.en"
        case settingsRowDataSource      = "settings.row.data_source"
        case settingsRowRefresh         = "settings.row.refresh"
        case settingsRefreshDoneTitle   = "settings.refresh.done.title"
        case settingsRefreshDoneBody    = "settings.refresh.done.body"
        case settingsRefreshFailedTitle = "settings.refresh.failed.title"
        case settingsRefreshFailedBody  = "settings.refresh.failed.body"
        case commonOK                   = "common.ok"
        case commonInProgress           = "common.in_progress"
        case splashLoading              = "splash.loading"

        // Legal
        case legalDisclaimer = "legal.disclaimer"
        case legalImageSource = "legal.image_source"

        // Field labels
        case fieldTrainee     = "field.trainee"
        case fieldSupport     = "field.support"

        // Widget gallery (per widget)
        case galleryL1Title = "gallery.l1.title"
        case galleryL1Desc  = "gallery.l1.desc"
        case galleryL2Title = "gallery.l2.title"
        case galleryL2Desc  = "gallery.l2.desc"
        case galleryM1Title = "gallery.m1.title"
        case galleryM1Desc  = "gallery.m1.desc"
        case galleryM2Title = "gallery.m2.title"
        case galleryM2Desc  = "gallery.m2.desc"
        case galleryM3Title = "gallery.m3.title"
        case galleryM3Desc  = "gallery.m3.desc"
        case galleryS1Title = "gallery.s1.title"
        case galleryS1Desc  = "gallery.s1.desc"
        case galleryS2Title = "gallery.s2.title"
        case galleryS2Desc  = "gallery.s2.desc"
        case galleryS3Title = "gallery.s3.title"
        case galleryS3Desc  = "gallery.s3.desc"
        case galleryS4Title = "gallery.s4.title"
        case galleryS4Desc  = "gallery.s4.desc"
        case galleryLockRectTitle = "gallery.lock_rect.title"
        case galleryLockRectDesc  = "gallery.lock_rect.desc"
        case galleryLockCircTitle = "gallery.lock_circ.title"
        case galleryLockCircDesc  = "gallery.lock_circ.desc"

        // App screens
        case tabSchedule             = "tab.schedule"
        case tabSettings             = "tab.settings"
        case scheduleSectionUpcoming = "schedule.section.upcoming"
        case detailSectionTrack      = "detail.section.track"
        case detailSectionPhases     = "detail.section.phases"
        case detailFieldPeriod       = "detail.field.period"

        // Course-map legend
        case detailLegendSectionTrack   = "detail.legend.section.track"
        case detailLegendTurf           = "detail.legend.turf"
        case detailLegendDirt           = "detail.legend.dirt"
        case detailLegendSectionPhase   = "detail.legend.section.phase"
        case detailLegendEarly          = "detail.legend.early"
        case detailLegendMid            = "detail.legend.mid"
        case detailLegendLate           = "detail.legend.late"
        case detailLegendSpurt          = "detail.legend.spurt"
        case detailLegendSectionTerrain = "detail.legend.section.terrain"
        case detailLegendStraight       = "detail.legend.straight"
        case detailLegendCorner         = "detail.legend.corner"
        case detailLegendSectionEtc     = "detail.legend.section.etc"
        case detailLegendPositionKeep   = "detail.legend.position_keep"
        case detailLegendSpurtStart     = "detail.legend.spurt_start"
    }

    public static func string(_ key: Key, locale: Locale? = nil) -> String {
        let effective = locale ?? currentLocale
        let bundle = Bundle.module
        if let effective, let lprojPath = bundle.path(forResource: effective.languageCode ?? "en", ofType: "lproj"),
           let localized = Bundle(path: lprojPath) {
            return NSLocalizedString(key.rawValue, tableName: nil, bundle: localized, value: key.rawValue, comment: "")
        }
        return NSLocalizedString(key.rawValue, tableName: nil, bundle: bundle, value: key.rawValue, comment: "")
    }
}
