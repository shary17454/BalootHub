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
    @State private var seed: UInt64 = 2026
    @State private var scenario: WhatToPlayScenario?
    @State private var selectedOption: WhatToPlayOption?
    @State private var errorMessage: String?
    @State private var isGeneratingScenario = false
    @State private var generationTask: Task<Void, Never>?

    private var statsSummary: WhatToPlayStatsSummary {
        WhatToPlayStatsAnalyzer.summarize(attempts: attempts)
    }

    private var recentAttempts: [WhatToPlayAttempt] {
        WhatToPlayStatsAnalyzer.recentAttempts(attempts)
    }

    private var difficultySummaries: [(difficulty: WhatToPlayDifficulty, summary: WhatToPlayStatsSummary)] {
        WhatToPlayStatsAnalyzer.summariesByDifficulty(attempts)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                header
                controls
                statsCard
                difficultyStatsCard
                recentAttemptsCard

            if let scenario {
                scenarioSummary(scenario)
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
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
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
            }
            .padding(AppSpacing.md)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
        }
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
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
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
            }

            currentTrick(scenario)
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
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
            isRevealed: selectedOption != nil
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
                isCorrect: evaluated.isExpertChoice,
                expectedImpact: evaluated.expectedImpact
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

    private func generateScenario() {
        generationTask?.cancel()
        selectedOption = nil
        errorMessage = nil
        scenario = nil
        isGeneratingScenario = true

        let requestSeed = seed
        let requestDifficulty = difficulty
        generationTask = Task {
            do {
                let generated = try await WhatToPlayScenarioLoader.generate(seed: requestSeed, difficulty: requestDifficulty)
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

    private func modeText(_ state: GameState) -> String {
        guard let mode = state.mode else { return "غير محدد" }
        if mode == .hokum, let suit = state.trumpSuit {
            return "\(mode.arabicName) \(suit.spokenName)"
        }
        return mode.arabicName
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
