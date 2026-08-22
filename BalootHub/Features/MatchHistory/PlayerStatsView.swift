import SwiftUI
import SwiftData
import BalootEngine

struct PlayerStatsView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query(sort: \ScoreSession.updatedAt, order: .reverse) private var sessions: [ScoreSession]
    @Query(sort: \WhatToPlayAttempt.createdAt, order: .reverse) private var whatToPlayAttempts: [WhatToPlayAttempt]
    @Query(sort: \ScoringQuizAttempt.createdAt, order: .reverse) private var scoringQuizAttempts: [ScoringQuizAttempt]
    @Query(sort: \ProjectDeclarationRecord.createdAt, order: .reverse) private var projectDeclarations: [ProjectDeclarationRecord]
    @Query private var settingsList: [AppSettings]

    private var projectKindStats: [ProjectKindStat] {
        ProjectStatsAnalyzer.kindBreakdown(records: projectDeclarations)
    }

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
                        title: "لا توجد بيانات كافية".localized,
                        message: "أنهِ جلسات تسجيل بلوت أو حل مواقف وش تلعب حتى يستطيع التطبيق تحليل أسلوب لعبك.".localized
                    )
                } else {
                    statsGrid
                    styleCard
                    modeBreakdown
                    if !projectKindStats.isEmpty {
                        projectKindBreakdown
                    }
                    trainingBreakdown
                    scoringQuizBreakdown
                    trainingStyleBreakdown
                }
            }
            .padding(AppSpacing.md)
            .adaptiveContentWidth()
        }
        .background(AppColor.background)
        .navigationTitle("أسلوب لعبك".localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label("إحصائيات اللاعب".localized, systemImage: "chart.line.uptrend.xyaxis")
                .font(AppTypography.title)
                .foregroundStyle(AppColor.primary)
            Text("تحليل محلي مبني على جلسات تسجيل البلوت المنتهية، ويستخدم بيانات السجل بدون اتصال أو حساب.".localized)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private var statsGrid: some View {
        LazyVGrid(columns: AppLayout.columns(2, for: dynamicTypeSize, spacing: AppSpacing.sm), spacing: AppSpacing.sm) {
            metric("المباريات".localized, "\(summary.finishedMatches)", "rectangle.stack.fill")
            metric("الفوز".localized, "\(summary.wins)", "checkmark.seal.fill")
            metric("الخسارة".localized, "\(summary.losses)", "xmark.seal.fill")
            metric("نسبة الفوز".localized, "\(Int((summary.winRate * 100).rounded()))%", "percent")
            metric("متوسط النقاط".localized, "\(Int(summary.averagePoints.rounded()))", "number")
            metric("أطول سلسلة".localized, "\(summary.longestWinStreak)", "flame.fill")
            metric("أعلى فوز".localized, "\(summary.highestWinMargin)", "arrow.up.circle.fill")
            metric("أكبر خسارة".localized, "\(summary.biggestLossMargin)", "arrow.down.circle.fill")
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
            Text("تفصيل اللعب".localized)
                .font(AppTypography.headline)
            metric("جولات صن".localized, "\(summary.sunRounds)", "sun.max.fill")
            metric("جولات حكم".localized, "\(summary.hokumRounds)", "suit.spade.fill")
            metric("نقاط المشاريع".localized, "\(summary.projectPoints)", "rectangle.stack.badge.plus")
            metric("الكبوت".localized, "\(summary.kabootCount)", "crown.fill")
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private var projectKindBreakdown: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("مشاريعك حسب النوع".localized)
                .font(AppTypography.headline)
            ForEach(projectKindStats) { stat in
                projectKindRow(stat)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private func projectKindRow(_ stat: ProjectKindStat) -> some View {
        HStack {
            Label(stat.kind.arabicName, systemImage: "rectangle.stack.badge.plus")
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColor.textSecondary)
            Spacer()
            Text("\(stat.declaredCount) \("مرة".localized) · \(stat.successRatePercent)% \("نجاح".localized)")
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textPrimary)
        }
        .padding(AppSpacing.sm)
        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }

    private var trainingBreakdown: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("تفصيل التدريب".localized)
                .font(AppTypography.headline)
            metric("مواقف وش تلعب".localized, "\(summary.trainingAttempts)", "questionmark.diamond.fill")
            metric("مطابقة الخبير".localized, "\(summary.trainingCorrectDecisions)", "checkmark.seal.fill")
            metric("قرارات مكلفة".localized, "\(summary.costlyTrainingDecisions)", "exclamationmark.triangle.fill")
            metric("متوسط الفاقد".localized, "\(summary.averageTrainingLostPoints)", "minus.circle.fill")
            metric("متوسط فاقد ثاني محاكاة".localized, "\(summary.averageProjectedSecondBestGap)", "chart.line.downtrend.xyaxis")
            metric("محاولات ثاني محاكاة".localized, "\(summary.projectedSecondBestComparisonAttempts)", "scope")
            if summary.trainingExpectedImprovement > 0, let source = summary.trainingExpectedImprovementSourceTitle {
                metric("تحسن متوقع".localized, "+\(summary.trainingExpectedImprovement)", "arrow.up.forward.circle.fill")
                metric("مصدر التحسن".localized, source, "scope")
            }
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
            trainingTargetRow

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

    private var trainingTargetRow: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(summary.trainingTargetTitle)
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Text(summary.trainingTargetDetail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let targetLine = summary.trainingTargetLine, !targetLine.isEmpty {
                    Text(targetLine)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppColor.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        } icon: {
            Image(systemName: "scope")
                .foregroundStyle(AppColor.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(AppColor.primary.opacity(0.10), in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
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
