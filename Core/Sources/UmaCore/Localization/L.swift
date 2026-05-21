import Foundation

public enum L {
    nonisolated(unsafe) public static var currentLocale: Locale? = nil

    public enum Key: String, CaseIterable, Sendable {
        // Categories
        case categoryChampions = "category.champions"
        case categoryLoH       = "category.loh"
        case categoryPickup    = "category.pickup"

        // Widget states
        case stateIdleTitle   = "state.idle.title"
        case stateIdleBody    = "state.idle.body"
        case stateNoDataTitle = "state.nodata.title"
        case stateNoDataBody  = "state.nodata.body"

        // Pickup labels
        case pickupTrainee     = "pickup.trainee"
        case pickupSupportCard = "pickup.support_card"

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

        // Legal
        case legalDisclaimer = "legal.disclaimer"

        // Field labels
        case fieldEstimated   = "field.estimated"
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
