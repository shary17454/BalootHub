import SwiftUI
import SwiftData

struct PlayerStatsView: View {
    @Query(sort: \ScoreSession.updatedAt, order: .reverse) private var sessions: [ScoreSession]
    @Query private var settingsList: [AppSettings]

    private var rules: ScoreRules {
        settingsList.first?.scoreRules ?? .standard
    }

    private var summary: PlayerStatsSummary {
        PlayerStatsAnalyzer.summarize(sessions: sessions, rules: rules)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                header

                if summary.finishedMatches == 0 {
                    EmptyStateView(
                        systemImage: "chart.xyaxis.line",
                        title: "لا توجد بيانات كافية",
                        message: "أنهِ جلسات تسجيل بلوت حتى يستطيع التطبيق تحليل أسلوب لعبك."
                    )
                } else {
                    statsGrid
                    styleCard
                    modeBreakdown
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
