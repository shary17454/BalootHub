import SwiftUI
import SwiftData

struct NewScorekeeperSessionView: View {
    @Environment(AppEnvironment.self) private var appEnvironment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsList: [AppSettings]

    @State private var teamOneName = "فريقنا"
    @State private var teamTwoName = "الخصم"
    @State private var useCustomTarget = false
    @State private var customTarget: Int = 152

    private var defaultTarget: Int { settingsList.first?.defaultTargetScore ?? 152 }

    private var isValid: Bool {
        !teamOneName.trimmingCharacters(in: .whitespaces).isEmpty
            && !teamTwoName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Form {
            Section("الفريقان") {
                TextField("اسم الفريق الأول", text: $teamOneName)
                TextField("اسم الفريق الثاني", text: $teamTwoName)
            }

            Section("الحد المستهدف") {
                Toggle("تخصيص الحد المستهدف", isOn: $useCustomTarget.animation())
                if useCustomTarget {
                    Stepper(value: $customTarget, in: AppSettings.allowedTargetScoreRange, step: 1) {
                        Text("\(customTarget) نقطة")
                    }
                } else {
                    HStack {
                        Text("الحد الافتراضي")
                        Spacer()
                        Text("\(defaultTarget) نقطة")
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
            }
        }
        .navigationTitle("جلسة جديدة")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("بدء") { createSession() }
                    .disabled(!isValid)
            }
        }
        .onAppear { customTarget = defaultTarget }
    }

    private func createSession() {
        let target = useCustomTarget ? customTarget : defaultTarget
        let session = ScoreSession(
            teamOneName: teamOneName.trimmingCharacters(in: .whitespaces),
            teamTwoName: teamTwoName.trimmingCharacters(in: .whitespaces),
            targetScore: target
        )
        modelContext.insert(session)
        try? modelContext.save()
        appEnvironment.scorekeeperPath.removeAll()
        appEnvironment.openScorekeeperSession(id: session.id)
    }
}

#Preview {
    NavigationStack {
        NewScorekeeperSessionView()
    }
    .environment(AppEnvironment())
    .modelContainer(PersistenceController.makePreviewContainer())
}
