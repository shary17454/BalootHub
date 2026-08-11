import SwiftUI
import BalootEngine

struct HouseRulesView: View {
    @State private var preset = HouseRulesStore.load()

    var body: some View {
        Form {
            Section("Preset") {
                Button("القواعد القياسية") {
                    preset = .standard
                    save()
                }
                Button("قواعد بطولة") {
                    preset = .tournament
                    save()
                }
                TextField("اسم القواعد", text: Binding(
                    get: { preset.name },
                    set: { preset.name = $0; save() }
                ))
            }

            Section("قواعد اللعب") {
                Toggle("القطع بالحكم عند الخلو من اللون", isOn: boolBinding(\.mustTrumpWhenVoid))
                Toggle("التعلية بالحكم عند الإمكان", isOn: boolBinding(\.mustOvertrump))
                Toggle("الطياح على المشتري", isOn: boolBinding(\.declarerMustWinMajority))
                Stepper(value: intBinding(\.matchTargetScore), in: 50...1000, step: 1) {
                    valueRow("هدف المباراة", value: preset.rules.matchTargetScore)
                }
            }

            Section("المشاريع") {
                Toggle("تفعيل المشاريع", isOn: boolBinding(\.projectsEnabled))
                Toggle("السرا والخمسين والمية", isOn: boolBinding(\.sequenceProjectsEnabled))
                Toggle("مشاريع نفس الرتبة", isOn: boolBinding(\.sameRankProjectsEnabled))
                Toggle("مشروع البلوت", isOn: boolBinding(\.belotProjectEnabled))
                Toggle("إعلان المشروع مطلوب", isOn: boolBinding(\.projectsRequireDeclaration))
                Toggle("أربعمية مفعلة", isOn: boolBinding(\.fourHundredEnabled))
            }

            Section("المضاعفات والكبوت") {
                Toggle("تفعيل دبل/ثري/فور/قهوة", isOn: boolBinding(\.multipliersEnabled))
                Toggle("السماح بالمضاعفة في الصن", isOn: boolBinding(\.multiplierAllowedInSun))
                Toggle("القفل", isOn: boolBinding(\.lockEnabled))
                Toggle("الكبوت", isOn: boolBinding(\.kabootEnabled))
                Picker("أعلى مضاعف", selection: multiplierBinding(\.maximumMultiplier)) {
                    ForEach(Multiplier.allCases, id: \.self) { multiplier in
                        Text(multiplier.arabicName).tag(multiplier)
                    }
                }
            }

            Section("النقاط") {
                Stepper(value: intBinding(\.hokumRoundTotal), in: 100...300, step: 1) {
                    valueRow("مجموع الحكم", value: preset.rules.hokumRoundTotal)
                }
                Stepper(value: intBinding(\.sunRoundBaseTotal), in: 100...300, step: 1) {
                    valueRow("مجموع الصن الأساسي", value: preset.rules.sunRoundBaseTotal)
                }
                Stepper(value: intBinding(\.lastTrickBonus), in: 0...50, step: 1) {
                    valueRow("آخر أكلة", value: preset.rules.lastTrickBonus)
                }
                Stepper(value: intBinding(\.siraPoints), in: 0...100, step: 5) {
                    valueRow("السرا", value: preset.rules.siraPoints)
                }
                Stepper(value: intBinding(\.fiftyPoints), in: 0...150, step: 5) {
                    valueRow("الخمسين", value: preset.rules.fiftyPoints)
                }
                Stepper(value: intBinding(\.hundredPoints), in: 0...250, step: 5) {
                    valueRow("المية", value: preset.rules.hundredPoints)
                }
                Stepper(value: intBinding(\.belotPoints), in: 0...100, step: 5) {
                    valueRow("البلوت", value: preset.rules.belotPoints)
                }
            }
        }
        .navigationTitle("قواعد مجلسي")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func valueRow(_ title: String, value: Int) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(value)")
                .foregroundStyle(AppColor.textSecondary)
        }
    }

    private func boolBinding(_ keyPath: WritableKeyPath<BalootRulesConfiguration, Bool>) -> Binding<Bool> {
        Binding(
            get: { preset.rules[keyPath: keyPath] },
            set: { preset.rules[keyPath: keyPath] = $0; save() }
        )
    }

    private func intBinding(_ keyPath: WritableKeyPath<BalootRulesConfiguration, Int>) -> Binding<Int> {
        Binding(
            get: { preset.rules[keyPath: keyPath] },
            set: { preset.rules[keyPath: keyPath] = $0; save() }
        )
    }

    private func multiplierBinding(_ keyPath: WritableKeyPath<BalootRulesConfiguration, Multiplier>) -> Binding<Multiplier> {
        Binding(
            get: { preset.rules[keyPath: keyPath] },
            set: { preset.rules[keyPath: keyPath] = $0; save() }
        )
    }

    private func save() {
        preset = HouseRulesStore.preset(named: preset.name, basedOn: preset.rules)
        HouseRulesStore.save(preset)
    }
}
