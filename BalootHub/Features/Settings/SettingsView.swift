import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [AppSettings]

    private var settings: AppSettings {
        if let existing = settingsList.first {
            return existing
        }
        let created = AppSettings()
        modelContext.insert(created)
        try? modelContext.save()
        return created
    }

    var body: some View {
        Form {
            Section("المظهر") {
                Picker("المظهر", selection: appearanceBinding) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
            }

            Section("الصوت والاهتزاز") {
                Toggle("المؤثرات الصوتية", isOn: soundBinding)
                Toggle("الاهتزاز اللمسي", isOn: hapticsBinding)
            }

            Section("تسجيل البلوت") {
                Stepper(value: targetScoreBinding, in: AppSettings.allowedTargetScoreRange, step: 1) {
                    HStack {
                        Text("الحد المستهدف الافتراضي")
                        Spacer()
                        Text("\(settings.defaultTargetScore)")
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }

                Toggle("تفعيل مضاعف \"قهوة\"", isOn: coffeeBinding)

                Picker("صيغة احتساب المضاعفات", selection: presetBinding) {
                    ForEach(ScoreRulePreset.allCases) { preset in
                        VStack(alignment: .leading) {
                            Text(preset.title)
                        }
                        .tag(preset)
                    }
                }
                Text(settings.selectedScoreRulePreset.subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)

                Toggle("تأكيد قبل الحذف أو التراجع", isOn: confirmBeforeDeleteBinding)
            }

            Section("عن التطبيق") {
                LabeledContent("الاسم", value: "البلوت")
                LabeledContent("الإصدار", value: "1.0.0")
                Text("لا يجمع التطبيق أي بيانات شخصية، ولا يحتاج اتصالًا بالإنترنت. كل البيانات تُخزَّن محليًا على جهازك فقط.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .navigationTitle("الإعدادات")
    }

    private var appearanceBinding: Binding<AppearanceMode> {
        Binding(get: { settings.appearanceMode }, set: { settings.appearanceMode = $0; save() })
    }
    private var soundBinding: Binding<Bool> {
        Binding(get: { settings.soundEnabled }, set: { settings.soundEnabled = $0; save() })
    }
    private var hapticsBinding: Binding<Bool> {
        Binding(get: { settings.hapticsEnabled }, set: { settings.hapticsEnabled = $0; save() })
    }
    private var targetScoreBinding: Binding<Int> {
        Binding(get: { settings.defaultTargetScore }, set: { settings.defaultTargetScore = $0; save() })
    }
    private var coffeeBinding: Binding<Bool> {
        Binding(get: { settings.enableCoffeeMultiplier }, set: { settings.enableCoffeeMultiplier = $0; save() })
    }
    private var presetBinding: Binding<ScoreRulePreset> {
        Binding(get: { settings.selectedScoreRulePreset }, set: { settings.selectedScoreRulePreset = $0; save() })
    }
    private var confirmBeforeDeleteBinding: Binding<Bool> {
        Binding(get: { settings.confirmBeforeDelete }, set: { settings.confirmBeforeDelete = $0; save() })
    }

    private func save() {
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(PersistenceController.makePreviewContainer())
}
