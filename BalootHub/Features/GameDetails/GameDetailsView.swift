import SwiftUI
import SwiftData
import BalootEngine

struct GameDetailsView: View {
    let slug: String

    @Environment(AppEnvironment.self) private var appEnvironment
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [GameCatalogItem]

    init(slug: String) {
        self.slug = slug
        let predicate = #Predicate<GameCatalogItem> { $0.slug == slug }
        _items = Query(filter: predicate)
    }

    private var item: GameCatalogItem? { items.first }

    var body: some View {
        Group {
            if let item {
                content(for: item)
            } else {
                ErrorStateView(message: "تعذّر العثور على هذه اللعبة في الكتالوج.")
            }
        }
        .background(AppColor.background)
        .navigationTitle(item?.displayTitle ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func content(for item: GameCatalogItem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                heroCard(item)

                Text(item.displayDescription)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textPrimary)

                infoGrid(item)

                if let howToPlay = item.ruleSection(.howToPlay) {
                    summaryCard(section: howToPlay)
                }
                if let scoring = item.ruleSection(.scoring) {
                    summaryCard(section: scoring)
                }
                if let mistakes = item.ruleSection(.commonMistakes) {
                    summaryCard(section: mistakes)
                }

                actionButtons(item)
            }
            .padding(AppSpacing.md)
        }
    }

    private func heroCard(_ item: GameCatalogItem) -> some View {
        let accent = AppColor.categoryColor(for: item.category)
        return ZStack {
            RoundedRectangle(cornerRadius: AppRadius.large)
                .fill(LinearGradient(colors: [accent.opacity(0.85), accent], startPoint: .topLeading, endPoint: .bottomTrailing))
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: item.iconName)
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(.white)
                Text(item.displayTitle)
                    .font(AppTypography.title)
                    .foregroundStyle(.white)
                if let englishTitle = item.englishTitle {
                    Text(englishTitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .padding(AppSpacing.xl)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .appShadow(AppShadow.elevated)
        .accessibilityElement(children: .combine)
    }

    private func infoGrid(_ item: GameCatalogItem) -> some View {
        VStack(spacing: AppSpacing.xs) {
            InfoRow(icon: item.category.iconName, title: "النوع", value: item.category.title)
            InfoRow(icon: "person.3.fill", title: "عدد اللاعبين", value: item.displayPlayerCount)
            InfoRow(icon: "chart.bar.fill", title: "مستوى الصعوبة", value: "\(item.difficulty.title) (\(String(repeating: "★", count: item.difficulty.starCount)))")
            InfoRow(icon: "clock.fill", title: "المدة المتوقعة", value: item.displayDuration)
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.medium))
    }

    private func summaryCard(section: GameRuleSection) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label(section.displayTitle, systemImage: section.iconName)
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.primary)
            Text(section.displayBody)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColor.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.medium))
    }

    private func actionButtons(_ item: GameCatalogItem) -> some View {
        VStack(spacing: AppSpacing.sm) {
            Button {
                appEnvironment.navigate(to: .rules(slug: item.slug), tab: appEnvironment.selectedTab)
            } label: {
                Label("عرض القواعد كاملة", systemImage: "book.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(AppColor.primary)
            .controlSize(.large)

            if item.slug == "hand-analyzer" {
                Button {
                    appEnvironment.navigate(to: .handAnalyzer, tab: appEnvironment.selectedTab)
                } label: {
                    Label("فتح أداة التحليل", systemImage: "wand.and.stars")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.primary)
                .controlSize(.large)
            }

            if item.slug == "baloot-training" {
                Button {
                    appEnvironment.navigate(to: .balootAcademy, tab: appEnvironment.selectedTab)
                } label: {
                    Label("فتح الأكاديمية", systemImage: "graduationcap.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.primary)
                .controlSize(.large)
            }

            if item.slug == "what-to-play-trainer" {
                Button {
                    appEnvironment.navigate(to: .whatToPlayTrainer, tab: appEnvironment.selectedTab)
                } label: {
                    Label("فتح المدرب", systemImage: "brain.head.profile")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.primary)
                .controlSize(.large)
            }

            if item.slug == "score-calculation-challenge" {
                Button {
                    appEnvironment.navigate(to: .scoringQuiz, tab: appEnvironment.selectedTab)
                } label: {
                    Label("بدء التحدي", systemImage: "function")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.primary)
                .controlSize(.large)
            }

            if item.slug == "daily-baloot-challenges" {
                Button {
                    appEnvironment.navigate(to: .dailyChallenges, tab: appEnvironment.selectedTab)
                } label: {
                    Label("فتح التحديات", systemImage: "calendar.badge.checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.primary)
                .controlSize(.large)
            }

            if item.slug == "baloot-achievements" {
                Button {
                    appEnvironment.navigate(to: .achievements, tab: appEnvironment.selectedTab)
                } label: {
                    Label("فتح الإنجازات", systemImage: "trophy.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.primary)
                .controlSize(.large)
            }

            if item.slug == "offline-tournaments" {
                Button {
                    appEnvironment.navigate(to: .offlineTournaments, tab: appEnvironment.selectedTab)
                } label: {
                    Label("فتح البطولات", systemImage: "trophy.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.primary)
                .controlSize(.large)
            }

            if item.isPlayable {
                Button {
                    appEnvironment.navigate(to: .balootGamePlay(slug: item.slug), tab: appEnvironment.selectedTab)
                } label: {
                    Label("بدء اللعب", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.primary)
                .controlSize(.large)
            }

            if item.category == .balootGame || item.slug == "baloot-scorekeeper" {
                Button {
                    appEnvironment.selectedTab = .scorekeeper
                } label: {
                    Label("فتح مسجل النقاط", systemImage: "list.clipboard.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.accent)
                .controlSize(.large)
            }

            Button {
                item.isFavorite.toggle()
                try? modelContext.save()
            } label: {
                Label(item.isFavorite ? "إزالة من المفضلة" : "إضافة إلى المفضلة", systemImage: item.isFavorite ? "heart.fill" : "heart")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(AppColor.danger)
            .controlSize(.large)
        }
    }
}

private struct InfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Label(title.localized, systemImage: icon)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColor.textSecondary)
            Spacer()
            Text(value)
                .font(AppTypography.subheadline.weight(.semibold))
                .foregroundStyle(AppColor.textPrimary)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct StatTile: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label(title.localized, systemImage: icon)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(value)
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
    }
}

#Preview {
    NavigationStack {
        GameDetailsView(slug: "baloot-classic")
    }
    .environment(AppEnvironment())
    .modelContainer(PersistenceController.makePreviewContainer())
}

struct WhatToPlayTrainerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WhatToPlayAttempt.createdAt, order: .reverse) private var attempts: [WhatToPlayAttempt]

    @State private var difficulty: WhatToPlayDifficulty = .medium
    @State private var preferredFocusRaw = "auto"
    @State private var seed: UInt64 = 2026
    @State private var scenario: WhatToPlayScenario?
    @State private var selectedOption: WhatToPlayOption?
    @State private var errorMessage: String?
    @State private var isGeneratingScenario = false
    @State private var generationTask: Task<Void, Never>?

    private var statsSummary: WhatToPlayStatsSummary {
        WhatToPlayStatsAnalyzer.summarize(attempts: attempts)
    }

    private var outcomeSummary: WhatToPlayOutcomeSummary {
        WhatToPlayStatsAnalyzer.outcomeSummary(for: attempts)
    }

    private var outcomeInsight: WhatToPlayOutcomeInsight? {
        WhatToPlayStatsAnalyzer.outcomeInsight(for: outcomeSummary)
    }

    private var recentAttempts: [WhatToPlayAttempt] {
        WhatToPlayStatsAnalyzer.recentAttempts(attempts)
    }

    private var reviewQueue: [WhatToPlayReviewItem] {
        WhatToPlayStatsAnalyzer.reviewQueue(for: attempts)
    }

    private var difficultySummaries: [(difficulty: WhatToPlayDifficulty, summary: WhatToPlayStatsSummary)] {
        WhatToPlayStatsAnalyzer.summariesByDifficulty(attempts)
    }

    private var scenarioFocusSummaries: [WhatToPlayScenarioFocusSummary] {
        WhatToPlayStatsAnalyzer.summariesByScenarioFocus(attempts)
    }

    private var scenarioFocusCoverage: WhatToPlayScenarioFocusCoverage {
        WhatToPlayStatsAnalyzer.scenarioFocusCoverage(for: attempts)
    }

    private var coachingTip: WhatToPlayCoachingTip {
        WhatToPlayStatsAnalyzer.coachingTip(for: attempts)
    }

    private var focusDifficulty: WhatToPlayDifficultyFocus? {
        WhatToPlayStatsAnalyzer.focusDifficulty(attempts)
    }

    private var difficultyImpactInsight: WhatToPlayDifficultyImpactInsight? {
        WhatToPlayStatsAnalyzer.difficultyImpactInsight(for: attempts)
    }

    private var performanceTrend: WhatToPlayPerformanceTrend? {
        WhatToPlayStatsAnalyzer.performanceTrend(attempts: attempts)
    }

    private var practiceRecommendation: WhatToPlayPracticeRecommendation {
        WhatToPlayStatsAnalyzer.practiceRecommendation(for: attempts)
    }

    private var trainingSessionPlan: WhatToPlayTrainingSessionPlan {
        WhatToPlayStatsAnalyzer.trainingSessionPlan(for: attempts)
    }

    private var mastery: WhatToPlayMastery {
        WhatToPlayStatsAnalyzer.mastery(for: attempts)
    }

    private var masteryMilestone: WhatToPlayMasteryMilestone? {
        WhatToPlayStatsAnalyzer.masteryMilestone(for: attempts)
    }

    private var practiceCoverage: WhatToPlayPracticeCoverage {
        WhatToPlayStatsAnalyzer.practiceCoverage(for: attempts)
    }

    private var sessionPulse: WhatToPlaySessionPulse {
        WhatToPlayStatsAnalyzer.sessionPulse(for: attempts)
    }

    private var microDrill: WhatToPlayMicroDrill {
        WhatToPlayStatsAnalyzer.microDrill(for: attempts)
    }

    private var playStyle: WhatToPlayPlayStyle {
        WhatToPlayStatsAnalyzer.playStyle(for: attempts)
    }

    private var decisionPattern: WhatToPlayDecisionPattern {
        WhatToPlayStatsAnalyzer.decisionPattern(for: attempts)
    }

    private var trainingSessionProgress: WhatToPlayTrainingSessionProgress {
        WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: trainingSessionPlan)
    }

    private var preferredFocus: WhatToPlayScenarioFocusKind? {
        WhatToPlayScenarioFocusKind(rawValue: preferredFocusRaw)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                header
                controls
                practiceRecommendationCard
                microDrillCard
                statsCard
                difficultyStatsCard
                scenarioFocusStatsCard
                recentAttemptsCard
                reviewQueueCard

            if let scenario {
                scenarioSummary(scenario)
                shareCardPreview(scenario)
                legalOptions(scenario)
                if let selectedOption {
                    resultCard(selectedOption, scenario: scenario)
                    optionComparisonCard(selectedOption: selectedOption, scenario: scenario)
                }
                } else if isGeneratingScenario {
                    EmptyStateView(
                        systemImage: "brain.head.profile",
                        title: "جارٍ تجهيز موقف".localized,
                        message: "يحلل المحرك موقفًا حقيقيًا في الخلفية بدون إيقاف الواجهة.".localized
                    )
                } else if let errorMessage {
                    ErrorStateView(message: errorMessage)
                } else {
                    EmptyStateView(
                        systemImage: "brain.head.profile",
                        title: "جارٍ تجهيز موقف".localized,
                        message: "يولّد المحرك جولة بلوت حقيقية ثم يوقفها عند دورك.".localized
                    )
                }
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.background)
        .navigationTitle("وش تلعب؟")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if scenario == nil { generateScenario() }
        }
        .onChange(of: difficulty) { _, _ in
            generateScenario()
        }
        .onChange(of: preferredFocusRaw) { _, _ in
            generateScenario()
        }
        .onDisappear {
            generationTask?.cancel()
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if let scenario {
                    ShareLink(item: WhatToPlayShareCard.text(for: scenario)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("مشاركة الموقف".localized)
                }

                Button {
                    nextScenario()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(isGeneratingScenario)
                .accessibilityLabel("موقف جديد")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("اختر أفضل ورقة")
                .font(AppTypography.title)
                .foregroundStyle(AppColor.textPrimary)
            Text("يعرض التطبيق الأوراق القانونية فقط، ثم يقارن قرارك بقرار Expert AI ويشرح الأثر المتوقع.")
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColor.textSecondary)
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Picker("الصعوبة", selection: $difficulty) {
                ForEach(WhatToPlayDifficulty.allCases, id: \.self) { level in
                    Text(level.displayTitle).tag(level)
                }
            }
            .pickerStyle(.segmented)

            Picker("نوع الموقف", selection: $preferredFocusRaw) {
                Text("تلقائي".localized).tag("auto")
                ForEach(WhatToPlayScenarioFocusKind.allCases, id: \.self) { focusKind in
                    Text(focusTitle(focusKind)).tag(focusKind.rawValue)
                }
            }
            .pickerStyle(.menu)
            .accessibilityLabel("نوع الموقف".localized)

            Button {
                nextScenario()
            } label: {
                Label("موقف جديد", systemImage: "shuffle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(AppColor.primary)
            .disabled(isGeneratingScenario)
        }
    }

    private var practiceRecommendationCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label("التدريب المقترح", systemImage: practiceRecommendation.iconName)
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.primary)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(practiceRecommendation.title)
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Text(practiceRecommendation.detail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            trainingSessionPlanView(trainingSessionPlan, progress: trainingSessionProgress)

            Button {
                startRecommendedPractice()
            } label: {
                Label(
                    "\("ابدأ".localized) \(trainingSessionPlan.difficulty.displayTitle)",
                    systemImage: "play.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColor.primary)
            .disabled(isGeneratingScenario)
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private func trainingSessionPlanView(
        _ plan: WhatToPlayTrainingSessionPlan,
        progress: WhatToPlayTrainingSessionProgress
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label(plan.title, systemImage: plan.iconName)
                .font(AppTypography.subheadline.weight(.semibold))
                .foregroundStyle(AppColor.textPrimary)

            Text(plan.detail)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.xs), count: 2), spacing: AppSpacing.xs) {
                miniPlanMetric(title: "المستوى".localized, value: plan.difficulty.displayTitle)
                miniPlanMetric(title: "تركيز التدريب".localized, value: plan.focusKind.map(focusTitle) ?? "تلقائي".localized)
                miniPlanMetric(title: "المواقف".localized, value: "\(plan.scenarioCount)")
                miniPlanMetric(title: "هدف الدقة".localized, value: "\(plan.targetAccuracyPercent)%")
            }

            Label(plan.successMetric, systemImage: "checkmark.circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColor.success)
                .fixedSize(horizontal: false, vertical: true)

            trainingSessionProgressView(progress)
        }
        .padding(AppSpacing.sm)
        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }

    private func trainingSessionProgressView(_ progress: WhatToPlayTrainingSessionProgress) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label(progress.title, systemImage: progress.iconName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(progress.state == .achieved ? AppColor.success : AppColor.textPrimary)

            Text(progress.detail)
                .font(.caption2)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            ProgressView(
                value: Double(progress.completedAttempts),
                total: Double(max(progress.targetAttempts, 1))
            )
            .tint(progress.state == .achieved ? AppColor.success : AppColor.primary)

            HStack(spacing: AppSpacing.sm) {
                miniPlanMetric(
                    title: "المكتمل".localized,
                    value: "\(progress.completedAttempts) \("من".localized) \(progress.targetAttempts)"
                )
                miniPlanMetric(
                    title: "الدقة الحالية".localized,
                    value: "\(progress.accuracyPercent)%"
                )
            }
        }
        .padding(.top, AppSpacing.xs)
    }

    private func miniPlanMetric(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(value)
                .font(AppTypography.caption.weight(.bold))
                .foregroundStyle(AppColor.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xs)
        .background(AppColor.background, in: RoundedRectangle(cornerRadius: AppRadius.small))
    }

    private var microDrillCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label(microDrill.title, systemImage: microDrill.iconName)
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.primary)

            Text(microDrill.detail)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: AppSpacing.xs) {
                ForEach(Array(microDrill.steps.enumerated()), id: \.offset) { index, step in
                    HStack(spacing: AppSpacing.sm) {
                        Text("\(index + 1)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(AppColor.primary, in: Circle())
                            .accessibilityHidden(true)
                        Text(step)
                            .font(AppTypography.subheadline)
                            .foregroundStyle(AppColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppSpacing.sm)
                    .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
                }
            }

            if let reviewItem = microDrill.reviewItem {
                Button {
                    replayReviewItem(reviewItem)
                } label: {
                    Label("إعادة أهم خطأ".localized, systemImage: "arrow.clockwise.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.primary)
                .disabled(isGeneratingScenario)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label("أداؤك في المدرب", systemImage: "chart.bar.xaxis")
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.primary)

            if statsSummary.attempts == 0 {
                Text("اختر ورقة في أول موقف ليبدأ التطبيق بتتبع دقتك وسلسلة إجاباتك.")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColor.textSecondary)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.xs), count: 2), spacing: AppSpacing.xs) {
                    StatTile(title: "المحاولات", value: "\(statsSummary.attempts)", icon: "number")
                    StatTile(title: "الدقة", value: "\(statsSummary.accuracyPercent)%", icon: "target")
                    StatTile(title: "السلسلة الحالية", value: "\(statsSummary.currentStreak)", icon: "flame.fill")
                    StatTile(title: "أفضل سلسلة", value: "\(statsSummary.bestStreak)", icon: "star.fill")
                }
                InfoRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "متوسط الأثر المتوقع",
                    value: impactText(statsSummary.averageExpectedImpact)
                )
                if statsSummary.lostExpectedPoints > 0 {
                    InfoRow(
                        icon: "drop.fill",
                        title: "نقاط متوقعة ضائعة".localized,
                        value: "\(statsSummary.lostExpectedPoints)"
                    )
                }
                if outcomeSummary.trackedAttempts > 0 {
                    outcomeSummaryView(outcomeSummary, insight: outcomeInsight)
                }
                masteryView(mastery, milestone: masteryMilestone)
                playStyleView(playStyle)
                decisionPatternView(decisionPattern)
                sessionPulseView(sessionPulse)
                coachingTipView(coachingTip)
                if let performanceTrend {
                    performanceTrendView(performanceTrend)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private func outcomeSummaryView(_ summary: WhatToPlayOutcomeSummary, insight: WhatToPlayOutcomeInsight?) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label("نتائج قراراتك".localized, systemImage: "rectangle.stack.badge.play.fill")
                .font(AppTypography.subheadline.weight(.semibold))
                .foregroundStyle(AppColor.textPrimary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.xs), count: 3), spacing: AppSpacing.xs) {
                miniMetric("يكسب الأكلة".localized, "\(summary.winningTrickAttempts)", AppColor.success)
                miniMetric("يخسر الأكلة".localized, "\(summary.losingTrickAttempts)", AppColor.danger)
                miniMetric("يبقي الأكلة مفتوحة".localized, "\(summary.openTrickAttempts)", AppColor.accent)
            }

            Text("\("محاولات مفحوصة".localized): \(summary.trackedAttempts) · \("نسبة كسب الأكلة".localized): \(summary.winningPercent)% · \("نسبة خسارة الأكلة".localized): \(summary.losingPercent)%")
                .font(.caption2)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if let insight {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(insight.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColor.textPrimary)
                        Text(insight.detail)
                            .font(.caption2)
                            .foregroundStyle(AppColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } icon: {
                    Image(systemName: insight.iconName)
                        .foregroundStyle(AppColor.primary)
                }
                .padding(.top, AppSpacing.xs)
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }

    private func miniMetric(_ title: String, _ value: String, _ tint: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(AppTypography.subheadline.weight(.bold))
                .foregroundStyle(tint)
            Text(title)
                .font(.caption2)
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xs)
    }

    private func coachingTipView(_ tip: WhatToPlayCoachingTip) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(tip.title)
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Text(tip.detail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } icon: {
            Image(systemName: tip.iconName)
                .foregroundStyle(AppColor.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }

    private func decisionPatternView(_ pattern: WhatToPlayDecisionPattern) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(pattern.title)
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Text(pattern.detail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\("محاولات مفحوصة".localized): \(pattern.inspectedAttempts) · \("محاولات متأثرة".localized): \(pattern.affectedAttempts)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(decisionPatternTint(pattern.kind))
            }
        } icon: {
            Image(systemName: pattern.iconName)
                .foregroundStyle(decisionPatternTint(pattern.kind))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(decisionPatternTint(pattern.kind).opacity(0.12), in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }

    private func decisionPatternTint(_ kind: WhatToPlayDecisionPatternKind) -> Color {
        switch kind {
        case .noData:
            AppColor.textSecondary
        case .clean:
            AppColor.success
        case .usefulAlternatives:
            AppColor.accent
        case .pointLeaks:
            AppColor.danger
        }
    }

    private func playStyleView(_ style: WhatToPlayPlayStyle) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(style.title)
                        .font(AppTypography.subheadline.weight(.semibold))
                        .foregroundStyle(AppColor.textPrimary)
                    Text(style.detail)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } icon: {
                Image(systemName: style.iconName)
                    .foregroundStyle(playStyleTint(style.kind))
            }

            VStack(spacing: AppSpacing.xs) {
                styleLine(title: "نقطة قوة".localized, value: style.strength, tint: AppColor.success)
                styleLine(title: "نقطة تحتاج تدريب".localized, value: style.weakness, tint: AppColor.accent)
                styleLine(title: "النصيحة التالية".localized, value: style.advice, tint: playStyleTint(style.kind))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(playStyleTint(style.kind).opacity(0.12), in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }

    private func styleLine(title: String, value: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.xs) {
            Circle()
                .fill(tint)
                .frame(width: 7, height: 7)
                .padding(.top, 6)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(tint)
                Text(value)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func playStyleTint(_ kind: WhatToPlayStyleKind) -> Color {
        switch kind {
        case .measuring:
            AppColor.textSecondary
        case .foundational:
            AppColor.danger
        case .cautious, .inconsistent:
            AppColor.accent
        case .expertAligned:
            AppColor.success
        }
    }

    private func masteryView(_ mastery: WhatToPlayMastery, milestone: WhatToPlayMasteryMilestone?) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: mastery.iconName)
                    .foregroundStyle(masteryTint(mastery.level))
                    .accessibilityHidden(true)
                Text(mastery.title)
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                Text("\(mastery.score)/100")
                    .font(AppTypography.subheadline.weight(.bold))
                    .foregroundStyle(masteryTint(mastery.level))
            }

            ProgressView(value: Double(mastery.score), total: 100)
                .tint(masteryTint(mastery.level))

            Text(mastery.detail)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if let milestone {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "flag.checkered")
                        .accessibilityHidden(true)
                    Text(milestone.detail)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(masteryTint(mastery.level))
                .padding(.top, 2)
            }
        }
        .padding(AppSpacing.sm)
        .background(masteryTint(mastery.level).opacity(0.12), in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }

    private func sessionPulseView(_ pulse: WhatToPlaySessionPulse) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(pulse.title)
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Text(pulse.detail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\("آخر محاولات مفحوصة".localized): \(pulse.inspectedAttempts)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(sessionPulseTint(pulse.state))
            }
        } icon: {
            Image(systemName: pulse.iconName)
                .foregroundStyle(sessionPulseTint(pulse.state))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(sessionPulseTint(pulse.state).opacity(0.12), in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }

    private func sessionPulseTint(_ state: WhatToPlaySessionState) -> Color {
        switch state {
        case .noData:
            AppColor.textSecondary
        case .warmingUp:
            AppColor.accent
        case .focused:
            AppColor.success
        case .reviewNeeded:
            AppColor.danger
        }
    }

    private func masteryTint(_ level: WhatToPlayMasteryLevel) -> Color {
        switch level {
        case .starting:
            AppColor.danger
        case .building:
            AppColor.accent
        case .confident, .sharp:
            AppColor.success
        }
    }

    private func performanceTrendView(_ trend: WhatToPlayPerformanceTrend) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(trend.title)
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Text(trend.detail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\("آخر أداء".localized): \(trend.recentAccuracyPercent)% · \("السابق".localized): \(trend.previousAccuracyPercent)%")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(trendTint(trend.direction))
            }
        } icon: {
            Image(systemName: trend.iconName)
                .foregroundStyle(trendTint(trend.direction))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(trendTint(trend.direction).opacity(0.12), in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }

    private func trendTint(_ direction: WhatToPlayTrendDirection) -> Color {
        switch direction {
        case .improving:
            AppColor.success
        case .stable:
            AppColor.accent
        case .declining:
            AppColor.danger
        }
    }

    @ViewBuilder
    private var difficultyStatsCard: some View {
        if !difficultySummaries.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Label("الأداء حسب الصعوبة", systemImage: "chart.bar.doc.horizontal")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.primary)

                VStack(spacing: AppSpacing.sm) {
                    ForEach(difficultySummaries, id: \.difficulty) { entry in
                        HStack {
                            Label(entry.difficulty.displayTitle, systemImage: "slider.horizontal.3")
                                .font(AppTypography.subheadline.weight(.semibold))
                                .foregroundStyle(AppColor.textPrimary)
                            Spacer()
                            Text("\(entry.summary.correct)/\(entry.summary.attempts)")
                                .font(AppTypography.caption.weight(.semibold))
                                .foregroundStyle(AppColor.textSecondary)
                            Text("\(entry.summary.accuracyPercent)%")
                                .font(AppTypography.subheadline.weight(.bold))
                                .foregroundStyle(entry.summary.accuracyPercent >= 70 ? AppColor.success : AppColor.accent)
                        }
                        .padding(AppSpacing.sm)
                        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
                        .accessibilityElement(children: .combine)
                    }
                }

                if let focusDifficulty {
                    focusDifficultyView(focusDifficulty)
                }

                if let difficultyImpactInsight {
                    difficultyImpactInsightView(difficultyImpactInsight)
                }

                practiceCoverageView(practiceCoverage)
            }
            .padding(AppSpacing.md)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
        }
    }

    private func focusDifficultyView(_ focus: WhatToPlayDifficultyFocus) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text("\("ركّز على".localized): \(focus.difficulty.displayTitle)")
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Text("\("دقتك هنا".localized): \(focus.summary.accuracyPercent)% (\(focus.summary.correct)/\(focus.summary.attempts))")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
        } icon: {
            Image(systemName: "scope")
                .foregroundStyle(AppColor.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(AppColor.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }

    private func difficultyImpactInsightView(_ insight: WhatToPlayDifficultyImpactInsight) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Text(insight.detail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\("متوسط الأثر".localized): \(impactText(insight.averageExpectedImpact)) · \(insight.attempts) \("محاولات".localized)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(insight.averageExpectedImpact < 0 ? AppColor.danger : AppColor.success)
            }
        } icon: {
            Image(systemName: insight.iconName)
                .foregroundStyle(insight.averageExpectedImpact < 0 ? AppColor.danger : AppColor.success)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background((insight.averageExpectedImpact < 0 ? AppColor.danger : AppColor.success).opacity(0.12), in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var scenarioFocusStatsCard: some View {
        if !scenarioFocusSummaries.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Label("الأداء حسب تركيز التدريب".localized, systemImage: "scope")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.primary)

                scenarioFocusCoverageView(scenarioFocusCoverage)

                VStack(spacing: AppSpacing.sm) {
                    ForEach(scenarioFocusSummaries, id: \.focusKind) { entry in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(focusTitle(entry.focusKind))
                                    .font(AppTypography.subheadline.weight(.semibold))
                                    .foregroundStyle(AppColor.textPrimary)
                                Text("\("النقاط الضائعة".localized): \(entry.summary.lostExpectedPoints)")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                            Spacer()
                            Text("\(entry.summary.correct)/\(entry.summary.attempts)")
                                .font(AppTypography.caption.weight(.semibold))
                                .foregroundStyle(AppColor.textSecondary)
                            Text("\(entry.summary.accuracyPercent)%")
                                .font(AppTypography.subheadline.weight(.bold))
                                .foregroundStyle(entry.summary.accuracyPercent >= 70 ? AppColor.success : AppColor.accent)
                        }
                        .padding(AppSpacing.sm)
                        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            .padding(AppSpacing.md)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
        }
    }

    private func scenarioFocusCoverageView(_ coverage: WhatToPlayScenarioFocusCoverage) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(coverage.title)
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Text(coverage.detail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\("التغطية".localized): \(coverage.sampledFocusKinds)/\(coverage.totalFocusKinds)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(coverage.isBalanced ? AppColor.success : AppColor.accent)
            }
        } icon: {
            Image(systemName: coverage.iconName)
                .foregroundStyle(coverage.isBalanced ? AppColor.success : AppColor.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background((coverage.isBalanced ? AppColor.success : AppColor.accent).opacity(0.12), in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }

    private func practiceCoverageView(_ coverage: WhatToPlayPracticeCoverage) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(coverage.title)
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Text(coverage.detail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\("التغطية".localized): \(coverage.sampledDifficulties)/\(coverage.totalDifficulties)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(coverage.isBalanced ? AppColor.success : AppColor.accent)
            }
        } icon: {
            Image(systemName: coverage.iconName)
                .foregroundStyle(coverage.isBalanced ? AppColor.success : AppColor.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background((coverage.isBalanced ? AppColor.success : AppColor.accent).opacity(0.12), in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var recentAttemptsCard: some View {
        if !recentAttempts.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Label("آخر المحاولات", systemImage: "clock.arrow.circlepath")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.primary)

                VStack(spacing: AppSpacing.sm) {
                    ForEach(recentAttempts) { attempt in
                        recentAttemptRow(attempt)
                    }
                }
            }
            .padding(AppSpacing.md)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
        }
    }

    private func recentAttemptRow(_ attempt: WhatToPlayAttempt) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: attempt.isCorrect ? "checkmark.seal.fill" : "xmark.seal.fill")
                .foregroundStyle(attempt.isCorrect ? AppColor.success : AppColor.danger)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("\("اختيارك".localized): \(cardName(attempt.selectedCard))")
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text("\("أفضل ورقة".localized): \(cardName(attempt.bestCard))")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if let outcome = attempt.outcome {
                    Text(optionOutcomeText(outcome))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(optionOutcomeTint(outcome))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(attempt.difficulty.displayTitle)
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(AppColor.textSecondary)
                Text(impactText(attempt.expectedImpact))
                    .font(.caption2)
                    .foregroundStyle(attempt.expectedImpact >= 0 ? AppColor.success : AppColor.danger)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                if attempt.lostExpectedPoints > 0 {
                    Text("-\(attempt.lostExpectedPoints)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppColor.danger)
                        .accessibilityLabel("\("نقاط متوقعة ضائعة".localized): \(attempt.lostExpectedPoints)")
                }
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var reviewQueueCard: some View {
        if !reviewQueue.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Label("مراجعة الأخطاء المهمة".localized, systemImage: "text.magnifyingglass")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.primary)

                Text("ابدأ بهذه المحاولات لأنها الأكثر فائدة للمراجعة حسب الأثر المتوقع.".localized)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: AppSpacing.sm) {
                    ForEach(reviewQueue) { item in
                        reviewQueueRow(item)
                    }
                }
            }
            .padding(AppSpacing.md)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
        }
    }

    private func reviewQueueRow(_ item: WhatToPlayReviewItem) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: item.iconName)
                .foregroundStyle(item.expectedImpact < 0 ? AppColor.danger : AppColor.accent)
                .frame(width: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(item.title)
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Text(item.detail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: AppSpacing.xs) {
                    StatusBadge(item.difficulty.displayTitle, systemImage: "slider.horizontal.3", tint: AppColor.primary)
                    StatusBadge(impactText(item.expectedImpact), systemImage: "chart.line.downtrend.xyaxis", tint: item.expectedImpact < 0 ? AppColor.danger : AppColor.accent)
                    if item.lostExpectedPoints > 0 {
                        StatusBadge("\(item.lostExpectedPoints)", systemImage: "drop.fill", tint: AppColor.danger)
                    }
                }
                Text("\("اختيارك".localized): \(cardName(item.selectedCard)) · \("أفضل ورقة".localized): \(cardName(item.bestCard))")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                if let secondBestCard = item.secondBestCard {
                    Text("\("ثاني أفضل".localized): \(cardName(secondBestCard))\(secondBestImpactSuffix(item.secondBestExpectedImpact))")
                        .font(.caption2)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }

                Button {
                    replayReviewItem(item)
                } label: {
                    Label("إعادة الموقف".localized, systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(AppColor.primary)
                .disabled(isGeneratingScenario)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }

    private func secondBestImpactSuffix(_ impact: Int?) -> String {
        guard let impact else { return "" }
        return " · \(impactText(impact))"
    }

    private func scenarioSummary(_ scenario: WhatToPlayScenario) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label("الموقف", systemImage: "tablecells.fill")
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.primary)

            VStack(spacing: AppSpacing.xs) {
                InfoRow(icon: "number", title: "البذرة", value: "\(scenario.seed)")
                InfoRow(icon: "flag.checkered", title: "النمط", value: modeText(scenario.state))
                InfoRow(icon: "person.crop.circle.fill", title: "الدور", value: scenario.state.player(id: scenario.playerID)?.name ?? "أنت")
                InfoRow(icon: "list.number", title: "الأكلة", value: "\(scenario.state.completedTricks.count + 1) من 8")
                InfoRow(icon: "arrow.turn.up.left", title: "قراءة الدور".localized, value: turnContextText(scenario.context))
                InfoRow(icon: "scope", title: "تركيز التدريب".localized, value: focusText(scenario.context.focusKind))
                InfoRow(icon: "rectangle.stack.fill", title: "الأوراق القانونية".localized, value: "\(scenario.context.legalOptionCount)")
                if let requiredSuit = scenario.context.requiredSuit {
                    InfoRow(icon: "suit.club.fill", title: "اللون المطلوب".localized, value: requiredSuit.spokenName)
                }
                if scenario.context.hasTrumpInCurrentTrick {
                    InfoRow(icon: "crown.fill", title: "الحكم على الطاولة".localized, value: scenario.context.trumpSuit?.spokenName ?? "حاضر".localized)
                }
            }

            currentTrick(scenario)
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private func shareCardPreview(_ scenario: WhatToPlayScenario) -> some View {
        let content = WhatToPlayShareCard.content(for: scenario)
        return VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label("بطاقة المشاركة".localized, systemImage: "square.and.arrow.up")
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.primary)

            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(content.title)
                            .font(AppTypography.title)
                            .foregroundStyle(.white)
                        Text(content.subtitle)
                            .font(AppTypography.caption)
                            .foregroundStyle(.white.opacity(0.78))
                    }
                    Spacer(minLength: AppSpacing.md)
                    Text("Baloot Hub")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppColor.primary)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xxs)
                        .background(.white, in: Capsule())
                }

                HStack(spacing: AppSpacing.xs) {
                    shareMetric("النمط".localized, content.mode)
                    shareMetric("الأكلة".localized, content.trickProgress)
                    shareMetric("الدور".localized, content.turnPlayerName)
                }

                HStack(spacing: AppSpacing.xs) {
                    shareMetric("الصعوبة".localized, content.difficulty)
                    shareMetric("تركيز التدريب".localized, content.focus)
                }

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("الأوراق على الطاولة".localized)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.86))

                    if content.isOpeningTrick {
                        Text("أنت تفتتح الأكلة.".localized)
                            .font(AppTypography.caption)
                            .foregroundStyle(.white.opacity(0.78))
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.xs) {
                            ForEach(Array(content.tableCards.enumerated()), id: \.offset) { _, line in
                                shareChip("\(line.playerName): \(line.cardName)")
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("الأوراق القانونية".localized)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.86))

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.xs) {
                        ForEach(content.legalCardNames, id: \.self) { cardName in
                            shareChip(cardName)
                        }
                    }
                }

                Text(content.prompt)
                    .font(AppTypography.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, AppSpacing.xs)
            }
            .padding(AppSpacing.md)
            .background(
                LinearGradient(
                    colors: [AppColor.primary, AppColor.primary.opacity(0.72), AppColor.accent.opacity(0.78)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: AppRadius.large)
            )
            .accessibilityElement(children: .combine)
        }
    }

    private func shareMetric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.xs)
        .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: AppRadius.small))
    }

    private func shareChip(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: AppRadius.small))
    }

    private func currentTrick(_ scenario: WhatToPlayScenario) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("الأوراق على الطاولة")
                .font(AppTypography.subheadline.weight(.semibold))
                .foregroundStyle(AppColor.textPrimary)

            let played = scenario.state.currentTrick?.playedCards ?? []
            if played.isEmpty {
                Text("أنت تفتتح الأكلة.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.xs), count: 2), spacing: AppSpacing.xs) {
                    ForEach(Array(played.enumerated()), id: \.offset) { _, playedCard in
                        VStack(spacing: 4) {
                            MiniAnalysisCard(card: playedCard.card, isSelected: false)
                            Text(scenario.state.player(id: playedCard.playerID)?.name ?? "لاعب")
                                .font(.caption2)
                                .foregroundStyle(AppColor.textSecondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
    }

    private func legalOptions(_ scenario: WhatToPlayScenario) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("وش تلعب؟")
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.textPrimary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.xs), count: 4), spacing: AppSpacing.xs) {
                ForEach(scenario.options) { option in
                    Button {
                        choose(option, in: scenario)
                    } label: {
                        VStack(spacing: 6) {
                            MiniAnalysisCard(card: option.card, isSelected: selectedOption?.card == option.card)
                            Text(optionBadgeText(option))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(optionBadgeTint(option))
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(optionAccessibilityLabel(option))
                }
            }
        }
    }

    private func optionBadgeText(_ option: WhatToPlayOption) -> String {
        WhatToPlayOptionDisclosure.badgeText(rank: option.rank, isRevealed: selectedOption != nil)
    }

    private func optionBadgeTint(_ option: WhatToPlayOption) -> Color {
        guard selectedOption != nil else { return AppColor.textSecondary }
        return option.rank == 1 ? AppColor.success : AppColor.textSecondary
    }

    private func optionAccessibilityLabel(_ option: WhatToPlayOption) -> String {
        WhatToPlayOptionDisclosure.accessibilityLabel(
            cardName: option.card.accessibilityName,
            rank: option.rank,
            isRevealed: selectedOption != nil,
            isSelected: selectedOption?.card == option.card,
            isExpertChoice: option.isExpertChoice
        )
    }

    private func choose(_ option: WhatToPlayOption, in scenario: WhatToPlayScenario) {
        guard let evaluated = WhatToPlayTrainer.evaluateChoice(card: option.card, in: scenario) else { return }
        if selectedOption == nil, let bestCard = scenario.bestOption?.card {
            let attempt = WhatToPlayAttempt(
                difficulty: scenario.difficulty,
                seed: scenario.seed,
                selectedCard: evaluated.card,
                bestCard: bestCard,
                secondBestCard: scenario.secondBestOption?.card,
                isCorrect: evaluated.isExpertChoice,
                expectedImpact: evaluated.expectedImpact,
                bestExpectedImpact: scenario.bestOption?.expectedImpact,
                secondBestExpectedImpact: scenario.secondBestOption?.expectedImpact,
                focusKind: scenario.context.focusKind,
                outcome: evaluated.outcome
            )
            modelContext.insert(attempt)
            try? modelContext.save()
        }
        selectedOption = evaluated
    }

    private func resultCard(_ option: WhatToPlayOption, scenario: WhatToPlayScenario) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label(option.isExpertChoice ? "قرار مطابق للخبير" : "تحليل اختيارك", systemImage: option.isExpertChoice ? "checkmark.seal.fill" : "lightbulb.fill")
                .font(AppTypography.headline)
                .foregroundStyle(option.isExpertChoice ? AppColor.success : AppColor.primary)

            VStack(spacing: AppSpacing.xs) {
                InfoRow(icon: "hand.point.up.left.fill", title: "اختيارك", value: option.card.accessibilityName)
                if let best = scenario.bestOption {
                    InfoRow(icon: "star.fill", title: "أفضل ورقة", value: best.card.accessibilityName)
                }
                if let second = scenario.secondBestOption {
                    InfoRow(icon: "2.circle.fill", title: "ثاني أفضل", value: second.card.accessibilityName)
                }
                InfoRow(icon: "chart.line.uptrend.xyaxis", title: "الأثر المتوقع", value: impactText(option.expectedImpact))
                InfoRow(icon: optionOutcomeIcon(option.outcome), title: "نتيجة القرار".localized, value: optionOutcomeText(option.outcome))
            }

            Text(option.outcomeReason.localized)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if let insight = WhatToPlayStatsAnalyzer.decisionInsight(for: option, in: scenario) {
                decisionInsightView(insight)
            }

            if let review = WhatToPlayStatsAnalyzer.decisionReview(for: option, in: scenario) {
                decisionReviewView(review)
            }

            Text(option.explanation)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColor.textPrimary)
                .padding(AppSpacing.md)
                .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private func decisionInsightView(_ insight: WhatToPlayDecisionInsight) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Text(insight.detail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if insight.lostExpectedPoints > 0 {
                    Text("\("نقاط متوقعة ضائعة".localized): \(insight.lostExpectedPoints)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppColor.danger)
                }
                if let secondBestGap = insight.secondBestGap, secondBestGap > 0 {
                    Text("\("فارق عن ثاني أفضل".localized): \(secondBestGap)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppColor.accent)
                }
            }
        } icon: {
            Image(systemName: insight.iconName)
                .foregroundStyle(decisionInsightTint(insight.kind))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(decisionInsightTint(insight.kind).opacity(0.12), in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }

    private func decisionReviewView(_ review: WhatToPlayDecisionReview) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label(review.title, systemImage: review.iconName)
                .font(AppTypography.subheadline.weight(.semibold))
                .foregroundStyle(AppColor.primary)

            Text(review.detail)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: AppSpacing.xs) {
                ForEach(Array(review.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: AppSpacing.xs) {
                        Text("\(index + 1)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .background(AppColor.primary, in: Circle())
                            .accessibilityHidden(true)
                        Text(step)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColor.primary.opacity(0.10), in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }

    private func decisionInsightTint(_ kind: WhatToPlayDecisionInsightKind) -> Color {
        switch kind {
        case .expertMatch:
            AppColor.success
        case .closeAlternative:
            AppColor.accent
        case .missedWinningChance, .pointLeak:
            AppColor.danger
        }
    }

    private func optionComparisonCard(selectedOption: WhatToPlayOption, scenario: WhatToPlayScenario) -> some View {
        let rows = WhatToPlayOptionComparison.rows(for: scenario, selectedCard: selectedOption.card)
        return VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label("أثر كل قرار".localized, systemImage: "list.bullet.rectangle.fill")
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.primary)

            VStack(spacing: AppSpacing.sm) {
                ForEach(rows) { row in
                    optionComparisonRow(row)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private func optionComparisonRow(_ row: WhatToPlayOptionComparisonRow) -> some View {
        HStack(spacing: AppSpacing.sm) {
            MiniAnalysisCard(card: row.card, isSelected: row.isSelected)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: AppSpacing.xs) {
                    Text(row.card.accessibilityName)
                        .font(AppTypography.subheadline.weight(.semibold))
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    if row.isSelected {
                        StatusBadge("اختيارك".localized, systemImage: "hand.point.up.left.fill", tint: AppColor.accent)
                    }
                    if row.isExpertChoice {
                        StatusBadge("الأفضل".localized, systemImage: "star.fill", tint: AppColor.success)
                    }
                }
                Text("\("الترتيب".localized) \(row.rank)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                if row.lostExpectedPoints > 0 {
                    Text("\("فارق عن الأفضل".localized): \(row.lostExpectedPoints)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppColor.danger)
                }
                Text(optionOutcomeText(row.outcome))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(optionOutcomeTint(row.outcome))
                Text(row.rationale)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(row.outcomeReason.localized)
                    .font(.caption2)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Text(impactText(row.expectedImpact))
                .font(AppTypography.caption.weight(.semibold))
                .foregroundStyle(row.expectedImpact >= 0 ? AppColor.success : AppColor.danger)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(AppSpacing.sm)
        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }

    private func optionOutcomeText(_ outcome: WhatToPlayOptionOutcome) -> String {
        switch outcome {
        case .leadsTrick:
            "يفتتح الأكلة".localized
        case .developsTrick:
            "يبقي الأكلة مفتوحة".localized
        case .winsTrick:
            "يكسب الأكلة".localized
        case .losesTrick:
            "يخسر الأكلة".localized
        }
    }

    private func optionOutcomeIcon(_ outcome: WhatToPlayOptionOutcome) -> String {
        switch outcome {
        case .leadsTrick:
            "arrowshape.turn.up.forward.fill"
        case .developsTrick:
            "ellipsis.circle.fill"
        case .winsTrick:
            "checkmark.circle.fill"
        case .losesTrick:
            "xmark.circle.fill"
        }
    }

    private func optionOutcomeTint(_ outcome: WhatToPlayOptionOutcome) -> Color {
        switch outcome {
        case .winsTrick:
            AppColor.success
        case .losesTrick:
            AppColor.danger
        case .leadsTrick, .developsTrick:
            AppColor.accent
        }
    }

    private func generateScenario() {
        generationTask?.cancel()
        selectedOption = nil
        errorMessage = nil
        scenario = nil
        isGeneratingScenario = true

        let requestSeed = seed
        let requestDifficulty = difficulty
        let requestFocus = preferredFocus
        generationTask = Task {
            do {
                let generated = try await WhatToPlayScenarioLoader.generate(
                    seed: requestSeed,
                    difficulty: requestDifficulty,
                    preferredFocus: requestFocus
                )
                guard !Task.isCancelled else { return }
                scenario = generated
                errorMessage = nil
            } catch {
                guard !Task.isCancelled else { return }
                scenario = nil
                errorMessage = "تعذّر توليد موقف تدريبي صالح. جرّب موقفًا جديدًا.".localized
            }
            isGeneratingScenario = false
        }
    }

    private func nextScenario() {
        seed &+= 1
        generateScenario()
    }

    private func replayReviewItem(_ item: WhatToPlayReviewItem) {
        seed = item.seed
        preferredFocusRaw = item.focusKind?.rawValue ?? "auto"
        selectedOption = nil
        if difficulty == item.difficulty {
            generateScenario()
        } else {
            difficulty = item.difficulty
        }
    }

    private func startRecommendedPractice() {
        let targetFocusRaw = trainingSessionPlan.focusKind?.rawValue ?? "auto"
        if difficulty == trainingSessionPlan.difficulty, preferredFocusRaw == targetFocusRaw {
            nextScenario()
        } else {
            difficulty = trainingSessionPlan.difficulty
            preferredFocusRaw = targetFocusRaw
            generateScenario()
        }
    }

    private func modeText(_ state: GameState) -> String {
        guard let mode = state.mode else { return "غير محدد" }
        if mode == .hokum, let suit = state.trumpSuit {
            return "\(mode.arabicName) \(suit.spokenName)"
        }
        return mode.arabicName
    }

    private func turnContextText(_ context: WhatToPlayScenarioContext) -> String {
        if context.isLeading {
            return "أنت تفتتح الأكلة".localized
        }
        return "\("أنت ترد بعد".localized) \(context.playedCardCount) \("ورقة".localized)"
    }

    private func focusText(_ focusKind: WhatToPlayScenarioFocusKind) -> String {
        switch focusKind {
        case .openingLead:
            return "اختر افتتاحًا يحفظ قوتك ويقرأ رد الخصوم".localized
        case .followSuit:
            return "اتبع اللون المطلوب ووازن بين ربح الأكلة وتقليل الخسارة".localized
        case .trumpPressure:
            return "اقرأ الحكم المطروح قبل رمي ورقة عالية".localized
        case .narrowChoice:
            return "خياراتك محدودة؛ ركز على أقل ضرر ممكن".localized
        }
    }

    private func focusTitle(_ focusKind: WhatToPlayScenarioFocusKind) -> String {
        switch focusKind {
        case .openingLead:
            return "افتتاح الأكلة".localized
        case .followSuit:
            return "اتباع اللون".localized
        case .trumpPressure:
            return "ضغط الحكم".localized
        case .narrowChoice:
            return "خيارات محدودة".localized
        }
    }

    private func impactText(_ impact: Int) -> String {
        if impact > 0 { return "+\(impact) نقطة متوقعة" }
        if impact < 0 { return "\(impact) نقطة متوقعة" }
        return "أثر محايد"
    }

    private func cardName(_ card: PlayingCard?) -> String {
        card?.accessibilityName ?? "ورقة غير معروفة".localized
    }
}

private extension WhatToPlayDifficulty {
    var displayTitle: String {
        switch self {
        case .easy: "سهل"
        case .medium: "متوسط"
        case .hard: "صعب"
        }
    }
}

struct HandAnalyzerView: View {
    @State private var selectedCards: Set<PlayingCard> = []

    private var sortedSelectedCards: [PlayingCard] {
        selectedCards.sorted { lhs, rhs in
            if lhs.suit.ordinal != rhs.suit.ordinal { return lhs.suit.ordinal < rhs.suit.ordinal }
            return lhs.rank.sequenceOrder < rhs.rank.sequenceOrder
        }
    }

    private var analysis: HandAnalysis? {
        guard selectedCards.count == 8 else { return nil }
        return HandAnalyzer.analyze(hand: sortedSelectedCards)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                intro
                selectedHand
                cardPicker
                if let analysis {
                    analysisSummary(analysis)
                } else {
                    EmptyStateView(
                        systemImage: "hand.draw.fill",
                        title: "اختر 8 أوراق",
                        message: "بعد اكتمال اليد يعرض التطبيق تقييم القوة، أفضل شراء، المشاريع، ونصيحة تكتيكية."
                    )
                }
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.background)
        .navigationTitle("حلّل يدي")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("مسح") { selectedCards.removeAll() }
                    .disabled(selectedCards.isEmpty)
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("أدخل أوراقك يدويًا")
                .font(AppTypography.title)
                .foregroundStyle(AppColor.textPrimary)
            Text("التحليل يستخدم نفس تقييم اليد والمشاريع داخل BalootEngine، ولا يحتاج كاميرا أو اتصالًا بالإنترنت.")
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColor.textSecondary)
        }
    }

    private var selectedHand: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("يدك")
                    .font(AppTypography.headline)
                Spacer()
                Text("\(selectedCards.count) / 8")
                    .font(AppTypography.caption)
                    .foregroundStyle(selectedCards.count == 8 ? AppColor.success : AppColor.textSecondary)
            }

            if selectedCards.isEmpty {
                Text("لم تختر أوراقًا بعد.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.xs) {
                        ForEach(sortedSelectedCards) { card in
                            MiniAnalysisCard(card: card, isSelected: true)
                                .onTapGesture { selectedCards.remove(card) }
                        }
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.medium))
    }

    private var cardPicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("اختر الأوراق")
                .font(AppTypography.headline)

            ForEach(Suit.allCases) { suit in
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(suit.spokenName)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.xs), count: 4), spacing: AppSpacing.xs) {
                        ForEach(Rank.allCases) { rank in
                            let card = PlayingCard(suit: suit, rank: rank)
                            let selected = selectedCards.contains(card)
                            Button {
                                toggle(card)
                            } label: {
                                MiniAnalysisCard(card: card, isSelected: selected)
                            }
                            .buttonStyle(.plain)
                            .disabled(!selected && selectedCards.count >= 8)
                            .opacity(!selected && selectedCards.count >= 8 ? 0.35 : 1)
                            .accessibilityLabel("\(card.accessibilityName)\(selected ? "، مختارة" : "")")
                        }
                    }
                }
            }
        }
    }

    private func toggle(_ card: PlayingCard) {
        if selectedCards.contains(card) {
            selectedCards.remove(card)
        } else if selectedCards.count < 8 {
            selectedCards.insert(card)
        }
    }

    private func analysisSummary(_ analysis: HandAnalysis) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label("نتيجة التحليل", systemImage: "chart.bar.xaxis")
                .font(AppTypography.title)
                .foregroundStyle(AppColor.primary)

            VStack(spacing: AppSpacing.xs) {
                InfoRow(icon: "hand.thumbsup.fill", title: "التوصية", value: recommendationText(analysis.recommendedBid))
                InfoRow(icon: "gauge.with.dots.needle.67percent", title: "قوة اليد", value: "\(analysis.strengthScore)")
                InfoRow(icon: "checkmark.seal.fill", title: "الثقة", value: confidenceText(analysis.confidence))
                InfoRow(icon: "sun.max.fill", title: "تقييم الصن", value: "\(analysis.evaluation.sunScore)")
                if let best = analysis.evaluation.bestHokum {
                    InfoRow(icon: "crown.fill", title: "أفضل حكم", value: "\(best.suit.spokenName) · \(best.score)")
                }
                InfoRow(icon: "star.fill", title: "المشاريع", value: projectsText(analysis.projects))
            }

            Text(adviceText(analysis))
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColor.textPrimary)
                .padding(AppSpacing.md)
                .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private func recommendationText(_ bid: Bid) -> String {
        switch bid {
        case .pass:
            return "بس"
        case .sun:
            return "اشترِ صن"
        case .hokum(let suit):
            return "اشترِ حكم \(suit.spokenName)"
        }
    }

    private func confidenceText(_ confidence: HandAnalysis.Confidence) -> String {
        switch confidence {
        case .low: "منخفضة"
        case .medium: "متوسطة"
        case .high: "عالية"
        }
    }

    private func projectsText(_ projects: [Project]) -> String {
        guard !projects.isEmpty else { return "لا يوجد" }
        return projects
            .map { "\($0.kind.arabicName) \($0.points)" }
            .joined(separator: " · ")
    }

    private func adviceText(_ analysis: HandAnalysis) -> String {
        switch analysis.recommendedBid {
        case .pass:
            return "اليد لا تتجاوز عتبة شراء آمنة حاليًا. الأفضل التمرير وانتظار فرصة أوضح بدل شراء ضعيف يعرّض الفريق للطياح."
        case .sun:
            return "قوة اليد في الصن أعلى من الحكم. اعتمد على الآسات والعشرات، وحاول حماية أوراق الشريك بدل تحويل الجولة إلى حكم بلا سيطرة واضحة."
        case .hokum(let suit):
            let projectHint = analysis.totalProjectPoints > 0 ? " ومعك مشاريع تضيف \(analysis.totalProjectPoints) نقطة" : ""
            return "أفضلية اليد في \(suit.spokenName) واضحة\(projectHint). الشراء مناسب إذا لم تظهر مزايدة أقوى من الخصم."
        }
    }
}

private struct MiniAnalysisCard: View {
    let card: PlayingCard
    let isSelected: Bool

    private var isRed: Bool { card.suit.isRed }

    var body: some View {
        HStack(spacing: 4) {
            Text(card.rank.shortLabel)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
            Text(card.suit.symbol)
                .font(.subheadline)
        }
        .foregroundStyle(isRed ? AppColor.danger : AppColor.textPrimary)
        .minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity)
        .frame(height: 42)
        .background(isSelected ? AppColor.primary.opacity(0.16) : AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.small))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.small).stroke(isSelected ? AppColor.primary : AppColor.border, lineWidth: isSelected ? 2 : 1))
    }
}
