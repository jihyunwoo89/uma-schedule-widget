import SwiftUI
import UmaCore

struct SettingsView: View {
    @Bindable var prefs: PrefsStore

    var body: some View {
        Form {
            Section(L.string(.settingsSectionCategories)) {
                ForEach(prefs.prefs.categoryOrder, id: \.self) { c in
                    HStack { Image(systemName: c.sfSymbol); Text(L.string(c.labelKey)) }
                }
                .onMove { from, to in
                    var order = prefs.prefs.categoryOrder
                    order.move(fromOffsets: from, toOffset: to)
                    prefs.update { $0.categoryOrder = order }
                }
            }

            Section(L.string(.settingsSectionFont)) {
                Picker(L.string(.settingsSectionFont), selection: fontBinding) {
                    Text(L.string(.settingsValueFontSystem)).tag(FontTheme.system)
                    Text(L.string(.settingsValueFontRounded)).tag(FontTheme.rounded)
                    Text(L.string(.settingsValueFontMono)).tag(FontTheme.mono)
                    Text(L.string(.settingsValueFontSerif)).tag(FontTheme.serif)
                }
            }

            Section(L.string(.settingsSectionLanguage)) {
                Picker(L.string(.settingsSectionLanguage), selection: localeBinding) {
                    Text(L.string(.settingsValueLanguageSystem)).tag(AppLocale.system)
                    Text(L.string(.settingsValueLanguageKo)).tag(AppLocale.ko)
                    Text(L.string(.settingsValueLanguageEn)).tag(AppLocale.en)
                }
            }

            Section(L.string(.settingsSectionNotify)) {
                Toggle(L.string(.settingsRowNotifyBefore), isOn: notifyBinding)
            }

            Section {
                Text(L.string(.legalDisclaimer)).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .environment(\.editMode, .constant(.active))
        .navigationTitle(L.string(.settingsTitle))
    }

    private var fontBinding: Binding<FontTheme> {
        Binding(get: { prefs.prefs.fontTheme }, set: { v in prefs.update { $0.fontTheme = v }; WidgetPreferenceApplierApp.apply(prefs.prefs) })
    }
    private var localeBinding: Binding<AppLocale> {
        Binding(get: { prefs.prefs.localeOverride }, set: { v in prefs.update { $0.localeOverride = v }; WidgetPreferenceApplierApp.apply(prefs.prefs) })
    }
    private var notifyBinding: Binding<Bool> {
        Binding(get: { prefs.prefs.notifyBeforePhase }, set: { v in prefs.update { $0.notifyBeforePhase = v } })
    }
}
