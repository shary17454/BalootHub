import SwiftUI
import SwiftData

struct ScorekeeperSessionView: View {
    let sessionID: UUID

    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [ScoreSession]
    @Query private var settingsList: [AppSettings]

    @State private var isPresentingAddRound = false
    @State private var roundBeingEdited: ScoreRound?
    @State private var isPresentingFinishConfirm = false
    @State private var isPresentingDeleteConfirm = false
    @State private var roundPendingDelete: ScoreRound?
    @State private var isPresentingUndoConfirm = false

    init(sessionID: UUID) {
        self.sessionID = sessionID
        let predicate = #Predicate<ScoreSession> { $0.id == sessionID }
        _sessions = Query(filter: predicate)
    }

    private var session: ScoreSession? { sessions.first }
    // قراءة القيم مباشرةً بدل `settingsList.first ?? AppSettings()`: تلك الصيغة كانت
    // تُنشئ كائن `@Model` جديدًا غير مُدرج في السياق مع كل تقييم للواجهة.
    private var rules: ScoreRules { settingsList.first?.scoreRules ?? .standard }
    private var confirmBeforeDelete: Bool { settingsList.first?.confirmBeforeDelete ?? true }

    var body: some View {
        Group {
            if let session {
                content(session)
            } else {
                ErrorStateView(message: "تعذّر العثور على هذه الجلسة.")
            }
        }
        .background(AppColor.background)
        .navigationTitle(session.map { "\($0.teamOneName) ضد \($0.teamTwoName)" } ?? "الجلسة")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func content(_ session: ScoreSession) -> some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                scoreHeader(session)

                if session.status == .active {
                    HStack(spacing: AppSpacing.sm) {
                        Button {
                            isPresentingAddRound = true
                        } label: {
                            Label("إضافة صكة", systemImage: "plus")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColor.primary)

                        Button {
                            confirmUndo()
                        } label: {
                            Label("تراجع", systemImage: "arrow.uturn.backward")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(session.rounds.isEmpty)
                    }
                }

                roundsList(session)

                if session.status == .active {
                    Button(role: .destructive) {
                        isPresentingFinishConfirm = true
                    } label: {
                        Label("إنهاء الجلسة", systemImage: "flag.checkered")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                ShareLink(item: session.textSummary(rules: rules)) {
                    Label("مشاركة الملخص", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(AppSpacing.md)
            .adaptiveContentWidth()
        }
        .sheet(isPresented: $isPresentingAddRound) {
            NavigationStack {
                AddEditRoundView(session: session, roundToEdit: nil)
            }
        }
        .sheet(item: $roundBeingEdited) { round in
            NavigationStack {
                AddEditRoundView(session: session, roundToEdit: round)
            }
        }
        .confirmationDialog("هل تريد إنهاء الجلسة؟", isPresented: $isPresentingFinishConfirm, titleVisibility: .visible) {
            Button("إنهاء الجلسة", role: .destructive) { finishSession(session) }
            Button("إلغاء", role: .cancel) {}
        }
        .confirmationDialog("هل تريد حذف هذه الصكة؟", isPresented: $isPresentingDeleteConfirm, titleVisibility: .visible) {
            Button("حذف", role: .destructive) {
                if let roundPendingDelete { delete(round: roundPendingDelete, from: session) }
            }
            Button("إلغاء", role: .cancel) {}
        }
        .confirmationDialog("هل تريد التراجع عن آخر صكة؟", isPresented: $isPresentingUndoConfirm, titleVisibility: .visible) {
            Button("تراجع", role: .destructive) { undoLastRound(session) }
            Button("إلغاء", role: .cancel) {}
        }
    }

    private func scoreHeader(_ session: ScoreSession) -> some View {
        let teamOneTotal = session.teamOneTotal(rules: rules)
        let teamTwoTotal = session.teamTwoTotal(rules: rules)
        let leading = session.leadingTeamName(rules: rules)
        let winner = session.winnerName(rules: rules)

        return VStack(spacing: AppSpacing.sm) {
            if let winner {
                Label("الفريق الفائز: \(winner) 🏆", systemImage: "trophy.fill")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.success)
            }

            HStack {
                teamScoreColumn(name: session.teamOneName, score: teamOneTotal, isLeading: leading == session.teamOneName)
                Spacer()
                Text("الهدف \(session.targetScore)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                Spacer()
                teamScoreColumn(name: session.teamTwoName, score: teamTwoTotal, isLeading: leading == session.teamTwoName)
            }

            ProgressView(value: min(Double(max(teamOneTotal, teamTwoTotal)), Double(session.targetScore)), total: Double(session.targetScore))
                .tint(AppColor.primary)
                .accessibilityLabel("التقدم نحو الهدف")
                .accessibilityValue("\(max(teamOneTotal, teamTwoTotal)) من \(session.targetScore)")
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private func teamScoreColumn(name: String, score: Int, isLeading: Bool) -> some View {
        VStack(spacing: AppSpacing.xxs) {
            HStack(spacing: AppSpacing.xxs) {
                Text(name).font(AppTypography.subheadline)
                if isLeading {
                    Image(systemName: "arrow.up.circle.fill").foregroundStyle(AppColor.success)
                }
            }
            Text("\(score)")
                .font(AppTypography.largeTitle)
                .foregroundStyle(isLeading ? AppColor.success : AppColor.textPrimary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name)، \(score) نقطة\(isLeading ? "، متقدم" : "")")
    }

    private func roundsList(_ session: ScoreSession) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("الصكات").font(AppTypography.title)

            if session.rounds.isEmpty {
                EmptyStateView(systemImage: "square.stack.3d.up.slash", title: "لا توجد صكات بعد", message: "أضف أول صكة لبدء تتبّع النتيجة.")
            } else {
                // `swipeActions` لا تعمل إلا داخل `List`، وهذه الصفوف داخل `VStack`
                // في `ScrollView`، فكان زر حذف الصكة غير موجود عمليًا ولا سبيل لحذف
                // صكة وسطية إطلاقًا. البديل هنا قائمة سياقية تعمل في أي حاوية.
                ForEach(session.sortedRounds) { round in
                    RoundRow(round: round, rules: rules)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if session.status == .active { roundBeingEdited = round }
                        }
                        .contextMenu {
                            if session.status == .active {
                                Button {
                                    roundBeingEdited = round
                                } label: {
                                    Label("تعديل", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    requestDelete(round: round, from: session)
                                } label: {
                                    Label("حذف", systemImage: "trash")
                                }
                            }
                        }
                        .accessibilityAction(named: Text("حذف")) {
                            if session.status == .active {
                                requestDelete(round: round, from: session)
                            }
                        }
                }
            }
        }
    }

    /// يحذف الصكة مباشرةً أو يطلب التأكيد أولًا، حسب إعداد "تأكيد قبل الحذف".
    private func requestDelete(round: ScoreRound, from session: ScoreSession) {
        roundPendingDelete = round
        if confirmBeforeDelete {
            isPresentingDeleteConfirm = true
        } else {
            delete(round: round, from: session)
        }
    }

    private func confirmUndo() {
        if confirmBeforeDelete {
            isPresentingUndoConfirm = true
        } else if let session {
            undoLastRound(session)
        }
    }

    private func undoLastRound(_ session: ScoreSession) {
        guard let last = session.sortedRounds.last else { return }
        delete(round: last, from: session)
    }

    private func delete(round: ScoreRound, from session: ScoreSession) {
        modelContext.delete(round)
        session.updatedAt = .now
        try? modelContext.save()
    }

    private func finishSession(_ session: ScoreSession) {
        session.status = .finished
        session.completedAt = .now
        session.updatedAt = .now
        try? modelContext.save()
    }
}

private struct RoundRow: View {
    let round: ScoreRound
    let rules: ScoreRules

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("الصكة \(round.roundNumber) · \(round.mode.title)")
                    .font(AppTypography.subheadline.weight(.semibold))
                if round.multiplier != .none {
                    Text(round.multiplier.title)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.warning)
                }
                if let notes = round.notes, !notes.isEmpty {
                    Text(notes)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
            Spacer()
            Text("\(round.teamOneFinalScore(rules: rules)) - \(round.teamTwoFinalScore(rules: rules))")
                .font(AppTypography.headline)
        }
        .padding(AppSpacing.sm)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        ScorekeeperSessionView(sessionID: UUID())
    }
    .environment(AppEnvironment())
    .modelContainer(PersistenceController.makePreviewContainer())
}
