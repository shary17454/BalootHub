import SwiftUI

struct ScoringQuizView: View {
    @State private var difficulty: ScoringQuizDifficulty = .medium
    @State private var seed: UInt64 = UInt64(Date().timeIntervalSince1970)
    @State private var question = ScoringQuizGenerator.generate(seed: UInt64(Date().timeIntervalSince1970), difficulty: .medium)
    @State private var answerText = ""
    @State private var feedback: QuizFeedback?
    @State private var streak = 0
    @State private var remainingSeconds = ScoringQuizDifficulty.medium.timeLimitSeconds
    @AppStorage("scoringQuizBestStreak") private var bestStreak = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                header
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
        .task(id: question.id) {
            await runTimer(for: question)
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
                scorePill(title: "أفضل رقم", value: "\(bestStreak)", tint: AppColor.primary)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
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
        let cleaned = answerText.trimmingCharacters(in: .whitespacesAndNewlines)
        let isCorrect = Int(cleaned) == question.answer
        if isCorrect {
            streak += 1
            bestStreak = max(bestStreak, streak)
        } else {
            streak = 0
        }
        feedback = QuizFeedback(isCorrect: isCorrect)
    }

    private func loadQuestion(seed: UInt64, difficulty: ScoringQuizDifficulty) {
        question = ScoringQuizGenerator.generate(seed: seed, difficulty: difficulty)
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
            feedback = QuizFeedback(isCorrect: false)
        }
    }
}

private struct QuizFeedback: Equatable {
    let isCorrect: Bool
}
