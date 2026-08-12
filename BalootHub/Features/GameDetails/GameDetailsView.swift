import SwiftUI
import SwiftData
import UIKit
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
                    appEnvironment.navigate(to: .balootAcademy(), tab: appEnvironment.selectedTab)
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
                    appEnvironment.navigate(to: .whatToPlayTrainer(), tab: appEnvironment.selectedTab)
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

            if item.slug == "baloot-career-mode" {
                Button {
                    appEnvironment.navigate(to: .careerMode, tab: appEnvironment.selectedTab)
                } label: {
                    Label("فتح المسيرة".localized, systemImage: "flag.checkered")
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

            if item.slug == "baloot-sandbox" {
                Button {
                    appEnvironment.navigate(to: .balootSandbox, tab: appEnvironment.selectedTab)
                } label: {
                    Label("فتح المختبر".localized, systemImage: "slider.horizontal.3")
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

            if item.isBalootModeReference {
                Button {
                    appEnvironment.navigate(to: .balootGamePlay(slug: "baloot-classic"), tab: appEnvironment.selectedTab)
                } label: {
                    Label("العب البلوت الكامل: صن وحكم في نفس الطاولة", systemImage: "suit.spade.fill")
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

struct InfoRow: View {
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
    @Environment(\.displayScale) private var displayScale
    @Query(sort: \WhatToPlayAttempt.createdAt, order: .reverse) private var attempts: [WhatToPlayAttempt]

    @State private var difficulty: WhatToPlayDifficulty = .medium
    @State private var preferredFocusRaw = "auto"
    @State private var preferredModeRaw = "auto"
    @State private var seed: UInt64 = 2026
    @State private var scenario: WhatToPlayScenario?
    @State private var selectedOption: WhatToPlayOption?
    @State private var errorMessage: String?
    @State private var illegalMoveExplanation: String?
    @State private var isGeneratingScenario = false
    @State private var isRetryingCurrentScenario = false
    @State private var generationTask: Task<Void, Never>?
    @State private var replayPresentation: WhatToPlayReplayPresentation?
    @State private var pendingReviewSelection: PlayingCard?
    @State private var shareImageURL: URL?
    @State private var isRenderingShareImage = false

    init(
        seed: UInt64? = nil,
        difficulty: WhatToPlayDifficulty? = nil,
        preferredFocus: WhatToPlayScenarioFocusKind? = nil
    ) {
        let storedPreferences = WhatToPlayTrainerPreferences.load()
        _difficulty = State(initialValue: difficulty ?? storedPreferences.difficulty)
        _preferredFocusRaw = State(initialValue: (preferredFocus ?? storedPreferences.preferredFocus)?.rawValue ?? "auto")
        _preferredModeRaw = State(initialValue: storedPreferences.preferredMode?.rawValue ?? "auto")
        _seed = State(initialValue: seed ?? 2026)
    }

    private var statsSummary: WhatToPlayStatsSummary {
        WhatToPlayStatsAnalyzer.summarize(attempts: attempts)
    }

    private var outcomeSummary: WhatToPlayOutcomeSummary {
        WhatToPlayStatsAnalyzer.outcomeSummary(for: attempts)
    }

    private var choiceRankSummary: WhatToPlayChoiceRankSummary {
        WhatToPlayStatsAnalyzer.choiceRankSummary(for: attempts)
    }

    private var decisionQualitySummary: WhatToPlayDecisionQualitySummary {
        WhatToPlayStatsAnalyzer.decisionQualitySummary(for: attempts)
    }

    private var decisionQualityInsight: WhatToPlayDecisionQualityInsight? {
        WhatToPlayStatsAnalyzer.decisionQualityInsight(for: decisionQualitySummary)
    }

    private var choiceRankInsight: WhatToPlayChoiceRankInsight? {
        WhatToPlayStatsAnalyzer.choiceRankInsight(for: choiceRankSummary)
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

    private var gameModeSummaries: [WhatToPlayGameModeSummary] {
        WhatToPlayStatsAnalyzer.summariesByGameMode(attempts)
    }

    private var scenarioFocusCoverage: WhatToPlayScenarioFocusCoverage {
        WhatToPlayStatsAnalyzer.scenarioFocusCoverage(for: attempts)
    }

    private var focusTrainingPriority: WhatToPlayFocusTrainingPriority? {
        WhatToPlayStatsAnalyzer.focusTrainingPriority(for: attempts)
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

    private var valueProgress: WhatToPlayValueProgress? {
        WhatToPlayStatsAnalyzer.valueProgress(attempts: attempts)
    }

    private var practiceRecommendation: WhatToPlayPracticeRecommendation {
        WhatToPlayStatsAnalyzer.practiceRecommendation(for: attempts)
    }

    private var trainingSessionPlan: WhatToPlayTrainingSessionPlan {
        WhatToPlayStatsAnalyzer.trainingSessionPlan(for: attempts)
    }

    private var nextScenarioRecommendation: WhatToPlayNextScenarioRecommendation {
        WhatToPlayStatsAnalyzer.nextScenarioRecommendation(for: attempts)
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

    private var bestDecisionHighlight: WhatToPlayDecisionHighlight? {
        WhatToPlayStatsAnalyzer.bestDecisionHighlight(for: attempts)
    }

    private var worstDecisionHighlight: WhatToPlayDecisionHighlight? {
        WhatToPlayStatsAnalyzer.worstDecisionHighlight(for: attempts)
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

    private var trainingSessionReview: WhatToPlayTrainingSessionReview {
        WhatToPlayStatsAnalyzer.trainingSessionReview(
            for: trainingSessionProgress,
            attempts: attempts,
            plan: trainingSessionPlan
        )
    }

    private var preferredFocus: WhatToPlayScenarioFocusKind? {
        WhatToPlayScenarioFocusKind(rawValue: preferredFocusRaw)
    }

    private var preferredMode: GameMode? {
        GameMode(rawValue: preferredModeRaw)
    }

    private func saveTrainerPreferences() {
        WhatToPlayTrainerPreferences.save(
            difficulty: difficulty,
            preferredFocus: preferredFocus,
            preferredMode: preferredMode
        )
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
                blockedCardsView(scenario)
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
            saveTrainerPreferences()
            seed = WhatToPlayScenarioLoader.unattemptedSeed(
                startingAt: seed,
                difficulty: difficulty,
                preferredFocus: preferredFocus,
                preferredMode: preferredMode,
                attempts: attempts
            )
            generateScenario()
        }
        .onChange(of: preferredFocusRaw) { _, _ in
            saveTrainerPreferences()
            seed = WhatToPlayScenarioLoader.unattemptedSeed(
                startingAt: seed,
                difficulty: difficulty,
                preferredFocus: preferredFocus,
                preferredMode: preferredMode,
                attempts: attempts
            )
            generateScenario()
        }
        .onChange(of: preferredModeRaw) { _, _ in
            saveTrainerPreferences()
            seed = WhatToPlayScenarioLoader.unattemptedSeed(
                startingAt: seed,
                difficulty: difficulty,
                preferredFocus: preferredFocus,
                preferredMode: preferredMode,
                attempts: attempts
            )
            generateScenario()
        }
        .onDisappear {
            generationTask?.cancel()
        }
        .sheet(item: $replayPresentation) { presentation in
            NavigationStack {
                RoundReplayView(
                    initialState: presentation.replay.initialState,
                    actions: presentation.replay.actions,
                    title: presentation.title,
                    contextText: presentation.contextText,
                    initialStep: presentation.initialStep,
                    visiblePlayerID: presentation.replay.playerID
                )
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if let scenario {
                    Menu {
                        if let shareImageURL {
                            ShareLink(item: shareImageURL) {
                                Label("مشاركة بطاقة كصورة".localized, systemImage: "photo")
                            }
                        } else {
                            Button {
                                renderShareImageForCurrentScenario()
                            } label: {
                                Label(
                                    isRenderingShareImage ? "جاري تجهيز صورة المشاركة".localized : "تجهيز صورة المشاركة".localized,
                                    systemImage: "photo"
                                )
                            }
                            .disabled(isRenderingShareImage)
                        }

                        ShareLink(item: WhatToPlayShareCard.text(for: scenario, selectedOption: selectedOption)) {
                            Label("مشاركة كنص".localized, systemImage: "text.quote")
                        }
                    } label: {
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

            Picker("النمط", selection: $preferredModeRaw) {
                Text("تلقائي".localized).tag("auto")
                ForEach(GameMode.allCases, id: \.self) { mode in
                    Text(modeTitle(mode)).tag(mode.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("النمط".localized)

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
            nextScenarioRecommendationView(nextScenarioRecommendation)

            Button {
                startNextScenarioRecommendation()
            } label: {
                Label(
                    "\("ابدأ".localized) \(nextScenarioRecommendation.difficulty.displayTitle)",
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

    private func nextScenarioRecommendationView(_ recommendation: WhatToPlayNextScenarioRecommendation) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(recommendation.title)
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Text(recommendation.detail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\("المستوى".localized): \(recommendation.difficulty.displayTitle) · \("تركيز التدريب".localized): \(recommendation.focusKind.map(focusTitle) ?? "تلقائي".localized)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppColor.accent)
            }
        } icon: {
            Image(systemName: recommendation.iconName)
                .foregroundStyle(AppColor.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(AppColor.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
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
                miniPlanMetric(title: "هدف الأثر".localized, value: "≥ \(impactText(plan.targetAverageExpectedImpact))")
            }

            Label(plan.successMetric, systemImage: "checkmark.circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColor.success)
                .fixedSize(horizontal: false, vertical: true)

            trainingSessionProgressView(progress)
            trainingSessionReviewView(trainingSessionReview)
        }
        .padding(AppSpacing.sm)
        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .contain)
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

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: AppSpacing.xs),
                GridItem(.flexible(), spacing: AppSpacing.xs)
            ], spacing: AppSpacing.xs) {
                miniPlanMetric(
                    title: "المكتمل".localized,
                    value: "\(progress.completedAttempts) \("من".localized) \(progress.targetAttempts)"
                )
                miniPlanMetric(
                    title: "الدقة الحالية".localized,
                    value: "\(progress.accuracyPercent)%"
                )
                miniPlanMetric(
                    title: "أفضل دقة ممكنة".localized,
                    value: "\(progress.bestPossibleAccuracyPercent)%"
                )
                miniPlanMetric(
                    title: "متوسط الأثر".localized,
                    value: impactText(progress.averageExpectedImpact)
                )
                miniPlanMetric(
                    title: "أثر الجلسة".localized,
                    value: impactText(progress.totalExpectedImpact)
                )
                if let bestExpectedImpact = progress.bestExpectedImpact {
                    miniPlanMetric(
                        title: "أفضل أثر".localized,
                        value: sessionImpactExtremeText(
                            bestExpectedImpact,
                            card: progress.bestExpectedImpactCard,
                            seed: progress.bestExpectedImpactSeed
                        )
                    )
                }
                if let worstExpectedImpact = progress.worstExpectedImpact {
                    miniPlanMetric(
                        title: "أسوأ أثر".localized,
                        value: sessionImpactExtremeText(
                            worstExpectedImpact,
                            card: progress.worstExpectedImpactCard,
                            seed: progress.worstExpectedImpactSeed
                        )
                    )
                }
                miniPlanMetric(
                    title: "باقي للدقة".localized,
                    value: "\(progress.correctAttemptsNeededForTarget)"
                )
                miniPlanMetric(
                    title: "فجوة الأثر".localized,
                    value: impactGapText(progress.averageExpectedImpactGap)
                )
                if progress.expectedImpactNeededForTarget > 0 {
                    miniPlanMetric(
                        title: "أثر مطلوب".localized,
                        value: impactText(progress.expectedImpactNeededForTarget)
                    )
                    if progress.expectedImpactNeededPerRemainingAttempt > 0 {
                        miniPlanMetric(
                            title: "لكل موقف متبقٍ".localized,
                            value: impactText(progress.expectedImpactNeededPerRemainingAttempt)
                        )
                    }
                }
                if progress.valueCaptureAttempts > 0 {
                    miniPlanMetric(
                        title: "التقاط القيمة".localized,
                        value: "\(progress.valueCapturePercent)%"
                    )
                }
                if progress.lostExpectedPoints > 0 {
                    miniPlanMetric(
                        title: "نقاط ضائعة".localized,
                        value: "\(progress.lostExpectedPoints)"
                    )
                    miniPlanMetric(
                        title: "متوسط الضياع".localized,
                        value: impactText(progress.averageLostExpectedPoints)
                    )
                }
                if progress.projectedTeamPointAttempts > 0 && progress.lostProjectedTeamPoints > 0 {
                    miniPlanMetric(
                        title: "نقاط محاكاة ضائعة".localized,
                        value: "\(progress.lostProjectedTeamPoints)"
                    )
                    miniPlanMetric(
                        title: "متوسط فاقد المحاكاة".localized,
                        value: "\(progress.averageLostProjectedTeamPoints)"
                    )
                }
                if let maxCostlyDecisions = progress.maxCostlyDecisions {
                    miniPlanMetric(
                        title: "قرارات مكلفة".localized,
                        value: "\(progress.costlyDecisions)/\(maxCostlyDecisions)"
                    )
                }
            }

            HStack(spacing: AppSpacing.xs) {
                sessionTargetBadge(
                    title: progress.accuracyTargetMet ? "تحقق هدف الدقة".localized : "لم يتحقق هدف الدقة".localized,
                    isMet: progress.accuracyTargetMet
                )
                sessionTargetBadge(
                    title: progress.accuracyTargetReachable ? "هدف الدقة ممكن".localized : "هدف الدقة غير ممكن".localized,
                    isMet: progress.accuracyTargetReachable
                )
                sessionTargetBadge(
                    title: progress.impactTargetMet ? "تحقق هدف الأثر".localized : "لم يتحقق هدف الأثر".localized,
                    isMet: progress.impactTargetMet
                )
                if progress.expectedImpactNeededForTarget > 0 {
                    sessionTargetBadge(
                        title: progress.impactRecoveryHighPressure ? "ضغط الأثر مرتفع".localized : "ضغط الأثر طبيعي".localized,
                        isMet: !progress.impactRecoveryHighPressure
                    )
                }
                if progress.maxCostlyDecisions != nil {
                    sessionTargetBadge(
                        title: progress.costlyDecisionTargetMet ? "تحقق هدف القرارات المكلفة".localized : "لم يتحقق هدف القرارات المكلفة".localized,
                        isMet: progress.costlyDecisionTargetMet
                    )
                }
            }

            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(progress.gradeTitle) · \(progress.gradePercent)/100")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppColor.textPrimary)
                    Text(progress.gradeDetail)
                        .font(.caption2)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } icon: {
                Image(systemName: progress.gradeIconName)
                    .foregroundStyle(sessionGradeTint(progress.gradePercent, completed: progress.completedAttempts))
            }
            .padding(.top, AppSpacing.xs)

            HStack(spacing: AppSpacing.xs) {
                miniPlanMetric(
                    title: "مكون الدقة".localized,
                    value: "\(progress.gradeAccuracyComponent)%"
                )
                miniPlanMetric(
                    title: "مكون الأثر".localized,
                    value: "\(progress.gradeImpactComponent)%"
                )
            }

            Text("\(progress.gradeReasonTitle): \(progress.gradeReasonDetail)")
                .font(.caption2)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(progress.impactTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppColor.textPrimary)
                    Text(progress.impactDetail)
                        .font(.caption2)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } icon: {
                Image(systemName: progress.impactIconName)
                    .foregroundStyle(sessionImpactTint(progress.averageExpectedImpact, completed: progress.completedAttempts))
            }
            .padding(.top, AppSpacing.xs)

            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(progress.nextStepTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppColor.textPrimary)
                    Text(progress.nextStepDetail)
                        .font(.caption2)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } icon: {
                Image(systemName: progress.nextStepIconName)
                    .foregroundStyle(AppColor.primary)
            }
            .padding(.top, AppSpacing.xs)

            Button {
                applyTrainingSessionNextStep(progress)
            } label: {
                Label(trainingSessionNextStepButtonTitle(progress), systemImage: progress.nextStepIconName)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(progress.state == .needsRepeat ? AppColor.warning : AppColor.primary)
            .disabled(isGeneratingScenario)

            if let reviewItem = progress.reviewItem {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Label("أهم موقف للمراجعة".localized, systemImage: reviewItem.iconName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppColor.danger)
                    Text(reviewItem.detail)
                        .font(.caption2)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\("اختيارك".localized): \(cardName(reviewItem.selectedCard)) · \("أفضل ورقة".localized): \(cardName(reviewItem.bestCard))")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                    if let secondBestCard = reviewItem.secondBestCard {
                        Text("\("ثاني أفضل".localized): \(cardName(secondBestCard))\(secondBestImpactSuffix(reviewItem.secondBestExpectedImpact))")
                            .font(.caption2)
                            .foregroundStyle(AppColor.textSecondary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                    }
                    reviewSimulationView(reviewItem)
                    Button {
                        replayReviewItem(reviewItem)
                    } label: {
                        Label("إعادة الموقف".localized, systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(AppColor.primary)
                    .disabled(isGeneratingScenario)
                }
                .padding(AppSpacing.sm)
                .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
            }
        }
        .padding(.top, AppSpacing.xs)
    }

    private func trainingSessionReviewView(_ review: WhatToPlayTrainingSessionReview) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(review.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Text(review.detail)
                    .font(.caption2)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\("المستوى".localized): \(review.difficulty?.displayTitle ?? "تلقائي".localized) · \("تركيز التدريب".localized): \(review.focusKind.map(focusTitle) ?? "تلقائي".localized)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppColor.accent)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
        } icon: {
            Image(systemName: review.iconName)
                .foregroundStyle(AppColor.accent)
        }
        .padding(AppSpacing.sm)
        .background(AppColor.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }

    private func sessionTargetBadge(title: String, isMet: Bool) -> some View {
        Label(title, systemImage: isMet ? "checkmark.circle.fill" : "xmark.circle.fill")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(isMet ? AppColor.success : AppColor.danger)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.xs)
            .padding(.horizontal, AppSpacing.xs)
            .background(
                (isMet ? AppColor.success : AppColor.danger).opacity(0.12),
                in: RoundedRectangle(cornerRadius: AppRadius.small)
            )
    }

    private func sessionImpactExtremeText(_ impact: Int, card: PlayingCard?, seed: UInt64?) -> String {
        var parts = [impactText(impact)]
        if let card {
            parts.append(card.displayLabel)
        }
        if let seed {
            parts.append("\("البذرة".localized) \(seed)")
        }
        return parts.joined(separator: " · ")
    }

    private func trainingSessionNextStepButtonTitle(_ progress: WhatToPlayTrainingSessionProgress) -> String {
        switch progress.state {
        case .notStarted:
            "ابدأ الجلسة".localized
        case .inProgress:
            "متابعة الجلسة".localized
        case .achieved:
            "انتقل للتحدي التالي".localized
        case .needsRepeat:
            "إعادة الخطة".localized
        }
    }

    private func sessionImpactTint(_ averageImpact: Int, completed: Int) -> Color {
        guard completed > 0 else { return AppColor.textSecondary }
        if averageImpact > 0 { return AppColor.success }
        if averageImpact == 0 { return AppColor.accent }
        return AppColor.danger
    }

    private func sessionGradeTint(_ grade: Int, completed: Int) -> Color {
        guard completed > 0 else { return AppColor.textSecondary }
        if grade >= 85 { return AppColor.success }
        if grade >= 70 { return AppColor.accent }
        if grade >= 50 { return AppColor.warning }
        return AppColor.danger
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
            } else if let seed = microDrill.seed,
                      let difficulty = microDrill.difficulty {
                Button {
                    startMicroDrill(scenarioSeed: seed, difficulty: difficulty, focusKind: microDrill.focusKind)
                } label: {
                    Label("بدء الخطة المصغرة".localized, systemImage: "play.circle.fill")
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
                if let bestDecisionHighlight {
                    decisionHighlightView(
                        title: "أفضل قرار".localized,
                        icon: "checkmark.seal.fill",
                        highlight: bestDecisionHighlight,
                        tint: AppColor.success
                    )
                }
                if let worstDecisionHighlight, worstDecisionHighlight.totalLoss > 0 {
                    decisionHighlightView(
                        title: "أسوأ قرار".localized,
                        icon: "exclamationmark.triangle.fill",
                        highlight: worstDecisionHighlight,
                        tint: AppColor.danger
                    )
                }
                if statsSummary.valueCaptureAttempts > 0 {
                    InfoRow(
                        icon: "speedometer",
                        title: "التقاط القيمة".localized,
                        value: "\(statsSummary.valueCapturePercent)%"
                    )
                    Text("\("محاولات القيمة".localized): \(statsSummary.valueCaptureAttempts)")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }
                if statsSummary.projectedTeamPointAttempts > 0 {
                    InfoRow(
                        icon: "chart.bar.xaxis",
                        title: "متوسط نقاط المحاكاة".localized,
                        value: "\(statsSummary.averageProjectedTeamPoints)"
                    )
                    if statsSummary.lostProjectedTeamPoints > 0 {
                        InfoRow(
                            icon: "arrow.down.forward.circle.fill",
                            title: "نقاط محاكاة ضائعة".localized,
                            value: "\(statsSummary.lostProjectedTeamPoints)"
                        )
                        InfoRow(
                            icon: "chart.bar.doc.horizontal.fill",
                            title: "متوسط ضياع المحاكاة".localized,
                            value: "\(statsSummary.averageLostProjectedTeamPoints)"
                        )
                    }
                    Text("\("محاولات المحاكاة".localized): \(statsSummary.projectedTeamPointAttempts)")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }
                if statsSummary.lostExpectedPoints > 0 {
                    InfoRow(
                        icon: "drop.fill",
                        title: "نقاط متوقعة ضائعة".localized,
                        value: "\(statsSummary.lostExpectedPoints)"
                    )
                    InfoRow(
                        icon: "chart.bar.doc.horizontal.fill",
                        title: "متوسط النقاط الضائعة".localized,
                        value: impactText(statsSummary.averageLostExpectedPoints)
                    )
                }
                if statsSummary.secondBestComparisonAttempts > 0 {
                    InfoRow(
                        icon: "arrow.left.and.right",
                        title: "فارق عن ثاني أفضل".localized,
                        value: "\(statsSummary.lostAgainstSecondBestPoints)"
                    )
                    InfoRow(
                        icon: "chart.bar.fill",
                        title: "متوسط الفارق".localized,
                        value: impactText(statsSummary.averageSecondBestGap)
                    )
                    Text("\("محاولات المقارنة".localized): \(statsSummary.secondBestComparisonAttempts)")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }
                if outcomeSummary.trackedAttempts > 0 {
                    outcomeSummaryView(outcomeSummary, insight: outcomeInsight)
                }
                if choiceRankSummary.trackedAttempts > 0 {
                    choiceRankSummaryView(choiceRankSummary, insight: choiceRankInsight)
                }
                if decisionQualitySummary.trackedAttempts > 0 {
                    decisionQualitySummaryView(decisionQualitySummary, insight: decisionQualityInsight)
                }
                masteryView(mastery, milestone: masteryMilestone)
                playStyleView(playStyle)
                decisionPatternView(decisionPattern)
                sessionPulseView(sessionPulse)
                coachingTipView(coachingTip)
                if let performanceTrend {
                    performanceTrendView(performanceTrend)
                }
                if let valueProgress {
                    valueProgressView(valueProgress)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private func decisionHighlightView(
        title: String,
        icon: String,
        highlight: WhatToPlayDecisionHighlight,
        tint: Color
    ) -> some View {
        let cardName = highlight.selectedCard?.accessibilityName ?? "غير محدد".localized
        let loss = highlight.totalLoss
        let detail = loss > 0
            ? "\("فاقد القرار".localized): \(loss)"
            : "\("أثر القرار".localized): \(impactText(highlight.expectedImpact))"
        return InfoRow(icon: icon, title: title, value: "\(cardName) · \(detail)")
            .foregroundStyle(tint)
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

    private func choiceRankSummaryView(
        _ summary: WhatToPlayChoiceRankSummary,
        insight: WhatToPlayChoiceRankInsight?
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label("قربك من اختيار الخبير".localized, systemImage: "list.number")
                .font(AppTypography.subheadline.weight(.semibold))
                .foregroundStyle(AppColor.textPrimary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.xs), count: 3), spacing: AppSpacing.xs) {
                miniMetric("اختيار الخبير".localized, "\(summary.expertPicks)", AppColor.success)
                miniMetric("ثاني أفضل".localized, "\(summary.secondBestPicks)", AppColor.accent)
                miniMetric("اختيارات بعيدة".localized, "\(summary.farPicks)", AppColor.danger)
            }

            Text("\("محاولات مفحوصة".localized): \(summary.trackedAttempts) · \("نسبة اختيار الخبير".localized): \(summary.expertPickPercent)% · \("نسبة الاقتراب من ثاني أفضل".localized): \(summary.nearMissPercent)% · \("نسبة الاختيارات البعيدة".localized): \(summary.farPickPercent)%")
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
                        .foregroundStyle(choiceRankInsightTint(insight.kind))
                }
                .padding(.top, AppSpacing.xs)
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }

    private func decisionQualitySummaryView(
        _ summary: WhatToPlayDecisionQualitySummary,
        insight: WhatToPlayDecisionQualityInsight?
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label("جودة قراراتك".localized, systemImage: "gauge.with.dots.needle.67percent")
                .font(AppTypography.subheadline.weight(.semibold))
                .foregroundStyle(AppColor.textPrimary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.xs), count: 2), spacing: AppSpacing.xs) {
                miniMetric("مطابق أو قريب".localized, "\(summary.expertMatches + summary.closeDecisions)", AppColor.success)
                miniMetric("قرار مقبول".localized, "\(summary.acceptableDecisions)", AppColor.warning)
                miniMetric("قرار مكلف".localized, "\(summary.costlyDecisions)", AppColor.danger)
                miniMetric("قوة القرار".localized, "\(summary.strongPercent)%", AppColor.accent)
            }

            Text("\("محاولات مفحوصة".localized): \(summary.trackedAttempts) · \("نسبة القرارات المكلفة".localized): \(summary.costlyPercent)%")
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
                        .foregroundStyle(decisionQualityInsightTint(insight.kind))
                }
                .padding(.top, AppSpacing.xs)
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }

    private func decisionQualityInsightTint(_ kind: WhatToPlayDecisionQualityInsightKind) -> Color {
        switch kind {
        case .strong:
            AppColor.success
        case .costly:
            AppColor.danger
        case .mixed:
            AppColor.accent
        }
    }

    private func choiceRankInsightTint(_ kind: WhatToPlayChoiceRankInsightKind) -> Color {
        switch kind {
        case .expertAligned:
            AppColor.success
        case .nearMisses:
            AppColor.accent
        case .farChoices:
            AppColor.danger
        }
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
        case .farRankChoices:
            AppColor.warning
        case .pointLeaks, .opponentTrickClosure, .unprotectedPointDump, .costlyOpeningLead:
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

    private func valueProgressView(_ progress: WhatToPlayValueProgress) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(progress.title)
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Text(progress.detail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\("البداية".localized): \(progress.earlyCapturePercent)% · \("الآن".localized): \(progress.recentCapturePercent)% · \("الفارق".localized): \(signedPercent(progress.deltaPercent))")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(valueProgressTint(progress.direction))
                Text("\("محاولات مفحوصة".localized): \(progress.inspectedAttempts)")
                    .font(.caption2)
                    .foregroundStyle(AppColor.textSecondary)
            }
        } icon: {
            Image(systemName: progress.iconName)
                .foregroundStyle(valueProgressTint(progress.direction))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(valueProgressTint(progress.direction).opacity(0.12), in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }

    private func valueProgressTint(_ direction: WhatToPlayTrendDirection) -> Color {
        switch direction {
        case .improving:
            AppColor.success
        case .stable:
            AppColor.accent
        case .declining:
            AppColor.danger
        }
    }

    private func signedPercent(_ value: Int) -> String {
        value > 0 ? "+\(value)%" : "\(value)%"
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

                gameModeStatsView(gameModeSummaries)
                practiceCoverageView(practiceCoverage)
            }
            .padding(AppSpacing.md)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
        }
    }

    @ViewBuilder
    private func gameModeStatsView(_ summaries: [WhatToPlayGameModeSummary]) -> some View {
        if !summaries.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Label("الأداء حسب النمط".localized, systemImage: "flag.checkered")
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: AppSpacing.xs),
                    GridItem(.flexible(), spacing: AppSpacing.xs)
                ], spacing: AppSpacing.xs) {
                    ForEach(summaries, id: \.mode) { entry in
                        VStack(alignment: .leading, spacing: 2) {
                            Label(modeTitle(entry.mode), systemImage: entry.mode == .hokum ? "crown.fill" : "sun.max.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppColor.textPrimary)
                            Text("\(entry.summary.correct)/\(entry.summary.attempts) · \(entry.summary.accuracyPercent)%")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(entry.summary.accuracyPercent >= 70 ? AppColor.success : AppColor.textSecondary)
                            Text("\("متوسط الأثر".localized): \(impactText(entry.summary.averageExpectedImpact))")
                                .font(.caption2)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AppSpacing.sm)
                        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            .padding(AppSpacing.sm)
            .background(AppColor.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: AppRadius.medium))
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

                if let focusTrainingPriority {
                    focusTrainingPriorityView(focusTrainingPriority)
                }

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

    private func focusTrainingPriorityView(_ priority: WhatToPlayFocusTrainingPriority) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(priority.title)
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Text(priority.detail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\("الدقة".localized): \(priority.summary.accuracyPercent)% · \("النقاط الضائعة".localized): \(priority.summary.lostExpectedPoints)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(priority.summary.lostExpectedPoints > 0 ? AppColor.danger : AppColor.accent)
            }
        } icon: {
            Image(systemName: priority.iconName)
                .foregroundStyle(priority.summary.lostExpectedPoints > 0 ? AppColor.danger : AppColor.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background((priority.summary.lostExpectedPoints > 0 ? AppColor.danger : AppColor.accent).opacity(0.12), in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
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
                if let breakdown = attempt.impactBreakdown {
                    Text(WhatToPlayImpactFormatter.detail(for: breakdown))
                        .font(.caption2)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                attemptSimulationView(attempt)
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
    private func attemptSimulationView(_ attempt: WhatToPlayAttempt) -> some View {
        if let simulationDisplay = WhatToPlaySimulationFormatter.display(for: attempt) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\("نتيجة المحاكاة".localized): \(simulationDisplay.summary)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let teamResult = simulationDisplay.teamResult {
                    Text("\("اتجاه الأكلة".localized): \(teamResult)\(simulationPointsSuffix(simulationDisplay.trickPoints))")
                        .font(.caption2)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
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
        let priority = WhatToPlayStatsAnalyzer.reviewPriority(for: item)

        return HStack(alignment: .top, spacing: AppSpacing.sm) {
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
                    if let gameMode = item.gameMode {
                        StatusBadge(modeTitle(gameMode), systemImage: gameMode == .hokum ? "crown.fill" : "sun.max.fill", tint: AppColor.accent)
                    }
                    StatusBadge(impactText(item.expectedImpact), systemImage: "chart.line.downtrend.xyaxis", tint: item.expectedImpact < 0 ? AppColor.danger : AppColor.accent)
                    if item.lostExpectedPoints > 0 {
                        StatusBadge("\(item.lostExpectedPoints)", systemImage: "drop.fill", tint: AppColor.danger)
                        StatusBadge(item.valueLossTitle, systemImage: "gauge.with.dots.needle.67percent", tint: valueLossSeverityTint(item.valueLossSeverity))
                    }
                    if item.lostProjectedTeamPoints > 0 {
                        StatusBadge("\(item.lostProjectedTeamPoints)", systemImage: "chart.bar.xaxis", tint: AppColor.warning)
                    }
                }
                if let projectedTeamPoints = item.projectedTeamPoints {
                    Text("\("نقاط فريقك بعد المحاكاة".localized): \(projectedTeamPoints)\(projectedLossSuffix(item.lostProjectedTeamPoints))")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(item.lostProjectedTeamPoints > 0 ? AppColor.warning : AppColor.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
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

                reviewSimulationView(item)

                if let title = item.tacticalReasonTitle,
                   let detail = item.tacticalReasonDetail,
                   let iconName = item.tacticalReasonIconName {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppColor.textPrimary)
                            Text(detail)
                                .font(.caption2)
                                .foregroundStyle(AppColor.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    } icon: {
                        Image(systemName: iconName)
                            .foregroundStyle(AppColor.danger)
                    }
                    .padding(AppSpacing.xs)
                    .background(AppColor.danger.opacity(0.1), in: RoundedRectangle(cornerRadius: AppRadius.small))
                }

                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(priority.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColor.textPrimary)
                        Text(priority.detail)
                            .font(.caption2)
                            .foregroundStyle(AppColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } icon: {
                    Image(systemName: priority.iconName)
                        .foregroundStyle(item.expectedImpact < 0 ? AppColor.danger : AppColor.accent)
                }
                .padding(AppSpacing.xs)
                .background(AppColor.background.opacity(0.7), in: RoundedRectangle(cornerRadius: AppRadius.small))

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

    @ViewBuilder
    private func reviewSimulationView(_ item: WhatToPlayReviewItem) -> some View {
        if let simulationSummary = item.simulationSummary {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\("نتيجة المحاكاة".localized): \(simulationSummary)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppColor.textPrimary)
                    if let simulationTeamResult = item.simulationTeamResult {
                        Text("\("اتجاه الأكلة".localized): \(simulationTeamResult)\(simulationPointsSuffix(item.simulationTrickPoints))")
                            .font(.caption2)
                            .foregroundStyle(AppColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            } icon: {
                Image(systemName: item.simulationTeamResult == nil ? "rectangle.stack.fill" : "flag.checkered")
                    .foregroundStyle(AppColor.accent)
            }
            .padding(AppSpacing.xs)
            .background(AppColor.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: AppRadius.small))
        }
    }

    private func secondBestImpactSuffix(_ impact: Int?) -> String {
        guard let impact else { return "" }
        return " · \(impactText(impact))"
    }

    private func simulationPointsSuffix(_ points: Int?) -> String {
        guard let points else { return "" }
        return " · \("نقاط الأكلة".localized): \(points)"
    }

    private func projectedLossSuffix(_ lostProjectedTeamPoints: Int) -> String {
        lostProjectedTeamPoints > 0
            ? " · \("نقاط محاكاة ضائعة".localized): \(lostProjectedTeamPoints)"
            : ""
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
                InfoRow(icon: "chart.bar.fill", title: "النقاط".localized, value: scenarioScoreText(scenario.context))
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
        let content = WhatToPlayShareCard.content(for: scenario, selectedOption: selectedOption)
        return VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label("بطاقة المشاركة".localized, systemImage: "square.and.arrow.up")
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.primary)

            WhatToPlayShareCardPreview(content: content)
        }
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
        let brief = WhatToPlayStatsAnalyzer.scenarioBrief(for: scenario)
        let checklist = WhatToPlayStatsAnalyzer.preDecisionChecklist(for: scenario)

        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("وش تلعب؟")
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.textPrimary)

            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(brief.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppColor.textPrimary)
                    Text(brief.detail)
                        .font(.caption2)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } icon: {
                Image(systemName: brief.iconName)
                    .foregroundStyle(AppColor.primary)
            }
            .padding(AppSpacing.sm)
            .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))

            preDecisionChecklistView(checklist)

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

    private func preDecisionChecklistView(_ checklist: WhatToPlayPreDecisionChecklist) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(checklist.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppColor.textPrimary)
                    Text(checklist.detail)
                        .font(.caption2)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } icon: {
                Image(systemName: checklist.iconName)
                    .foregroundStyle(AppColor.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(checklist.items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: AppSpacing.xs) {
                        Text("\(index + 1)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 18, height: 18)
                            .background(AppColor.accent, in: Circle())
                            .accessibilityHidden(true)
                        Text(item)
                            .font(.caption2)
                            .foregroundStyle(AppColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColor.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func blockedCardsView(_ scenario: WhatToPlayScenario) -> some View {
        if !scenario.blockedCards.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Label("لماذا لا أستطيع لعب هذه الأوراق؟".localized, systemImage: "questionmark.circle.fill")
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.xs), count: 4), spacing: AppSpacing.xs) {
                    ForEach(scenario.blockedCards) { blocked in
                        Button {
                            illegalMoveExplanation = RuleExplanationFormatter.illegalMoveExplanation(
                                for: blocked.card,
                                reason: blocked.reason,
                                trumpSuit: scenario.state.trumpSuit
                            )
                        } label: {
                            VStack(spacing: 6) {
                                MiniAnalysisCard(card: blocked.card, isSelected: false)
                                    .opacity(0.55)
                                Image(systemName: "lock.fill")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(blocked.card.accessibilityName)، \("ورقة غير قانونية".localized)")
                        .accessibilityHint(
                            RuleExplanationFormatter.illegalMoveExplanation(
                                for: blocked.card,
                                reason: blocked.reason,
                                trumpSuit: scenario.state.trumpSuit
                            )
                        )
                    }
                }

                if let illegalMoveExplanation {
                    Label {
                        Text(illegalMoveExplanation)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(AppColor.primary)
                    }
                    .padding(AppSpacing.sm)
                    .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
                }
            }
            .padding(AppSpacing.md)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
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
        illegalMoveExplanation = nil
        if selectedOption == nil, !isRetryingCurrentScenario, let bestCard = scenario.bestOption?.card {
            let attempt = WhatToPlayAttempt(
                difficulty: scenario.difficulty,
                seed: scenario.seed,
                selectedCard: evaluated.card,
                bestCard: bestCard,
                secondBestCard: scenario.secondBestOption?.card,
                isCorrect: evaluated.isExpertChoice,
                selectedRank: evaluated.rank,
                expectedImpact: evaluated.expectedImpact,
                bestExpectedImpact: scenario.bestOption?.expectedImpact,
                secondBestExpectedImpact: scenario.secondBestOption?.expectedImpact,
                projectedTeamPoints: evaluated.projectedTeamPoints,
                bestProjectedTeamPoints: scenario.bestOption?.projectedTeamPoints,
                secondBestProjectedTeamPoints: scenario.secondBestOption?.projectedTeamPoints,
                focusKind: scenario.context.focusKind,
                gameMode: scenario.state.mode,
                outcome: evaluated.outcome,
                impactBreakdown: evaluated.impactBreakdown,
                simulation: evaluated.simulation
            )
            modelContext.insert(attempt)
            try? modelContext.save()
        }
        selectedOption = evaluated
        shareImageURL = nil
        renderShareImageForCurrentScenario()
        isRetryingCurrentScenario = false
    }

    private func showDecisionReplay(
        for option: WhatToPlayOption,
        in scenario: WhatToPlayScenario,
        label: String
    ) {
        guard let replay = WhatToPlayTrainer.decisionReplay(for: option.card, in: scenario) else { return }
        let context = WhatToPlayStatsAnalyzer.replayContext(for: option, in: scenario)
        replayPresentation = WhatToPlayReplayPresentation(
            replay: replay,
            title: label,
            contextText: context.text,
            initialStep: replay.actions.count
        )
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
                InfoRow(icon: "chart.bar.xaxis", title: "نقاط فريقك بعد المحاكاة".localized, value: "\(option.projectedTeamPoints)")
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

            if let nextAction = WhatToPlayStatsAnalyzer.nextDecisionAction(for: option, in: scenario) {
                nextDecisionActionView(nextAction)
            }

            if let retryPrompt = WhatToPlayStatsAnalyzer.retryPrompt(for: option, in: scenario) {
                retryPromptView(retryPrompt)
            }

            optionSimulationView(option, scenario: scenario)

            decisionReplayButtons(for: option, in: scenario)

            nextScenarioAfterDecisionView(nextScenarioRecommendation)

            Text(option.explanation)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColor.textPrimary)
                .padding(AppSpacing.md)
                .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private func nextScenarioAfterDecisionView(_ recommendation: WhatToPlayNextScenarioRecommendation) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label("تدريب مقترح بعد القرار".localized, systemImage: recommendation.iconName)
                .font(AppTypography.caption.weight(.semibold))
                .foregroundStyle(AppColor.textSecondary)

            Text("\(recommendation.difficulty.displayTitle) · \(recommendation.focusKind.map(focusTitle) ?? "تلقائي".localized)")
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textPrimary)

            Button {
                startNextScenarioRecommendation()
            } label: {
                Label("الموقف التالي".localized, systemImage: "arrow.forward.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColor.primary)
            .disabled(isGeneratingScenario)
        }
        .padding(AppSpacing.sm)
        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
    }

    private func decisionReplayButtons(for option: WhatToPlayOption, in scenario: WhatToPlayScenario) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Button {
                showDecisionReplay(for: option, in: scenario, label: "إعادة اختيارك".localized)
            } label: {
                Label("إعادة اختيارك".localized, systemImage: "play.rectangle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(AppColor.primary)

            if let best = scenario.bestOption, best.card != option.card {
                Button {
                    showDecisionReplay(for: best, in: scenario, label: "إعادة أفضل قرار".localized)
                } label: {
                    Label("إعادة أفضل قرار".localized, systemImage: "star.rectangle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.primary)
            }

            if let second = scenario.secondBestOption,
               second.card != option.card,
               second.card != scenario.bestOption?.card {
                Button {
                    showDecisionReplay(for: second, in: scenario, label: "إعادة ثاني أفضل قرار".localized)
                } label: {
                    Label("إعادة ثاني أفضل قرار".localized, systemImage: "2.square.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(AppColor.accent)
            }
        }
    }

    private func optionSimulationView(_ option: WhatToPlayOption, scenario: WhatToPlayScenario) -> some View {
        let simulation = option.simulation
        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label("ماذا يحدث لو لعبتها؟".localized, systemImage: "sparkles.rectangle.stack.fill")
                .font(AppTypography.subheadline.weight(.semibold))
                .foregroundStyle(AppColor.primary)

            VStack(spacing: AppSpacing.xs) {
                InfoRow(
                    icon: simulation.completedTrickWinnerID == nil ? "rectangle.stack.fill" : "flag.checkered",
                    title: "بعد الورقة".localized,
                    value: simulationSummary(simulation)
                )
                if let nextTurnPlayerID = simulation.nextTurnPlayerID,
                   let nextPlayer = scenario.state.player(id: nextTurnPlayerID) {
                    InfoRow(icon: "arrow.turn.up.right", title: "الدور التالي".localized, value: nextPlayer.name)
                }
                if let winnerID = simulation.completedTrickWinnerID,
                   let winner = scenario.state.player(id: winnerID) {
                    InfoRow(icon: "crown.fill", title: "الفائز بالأكلة".localized, value: winner.name)
                    if let teamResult = simulationTeamResult(simulation) {
                        InfoRow(icon: "person.2.fill", title: "اتجاه الأكلة".localized, value: teamResult)
                    }
                    InfoRow(icon: "sum", title: "نقاط الأكلة".localized, value: "\(simulation.completedTrickPoints)")
                }
                InfoRow(icon: "chart.bar.xaxis", title: "نقاط فريقك بعد المحاكاة".localized, value: "\(option.projectedTeamPoints)")
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }

    private func simulationSummary(_ simulation: WhatToPlayOptionSimulation) -> String {
        WhatToPlaySimulationFormatter.display(for: simulation).summary
    }

    private func simulationTeamResult(_ simulation: WhatToPlayOptionSimulation) -> String? {
        WhatToPlaySimulationFormatter.display(for: simulation).teamResult
    }

    private func retryPromptView(_ prompt: WhatToPlayRetryPrompt) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label(prompt.title, systemImage: prompt.iconName)
                .font(AppTypography.subheadline.weight(.semibold))
                .foregroundStyle(AppColor.primary)

            Text(prompt.detail)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                retryCurrentScenario()
            } label: {
                Label("أعد نفس الموقف".localized, systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColor.primary)
        }
        .padding(AppSpacing.sm)
        .background(AppColor.primary.opacity(0.10), in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .contain)
    }

    private func nextDecisionActionView(_ action: WhatToPlayNextDecisionAction) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(action.title)
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Text(action.detail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let recommendedCard = action.recommendedCard {
                    Text("\("ورقة المراجعة".localized): \(recommendedCard.accessibilityName)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppColor.primary)
                }
                if action.expectedImprovement > 0 {
                    Text("\("تحسن متوقع".localized): +\(action.expectedImprovement)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppColor.success)
                }
            }
        } icon: {
            Image(systemName: action.iconName)
                .foregroundStyle(AppColor.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(AppColor.primary.opacity(0.10), in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }

    private func decisionInsightView(_ insight: WhatToPlayDecisionInsight) -> some View {
        let hasValueLoss = insight.lostExpectedPoints > 0 || insight.lostProjectedTeamPoints > 0
        return Label {
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
                if insight.lostProjectedTeamPoints > 0 {
                    Text("\("نقاط محاكاة ضائعة".localized): \(insight.lostProjectedTeamPoints)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppColor.danger)
                }
                if hasValueLoss {
                    Text(insight.valueLossTitle)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(valueLossSeverityTint(insight.valueLossSeverity))
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

    private func valueLossSeverityTint(_ severity: WhatToPlayValueLossSeverity) -> Color {
        switch severity {
        case .none:
            AppColor.success
        case .low:
            AppColor.accent
        case .medium:
            AppColor.warning
        case .high:
            AppColor.danger
        }
    }

    private func optionComparisonCard(selectedOption: WhatToPlayOption, scenario: WhatToPlayScenario) -> some View {
        let rows = WhatToPlayOptionComparison.rows(for: scenario, selectedCard: selectedOption.card)
        let summary = WhatToPlayOptionComparison.summary(for: scenario, selectedCard: selectedOption.card)
        return VStack(alignment: .leading, spacing: AppSpacing.md) {
            Label("أثر كل قرار".localized, systemImage: "list.bullet.rectangle.fill")
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.primary)

            optionComparisonSummary(summary)

            VStack(spacing: AppSpacing.sm) {
                ForEach(rows) { row in
                    optionComparisonRow(row)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private func optionComparisonSummary(_ summary: WhatToPlayOptionComparisonSummary) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppSpacing.xs) {
                    optionSummaryMetrics(summary)
                }
                VStack(spacing: AppSpacing.xs) {
                    optionSummaryMetrics(summary)
                }
            }
            if let gap = summary.bestToSecondGap {
                Label("\("الفارق بين الأفضل والثاني".localized): \(impactText(gap))", systemImage: "arrow.left.and.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(gap <= 2 ? AppColor.accent : AppColor.warning)
            }
            if let quality = summary.decisionQuality,
               let lost = summary.selectedLostExpectedPoints {
                Label(
                    "\("تقييم اختيارك".localized): \(quality.title) · \("الفاقد".localized): \(impactText(lost))",
                    systemImage: quality.systemImage
                )
                .font(.caption2.weight(.semibold))
                .foregroundStyle(decisionQualityTint(quality))
            }
            if let projectedLoss = summary.selectedLostProjectedTeamPoints, projectedLoss > 0 {
                Label(
                    "\("نقاط محاكاة ضائعة".localized): \(projectedLoss)",
                    systemImage: "chart.bar.doc.horizontal.fill"
                )
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AppColor.danger)
            }
            if let nextActionTitle = summary.nextActionTitle,
               let nextActionDetail = summary.nextActionDetail {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(nextActionTitle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColor.textPrimary)
                        Text(nextActionDetail)
                            .font(.caption2)
                            .foregroundStyle(AppColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } icon: {
                    Image(systemName: "arrow.triangle.branch")
                        .foregroundStyle(AppColor.accent)
                }
                .padding(.top, AppSpacing.xs)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func decisionQualityTint(_ quality: WhatToPlayDecisionQuality) -> Color {
        switch quality {
        case .expertMatch:
            AppColor.success
        case .close:
            AppColor.accent
        case .acceptable:
            AppColor.warning
        case .costly:
            AppColor.danger
        }
    }

    @ViewBuilder
    private func optionSummaryMetrics(_ summary: WhatToPlayOptionComparisonSummary) -> some View {
        miniPlanMetric(
            title: "أفضل ورقة".localized,
            value: optionSummaryCardText(
                card: summary.bestCard,
                impact: summary.bestExpectedImpact,
                projectedTeamPoints: summary.bestProjectedTeamPoints
            )
        )
        miniPlanMetric(
            title: "ثاني أفضل".localized,
            value: optionSummaryCardText(
                card: summary.secondBestCard,
                impact: summary.secondBestExpectedImpact,
                projectedTeamPoints: summary.secondBestProjectedTeamPoints
            )
        )
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
                Text("\("نقاط فريقك بعد المحاكاة".localized): \(row.projectedTeamPoints)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppColor.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                if row.lostProjectedTeamPoints > 0 {
                    Text("\("نقاط محاكاة ضائعة".localized): \(row.lostProjectedTeamPoints)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppColor.warning)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                Text(optionOutcomeText(row.outcome))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(optionOutcomeTint(row.outcome))
                Text(row.impactDetail)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(row.expectedImpact >= 0 ? AppColor.success : AppColor.danger)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Label(row.simulationSummary, systemImage: row.simulationTeamResult == nil ? "rectangle.stack.fill" : "flag.checkered")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(row.simulationTeamResult == "للخصم".localized ? AppColor.warning : AppColor.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                if let simulationTeamResult = row.simulationTeamResult {
                    let pointsSuffix = row.simulationTrickPoints.map { " · \("نقاط الأكلة".localized): \($0)" } ?? ""
                    Text("\("اتجاه الأكلة".localized): \(simulationTeamResult)\(pointsSuffix)")
                        .font(.caption2)
                        .foregroundStyle(simulationTeamResult == "للخصم".localized ? AppColor.danger : AppColor.success)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                Label(row.tacticalTag.title, systemImage: row.tacticalTag.systemImage)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(optionTacticalTint(row.tacticalTag))
                Text(row.tacticalSummary)
                    .font(.caption2)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
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

    private func optionSummaryCardText(card: PlayingCard?, impact: Int?, projectedTeamPoints: Int?) -> String {
        guard let card, let impact else { return "لا يوجد بديل".localized }
        let projection = projectedTeamPoints.map { " · \("محاكاة".localized): \($0)" } ?? ""
        return "\(card.accessibilityName) · \(impactText(impact))\(projection)"
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

    private func optionTacticalTint(_ tag: WhatToPlayOptionTacticalTag) -> Color {
        switch tag {
        case .expertPick, .winsNow:
            AppColor.success
        case .closeAlternative, .holdsPosition:
            AppColor.accent
        case .opensRisk:
            AppColor.warning
        case .costly:
            AppColor.danger
        }
    }

    private func generateScenario() {
        generationTask?.cancel()
        selectedOption = nil
        errorMessage = nil
        illegalMoveExplanation = nil
        shareImageURL = nil
        isRenderingShareImage = false
        isRetryingCurrentScenario = false
        scenario = nil
        isGeneratingScenario = true

        let requestSeed = seed
        let requestDifficulty = difficulty
        let requestFocus = preferredFocus
        let requestMode = preferredMode
        let reviewSelection = pendingReviewSelection
        pendingReviewSelection = nil
        generationTask = Task {
            do {
                let generated = try await WhatToPlayScenarioLoader.generate(
                    seed: requestSeed,
                    difficulty: requestDifficulty,
                    preferredFocus: requestFocus,
                    preferredMode: requestMode
                )
                guard !Task.isCancelled else { return }
                scenario = generated
                if let reviewSelection {
                    selectedOption = WhatToPlayTrainer.evaluateChoice(card: reviewSelection, in: generated)
                    isRetryingCurrentScenario = selectedOption != nil
                }
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
        seed = WhatToPlayScenarioLoader.nextUnattemptedSeed(
            after: seed,
            difficulty: difficulty,
            preferredFocus: preferredFocus,
            preferredMode: preferredMode,
            attempts: attempts
        )
        isRetryingCurrentScenario = false
        generateScenario()
    }

    private func replayReviewItem(_ item: WhatToPlayReviewItem) {
        seed = item.seed
        preferredFocusRaw = item.focusKind?.rawValue ?? "auto"
        preferredModeRaw = item.gameMode?.rawValue ?? "auto"
        selectedOption = nil
        pendingReviewSelection = item.selectedCard
        isRetryingCurrentScenario = false
        if difficulty == item.difficulty {
            generateScenario()
        } else {
            difficulty = item.difficulty
        }
    }

    private func startNextScenarioRecommendation() {
        let targetFocusRaw = nextScenarioRecommendation.focusKind?.rawValue ?? "auto"
        isRetryingCurrentScenario = false
        if difficulty == nextScenarioRecommendation.difficulty, preferredFocusRaw == targetFocusRaw {
            nextScenario()
        } else {
            difficulty = nextScenarioRecommendation.difficulty
            preferredFocusRaw = targetFocusRaw
            generateScenario()
        }
    }

    private func startMicroDrill(
        scenarioSeed: UInt64,
        difficulty targetDifficulty: WhatToPlayDifficulty,
        focusKind: WhatToPlayScenarioFocusKind?
    ) {
        let targetFocusRaw = focusKind?.rawValue ?? "auto"
        seed = scenarioSeed
        isRetryingCurrentScenario = false
        if difficulty == targetDifficulty, preferredFocusRaw == targetFocusRaw {
            generateScenario()
        } else {
            difficulty = targetDifficulty
            preferredFocusRaw = targetFocusRaw
            generateScenario()
        }
    }

    private func retryCurrentScenario() {
        selectedOption = nil
        illegalMoveExplanation = nil
        shareImageURL = nil
        isRenderingShareImage = false
        isRetryingCurrentScenario = true
    }

    @MainActor
    private func renderShareImageForCurrentScenario() {
        guard let scenario else {
            shareImageURL = nil
            isRenderingShareImage = false
            return
        }

        let content = WhatToPlayShareCard.content(for: scenario, selectedOption: selectedOption)
        let fileName = WhatToPlayShareCardImageRenderer.fileName(for: scenario, selectedOption: selectedOption)

        isRenderingShareImage = true
        defer { isRenderingShareImage = false }

        do {
            shareImageURL = try WhatToPlayShareCardImageRenderer.render(
                content: content,
                fileName: fileName,
                scale: displayScale
            )
        } catch {
            shareImageURL = nil
        }
    }

    private func applyTrainingSessionNextStep(_ progress: WhatToPlayTrainingSessionProgress) {
        switch progress.state {
        case .notStarted, .inProgress, .needsRepeat:
            startTrainingSessionPlan()
        case .achieved:
            startNextScenarioRecommendation()
        }
    }

    private func startTrainingSessionPlan() {
        let targetFocusRaw = trainingSessionPlan.focusKind?.rawValue ?? "auto"
        seed = WhatToPlayStatsAnalyzer.nextTrainingSessionSeed(for: attempts, plan: trainingSessionPlan)
        if difficulty == trainingSessionPlan.difficulty, preferredFocusRaw == targetFocusRaw {
            generateScenario()
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

    private func modeTitle(_ mode: GameMode) -> String {
        mode.arabicName.localized
    }

    private func turnContextText(_ context: WhatToPlayScenarioContext) -> String {
        if context.isLeading {
            return "أنت تفتتح الأكلة".localized
        }
        return "\("أنت ترد بعد".localized) \(context.playedCardCount) \("ورقة".localized)"
    }

    private func scenarioScoreText(_ context: WhatToPlayScenarioContext) -> String {
        let margin = context.playerTeamPointMargin
        let marginPrefix = margin > 0 ? "+" : ""
        return "\("فريقنا".localized) \(context.playerTeamTrickPoints) · \("الخصم".localized) \(context.opponentTeamTrickPoints) · \(marginPrefix)\(margin)"
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
        if impact > 0 { return "+\(impact) \("نقطة متوقعة".localized)" }
        if impact < 0 { return "\(impact) \("نقطة متوقعة".localized)" }
        return "أثر محايد".localized
    }

    private func impactGapText(_ gap: Int) -> String {
        gap > 0 ? "\(gap)" : "مكتمل".localized
    }

    private func cardName(_ card: PlayingCard?) -> String {
        card?.accessibilityName ?? "ورقة غير معروفة".localized
    }
}

private extension WhatToPlayDifficulty {
    var displayTitle: String {
        switch self {
        case .easy: "سهل".localized
        case .medium: "متوسط".localized
        case .hard: "صعب".localized
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
        let hand = sortedSelectedCards
        guard HandAnalyzer.inputValidation(for: hand).isValid else { return nil }
        return HandAnalyzer.analyze(hand: hand)
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
            if let analysis {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: HandAnalysisShareSummary.text(for: analysis)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("مشاركة تحليل اليد".localized)
                }
            }
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
                InfoRow(icon: "scope", title: "خلاصة القرار", value: decisionGradeText(analysis.decisionGrade))
                InfoRow(icon: "arrow.triangle.branch", title: "الخطوة التالية", value: analysis.nextActionTitle)
                InfoRow(icon: "hand.thumbsup.fill", title: "التوصية", value: recommendationText(analysis.recommendedBid))
                InfoRow(icon: "gauge.with.dots.needle.67percent", title: "قوة اليد", value: "\(analysis.strengthPercent)%")
                InfoRow(icon: "chart.line.uptrend.xyaxis", title: "احتمال الشراء", value: "\(analysis.buyConfidencePercent)%")
                InfoRow(icon: "checkmark.seal.fill", title: "الثقة", value: confidenceText(analysis.confidence))
                InfoRow(icon: "sun.max.fill", title: "احتمال الصن", value: "\(analysis.sunConfidencePercent)% · \(analysis.evaluation.sunScore)")
                if let best = analysis.evaluation.bestHokum {
                    InfoRow(icon: "crown.fill", title: "أفضل حكم", value: "\(best.suit.spokenName) · \(analysis.hokumConfidencePercent)% · \(best.score)")
                }
                InfoRow(icon: "arrow.left.arrow.right", title: "مقارنة الصن والحكم".localized, value: analysis.modeComparisonTitle)
                InfoRow(icon: "star.fill", title: "المشاريع", value: projectsText(analysis.projects))
            }

            rationaleGroup(title: "نقاط القوة".localized, systemImage: "plus.circle.fill", items: analysis.strengths, tint: AppColor.success)
            rationaleGroup(title: "نقاط الضعف".localized, systemImage: "exclamationmark.triangle.fill", items: analysis.weaknesses, tint: AppColor.warning)
            bidOptionsView(analysis.bidOptions)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Label("مقارنة الصن والحكم".localized, systemImage: "arrow.left.arrow.right")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.primary)
                Text(analysis.modeComparisonDetail)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(AppSpacing.md)
            .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Label("الخطوة التالية".localized, systemImage: "arrow.triangle.branch")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.accent)
                Text(analysis.nextActionDetail)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(AppSpacing.md)
            .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Label("النصيحة التكتيكية".localized, systemImage: "lightbulb.fill")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.primary)
                Text(analysis.tacticalAdvice)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColor.textPrimary)
            }
            .padding(AppSpacing.md)
            .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private func bidOptionsView(_ options: [HandAnalysis.BidOption]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label("ترتيب خيارات المزايدة".localized, systemImage: "list.number")
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.primary)

            ForEach(options) { option in
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(option.title)
                            .font(AppTypography.caption.weight(.semibold))
                            .foregroundStyle(AppColor.textPrimary)
                        Spacer()
                        Text("\(option.confidencePercent)%")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(option.isRecommended ? AppColor.success : AppColor.textSecondary)
                    }
                    Text(option.detail)
                        .font(.caption2)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(AppSpacing.xs)
                .background(
                    (option.isRecommended ? AppColor.success : AppColor.surfaceElevated).opacity(option.isRecommended ? 0.12 : 1),
                    in: RoundedRectangle(cornerRadius: AppRadius.small)
                )
                .accessibilityElement(children: .combine)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
    }

    private func rationaleGroup(title: String, systemImage: String, items: [String], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label(title, systemImage: systemImage)
                .font(AppTypography.headline)
                .foregroundStyle(tint)
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: AppSpacing.xs) {
                    Circle()
                        .fill(tint)
                        .frame(width: 6, height: 6)
                        .padding(.top, 7)
                    Text(item)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
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

    private func decisionGradeText(_ grade: HandAnalysis.DecisionGrade) -> String {
        switch grade {
        case .strongBuy:
            return "شراء قوي".localized
        case .cautiousBuy:
            return "شراء حذر".localized
        case .closePass:
            return "تمرير قريب".localized
        case .clearPass:
            return "تمرير واضح".localized
        }
    }

    private func projectsText(_ projects: [Project]) -> String {
        guard !projects.isEmpty else { return "لا يوجد" }
        return projects
            .map { "\($0.kind.arabicName) \($0.points)" }
            .joined(separator: " · ")
    }

}

struct WhatToPlayShareCardPreview: View {
    let content: WhatToPlayShareCardContent

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(content.title)
                        .font(AppTypography.title)
                        .foregroundStyle(.white)
                    Text(content.contextLine)
                        .font(AppTypography.headline)
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
                shareMetric("النقاط".localized, content.scoreLine)
                shareMetric("الصعوبة".localized, content.difficulty)
                shareMetric("تركيز التدريب".localized, content.focus)
            }

            tableCardsSection
            legalCardsSection

            if content.includesAnswerReview {
                answerReviewSection
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

    private var tableCardsSection: some View {
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
    }

    private var legalCardsSection: some View {
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
    }

    private var answerReviewSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("مراجعة القرار".localized)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.86))

            if let selectedCardName = content.selectedCardName {
                shareChip("\("اختياري".localized): \(selectedCardName)")
            }
            if let bestCardName = content.bestCardName {
                shareChip("\("أفضل ورقة".localized): \(bestCardName)")
            }
            if let bestExpectedImpact = content.bestExpectedImpact {
                shareChip("\("أثر الأفضل".localized): \(impactText(bestExpectedImpact))")
            }
            if let secondBestCardName = content.secondBestCardName {
                shareChip("\("ثاني أفضل".localized): \(secondBestCardName)")
            }
            if let secondBestExpectedImpact = content.secondBestExpectedImpact {
                shareChip("\("أثر ثاني أفضل".localized): \(impactText(secondBestExpectedImpact))")
            }
            if let selectedRank = content.selectedRank {
                shareChip("\("ترتيب اختياري".localized): \(selectedRank)")
            }
            if let selectedImpact = content.selectedImpact {
                shareChip("\("الأثر المتوقع".localized): \(impactText(selectedImpact))")
            }
            if let selectedImpactDetail = content.selectedImpactDetail {
                shareNote("\("تفصيل الأثر".localized): \(selectedImpactDetail)")
            }
            if let lostExpectedPoints = content.lostExpectedPoints {
                shareChip("\("نقاط متوقعة ضائعة".localized): \(lostExpectedPoints)")
            }
            if let lostProjectedTeamPoints = content.lostProjectedTeamPoints {
                shareChip("\("نقاط محاكاة ضائعة".localized): \(lostProjectedTeamPoints)")
            }
            if let valueLossTitle = content.valueLossTitle {
                shareChip("\("شدة خسارة القيمة".localized): \(valueLossTitle)")
            }
            if let decisionQualityTitle = content.decisionQualityTitle {
                shareChip("\("تقييم القرار".localized): \(decisionQualityTitle)")
            }
            if let nextActionTitle = content.nextActionTitle {
                shareChip("\("الإجراء التالي".localized): \(nextActionTitle)")
            }
            if let nextActionDetail = content.nextActionDetail {
                shareNote(nextActionDetail)
            }
            if let lostAgainstSecondBestPoints = content.lostAgainstSecondBestPoints {
                shareChip("\("فارق عن ثاني أفضل".localized): \(lostAgainstSecondBestPoints)")
            }
            if let selectedProjectedTeamPoints = content.selectedProjectedTeamPoints {
                shareChip("\("نقاط فريقك بعد المحاكاة".localized): \(selectedProjectedTeamPoints)")
            }
            if let selectedSimulationSummary = content.selectedSimulationSummary {
                shareChip("\("نتيجة المحاكاة".localized): \(selectedSimulationSummary)")
            }
            if let selectedSimulationTeamResult = content.selectedSimulationTeamResult {
                shareChip("\("اتجاه الأكلة".localized): \(selectedSimulationTeamResult)")
            }
            if let selectedSimulationTrickPoints = content.selectedSimulationTrickPoints {
                shareChip("\("نقاط الأكلة".localized): \(selectedSimulationTrickPoints)")
            }
            if let tacticalReasonTitle = content.tacticalReasonTitle {
                shareChip("\("سبب تكتيكي".localized): \(tacticalReasonTitle)")
            }
            if let tacticalReasonDetail = content.tacticalReasonDetail {
                shareNote(tacticalReasonDetail)
            }
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

    private func shareNote(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .foregroundStyle(.white.opacity(0.86))
            .lineLimit(3)
            .minimumScaleFactor(0.8)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: AppRadius.small))
    }

    private func impactText(_ impact: Int) -> String {
        if impact > 0 { return "+\(impact) \("نقطة متوقعة".localized)" }
        if impact < 0 { return "\(impact) \("نقطة متوقعة".localized)" }
        return "أثر محايد".localized
    }
}

enum WhatToPlayShareCardImageRenderer {
    static func fileName(for scenario: WhatToPlayScenario, selectedOption: WhatToPlayOption?) -> String {
        let selectedCard = selectedOption.map { "\($0.card.suit.ordinal)-\($0.card.rank.ordinal)" } ?? "prompt"
        let focus = scenario.context.focusKind.rawValue
        return "baloothub-what-to-play-\(scenario.seed)-\(scenario.difficulty.rawValue)-\(focus)-\(selectedCard).png"
    }

    @MainActor
    static func render(
        content: WhatToPlayShareCardContent,
        fileName: String,
        scale: CGFloat
    ) throws -> URL {
        let renderer = ImageRenderer(
            content: WhatToPlayShareCardPreview(content: content)
                .frame(width: 430)
                .environment(\.layoutDirection, .rightToLeft)
        )
        renderer.scale = scale

        guard let image = renderer.uiImage, let data = image.pngData() else {
            throw CocoaError(.fileWriteUnknown)
        }

        let url = FileManager.default.temporaryDirectory.appending(path: fileName)
        try data.write(to: url, options: [.atomic])
        return url
    }
}

private struct WhatToPlayReplayPresentation: Identifiable {
    let id = UUID()
    let replay: WhatToPlayDecisionReplay
    let title: String
    let contextText: String
    let initialStep: Int
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
