import SwiftUI
import SwiftData

struct AchievementsView: View {
    @AppStorage("unlockedBalootAchievementIDs") private var unlockedAchievementIDs = ""
    @AppStorage("balootAcademyCompletedLessons") private var completedAcademyLessonIDs = ""
    @Query(sort: \WhatToPlayAttempt.createdAt, order: .reverse) private var whatToPlayAttempts: [WhatToPlayAttempt]
    @Query(sort: \ScoringQuizAttempt.createdAt, order: .reverse) private var scoringQuizAttempts: [ScoringQuizAttempt]
    @Query(sort: \AcademyLessonProgress.completedAt, order: .reverse) private var academyProgress: [AcademyLessonProgress]
    @Query(sort: \ScoreSession.createdAt, order: .reverse) private var scoreSessions: [ScoreSession]

    private var unlockedSet: Set<String> {
        Set(unlockedAchievementIDs.split(separator: ",").map(String.init))
            .union(AchievementCenter.earnedAchievementIDs(
                whatToPlayAttempts: whatToPlayAttempts,
                scoringQuizAttempts: scoringQuizAttempts,
                scoreSessions: scoreSessions,
                academyProgress: academyProgress,
                legacyCompletedAcademyLessonIDs: completedAcademySet
            ))
    }

    private var completedAcademySet: Set<String> {
        Set(completedAcademyLessonIDs.split(separator: ",").map(String.init))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                header
                ForEach(AchievementCenter.all) { achievement in
                    achievementCard(achievement)
                }
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.background)
        .navigationTitle("الإنجازات والألقاب")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label("إنجازات محلية", systemImage: "trophy.fill")
                .font(AppTypography.title)
                .foregroundStyle(AppColor.primary)
            Text("نظام ألقاب يعمل دون إنترنت، ومصمم ليُربط لاحقًا بـ Game Center عند إضافة التكامل.")
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColor.textSecondary)
            StatusBadge("\(unlockedSet.count)/\(AchievementCenter.all.count)", systemImage: "checkmark.seal.fill", tint: AppColor.success)
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private func achievementCard(_ achievement: LocalAchievement) -> some View {
        let isUnlocked = unlockedSet.contains(achievement.id)

        return VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                Image(systemName: achievement.iconName)
                    .font(.title2)
                    .foregroundStyle(isUnlocked ? AppColor.warning : AppColor.textSecondary)
                    .frame(width: 36, height: 36)
                    .background((isUnlocked ? AppColor.warning : AppColor.textSecondary).opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack {
                        Text(achievement.title)
                            .font(AppTypography.headline)
                            .foregroundStyle(AppColor.textPrimary)
                        Spacer()
                        StatusBadge(achievement.rarity.title, tint: rarityTint(achievement.rarity))
                    }
                    Text(achievement.detail)
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppColor.textSecondary)
                    Text(achievement.requirement)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }

            Button {
                toggle(achievement.id)
            } label: {
                Label(isUnlocked ? "مفتوح" : "تجربة الفتح المحلي", systemImage: isUnlocked ? "lock.open.fill" : "lock.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(isUnlocked ? AppColor.success : AppColor.primary)
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
        .accessibilityElement(children: .combine)
    }

    private func rarityTint(_ rarity: AchievementRarity) -> Color {
        switch rarity {
        case .bronze: AppColor.accent
        case .silver: AppColor.textSecondary
        case .gold: AppColor.warning
        case .legendary: AppColor.danger
        }
    }

    private func toggle(_ achievementID: String) {
        var set = unlockedSet
        if set.contains(achievementID) {
            set.remove(achievementID)
        } else {
            set.insert(achievementID)
        }
        unlockedAchievementIDs = set.sorted().joined(separator: ",")
    }
}

