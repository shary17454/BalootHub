import SwiftUI
import SwiftData

struct PlayerStatsView: View {
    @Query(sort: \ScoreSession.updatedAt, order: .reverse) private var sessions: [ScoreSession]
    @Query(sort: \WhatToPlayAttempt.createdAt, order: .reverse) private var whatToPlayAttempts: [WhatToPlayAttempt]
    @Query(sort: \ScoringQuizAttempt.createdAt, order: .reverse) private var scoringQuizAttempts: [ScoringQuizAttempt]
    @Query private var settingsList: [AppSettings]

    private var rules: ScoreRules {
        settingsList.first?.scoreRules ?? .standard
    }

    private var summary: PlayerStatsSummary {
        PlayerStatsAnalyzer.summarize(
            sessions: sessions,
            whatToPlayAttempts: whatToPlayAttempts,
            scoringQuizAttempts: scoringQuizAttempts,
            rules: rules
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                header

                if summary.finishedMatches == 0, summary.trainingAttempts == 0 {
                    EmptyStateView(
                        systemImage: "chart.xyaxis.line",
                        title: "لا توجد بيانات كافية",
                        message: "أنهِ جلسات تسجيل بلوت أو حل مواقف وش تلعب حتى يستطيع التطبيق تحليل أسلوب لعبك."
                    )
                } else {
                    statsGrid
                    styleCard
                    modeBreakdown
                    trainingBreakdown
                    scoringQuizBreakdown
                    trainingStyleBreakdown
                }
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.background)
        .navigationTitle("أسلوب لعبك")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label("إحصائيات اللاعب", systemImage: "chart.line.uptrend.xyaxis")
                .font(AppTypography.title)
                .foregroundStyle(AppColor.primary)
            Text("تحليل محلي مبني على جلسات تسجيل البلوت المنتهية، ويستخدم بيانات السجل بدون اتصال أو حساب.")
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
            metric("المباريات", "\(summary.finishedMatches)", "rectangle.stack.fill")
            metric("الفوز", "\(summary.wins)", "checkmark.seal.fill")
            metric("الخسارة", "\(summary.losses)", "xmark.seal.fill")
            metric("نسبة الفوز", "\(Int((summary.winRate * 100).rounded()))%", "percent")
            metric("متوسط النقاط", "\(Int(summary.averagePoints.rounded()))", "number")
            metric("أطول سلسلة", "\(summary.longestWinStreak)", "flame.fill")
            metric("أعلى فوز", "\(summary.highestWinMargin)", "arrow.up.circle.fill")
            metric("أكبر خسارة", "\(summary.biggestLossMargin)", "arrow.down.circle.fill")
            metric("دقة التدريب".localized, "\(summary.trainingAccuracyPercent)%", "brain.head.profile")
            metric("قرارات خاطئة".localized, "\(summary.trainingWrongDecisions)", "xmark.octagon.fill")
        }
    }

    private var styleCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label(summary.styleTitle, systemImage: "person.text.rectangle.fill")
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.primary)
            Text(summary.advice)
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textPrimary)
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private var modeBreakdown: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("تفصيل اللعب")
                .font(AppTypography.headline)
            metric("جولات صن", "\(summary.sunRounds)", "sun.max.fill")
            metric("جولات حكم", "\(summary.hokumRounds)", "suit.spade.fill")
            metric("نقاط المشاريع", "\(summary.projectPoints)", "rectangle.stack.badge.plus")
            metric("الكبوت", "\(summary.kabootCount)", "crown.fill")
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private var trainingBreakdown: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("تفصيل التدريب".localized)
                .font(AppTypography.headline)
            metric("مواقف وش تلعب".localized, "\(summary.trainingAttempts)", "questionmark.diamond.fill")
            metric("مطابقة الخبير".localized, "\(summary.trainingCorrectDecisions)", "checkmark.seal.fill")
            metric("قرارات مكلفة".localized, "\(summary.costlyTrainingDecisions)", "exclamationmark.triangle.fill")
            metric("متوسط الفاقد".localized, "\(summary.averageTrainingLostPoints)", "minus.circle.fill")
            metric("التقاط القيمة".localized, "\(summary.trainingValueCapturePercent)%", "gauge.with.dots.needle.67percent")
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private var scoringQuizBreakdown: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("حساب النقاط".localized)
                .font(AppTypography.headline)
            metric("محاولات الحساب".localized, "\(summary.scoringQuizAttempts)", "function")
            metric("إجابات صحيحة".localized, "\(summary.scoringQuizCorrectAnswers)", "checkmark.seal.fill")
            metric("دقة الحساب".localized, "\(summary.scoringQuizAccuracyPercent)%", "percent")
            metric("أقوى نوع".localized, summary.scoringStrongestCategoryTitle, "arrow.up.circle.fill")
            metric("يحتاج تدريب".localized, summary.scoringWeakestCategoryTitle, "target")
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private var trainingStyleBreakdown: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label("بصمة قراراتك".localized, systemImage: "person.crop.rectangle.badge.magnifyingglass")
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.primary)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(summary.trainingStyleTitle)
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Text(summary.trainingStyleDetail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            insightRow("نقطة قوة".localized, summary.trainingStrength, "checkmark.circle.fill")
            insightRow("نقطة ضعف".localized, summary.trainingWeakness, "exclamationmark.circle.fill")
            insightRow("نصيحة التدريب".localized, summary.trainingAdvice, "lightbulb.fill")

            Divider()

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(summary.decisionPatternTitle)
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Text(summary.decisionPatternDetail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if summary.decisionPatternInspectedAttempts > 0 {
                    Text("\("تأثرت".localized) \(summary.decisionPatternAffectedAttempts) \("من".localized) \(summary.decisionPatternInspectedAttempts) \("محاولات حديثة".localized)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppColor.accent)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private func insightRow(_ title: String, _ detail: String, _ icon: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Text(detail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(AppColor.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }

    private func metric(_ title: String, _ value: String, _ icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColor.textSecondary)
            Spacer()
            Text(value)
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.textPrimary)
        }
        .padding(AppSpacing.sm)
        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }
}
