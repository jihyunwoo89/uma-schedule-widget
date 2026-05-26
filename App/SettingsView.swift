import SwiftUI
import WidgetKit
import UmaCore

struct SettingsView: View {
    @Bindable var prefs: PrefsStore
    @State private var refreshAlert = false
    @State private var refreshSucceeded = false

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
                Button(L.string(.settingsRowRefresh), action: refreshNow)
                HStack {
                    Text(L.string(.settingsRowDataSource))
                    Spacer()
                    Text(ScheduleEndpoint.url.host ?? "").foregroundStyle(.secondary)
                }
            }

            Section {
                Text(L.string(.legalDisclaimer)).font(.footnote).foregroundStyle(.secondary)
                Text(L.string(.legalImageSource)).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .environment(\.editMode, .constant(.active))
        .navigationTitle(L.string(.settingsTitle))
        .alert(L.string(refreshSucceeded ? .settingsRefreshDoneTitle : .settingsRefreshFailedTitle),
               isPresented: $refreshAlert) {
            Button(L.string(.commonOK), role: .cancel) {}
        } message: {
            Text(L.string(refreshSucceeded ? .settingsRefreshDoneBody : .settingsRefreshFailedBody))
        }
    }

    /// Force a network refresh, update widgets, then confirm with a popup.
    private func refreshNow() {
        Task {
            let ok: Bool
            do { _ = try await ScheduleRepository.makeLive().refresh(); ok = true }
            catch { ok = false }
            if ok { WidgetCenter.shared.reloadAllTimelines() }
            await MainActor.run { refreshSucceeded = ok; refreshAlert = true }
        }
    }

    private var localeBinding: Binding<AppLocale> {
        Binding(get: { prefs.prefs.localeOverride }, set: { v in prefs.update { $0.localeOverride = v }; WidgetPreferenceApplierApp.apply(prefs.prefs) })
    }
    private var notifyBinding: Binding<Bool> {
        Binding(get: { prefs.prefs.notifyBeforePhase }, set: { v in prefs.update { $0.notifyBeforePhase = v } })
    }
}
