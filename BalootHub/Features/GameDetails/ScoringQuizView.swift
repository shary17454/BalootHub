import SwiftUI
import SwiftData

struct ScoringQuizView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ScoringQuizAttempt.createdAt, order: .reverse) private var attempts: [ScoringQuizAttempt]
    @Query private var settingsList: [AppSettings]

    @State private var difficulty: ScoringQuizDifficulty = .medium
    @State private var seed: UInt64 = UInt64(Date().timeIntervalSince1970)
    @State private var question = ScoringQuizGenerator.generate(seed: UInt64(Date().timeIntervalSince1970), difficulty: .medium)
    @State private var answerText = ""
    @State private var feedback: QuizFeedback?
    @State private var streak = 0
    @State private var remainingSeconds = ScoringQuizDifficulty.medium.timeLimitSeconds
    @State private var didLoadInitialQuestion = false
    @AppStorage("scoringQuizBestStreak") private var bestStreak = 0

    private var statsSummary: ScoringQuizStatsSummary {
        ScoringQuizStatsAnalyzer.summarize(attempts: attempts)
    }

    private var scoreRules: ScoreRules {
        settingsList.first?.scoreRules ?? .standard
    }

    private var coachingInsight: ScoringQuizCoachingInsight {
        ScoringQuizStatsAnalyzer.coachingInsight(for: attempts)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                header
                statsCard
                difficultyPicker
                questionCard
                answerCard
                if let feedback {
                    feedbackCard(feedback)
                }
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.background)
        .navigationTitle("تحدي حساب النقاط")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard !didLoadInitialQuestion else { return }
            didLoadInitialQuestion = true
            loadQuestion(seed: seed, difficulty: difficulty)
        }
        .task(id: question.id) {
            await runTimer(for: question)
        }
        .onChange(of: scoreRules) { _, _ in
            loadQuestion(seed: seed, difficulty: difficulty)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Label("Quiz", systemImage: "function")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.primary)
                Spacer()
                StatusBadge("\(remainingSeconds)s", systemImage: "timer", tint: remainingSeconds <= 10 ? AppColor.danger : AppColor.accent)
            }
            HStack {
                scorePill(title: "السلسلة", value: "\(streak)", tint: AppColor.success)
                scorePill(title: "أفضل رقم", value: "\(max(bestStreak, statsSummary.bestStreak))", tint: AppColor.primary)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label("سجل تحدي النقاط".localized, systemImage: "chart.bar.xaxis")
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.primary)

            if statsSummary.attempts == 0 {
                Text("أجب على أول سؤال ليبدأ التطبيق بحفظ أدائك محليًا دون إنترنت.".localized)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColor.textSecondary)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.xs) {
                    metric("المحاولات".localized, "\(statsSummary.attempts)", icon: "number")
                    metric("الدقة".localized, "\(statsSummary.accuracyPercent)%", icon: "target")
                    metric("إجابات صحيحة".localized, "\(statsSummary.correctAnswers)", icon: "checkmark.seal.fill")
                    metric("متوسط الوقت المتبقي".localized, "\(statsSummary.averageRemainingSeconds)s", icon: "timer")
                }

                coachingInsightView(coachingInsight)

                if let hardest = statsSummary.hardestSolvedDifficulty {
                    InfoRow(
                        icon: "gauge.with.dots.needle.67percent",
                        title: "أصعب مستوى محلول".localized,
                        value: hardest.title
                    )
                }

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    ForEach(ScoringQuizStatsAnalyzer.summariesByDifficulty(attempts)) { summary in
                        HStack {
                            Text(summary.difficulty.title)
                                .font(AppTypography.caption.weight(.semibold))
                                .foregroundStyle(AppColor.textPrimary)
                            Spacer()
                            Text("\(summary.correctAnswers)/\(summary.attempts) · \(summary.accuracyPercent)%")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(AppSpacing.sm)
                .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))

                let recent = ScoringQuizStatsAnalyzer.recentAttempts(attempts)
                if !recent.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Label("آخر المحاولات".localized, systemImage: "clock.arrow.circlepath")
                            .font(AppTypography.subheadline.weight(.semibold))
                            .foregroundStyle(AppColor.textPrimary)
                        ForEach(recent) { attempt in
                            HStack {
                                Image(systemName: attempt.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(attempt.isCorrect ? AppColor.success : AppColor.danger)
                                Text(attempt.difficulty.title)
                                    .font(AppTypography.caption.weight(.semibold))
                                    .foregroundStyle(AppColor.textPrimary)
                                Text("\(attempt.mode.title) · \(attempt.multiplier.title)")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColor.textSecondary)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(attempt.submittedAnswer.map(String.init) ?? "—") / \(attempt.expectedAnswer)")
                                    .font(AppTypography.caption.monospacedDigit())
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .padding(AppSpacing.sm)
                    .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private func coachingInsightView(_ insight: ScoringQuizCoachingInsight) -> some View {
        Label {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(insight.title)
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Text(insight.detail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\("المستوى المقترح".localized): \(insight.recommendedDifficulty.title)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppColor.accent)
            }
        } icon: {
            Image(systemName: insight.iconName)
                .foregroundStyle(AppColor.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }

    private var difficultyPicker: some View {
        Picker("المستوى", selection: $difficulty) {
            ForEach(ScoringQuizDifficulty.allCases) { level in
                Text(level.title).tag(level)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: difficulty) { _, newValue in
            seed &+= 97
            loadQuestion(seed: seed, difficulty: newValue)
        }
    }

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("كم نتيجة \(question.targetTeam.title)؟")
                .font(AppTypography.title)
                .foregroundStyle(AppColor.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
                metric("النمط", question.mode.title, icon: question.mode == .sun ? "sun.max.fill" : "suit.spade.fill")
                metric("المضاعف", question.multiplier.title, icon: "multiply")
                metric("نقاط فريقنا", "\(question.teamOneBase)", icon: "1.circle.fill")
                metric("مشاريع فريقنا", "\(question.teamOneProjects)", icon: "plus.circle.fill")
                metric("نقاط الخصم", "\(question.teamTwoBase)", icon: "2.circle.fill")
                metric("مشاريع الخصم", "\(question.teamTwoProjects)", icon: "plus.circle")
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private var answerCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            TextField("اكتب النتيجة", text: $answerText)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .disabled(feedback != nil)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("تم") { submitAnswer() }
                    }
                }

            HStack {
                Button {
                    submitAnswer()
                } label: {
                    Label("تحقق", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.primary)
                .disabled(feedback != nil || answerText.trimmingCharacters(in: .whitespaces).isEmpty)

                Button {
                    seed &+= 1
                    loadQuestion(seed: seed, difficulty: difficulty)
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 42)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("سؤال جديد")
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private func feedbackCard(_ feedback: QuizFeedback) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label(feedback.isCorrect ? "إجابة صحيحة" : "إجابة غير صحيحة", systemImage: feedback.isCorrect ? "checkmark.seal.fill" : "xmark.octagon.fill")
                .font(AppTypography.headline)
                .foregroundStyle(feedback.isCorrect ? AppColor.success : AppColor.danger)
            Text("الإجابة: \(question.answer)")
                .font(AppTypography.subheadline.weight(.semibold))
            Text(question.explanation)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColor.textSecondary)
            Button {
                seed &+= 1
                loadQuestion(seed: seed, difficulty: difficulty)
            } label: {
                Label("السؤال التالي", systemImage: "arrow.forward.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColor.success)
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private func metric(_ title: String, _ value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Label(title, systemImage: icon)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
            Text(value)
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.textPrimary)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }

    private func scorePill(title: String, value: String, tint: Color) -> some View {
        HStack {
            Text(title)
                .font(AppTypography.caption)
            Spacer()
            Text(value)
                .font(AppTypography.caption.weight(.bold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(tint.opacity(0.12), in: Capsule())
    }

    private func submitAnswer() {
        guard feedback == nil else { return }
        let evaluation = ScoringQuizEvaluator.evaluate(answerText: answerText, question: question)
        if evaluation.isCorrect {
            streak += 1
            bestStreak = max(bestStreak, streak)
        } else {
            streak = 0
        }
        feedback = QuizFeedback(evaluation: evaluation)
        saveAttempt(evaluation)
    }

    private func loadQuestion(seed: UInt64, difficulty: ScoringQuizDifficulty) {
        question = ScoringQuizGenerator.generate(seed: seed, difficulty: difficulty, rules: scoreRules)
        answerText = ""
        feedback = nil
        remainingSeconds = difficulty.timeLimitSeconds
    }

    private func runTimer(for question: ScoringQuizQuestion) async {
        remainingSeconds = question.difficulty.timeLimitSeconds
        while remainingSeconds > 0, feedback == nil, !Task.isCancelled {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled, feedback == nil else { return }
            remainingSeconds -= 1
        }
        if remainingSeconds == 0, feedback == nil {
            streak = 0
            let evaluation = ScoringQuizEvaluation(
                submittedAnswer: nil,
                expectedAnswer: question.answer,
                isCorrect: false
            )
            feedback = QuizFeedback(evaluation: evaluation)
            saveAttempt(evaluation)
        }
    }

    private func saveAttempt(_ evaluation: ScoringQuizEvaluation) {
        let attempt = ScoringQuizAttempt(
            question: question,
            evaluation: evaluation,
            remainingSeconds: remainingSeconds
        )
        modelContext.insert(attempt)
        try? modelContext.save()
    }
}

private struct QuizFeedback: Equatable {
    let evaluation: ScoringQuizEvaluation

    var isCorrect: Bool {
        evaluation.isCorrect
    }
}
