import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [AppSettings]

    /// سجل الإعدادات إن وُجد.
    ///
    /// كانت هذه الخاصية تُنشئ سجلًا وتُدخله وتحفظه عند غيابه — أي تعديل على المخزن
    /// أثناء تقييم `body`، وهو ما يسبب تحذير SwiftUI "Modifying state during view
    /// update" ويُعاد تنفيذه عدة مرات في كل رسم. الإنشاء صار في ``ensureSettings()``
    /// المستدعاة من `task`، والواجهة تعرض حالة انتظار قصيرة إن لم يجهز السجل بعد.
    private var settings: AppSettings? { settingsList.first }

    var body: some View {
        Group {
            if let settings {
                form(settings)
            } else {
                LoadingStateView(message: "جارِ تحضير الإعدادات…")
            }
        }
        .navigationTitle("الإعدادات")
        .task { ensureSettings() }
    }

    /// ينشئ سجل الإعدادات الوحيد إن لم يكن موجودًا. تُستدعى خارج دورة الرسم.
    private func ensureSettings() {
        guard settingsList.isEmpty else { return }
        SettingsRepository.ensureSettingsExist(context: modelContext)
    }

    private func form(_ settings: AppSettings) -> some View {
        Form {
            Section("المظهر") {
                Picker("المظهر", selection: binding(settings, \.appearanceMode)) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
            }

            Section("الصوت والاهتزاز") {
                Toggle("المؤثرات الصوتية", isOn: binding(settings, \.soundEnabled))
                Toggle("الاهتزاز اللمسي", isOn: binding(settings, \.hapticsEnabled))
            }

            Section("تسجيل البلوت") {
                Stepper(value: binding(settings, \.defaultTargetScore), in: AppSettings.allowedTargetScoreRange, step: 1) {
                    HStack {
                        Text("الحد المستهدف الافتراضي")
                        Spacer()
                        Text("\(settings.defaultTargetScore)")
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }

                Toggle("تفعيل مضاعف \"قهوة\"", isOn: binding(settings, \.enableCoffeeMultiplier))

                Picker("صيغة احتساب المضاعفات", selection: binding(settings, \.selectedScoreRulePreset)) {
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

                Toggle("تأكيد قبل الحذف أو التراجع", isOn: binding(settings, \.confirmBeforeDelete))
            }

            Section("عن التطبيق") {
                LabeledContent("الاسم", value: "البلوت".localized)
                LabeledContent("الإصدار", value: Self.appVersion)
                Text("لا يجمع التطبيق أي بيانات شخصية، ولا يحتاج اتصالًا بالإنترنت. كل البيانات تُخزَّن محليًا على جهازك فقط.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
    }

    /// رقم الإصدار ورقم البناء كما في `Info.plist`.
    ///
    /// كان النص مثبّتًا "1.0.0" فلا يتغيّر مع أي إصدار فعلي، وقد سبق أن اختلف عن رقم
    /// البناء الحقيقي للمشروع.
    private static var appVersion: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String
        return build.map { "\(short) (\($0))" } ?? short
    }

    /// ربط موحّد لأي خاصية في الإعدادات مع الحفظ بعد كل تغيير، بدل سبع خصائص متطابقة.
    private func binding<Value>(
        _ settings: AppSettings,
        _ keyPath: ReferenceWritableKeyPath<AppSettings, Value>
    ) -> Binding<Value> {
        Binding(
            get: { settings[keyPath: keyPath] },
            set: { settings[keyPath: keyPath] = $0; try? modelContext.save() }
        )
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(PersistenceController.makePreviewContainer())
}
