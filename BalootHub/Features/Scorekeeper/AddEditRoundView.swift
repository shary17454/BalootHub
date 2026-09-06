import SwiftUI
import SwiftData

struct AddEditRoundView: View {
    let session: ScoreSession
    let roundToEdit: ScoreRound?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsList: [AppSettings]

    @State private var mode: BalootMode = .hokum
    @State private var teamOneScoreText = ""
    @State private var teamTwoScoreText = ""
    @State private var teamOneProjectsText = "0"
    @State private var teamTwoProjectsText = "0"
    @State private var autoFillOpponentScore = true
    @State private var multiplier: ScoreMultiplier = .none
    @State private var notes = ""
    @State private var validationMessage: String?
    /// لوحة الأرقام لا تحتوي زر إرجاع، فبدون تركيز صريح يمكن إغلاقه تبقى مفتوحة
    /// وتغطي بقية الحقول.
    @FocusState private var isEditingNumber: Bool

    private var coffeeEnabled: Bool { settingsList.first?.enableCoffeeMultiplier ?? false }

    private var availableMultipliers: [ScoreMultiplier] {
        ScoreMultiplier.allCases.filter { $0 != .coffee || coffeeEnabled }
    }

    var body: some View {
        Form {
            Section("نوع الجولة") {
                Picker("النمط", selection: $mode) {
                    ForEach(BalootMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
            .onChange(of: mode) { _, _ in
                refreshAutomaticScoreFromCurrentInput()
            }

            Section("النقاط") {
                Toggle("احتساب الفريق الآخر تلقائيًا", isOn: $autoFillOpponentScore.animation())
                    .onChange(of: autoFillOpponentScore) { _, isEnabled in
                        if isEnabled { refreshAutomaticScoreFromCurrentInput() }
                    }

                LabeledContent(session.teamOneName) {
                    TextField("0", text: scoreBinding(for: .teamOne))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .focused($isEditingNumber)
                }
                LabeledContent(session.teamTwoName) {
                    TextField("0", text: scoreBinding(for: .teamTwo))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .focused($isEditingNumber)
                }
                Text("اكتب نقاط فريق واحد، وسيكمل التطبيق الفريق الآخر من مجموع \(ScoreRoundAutofill.basePointTotal(for: mode)) نقطة.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Section("المشاريع") {
                LabeledContent("مشاريع \(session.teamOneName)") {
                    TextField("0", text: $teamOneProjectsText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .focused($isEditingNumber)
                }
                LabeledContent("مشاريع \(session.teamTwoName)") {
                    TextField("0", text: $teamTwoProjectsText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .focused($isEditingNumber)
                }
            }

            Section("الدبل") {
                Picker("المضاعف", selection: $multiplier) {
                    ForEach(availableMultipliers) { multiplier in
                        Text(multiplier.title).tag(multiplier)
                    }
                }
            }

            Section("ملاحظات (اختياري)") {
                TextField("ملاحظات عن الصكة", text: $notes, axis: .vertical)
            }

            if let validationMessage {
                Section {
                    Text(validationMessage)
                        .foregroundStyle(AppColor.danger)
                        .font(AppTypography.caption)
                }
            }
        }
        .navigationTitle(roundToEdit == nil ? "إضافة صكة" : "تعديل الصكة")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("إلغاء") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("حفظ") { save() }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("تم") { isEditingNumber = false }
            }
        }
        .onAppear(perform: loadInitialValues)
    }

    private func loadInitialValues() {
        guard let roundToEdit else { return }
        mode = roundToEdit.mode
        teamOneScoreText = String(roundToEdit.teamOneBaseScore)
        teamTwoScoreText = String(roundToEdit.teamTwoBaseScore)
        teamOneProjectsText = String(roundToEdit.teamOneProjects)
        teamTwoProjectsText = String(roundToEdit.teamTwoProjects)
        autoFillOpponentScore = false
        multiplier = roundToEdit.multiplier
        notes = roundToEdit.notes ?? ""
    }

    private enum ScoreTeam {
        case teamOne
        case teamTwo
    }

    private func scoreBinding(for team: ScoreTeam) -> Binding<String> {
        Binding(
            get: {
                switch team {
                case .teamOne: teamOneScoreText
                case .teamTwo: teamTwoScoreText
                }
            },
            set: { newValue in
                let filtered = newValue.filter(\.isNumber)
                switch team {
                case .teamOne:
                    teamOneScoreText = filtered
                    applyAutomaticScore(from: .teamOne)
                case .teamTwo:
                    teamTwoScoreText = filtered
                    applyAutomaticScore(from: .teamTwo)
                }
            }
        )
    }

    private func refreshAutomaticScoreFromCurrentInput() {
        if !teamOneScoreText.isEmpty {
            applyAutomaticScore(from: .teamOne)
        } else if !teamTwoScoreText.isEmpty {
            applyAutomaticScore(from: .teamTwo)
        }
    }

    private func applyAutomaticScore(from sourceTeam: ScoreTeam) {
        guard autoFillOpponentScore else { return }
        switch sourceTeam {
        case .teamOne:
            guard let teamOneScore = Int(teamOneScoreText) else {
                teamTwoScoreText = ""
                return
            }
            teamTwoScoreText = String(ScoreRoundAutofill.complementaryScore(for: teamOneScore, mode: mode))
        case .teamTwo:
            guard let teamTwoScore = Int(teamTwoScoreText) else {
                teamOneScoreText = ""
                return
            }
            teamOneScoreText = String(ScoreRoundAutofill.complementaryScore(for: teamTwoScore, mode: mode))
        }
        validationMessage = nil
    }

    private func save() {
        guard let teamOneScore = Int(teamOneScoreText), teamOneScore >= 0,
              let teamTwoScore = Int(teamTwoScoreText), teamTwoScore >= 0 else {
            validationMessage = "أدخل نقاطًا صحيحة غير سالبة لكلا الفريقين."
            return
        }
        let teamOneProjects = Int(teamOneProjectsText) ?? 0
        let teamTwoProjects = Int(teamTwoProjectsText) ?? 0
        guard teamOneProjects >= 0, teamTwoProjects >= 0 else {
            validationMessage = "لا يمكن أن تكون نقاط المشاريع سالبة."
            return
        }
        guard teamOneScore > 0 || teamTwoScore > 0 || teamOneProjects > 0 || teamTwoProjects > 0 else {
            validationMessage = "لا يمكن حفظ صكة فارغة بدون أي نقاط."
            return
        }

        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if let roundToEdit {
            roundToEdit.mode = mode
            roundToEdit.teamOneBaseScore = teamOneScore
            roundToEdit.teamTwoBaseScore = teamTwoScore
            roundToEdit.teamOneProjects = teamOneProjects
            roundToEdit.teamTwoProjects = teamTwoProjects
            roundToEdit.multiplier = multiplier
            roundToEdit.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
        } else {
            // الاعتماد على العدد وحده كان يُنتج رقمين متطابقين بعد حذف صكة وسطية
            // (٣ صكات ⇒ حذف الثانية ⇒ التالية تأخذ الرقم ٣ الموجود أصلًا).
            let nextRoundNumber = (session.rounds.map(\.roundNumber).max() ?? 0) + 1
            let round = ScoreRound(
                roundNumber: nextRoundNumber,
                mode: mode,
                teamOneBaseScore: teamOneScore,
                teamTwoBaseScore: teamTwoScore,
                teamOneProjects: teamOneProjects,
                teamTwoProjects: teamTwoProjects,
                multiplier: multiplier,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes
            )
            round.session = session
            session.rounds.append(round)
        }

        session.updatedAt = .now
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    let container = PersistenceController.makePreviewContainer()
    let session = ScoreSession(teamOneName: "فريقنا", teamTwoName: "الخصم", targetScore: 152)
    return NavigationStack {
        AddEditRoundView(session: session, roundToEdit: nil)
    }
    .modelContainer(container)
}