struct CareerModeView: View {
    @AppStorage("unlockedBalootAchievementIDs") private var unlockedAchievementIDs = ""
    @AppStorage("balootAcademyCompletedLessons") private var completedAcademyLessonIDs = ""
    @Query(sort: \ScoreSession.createdAt, order: .reverse) private var scoreSessions: [ScoreSession]
    @Query(sort: \WhatToPlayAttempt.createdAt, order: .reverse) private var whatToPlayAttempts: [WhatToPlayAttempt]
    @Query(sort: \ScoringQuizAttempt.createdAt, order: .reverse) private var scoringQuizAttempts: [ScoringQuizAttempt]
    @Query(sort: \AcademyLessonProgress.completedAt, order: .reverse) private var academyProgress: [AcademyLessonProgress]

    private var summary: CareerProgressSummary {
        CareerProgressAnalyzer.summarize(
            scoreSessions: scoreSessions,
            whatToPlayAttempts: whatToPlayAttempts,
            scoringQuizAttempts: scoringQuizAttempts,
            academyProgress: academyProgress,
            unlockedAchievementIDs: unlockedSet,
            legacyCompletedAcademyLessonIDs: completedAcademySet
        )
    }

    private var unlockedSet: Set<String> {
        Set(unlockedAchievementIDs.split(separator: ",").map(String.init))
    }

    private var completedAcademySet: Set<String> {
        Set(completedAcademyLessonIDs.split(separator: ",").map(String.init))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                header(summary)
                statsGrid(summary)
                unlocksSection(summary.unlocks)
                nextStep(summary)
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.background)
        .navigationTitle("نمط المسيرة".localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func header(_ summary: CareerProgressSummary) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(summary.rank.title)
                        .font(AppTypography.title)
                        .foregroundStyle(AppColor.primary)
                    Text("\(summary.xp) XP")
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColor.textPrimary)
                }
                Spacer()
                Image(systemName: "flag.checkered")
                    .font(.title)
                    .foregroundStyle(AppColor.warning)
            }

            ProgressView(value: summary.progressToNextRank)
                .tint(AppColor.primary)
                .accessibilityLabel("تقدم رتبة المسيرة".localized)

            Text(nextRankText(summary))
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private func statsGrid(_ summary: CareerProgressSummary) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
            careerMetric("المباريات".localized, "\(summary.completedMatches)", "suit.spade.fill")
            careerMetric("قرارات صحيحة".localized, "\(summary.correctTrainingAttempts)/\(summary.trainingAttempts)", "brain.head.profile")
            careerMetric("إجابات الحساب".localized, "\(summary.correctScoringAnswers)", "function")
            careerMetric("دروس مكتملة".localized, "\(summary.completedAcademyLessons)", "graduationcap.fill")
            careerMetric("إنجازات".localized, "\(summary.unlockedAchievementCount)", "trophy.fill")
        }
    }

    private func careerMetric(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .foregroundStyle(AppColor.accent)
            Text(value)
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.textPrimary)
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.medium))
    }

    private func unlocksSection(_ unlocks: [CareerUnlock]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label("المحتوى المفتوح".localized, systemImage: "sparkles")
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.primary)

            ForEach(unlocks) { unlock in
                HStack(alignment: .top, spacing: AppSpacing.sm) {
                    Image(systemName: unlock.isUnlocked ? "lock.open.fill" : "lock.fill")
                        .foregroundStyle(unlock.isUnlocked ? AppColor.success : AppColor.textSecondary)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(unlock.title)
                            .font(AppTypography.subheadline.weight(.semibold))
                            .foregroundStyle(AppColor.textPrimary)
                        Text(unlock.detail)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    Spacer()
                }
                .padding(AppSpacing.sm)
                .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private func nextStep(_ summary: CareerProgressSummary) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label(summary.nextStepTitle, systemImage: "arrow.triangle.branch")
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.accent)
            Text(summary.nextStepDetail)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColor.textPrimary)
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private func nextRankText(_ summary: CareerProgressSummary) -> String {
        guard let nextRank = summary.nextRank else {
            return "وصلت إلى أعلى رتبة حالية في المسيرة.".localized
        }
        return "\("الرتبة التالية".localized): \(nextRank.title) · \(nextRank.requiredXP) XP"
    }
}
