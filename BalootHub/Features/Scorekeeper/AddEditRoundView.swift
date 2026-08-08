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

            Section("النقاط") {
                LabeledContent(session.teamOneName) {
                    TextField("0", text: $teamOneScoreText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .focused($isEditingNumber)
                }
                LabeledContent(session.teamTwoName) {
                    TextField("0", text: $teamTwoScoreText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .focused($isEditingNumber)
                }
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
        multiplier = roundToEdit.multiplier
        notes = roundToEdit.notes ?? ""
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
