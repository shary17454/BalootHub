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
    @State private var saveError: String?
    @State private var pendingSession: ScoreSession?

    private var defaultTarget: Int { settingsList.first?.defaultTargetScore ?? 152 }

    private var isValid: Bool {
        !teamOneName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !teamTwoName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
                    Stepper(value: customTargetBinding, in: AppSettings.allowedTargetScoreRange, step: 1) {
                        HStack(spacing: AppSpacing.xs) {
                            TextField("الحد المستهدف", value: customTargetBinding, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(minWidth: 72, idealWidth: 88, maxWidth: 110)
                                .textFieldStyle(.roundedBorder)
                                .accessibilityLabel("الحد المستهدف")
                                .accessibilityValue("\(customTarget) نقطة")
                            Text("نقطة")
                                .foregroundStyle(AppColor.textSecondary)
                        }
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
        .alert("تنبيه", isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
            Button("حسنًا") { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
    }

    private var customTargetBinding: Binding<Int> {
        Binding(
            get: { customTarget },
            set: { newValue in
                customTarget = min(
                    max(newValue, AppSettings.allowedTargetScoreRange.lowerBound),
                    AppSettings.allowedTargetScoreRange.upperBound
                )
            }
        )
    }

    private func createSession() {
        let target = useCustomTarget ? customTarget : defaultTarget
        guard isValid else { return }
        let session = pendingSession ?? ScoreSession(
            teamOneName: teamOneName.trimmingCharacters(in: .whitespacesAndNewlines),
            teamTwoName: teamTwoName.trimmingCharacters(in: .whitespacesAndNewlines),
            targetScore: target
        )
        session.teamOneName = teamOneName.trimmingCharacters(in: .whitespacesAndNewlines)
        session.teamTwoName = teamTwoName.trimmingCharacters(in: .whitespacesAndNewlines)
        session.targetScore = target
        if pendingSession == nil { modelContext.insert(session) }
        pendingSession = session
        do {
            try modelContext.save()
            pendingSession = nil
            appEnvironment.scorekeeperPath.removeAll()
            appEnvironment.openScorekeeperSession(id: session.id)
        } catch {
            AppLogger.persistence.error("Score session save failed: \(error.localizedDescription, privacy: .private)")
            saveError = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        NewScorekeeperSessionView()
    }
    .environment(AppEnvironment())
    .modelContainer(PersistenceController.makePreviewContainer())
}
