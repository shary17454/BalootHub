import XCTest
import SwiftData
import BalootEngine
@testable import BalootHub

final class WhatToPlayStatsAnalyzerTests: XCTestCase {
    func testSummaryCalculatesAccuracyStreaksAndAverageImpact() {
        let attempts = [
            attempt(daysAgo: 4, correct: true, impact: 10),
            attempt(daysAgo: 3, correct: true, impact: 4),
            attempt(daysAgo: 2, correct: false, impact: -8),
            attempt(daysAgo: 1, correct: true, impact: 2)
        ]

        let summary = WhatToPlayStatsAnalyzer.summarize(attempts: attempts)

        XCTAssertEqual(summary.attempts, 4)
        XCTAssertEqual(summary.correct, 3)
        XCTAssertEqual(summary.accuracyPercent, 75)
        XCTAssertEqual(summary.bestStreak, 2)
        XCTAssertEqual(summary.currentStreak, 1)
        XCTAssertEqual(summary.averageExpectedImpact, 2)
        XCTAssertEqual(summary.lostExpectedPoints, 0)
        XCTAssertEqual(summary.valueCapturePercent, 0)
        XCTAssertEqual(summary.valueCaptureAttempts, 0)
    }

    func testSummaryAccumulatesLostExpectedPointsWhenBestImpactIsKnown() {
        let attempts = [
            attempt(daysAgo: 3, correct: true, impact: 4, bestImpact: 4),
            attempt(daysAgo: 2, correct: false, impact: -3, bestImpact: 5),
            attempt(daysAgo: 1, correct: false, impact: 2, bestImpact: 6)
        ]

        let summary = WhatToPlayStatsAnalyzer.summarize(attempts: attempts)

        XCTAssertEqual(summary.lostExpectedPoints, 12)
        XCTAssertEqual(summary.valueCaptureAttempts, 3)
        XCTAssertEqual(summary.valueCapturePercent, 40)
    }

    func testSummaryValueCaptureClampsSelectedImpactAndIgnoresNonPositiveBest() {
        let attempts = [
            attempt(daysAgo: 3, correct: true, impact: 10, bestImpact: 6),
            attempt(daysAgo: 2, correct: false, impact: 3, bestImpact: 0),
            attempt(daysAgo: 1, correct: false, impact: -4, bestImpact: 4)
        ]

        let summary = WhatToPlayStatsAnalyzer.summarize(attempts: attempts)

        XCTAssertEqual(summary.valueCaptureAttempts, 2)
        XCTAssertEqual(summary.valueCapturePercent, 60)
    }

    func testOutcomeSummaryCountsTrackedDecisionOutcomes() {
        let attempts = [
            attempt(daysAgo: 5, correct: true, impact: 5, outcome: .winsTrick),
            attempt(daysAgo: 4, correct: false, impact: -6, outcome: .losesTrick),
            attempt(daysAgo: 3, correct: false, impact: 0, outcome: .leadsTrick),
            attempt(daysAgo: 2, correct: true, impact: 1, outcome: .developsTrick),
            attempt(daysAgo: 1, correct: false, impact: -1)
        ]

        let summary = WhatToPlayStatsAnalyzer.outcomeSummary(for: attempts)

        XCTAssertEqual(summary.trackedAttempts, 4)
        XCTAssertEqual(summary.winningTrickAttempts, 1)
        XCTAssertEqual(summary.losingTrickAttempts, 1)
        XCTAssertEqual(summary.openTrickAttempts, 2)
        XCTAssertEqual(summary.winningPercent, 25)
        XCTAssertEqual(summary.losingPercent, 25)
    }

    func testOutcomeSummaryIgnoresLegacyAttemptsWithoutOutcome() {
        let attempts = [
            attempt(daysAgo: 2, correct: true, impact: 5),
            attempt(daysAgo: 1, correct: false, impact: -6)
        ]

        XCTAssertEqual(WhatToPlayStatsAnalyzer.outcomeSummary(for: attempts), .empty)
    }

    func testOutcomeInsightWaitsForEnoughTrackedAttempts() {
        let summary = WhatToPlayOutcomeSummary(
            trackedAttempts: 2,
            winningTrickAttempts: 1,
            losingTrickAttempts: 1,
            openTrickAttempts: 0
        )

        XCTAssertNil(WhatToPlayStatsAnalyzer.outcomeInsight(for: summary))
    }

    func testOutcomeInsightWarnsWhenLosingTricksOften() {
        let summary = WhatToPlayOutcomeSummary(
            trackedAttempts: 4,
            winningTrickAttempts: 1,
            losingTrickAttempts: 2,
            openTrickAttempts: 1
        )

        let insight = WhatToPlayStatsAnalyzer.outcomeInsight(for: summary)

        XCTAssertEqual(insight?.title, "خسارة الأكلة متكررة".localized)
        XCTAssertEqual(insight?.iconName, "exclamationmark.triangle.fill")
    }

    func testOutcomeInsightRecognizesWinningTricksOften() {
        let summary = WhatToPlayOutcomeSummary(
            trackedAttempts: 4,
            winningTrickAttempts: 2,
            losingTrickAttempts: 1,
            openTrickAttempts: 1
        )

        let insight = WhatToPlayStatsAnalyzer.outcomeInsight(for: summary)

        XCTAssertEqual(insight?.title, "تحسم الأكلات بثبات".localized)
        XCTAssertEqual(insight?.iconName, "checkmark.seal.fill")
    }

    func testOutcomeInsightDetectsOpenTrickPattern() {
        let summary = WhatToPlayOutcomeSummary(
            trackedAttempts: 5,
            winningTrickAttempts: 1,
            losingTrickAttempts: 1,
            openTrickAttempts: 3
        )

        let insight = WhatToPlayStatsAnalyzer.outcomeInsight(for: summary)

        XCTAssertEqual(insight?.title, "قراراتك تترك الأكلة مفتوحة".localized)
        XCTAssertEqual(insight?.iconName, "ellipsis.circle.fill")
    }

    func testOutcomeInsightFallsBackToBalancedPattern() {
        let summary = WhatToPlayOutcomeSummary(
            trackedAttempts: 5,
            winningTrickAttempts: 2,
            losingTrickAttempts: 1,
            openTrickAttempts: 2
        )

        let insight = WhatToPlayStatsAnalyzer.outcomeInsight(for: summary)

        XCTAssertEqual(insight?.title, "نتائج قراراتك متوازنة".localized)
        XCTAssertEqual(insight?.iconName, "scale.3d")
    }

    func testAttemptPersistsInSwiftDataSchemaAndRestoresCards() throws {
        let configuration = ModelConfiguration(schema: PersistenceController.appSchema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PersistenceController.appSchema, configurations: [configuration])
        let context = ModelContext(container)
        let selected = PlayingCard(suit: .spades, rank: .ace)
        let best = PlayingCard(suit: .hearts, rank: .jack)
        let secondBest = PlayingCard(suit: .diamonds, rank: .ace)
        let attempt = WhatToPlayAttempt(
            difficulty: .hard,
            seed: 2_026,
            selectedCard: selected,
            bestCard: best,
            secondBestCard: secondBest,
            isCorrect: false,
            selectedRank: 3,
            expectedImpact: -6,
            bestExpectedImpact: 4,
            secondBestExpectedImpact: 2,
            focusKind: .trumpPressure,
            outcome: .losesTrick
        )

        context.insert(attempt)
        try context.save()

        let saved = try XCTUnwrap(try context.fetch(FetchDescriptor<WhatToPlayAttempt>()).first)
        XCTAssertEqual(saved.difficulty, .hard)
        XCTAssertEqual(saved.seedValue, 2_026)
        XCTAssertEqual(saved.selectedCard, selected)
        XCTAssertEqual(saved.bestCard, best)
        XCTAssertEqual(saved.secondBestCard, secondBest)
        XCTAssertFalse(saved.isCorrect)
        XCTAssertEqual(saved.selectedRank, 3)
        XCTAssertEqual(saved.expectedImpact, -6)
        XCTAssertEqual(saved.bestExpectedImpact, 4)
        XCTAssertEqual(saved.secondBestExpectedImpact, 2)
        XCTAssertEqual(saved.lostExpectedPoints, 10)
        XCTAssertEqual(saved.focusKind, .trumpPressure)
        XCTAssertEqual(saved.outcome, .losesTrick)
    }

    func testAttemptWithoutBestExpectedImpactKeepsBackwardCompatibleZeroLoss() {
        let attempt = WhatToPlayAttempt(
            difficulty: .medium,
            seed: 99,
            selectedCard: PlayingCard(suit: .clubs, rank: .seven),
            bestCard: PlayingCard(suit: .clubs, rank: .ace),
            isCorrect: false,
            expectedImpact: -4
        )

        XCTAssertNil(attempt.bestExpectedImpact)
        XCTAssertEqual(attempt.lostExpectedPoints, 0)
    }

    func testAttemptWithoutOutcomeKeepsBackwardCompatibleNilOutcome() {
        let attempt = WhatToPlayAttempt(
            difficulty: .medium,
            seed: 99,
            selectedCard: PlayingCard(suit: .clubs, rank: .seven),
            bestCard: PlayingCard(suit: .clubs, rank: .ace),
            isCorrect: false,
            expectedImpact: -4
        )

        XCTAssertNil(attempt.outcomeRaw)
        XCTAssertNil(attempt.outcome)
    }

    func testAttemptWithoutSecondBestKeepsBackwardCompatibleNilSecondBest() {
        let attempt = WhatToPlayAttempt(
            difficulty: .medium,
            seed: 99,
            selectedCard: PlayingCard(suit: .clubs, rank: .seven),
            bestCard: PlayingCard(suit: .clubs, rank: .ace),
            isCorrect: false,
            expectedImpact: -4
        )

        XCTAssertNil(attempt.secondBestSuitRaw)
        XCTAssertNil(attempt.secondBestRankRaw)
        XCTAssertNil(attempt.secondBestCard)
        XCTAssertNil(attempt.secondBestExpectedImpact)
    }

    func testAttemptWithoutSelectedRankKeepsBackwardCompatibleNilRank() {
        let attempt = WhatToPlayAttempt(
            difficulty: .medium,
            seed: 99,
            selectedCard: PlayingCard(suit: .clubs, rank: .seven),
            bestCard: PlayingCard(suit: .clubs, rank: .ace),
            isCorrect: false,
            expectedImpact: -4
        )

        XCTAssertNil(attempt.selectedRank)
    }

    func testChoiceRankSummaryCountsExpertSecondBestAndFarChoices() {
        let attempts = [
            attempt(daysAgo: 5, correct: true, impact: 4, selectedRank: 1),
            attempt(daysAgo: 4, correct: false, impact: 2, selectedRank: 2),
            attempt(daysAgo: 3, correct: false, impact: 1, selectedRank: 2),
            attempt(daysAgo: 2, correct: false, impact: -4, selectedRank: 4),
            attempt(daysAgo: 1, correct: false, impact: -3)
        ]

        let summary = WhatToPlayStatsAnalyzer.choiceRankSummary(for: attempts)

        XCTAssertEqual(summary.trackedAttempts, 4)
        XCTAssertEqual(summary.expertPicks, 1)
        XCTAssertEqual(summary.secondBestPicks, 2)
        XCTAssertEqual(summary.farPicks, 1)
        XCTAssertEqual(summary.expertPickPercent, 25)
        XCTAssertEqual(summary.nearMissPercent, 50)
    }

    func testChoiceRankSummaryIgnoresLegacyAttemptsWithoutRank() {
        let attempts = [
            attempt(daysAgo: 2, correct: true, impact: 5),
            attempt(daysAgo: 1, correct: false, impact: -6)
        ]

        XCTAssertEqual(WhatToPlayStatsAnalyzer.choiceRankSummary(for: attempts), .empty)
    }

    func testChoiceRankInsightWaitsForEnoughTrackedAttempts() {
        let summary = WhatToPlayChoiceRankSummary(
            trackedAttempts: 2,
            expertPicks: 1,
            secondBestPicks: 1,
            farPicks: 0
        )

        XCTAssertNil(WhatToPlayStatsAnalyzer.choiceRankInsight(for: summary))
    }

    func testChoiceRankInsightRecognizesExpertAlignment() {
        let summary = WhatToPlayChoiceRankSummary(
            trackedAttempts: 10,
            expertPicks: 7,
            secondBestPicks: 2,
            farPicks: 1
        )

        let insight = WhatToPlayStatsAnalyzer.choiceRankInsight(for: summary)

        XCTAssertEqual(insight?.kind, .expertAligned)
        XCTAssertEqual(insight?.title, "اختياراتك قريبة من الخبير".localized)
        XCTAssertEqual(insight?.iconName, "checkmark.seal.fill")
    }

    func testChoiceRankInsightRecognizesFarChoices() {
        let summary = WhatToPlayChoiceRankSummary(
            trackedAttempts: 6,
            expertPicks: 1,
            secondBestPicks: 1,
            farPicks: 4
        )

        let insight = WhatToPlayStatsAnalyzer.choiceRankInsight(for: summary)

        XCTAssertEqual(insight?.kind, .farChoices)
        XCTAssertEqual(insight?.title, "اختياراتك بعيدة عن التحليل".localized)
        XCTAssertEqual(insight?.iconName, "exclamationmark.triangle.fill")
    }

    func testChoiceRankInsightFallsBackToNearMisses() {
        let summary = WhatToPlayChoiceRankSummary(
            trackedAttempts: 6,
            expertPicks: 2,
            secondBestPicks: 3,
            farPicks: 1
        )

        let insight = WhatToPlayStatsAnalyzer.choiceRankInsight(for: summary)

        XCTAssertEqual(insight?.kind, .nearMisses)
        XCTAssertEqual(insight?.title, "أخطاؤك قريبة وقابلة للتصحيح".localized)
        XCTAssertEqual(insight?.iconName, "2.circle.fill")
    }

    func testRecentAttemptsReturnsNewestFirstWithLimit() {
        let attempts = [
            attempt(daysAgo: 5, correct: true, impact: 0),
            attempt(daysAgo: 4, correct: true, impact: 1),
            attempt(daysAgo: 3, correct: false, impact: 2),
            attempt(daysAgo: 2, correct: true, impact: 3),
            attempt(daysAgo: 1, correct: false, impact: 4)
        ]

        let recent = WhatToPlayStatsAnalyzer.recentAttempts(attempts, limit: 3)

        XCTAssertEqual(recent.map(\.expectedImpact), [4, 3, 2])
    }

    func testRecentAttemptsRejectsZeroLimit() {
        XCTAssertTrue(WhatToPlayStatsAnalyzer.recentAttempts([attempt(daysAgo: 1, correct: true, impact: 0)], limit: 0).isEmpty)
    }

    func testReviewQueueReturnsWorstIncorrectAttemptsFirst() {
        let attempts = [
            attempt(daysAgo: 5, difficulty: .easy, correct: false, impact: -2),
            attempt(daysAgo: 4, difficulty: .medium, correct: true, impact: -20),
            attempt(daysAgo: 3, difficulty: .hard, correct: false, impact: -8),
            attempt(daysAgo: 2, difficulty: .medium, correct: false, impact: 1),
            attempt(daysAgo: 1, difficulty: .easy, correct: false, impact: -5)
        ]

        let queue = WhatToPlayStatsAnalyzer.reviewQueue(for: attempts, limit: 3)

        XCTAssertEqual(queue.map(\.expectedImpact), [-8, -5, -2])
        XCTAssertEqual(queue.first?.difficulty, .hard)
        XCTAssertEqual(queue.first?.seed, 3)
        XCTAssertEqual(queue.first?.title, "راجع اختيارًا مكلفًا".localized)
    }

    func testReviewQueuePrioritizesLargestLostExpectedPointsWhenKnown() {
        let attempts = [
            attempt(daysAgo: 3, difficulty: .easy, correct: false, impact: -5, bestImpact: -1),
            attempt(daysAgo: 2, difficulty: .hard, correct: false, impact: 2, bestImpact: 14),
            attempt(daysAgo: 1, difficulty: .medium, correct: false, impact: -9, bestImpact: -8)
        ]

        let queue = WhatToPlayStatsAnalyzer.reviewQueue(for: attempts, limit: 3)

        XCTAssertEqual(queue.map(\.lostExpectedPoints), [12, 4, 1])
        XCTAssertEqual(queue.first?.difficulty, .hard)
        XCTAssertEqual(queue.first?.expectedImpact, 2)
    }

    func testReviewQueueLabelsPositiveLargeGapAsMissedOpportunity() {
        let attempts = [
            attempt(daysAgo: 1, difficulty: .hard, correct: false, impact: 3, bestImpact: 12)
        ]

        let item = WhatToPlayStatsAnalyzer.reviewQueue(for: attempts).first

        XCTAssertEqual(item?.title, "راجع فرصة ضائعة".localized)
        XCTAssertEqual(item?.detail, "\("قرارك لم يكن خاسرًا مباشرة، لكنه ضيّع نقاطًا متوقعة عن اختيار الخبير".localized): 9. \("راجع لماذا كانت الورقة الأفضل أعلى قيمة.".localized)")
        XCTAssertEqual(item?.iconName, "arrow.up.right.circle.fill")
    }

    func testReviewQueueCarriesLostExpectedPoints() {
        let attempts = [
            attempt(daysAgo: 1, correct: false, impact: -4, bestImpact: 3)
        ]

        let queue = WhatToPlayStatsAnalyzer.reviewQueue(for: attempts)

        XCTAssertEqual(queue.first?.lostExpectedPoints, 7)
    }

    func testReviewQueueCarriesSecondBestForReplayReview() {
        let secondBest = PlayingCard(suit: .diamonds, rank: .ace)
        let attempts = [
            attempt(
                daysAgo: 1,
                difficulty: .hard,
                correct: false,
                impact: -4,
                bestImpact: 3,
                secondBestCard: secondBest,
                secondBestImpact: 1
            )
        ]

        let queue = WhatToPlayStatsAnalyzer.reviewQueue(for: attempts)

        XCTAssertEqual(queue.first?.secondBestCard, secondBest)
        XCTAssertEqual(queue.first?.secondBestExpectedImpact, 1)
    }

    func testReviewQueueCarriesScenarioFocusForReplay() {
        let attempts = [
            attempt(
                daysAgo: 1,
                difficulty: .medium,
                correct: false,
                impact: -4,
                bestImpact: 3,
                focusKind: .followSuit
            )
        ]

        let queue = WhatToPlayStatsAnalyzer.reviewQueue(for: attempts)

        XCTAssertEqual(queue.first?.focusKind, .followSuit)
    }

    func testReviewPriorityMarksNegativeImpactAsHighPriority() throws {
        let item = try XCTUnwrap(
            WhatToPlayStatsAnalyzer.reviewQueue(
                for: [attempt(daysAgo: 1, correct: false, impact: -4, bestImpact: 3)]
            ).first
        )

        let priority = WhatToPlayStatsAnalyzer.reviewPriority(for: item)

        XCTAssertEqual(priority.title, "أولوية عالية".localized)
        XCTAssertEqual(priority.iconName, "exclamationmark.triangle.fill")
        XCTAssertTrue(priority.detail.contains("-4"))
    }

    func testReviewPriorityMarksPositiveGapAsMissedValue() throws {
        let item = try XCTUnwrap(
            WhatToPlayStatsAnalyzer.reviewQueue(
                for: [attempt(daysAgo: 1, correct: false, impact: 3, bestImpact: 12)]
            ).first
        )

        let priority = WhatToPlayStatsAnalyzer.reviewPriority(for: item)

        XCTAssertEqual(priority.title, "فرصة قيمة ضاعت".localized)
        XCTAssertEqual(priority.iconName, "arrow.up.right.circle.fill")
        XCTAssertTrue(priority.detail.contains("9"))
    }

    func testReviewPriorityMarksSmallGapAsTacticalDifference() throws {
        let item = try XCTUnwrap(
            WhatToPlayStatsAnalyzer.reviewQueue(
                for: [attempt(daysAgo: 1, correct: false, impact: 4, bestImpact: 5)]
            ).first
        )

        let priority = WhatToPlayStatsAnalyzer.reviewPriority(for: item)

        XCTAssertEqual(priority.title, "فرق تكتيكي قريب".localized)
        XCTAssertEqual(priority.iconName, "2.circle.fill")
    }

    func testReviewQueueUsesRecentTieBreakerForEqualImpact() {
        let attempts = [
            attempt(daysAgo: 3, correct: false, impact: -4),
            attempt(daysAgo: 1, correct: false, impact: -4)
        ]

        let queue = WhatToPlayStatsAnalyzer.reviewQueue(for: attempts)

        XCTAssertEqual(queue.first?.createdAt, attempts[1].createdAt)
    }

    func testReviewQueueReturnsEmptyForCorrectAttemptsOrZeroLimit() {
        let attempts = [
            attempt(daysAgo: 2, correct: true, impact: -10),
            attempt(daysAgo: 1, correct: true, impact: 4)
        ]

        XCTAssertTrue(WhatToPlayStatsAnalyzer.reviewQueue(for: attempts).isEmpty)
        XCTAssertTrue(WhatToPlayStatsAnalyzer.reviewQueue(for: [attempt(daysAgo: 1, correct: false, impact: -4)], limit: 0).isEmpty)
    }

    func testSummariesByDifficultySkipEmptyLevelsAndPreserveDifficultyOrder() {
        let attempts = [
            attempt(daysAgo: 3, difficulty: .hard, correct: true, impact: 4),
            attempt(daysAgo: 2, difficulty: .easy, correct: false, impact: -2),
            attempt(daysAgo: 1, difficulty: .hard, correct: false, impact: -6)
        ]

        let summaries = WhatToPlayStatsAnalyzer.summariesByDifficulty(attempts)

        XCTAssertEqual(summaries.map(\.difficulty), [.easy, .hard])
        XCTAssertEqual(summaries.first?.summary.accuracyPercent, 0)
        XCTAssertEqual(summaries.last?.summary.attempts, 2)
        XCTAssertEqual(summaries.last?.summary.accuracyPercent, 50)
    }

    func testSummariesByScenarioFocusSkipLegacyAttemptsAndPreserveFocusOrder() {
        let attempts = [
            attempt(daysAgo: 4, difficulty: .easy, correct: true, impact: 4, bestImpact: 4, focusKind: .trumpPressure),
            attempt(daysAgo: 3, difficulty: .easy, correct: false, impact: -2, bestImpact: 3, focusKind: .openingLead),
            attempt(daysAgo: 2, difficulty: .medium, correct: false, impact: -4, bestImpact: 2, focusKind: .trumpPressure),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: 1)
        ]

        let summaries = WhatToPlayStatsAnalyzer.summariesByScenarioFocus(attempts)

        XCTAssertEqual(summaries.map(\.focusKind), [.openingLead, .trumpPressure])
        XCTAssertEqual(summaries.first?.summary.lostExpectedPoints, 5)
        XCTAssertEqual(summaries.last?.summary.attempts, 2)
        XCTAssertEqual(summaries.last?.summary.accuracyPercent, 50)
        XCTAssertEqual(summaries.last?.summary.lostExpectedPoints, 6)
    }

    func testFocusScenarioKindPicksWeakestTrainingFocus() {
        let attempts = [
            attempt(daysAgo: 6, difficulty: .easy, correct: true, impact: 3, bestImpact: 3, focusKind: .openingLead),
            attempt(daysAgo: 5, difficulty: .easy, correct: false, impact: -1, bestImpact: 2, focusKind: .openingLead),
            attempt(daysAgo: 4, difficulty: .medium, correct: false, impact: -8, bestImpact: 4, focusKind: .trumpPressure),
            attempt(daysAgo: 3, difficulty: .medium, correct: true, impact: 2, bestImpact: 2, focusKind: .trumpPressure),
            attempt(daysAgo: 2, difficulty: .hard, correct: false, impact: -3, bestImpact: 2, focusKind: .followSuit),
            attempt(daysAgo: 1, difficulty: .hard, correct: false, impact: -2, bestImpact: 1, focusKind: .followSuit)
        ]

        let focus = WhatToPlayStatsAnalyzer.focusScenarioKind(attempts)

        XCTAssertEqual(focus?.focusKind, .followSuit)
        XCTAssertEqual(focus?.summary.accuracyPercent, 0)
        XCTAssertEqual(focus?.summary.lostExpectedPoints, 8)
    }

    func testFocusScenarioKindUsesLostPointsAsTieBreaker() {
        let attempts = [
            attempt(daysAgo: 4, difficulty: .easy, correct: false, impact: -4, bestImpact: 1, focusKind: .openingLead),
            attempt(daysAgo: 3, difficulty: .easy, correct: true, impact: 1, bestImpact: 1, focusKind: .openingLead),
            attempt(daysAgo: 2, difficulty: .medium, correct: false, impact: -9, bestImpact: 3, focusKind: .trumpPressure),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: 3, bestImpact: 3, focusKind: .trumpPressure)
        ]

        let focus = WhatToPlayStatsAnalyzer.focusScenarioKind(attempts)

        XCTAssertEqual(focus?.focusKind, .trumpPressure)
        XCTAssertEqual(focus?.summary.accuracyPercent, 50)
        XCTAssertEqual(focus?.summary.lostExpectedPoints, 12)
    }

    func testFocusDifficultyRequiresMinimumAttemptsAndPicksLowestAccuracy() {
        let attempts = [
            attempt(daysAgo: 5, difficulty: .easy, correct: false, impact: -20),
            attempt(daysAgo: 4, difficulty: .medium, correct: true, impact: 4),
            attempt(daysAgo: 3, difficulty: .medium, correct: false, impact: -2),
            attempt(daysAgo: 2, difficulty: .hard, correct: false, impact: -8),
            attempt(daysAgo: 1, difficulty: .hard, correct: false, impact: -6)
        ]

        let focus = WhatToPlayStatsAnalyzer.focusDifficulty(attempts)

        XCTAssertEqual(focus?.difficulty, .hard)
        XCTAssertEqual(focus?.summary.accuracyPercent, 0)
    }

    func testFocusDifficultyReturnsNilWithoutEnoughAttempts() {
        let attempts = [
            attempt(daysAgo: 1, difficulty: .easy, correct: false, impact: -10)
        ]

        XCTAssertNil(WhatToPlayStatsAnalyzer.focusDifficulty(attempts))
    }

    func testFocusDifficultyUsesExpectedImpactAsTieBreaker() {
        let attempts = [
            attempt(daysAgo: 4, difficulty: .medium, correct: true, impact: 0),
            attempt(daysAgo: 3, difficulty: .medium, correct: false, impact: -10),
            attempt(daysAgo: 2, difficulty: .hard, correct: true, impact: 6),
            attempt(daysAgo: 1, difficulty: .hard, correct: false, impact: 0)
        ]

        let focus = WhatToPlayStatsAnalyzer.focusDifficulty(attempts)

        XCTAssertEqual(focus?.difficulty, .medium)
        XCTAssertEqual(focus?.summary.accuracyPercent, 50)
        XCTAssertEqual(focus?.summary.averageExpectedImpact, -5)
    }

    func testDifficultyImpactInsightRequiresEnoughSamples() {
        let attempts = [
            attempt(daysAgo: 1, difficulty: .hard, correct: false, impact: -10)
        ]

        XCTAssertNil(WhatToPlayStatsAnalyzer.difficultyImpactInsight(for: attempts))
    }

    func testDifficultyImpactInsightFindsWorstExpectedImpactDifficulty() {
        let attempts = [
            attempt(daysAgo: 6, difficulty: .easy, correct: true, impact: 2),
            attempt(daysAgo: 5, difficulty: .easy, correct: false, impact: 0),
            attempt(daysAgo: 4, difficulty: .medium, correct: true, impact: -2),
            attempt(daysAgo: 3, difficulty: .medium, correct: false, impact: -6),
            attempt(daysAgo: 2, difficulty: .hard, correct: false, impact: -1),
            attempt(daysAgo: 1, difficulty: .hard, correct: true, impact: 1)
        ]

        let insight = WhatToPlayStatsAnalyzer.difficultyImpactInsight(for: attempts)

        XCTAssertEqual(insight?.difficulty, .medium)
        XCTAssertEqual(insight?.averageExpectedImpact, -4)
        XCTAssertEqual(insight?.attempts, 2)
        XCTAssertEqual(insight?.title, "أكبر نزيف حسب الصعوبة".localized)
    }

    func testDifficultyImpactInsightReportsNoLeakWhenAveragesAreNonNegative() {
        let attempts = [
            attempt(daysAgo: 4, difficulty: .easy, correct: true, impact: 2),
            attempt(daysAgo: 3, difficulty: .easy, correct: false, impact: 0),
            attempt(daysAgo: 2, difficulty: .medium, correct: true, impact: 4),
            attempt(daysAgo: 1, difficulty: .medium, correct: false, impact: 0)
        ]

        let insight = WhatToPlayStatsAnalyzer.difficultyImpactInsight(for: attempts)

        XCTAssertEqual(insight?.difficulty, .easy)
        XCTAssertEqual(insight?.averageExpectedImpact, 1)
        XCTAssertEqual(insight?.title, "لا يوجد نزيف واضح".localized)
    }

    func testPerformanceTrendDetectsImprovement() {
        let attempts = [
            attempt(daysAgo: 6, correct: false, impact: -6),
            attempt(daysAgo: 5, correct: false, impact: -4),
            attempt(daysAgo: 4, correct: false, impact: -2),
            attempt(daysAgo: 3, correct: true, impact: 2),
            attempt(daysAgo: 2, correct: true, impact: 4),
            attempt(daysAgo: 1, correct: true, impact: 6)
        ]

        let trend = WhatToPlayStatsAnalyzer.performanceTrend(attempts: attempts, recentWindow: 3)

        XCTAssertEqual(trend?.direction, .improving)
        XCTAssertEqual(trend?.recentAccuracyPercent, 100)
        XCTAssertEqual(trend?.previousAccuracyPercent, 0)
    }

    func testPerformanceTrendDetectsDecline() {
        let attempts = [
            attempt(daysAgo: 6, correct: true, impact: 6),
            attempt(daysAgo: 5, correct: true, impact: 4),
            attempt(daysAgo: 4, correct: true, impact: 2),
            attempt(daysAgo: 3, correct: false, impact: -2),
            attempt(daysAgo: 2, correct: false, impact: -4),
            attempt(daysAgo: 1, correct: false, impact: -6)
        ]

        let trend = WhatToPlayStatsAnalyzer.performanceTrend(attempts: attempts, recentWindow: 3)

        XCTAssertEqual(trend?.direction, .declining)
        XCTAssertEqual(trend?.recentAccuracyPercent, 0)
        XCTAssertEqual(trend?.previousAccuracyPercent, 100)
    }

    func testPerformanceTrendDetectsStablePerformance() {
        let attempts = [
            attempt(daysAgo: 6, correct: true, impact: 2),
            attempt(daysAgo: 5, correct: false, impact: -2),
            attempt(daysAgo: 4, correct: true, impact: 2),
            attempt(daysAgo: 3, correct: true, impact: 2),
            attempt(daysAgo: 2, correct: false, impact: -2),
            attempt(daysAgo: 1, correct: true, impact: 2)
        ]

        let trend = WhatToPlayStatsAnalyzer.performanceTrend(attempts: attempts, recentWindow: 3)

        XCTAssertEqual(trend?.direction, .stable)
        XCTAssertEqual(trend?.recentAccuracyPercent, 67)
        XCTAssertEqual(trend?.previousAccuracyPercent, 67)
    }

    func testPerformanceTrendReturnsNilWithoutEnoughAttempts() {
        let attempts = [
            attempt(daysAgo: 3, correct: true, impact: 2),
            attempt(daysAgo: 2, correct: false, impact: -2),
            attempt(daysAgo: 1, correct: true, impact: 2)
        ]

        XCTAssertNil(WhatToPlayStatsAnalyzer.performanceTrend(attempts: attempts, recentWindow: 3))
    }

    func testPracticeRecommendationStartsEasyWithoutAttempts() {
        let recommendation = WhatToPlayStatsAnalyzer.practiceRecommendation(for: [])

        XCTAssertEqual(recommendation.difficulty, .easy)
        XCTAssertEqual(recommendation.title, "ابدأ من السهل".localized)
    }

    func testPracticeRecommendationUsesWeakFocusDifficulty() {
        let attempts = [
            attempt(daysAgo: 5, difficulty: .easy, correct: true, impact: 4),
            attempt(daysAgo: 4, difficulty: .easy, correct: true, impact: 4),
            attempt(daysAgo: 3, difficulty: .hard, correct: false, impact: -8),
            attempt(daysAgo: 2, difficulty: .hard, correct: false, impact: -6),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: 2)
        ]

        let recommendation = WhatToPlayStatsAnalyzer.practiceRecommendation(for: attempts)

        XCTAssertEqual(recommendation.difficulty, .hard)
        XCTAssertEqual(recommendation.title, "درّب نقطة الضعف".localized)
    }

    func testPracticeRecommendationRaisesChallengeAfterStrongStreak() {
        let attempts = [
            attempt(daysAgo: 4, difficulty: .easy, correct: true, impact: 4),
            attempt(daysAgo: 3, difficulty: .easy, correct: true, impact: 4),
            attempt(daysAgo: 2, difficulty: .easy, correct: true, impact: 4),
            attempt(daysAgo: 1, difficulty: .easy, correct: true, impact: 4)
        ]

        let recommendation = WhatToPlayStatsAnalyzer.practiceRecommendation(for: attempts)

        XCTAssertEqual(recommendation.difficulty, .medium)
        XCTAssertEqual(recommendation.title, "ارفع التحدي".localized)
    }

    func testPracticeRecommendationRespondsToDecline() {
        let attempts = [
            attempt(daysAgo: 6, difficulty: .medium, correct: true, impact: 5),
            attempt(daysAgo: 5, difficulty: .medium, correct: true, impact: 4),
            attempt(daysAgo: 4, difficulty: .medium, correct: true, impact: 3),
            attempt(daysAgo: 3, difficulty: .medium, correct: false, impact: -1),
            attempt(daysAgo: 2, difficulty: .medium, correct: false, impact: -2),
            attempt(daysAgo: 1, difficulty: .medium, correct: false, impact: -3)
        ]

        let recommendation = WhatToPlayStatsAnalyzer.practiceRecommendation(for: attempts)

        XCTAssertEqual(recommendation.difficulty, .medium)
        XCTAssertEqual(recommendation.title, "ارجع خطوة تكتيكية".localized)
    }

    func testDecisionInsightRecognizesExpertMatch() {
        let insight = WhatToPlayStatsAnalyzer.decisionInsight(
            selectedRank: 1,
            selectedImpact: 8,
            bestImpact: 8,
            secondBestImpact: 6
        )

        XCTAssertEqual(insight.kind, .expertMatch)
        XCTAssertEqual(insight.lostExpectedPoints, 0)
        XCTAssertEqual(insight.secondBestGap, 0)
        XCTAssertEqual(insight.title, "اختيار خبير".localized)
    }

    func testDecisionInsightRecognizesCloseAlternative() {
        let insight = WhatToPlayStatsAnalyzer.decisionInsight(
            selectedRank: 2,
            selectedImpact: 6,
            bestImpact: 8,
            secondBestImpact: 6
        )

        XCTAssertEqual(insight.kind, .closeAlternative)
        XCTAssertEqual(insight.lostExpectedPoints, 2)
        XCTAssertEqual(insight.secondBestGap, 0)
    }

    func testDecisionInsightRecognizesMissedWinningChance() {
        let insight = WhatToPlayStatsAnalyzer.decisionInsight(
            selectedRank: 4,
            selectedImpact: -3,
            bestImpact: 7,
            secondBestImpact: 2
        )

        XCTAssertEqual(insight.kind, .missedWinningChance)
        XCTAssertEqual(insight.lostExpectedPoints, 10)
        XCTAssertEqual(insight.secondBestGap, 5)
    }

    func testDecisionInsightRecognizesPointLeak() {
        let insight = WhatToPlayStatsAnalyzer.decisionInsight(
            selectedRank: 3,
            selectedImpact: 1,
            bestImpact: 6,
            secondBestImpact: 4
        )

        XCTAssertEqual(insight.kind, .pointLeak)
        XCTAssertEqual(insight.lostExpectedPoints, 5)
        XCTAssertEqual(insight.secondBestGap, 3)
    }

    func testDecisionInsightKeepsSecondBestGapNilWhenUnavailable() {
        let insight = WhatToPlayStatsAnalyzer.decisionInsight(
            selectedRank: 3,
            selectedImpact: 1,
            bestImpact: 6,
            secondBestImpact: nil
        )

        XCTAssertNil(insight.secondBestGap)
    }

    func testDecisionReviewUsesScenarioFocusAndDecisionKind() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let selected = try XCTUnwrap(scenario.options.last)

        let review = try XCTUnwrap(WhatToPlayStatsAnalyzer.decisionReview(for: selected, in: scenario))

        XCTAssertEqual(review.title, "راجع القرار بهذه الطريقة".localized)
        XCTAssertEqual(review.steps.count, 3)
        XCTAssertEqual(review.steps.first, expectedFirstReviewStep(for: scenario.context.focusKind))
        XCTAssertEqual(review.steps.last, "أعد الموقف إذا كان الفارق أكثر من نقطتين متوقعتين.".localized)
    }

    func testDecisionReviewUsesMissedWinningChanceRemedy() throws {
        let insight = WhatToPlayStatsAnalyzer.decisionInsight(
            selectedRank: 3,
            selectedImpact: -3,
            bestImpact: 7,
            secondBestImpact: 2
        )

        let review = WhatToPlayStatsAnalyzer.decisionReview(insight: insight, focusKind: .followSuit)

        XCTAssertEqual(review.steps.first, expectedFirstReviewStep(for: .followSuit))
        XCTAssertTrue(review.steps.contains("ابحث عن الورقة التي كانت ستحوّل الأكلة من خسارة إلى ربح.".localized))
    }

    func testNextDecisionActionReinforcesExpertMatchByFocus() {
        let insight = WhatToPlayStatsAnalyzer.decisionInsight(
            selectedRank: 1,
            selectedImpact: 8,
            bestImpact: 8,
            secondBestImpact: 5
        )
        let bestCard = PlayingCard(suit: .spades, rank: .ace)

        let action = WhatToPlayStatsAnalyzer.nextDecisionAction(
            insight: insight,
            focusKind: .trumpPressure,
            bestCard: bestCard
        )

        XCTAssertEqual(action.title, "ثبّت القراءة".localized)
        XCTAssertTrue(action.detail.contains("الحكم".localized))
        XCTAssertEqual(action.recommendedCard, bestCard)
    }

    func testNextDecisionActionTargetsMissedWinningChance() {
        let insight = WhatToPlayStatsAnalyzer.decisionInsight(
            selectedRank: 4,
            selectedImpact: -3,
            bestImpact: 7,
            secondBestImpact: 2
        )

        let action = WhatToPlayStatsAnalyzer.nextDecisionAction(
            insight: insight,
            focusKind: .followSuit,
            bestCard: PlayingCard(suit: .hearts, rank: .king)
        )

        XCTAssertEqual(action.title, "ابحث عن الورقة الرابحة".localized)
        XCTAssertTrue(action.detail.contains("تنقل الأكلة لفريقك".localized))
    }

    func testScenarioBriefExplainsFollowSuitContext() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(
            seed: 2026,
            difficulty: .easy,
            preferredFocus: .followSuit
        )

        let brief = WhatToPlayStatsAnalyzer.scenarioBrief(for: scenario)

        XCTAssertEqual(brief.title, "التزم باللون المطلوب".localized)
        XCTAssertEqual(brief.iconName, "suit.club.fill")
        if let requiredSuit = scenario.context.requiredSuit {
            XCTAssertTrue(brief.detail.contains(requiredSuit.spokenName))
        }
    }

    func testScenarioBriefExplainsNarrowChoiceContext() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(
            seed: 2026,
            difficulty: .easy,
            preferredFocus: .narrowChoice
        )

        let brief = WhatToPlayStatsAnalyzer.scenarioBrief(for: scenario)

        XCTAssertEqual(brief.title, "خياراتك محدودة".localized)
        XCTAssertEqual(brief.iconName, "2.circle.fill")
        XCTAssertTrue(brief.detail.contains("\(scenario.context.legalOptionCount)"))
    }

    func testMasteryStartsAtZeroWithoutAttempts() {
        let mastery = WhatToPlayStatsAnalyzer.mastery(for: [])

        XCTAssertEqual(mastery.level, .starting)
        XCTAssertEqual(mastery.score, 0)
        XCTAssertEqual(mastery.title, "بداية التدريب".localized)
    }

    func testMasteryDetectsBuildingLevel() {
        let attempts = [
            attempt(daysAgo: 4, correct: true, impact: 0),
            attempt(daysAgo: 3, correct: false, impact: 0),
            attempt(daysAgo: 2, correct: false, impact: 0),
            attempt(daysAgo: 1, correct: true, impact: 0)
        ]

        let mastery = WhatToPlayStatsAnalyzer.mastery(for: attempts)

        XCTAssertEqual(mastery.level, .building)
        XCTAssertEqual(mastery.score, 44)
    }

    func testMasteryDetectsConfidentLevel() {
        let attempts = [
            attempt(daysAgo: 4, correct: true, impact: 0),
            attempt(daysAgo: 3, correct: false, impact: 0),
            attempt(daysAgo: 2, correct: true, impact: 0),
            attempt(daysAgo: 1, correct: true, impact: 0)
        ]

        let mastery = WhatToPlayStatsAnalyzer.mastery(for: attempts)

        XCTAssertEqual(mastery.level, .confident)
        XCTAssertEqual(mastery.score, 63)
    }

    func testMasteryDetectsSharpLevel() {
        let attempts = [
            attempt(daysAgo: 5, correct: true, impact: 10),
            attempt(daysAgo: 4, correct: true, impact: 10),
            attempt(daysAgo: 3, correct: true, impact: 10),
            attempt(daysAgo: 2, correct: true, impact: 10),
            attempt(daysAgo: 1, correct: true, impact: 10)
        ]

        let mastery = WhatToPlayStatsAnalyzer.mastery(for: attempts)

        XCTAssertEqual(mastery.level, .sharp)
        XCTAssertEqual(mastery.score, 100)
    }

    func testMasteryMilestoneTargetsBuildingFromStartingScore() {
        let attempts = [
            attempt(daysAgo: 2, correct: false, impact: -10),
            attempt(daysAgo: 1, correct: false, impact: -10)
        ]

        let milestone = WhatToPlayStatsAnalyzer.masteryMilestone(for: attempts)

        XCTAssertEqual(milestone?.targetScore, 35)
        XCTAssertEqual(milestone?.targetTitle, "تبني القراءة".localized)
        XCTAssertEqual(milestone?.pointsRemaining, 35)
    }

    func testMasteryMilestoneTargetsConfidentFromBuildingScore() {
        let attempts = [
            attempt(daysAgo: 4, correct: true, impact: 0),
            attempt(daysAgo: 3, correct: false, impact: 0),
            attempt(daysAgo: 2, correct: false, impact: 0),
            attempt(daysAgo: 1, correct: true, impact: 0)
        ]

        let milestone = WhatToPlayStatsAnalyzer.masteryMilestone(for: attempts)

        XCTAssertEqual(milestone?.targetScore, 60)
        XCTAssertEqual(milestone?.targetTitle, "متمكن".localized)
        XCTAssertEqual(milestone?.pointsRemaining, 16)
    }

    func testMasteryMilestoneReturnsNilAfterSharpLevel() {
        let attempts = [
            attempt(daysAgo: 5, correct: true, impact: 10),
            attempt(daysAgo: 4, correct: true, impact: 10),
            attempt(daysAgo: 3, correct: true, impact: 10),
            attempt(daysAgo: 2, correct: true, impact: 10),
            attempt(daysAgo: 1, correct: true, impact: 10)
        ]

        XCTAssertNil(WhatToPlayStatsAnalyzer.masteryMilestone(for: attempts))
    }

    func testPracticeCoverageReportsMissingDifficulties() {
        let attempts = [
            attempt(daysAgo: 2, difficulty: .easy, correct: true, impact: 2),
            attempt(daysAgo: 1, difficulty: .easy, correct: false, impact: -2)
        ]

        let coverage = WhatToPlayStatsAnalyzer.practiceCoverage(for: attempts)

        XCTAssertFalse(coverage.isBalanced)
        XCTAssertEqual(coverage.sampledDifficulties, 1)
        XCTAssertEqual(coverage.totalDifficulties, 3)
        XCTAssertEqual(coverage.missingDifficulties, [.medium, .hard])
        XCTAssertEqual(coverage.title, "أكمل تغطية التدريب".localized)
    }

    func testPracticeCoverageRequiresMinimumAttemptsPerDifficulty() {
        let attempts = [
            attempt(daysAgo: 5, difficulty: .easy, correct: true, impact: 2),
            attempt(daysAgo: 4, difficulty: .easy, correct: true, impact: 2),
            attempt(daysAgo: 3, difficulty: .medium, correct: true, impact: 2),
            attempt(daysAgo: 2, difficulty: .hard, correct: true, impact: 2),
            attempt(daysAgo: 1, difficulty: .hard, correct: true, impact: 2)
        ]

        let coverage = WhatToPlayStatsAnalyzer.practiceCoverage(for: attempts)

        XCTAssertFalse(coverage.isBalanced)
        XCTAssertEqual(coverage.sampledDifficulties, 2)
        XCTAssertEqual(coverage.missingDifficulties, [.medium])
    }

    func testPracticeCoverageReportsBalancedCoverage() {
        let attempts = [
            attempt(daysAgo: 6, difficulty: .easy, correct: true, impact: 2),
            attempt(daysAgo: 5, difficulty: .easy, correct: false, impact: -2),
            attempt(daysAgo: 4, difficulty: .medium, correct: true, impact: 2),
            attempt(daysAgo: 3, difficulty: .medium, correct: false, impact: -2),
            attempt(daysAgo: 2, difficulty: .hard, correct: true, impact: 2),
            attempt(daysAgo: 1, difficulty: .hard, correct: false, impact: -2)
        ]

        let coverage = WhatToPlayStatsAnalyzer.practiceCoverage(for: attempts)

        XCTAssertTrue(coverage.isBalanced)
        XCTAssertEqual(coverage.sampledDifficulties, 3)
        XCTAssertTrue(coverage.missingDifficulties.isEmpty)
        XCTAssertEqual(coverage.title, "تغطية متوازنة".localized)
    }

    func testScenarioFocusCoverageReportsMissingFocusKinds() {
        let attempts = [
            attempt(daysAgo: 3, difficulty: .easy, correct: true, impact: 2, focusKind: .openingLead),
            attempt(daysAgo: 2, difficulty: .easy, correct: false, impact: -2, focusKind: .openingLead),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: 1, focusKind: .trumpPressure)
        ]

        let coverage = WhatToPlayStatsAnalyzer.scenarioFocusCoverage(for: attempts)

        XCTAssertFalse(coverage.isBalanced)
        XCTAssertEqual(coverage.sampledFocusKinds, 1)
        XCTAssertEqual(coverage.totalFocusKinds, 4)
        XCTAssertEqual(coverage.missingFocusKinds, [.followSuit, .trumpPressure, .narrowChoice])
        XCTAssertEqual(coverage.title, "أكمل أنواع المواقف".localized)
    }

    func testScenarioFocusCoverageReportsBalancedCoverage() {
        let attempts = [
            attempt(daysAgo: 8, difficulty: .easy, correct: true, impact: 2, focusKind: .openingLead),
            attempt(daysAgo: 7, difficulty: .easy, correct: false, impact: -2, focusKind: .openingLead),
            attempt(daysAgo: 6, difficulty: .medium, correct: true, impact: 2, focusKind: .followSuit),
            attempt(daysAgo: 5, difficulty: .medium, correct: false, impact: -2, focusKind: .followSuit),
            attempt(daysAgo: 4, difficulty: .hard, correct: true, impact: 2, focusKind: .trumpPressure),
            attempt(daysAgo: 3, difficulty: .hard, correct: false, impact: -2, focusKind: .trumpPressure),
            attempt(daysAgo: 2, difficulty: .easy, correct: true, impact: 2, focusKind: .narrowChoice),
            attempt(daysAgo: 1, difficulty: .easy, correct: false, impact: -2, focusKind: .narrowChoice)
        ]

        let coverage = WhatToPlayStatsAnalyzer.scenarioFocusCoverage(for: attempts)

        XCTAssertTrue(coverage.isBalanced)
        XCTAssertEqual(coverage.sampledFocusKinds, 4)
        XCTAssertTrue(coverage.missingFocusKinds.isEmpty)
        XCTAssertEqual(coverage.title, "تغطية مواقف متوازنة".localized)
    }

    func testFocusTrainingPriorityUsesLargestLostPointsByFocus() {
        let attempts = [
            attempt(daysAgo: 6, correct: false, impact: -1, bestImpact: 1, focusKind: .openingLead),
            attempt(daysAgo: 5, correct: true, impact: 1, bestImpact: 1, focusKind: .openingLead),
            attempt(daysAgo: 4, correct: false, impact: -8, bestImpact: 4, focusKind: .trumpPressure),
            attempt(daysAgo: 3, correct: true, impact: 2, bestImpact: 2, focusKind: .trumpPressure),
            attempt(daysAgo: 2, correct: false, impact: -3, bestImpact: 2, focusKind: .followSuit),
            attempt(daysAgo: 1, correct: true, impact: 2, bestImpact: 2, focusKind: .followSuit)
        ]

        let priority = WhatToPlayStatsAnalyzer.focusTrainingPriority(for: attempts)

        XCTAssertEqual(priority?.focusKind, .trumpPressure)
        XCTAssertEqual(priority?.summary.lostExpectedPoints, 12)
        XCTAssertEqual(priority?.title, "\("أولوية التدريب".localized): \("ضغط الحكم".localized)")
        XCTAssertEqual(priority?.iconName, "crown.fill")
    }

    func testFocusTrainingPriorityUsesWorstAccuracyWhenLostPointsTie() {
        let attempts = [
            attempt(daysAgo: 6, correct: false, impact: -1, bestImpact: 3, focusKind: .openingLead),
            attempt(daysAgo: 5, correct: true, impact: 1, bestImpact: 1, focusKind: .openingLead),
            attempt(daysAgo: 4, correct: false, impact: -2, bestImpact: 2, focusKind: .followSuit),
            attempt(daysAgo: 3, correct: false, impact: 0, bestImpact: 0, focusKind: .followSuit)
        ]

        let priority = WhatToPlayStatsAnalyzer.focusTrainingPriority(for: attempts)

        XCTAssertEqual(priority?.focusKind, .followSuit)
        XCTAssertEqual(priority?.summary.lostExpectedPoints, 4)
        XCTAssertEqual(priority?.summary.accuracyPercent, 0)
    }

    func testFocusTrainingPriorityWaitsForEnoughAttemptsPerFocus() {
        let attempts = [
            attempt(daysAgo: 2, correct: false, impact: -10, bestImpact: 5, focusKind: .trumpPressure),
            attempt(daysAgo: 1, correct: true, impact: 2, bestImpact: 2, focusKind: .openingLead)
        ]

        XCTAssertNil(WhatToPlayStatsAnalyzer.focusTrainingPriority(for: attempts))
    }

    func testFocusTrainingPriorityReturnsNilWhenFocusedPerformanceIsPerfect() {
        let attempts = [
            attempt(daysAgo: 4, correct: true, impact: 2, bestImpact: 2, focusKind: .openingLead),
            attempt(daysAgo: 3, correct: true, impact: 3, bestImpact: 3, focusKind: .openingLead),
            attempt(daysAgo: 2, correct: true, impact: 2, bestImpact: 2, focusKind: .followSuit),
            attempt(daysAgo: 1, correct: true, impact: 3, bestImpact: 3, focusKind: .followSuit)
        ]

        XCTAssertNil(WhatToPlayStatsAnalyzer.focusTrainingPriority(for: attempts))
    }

    func testSessionPulseReportsNoData() {
        let pulse = WhatToPlayStatsAnalyzer.sessionPulse(for: [])

        XCTAssertEqual(pulse.state, .noData)
        XCTAssertEqual(pulse.inspectedAttempts, 0)
        XCTAssertEqual(pulse.title, "لا توجد جلسة بعد".localized)
    }

    func testSessionPulseReportsWarmingUpBeforeWindowIsReady() {
        let attempts = [
            attempt(daysAgo: 2, correct: true, impact: 2),
            attempt(daysAgo: 1, correct: false, impact: -2)
        ]

        let pulse = WhatToPlayStatsAnalyzer.sessionPulse(for: attempts, window: 3)

        XCTAssertEqual(pulse.state, .warmingUp)
        XCTAssertEqual(pulse.inspectedAttempts, 2)
        XCTAssertEqual(pulse.title, "بداية جلسة".localized)
    }

    func testSessionPulseReportsFocusedRecentWindow() {
        let attempts = [
            attempt(daysAgo: 4, correct: false, impact: -10),
            attempt(daysAgo: 3, correct: true, impact: 2),
            attempt(daysAgo: 2, correct: true, impact: 3),
            attempt(daysAgo: 1, correct: true, impact: 4)
        ]

        let pulse = WhatToPlayStatsAnalyzer.sessionPulse(for: attempts, window: 3)

        XCTAssertEqual(pulse.state, .focused)
        XCTAssertEqual(pulse.inspectedAttempts, 3)
        XCTAssertEqual(pulse.title, "جلسة مركزة".localized)
    }

    func testSessionPulseReportsReviewNeededForRecentMistakes() {
        let attempts = [
            attempt(daysAgo: 4, correct: true, impact: 5),
            attempt(daysAgo: 3, correct: false, impact: -2),
            attempt(daysAgo: 2, correct: false, impact: -4),
            attempt(daysAgo: 1, correct: true, impact: -6)
        ]

        let pulse = WhatToPlayStatsAnalyzer.sessionPulse(for: attempts, window: 3)

        XCTAssertEqual(pulse.state, .reviewNeeded)
        XCTAssertEqual(pulse.inspectedAttempts, 3)
        XCTAssertEqual(pulse.title, "توقف للمراجعة".localized)
    }

    func testMicroDrillStartsWithBaselinePlanWithoutAttempts() {
        let drill = WhatToPlayStatsAnalyzer.microDrill(for: [])

        XCTAssertEqual(drill.title, "خطة البداية".localized)
        XCTAssertEqual(drill.steps.count, 3)
        XCTAssertEqual(drill.steps.first, "ابدأ بمستوى سهل".localized)
    }

    func testMicroDrillPrioritizesReviewWhenSessionNeedsReview() {
        let attempts = [
            attempt(daysAgo: 3, difficulty: .easy, correct: false, impact: -4, bestImpact: 0),
            attempt(daysAgo: 2, difficulty: .hard, correct: false, impact: -6, bestImpact: 5),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: -2, bestImpact: -2)
        ]

        let drill = WhatToPlayStatsAnalyzer.microDrill(for: attempts)

        XCTAssertEqual(drill.title, "خطة المراجعة".localized)
        XCTAssertEqual(drill.steps.first, "\("أعد موقف".localized) \("صعب".localized) · \("نقاط متوقعة ضائعة".localized): 11")
        XCTAssertEqual(drill.reviewItem?.difficulty, .hard)
        XCTAssertEqual(drill.reviewItem?.lostExpectedPoints, 11)
    }

    func testMicroDrillTargetsCoverageBeforeGenericPractice() {
        let attempts = [
            attempt(daysAgo: 3, difficulty: .easy, correct: true, impact: 3),
            attempt(daysAgo: 2, difficulty: .easy, correct: true, impact: 3),
            attempt(daysAgo: 1, difficulty: .easy, correct: true, impact: 3)
        ]

        let drill = WhatToPlayStatsAnalyzer.microDrill(for: attempts)

        XCTAssertEqual(drill.title, "خطة التوازن".localized)
        XCTAssertEqual(drill.steps.first, "أكمل المستويات الناقصة".localized)
    }

    func testMicroDrillRaisesChallengeForSharpBalancedPlayer() {
        let attempts = [
            attempt(daysAgo: 6, difficulty: .easy, correct: true, impact: 10),
            attempt(daysAgo: 5, difficulty: .easy, correct: true, impact: 10),
            attempt(daysAgo: 4, difficulty: .medium, correct: true, impact: 10),
            attempt(daysAgo: 3, difficulty: .medium, correct: true, impact: 10),
            attempt(daysAgo: 2, difficulty: .hard, correct: true, impact: 10),
            attempt(daysAgo: 1, difficulty: .hard, correct: true, impact: 10)
        ]

        let drill = WhatToPlayStatsAnalyzer.microDrill(for: attempts)

        XCTAssertEqual(drill.title, "خطة التحدي".localized)
        XCTAssertEqual(drill.steps.first, "انتقل إلى الصعب".localized)
    }

    func testMicroDrillFallsBackToContinuationPlan() {
        let attempts = [
            attempt(daysAgo: 6, difficulty: .easy, correct: true, impact: 0),
            attempt(daysAgo: 5, difficulty: .easy, correct: false, impact: 0),
            attempt(daysAgo: 4, difficulty: .medium, correct: true, impact: 0),
            attempt(daysAgo: 3, difficulty: .medium, correct: false, impact: 0),
            attempt(daysAgo: 2, difficulty: .hard, correct: true, impact: 0),
            attempt(daysAgo: 1, difficulty: .hard, correct: true, impact: 0)
        ]

        let drill = WhatToPlayStatsAnalyzer.microDrill(for: attempts)

        XCTAssertEqual(drill.title, "خطة الاستمرار".localized)
        XCTAssertEqual(drill.steps.first, "ابدأ بالمستوى المقترح".localized)
    }

    func testPlayStyleStaysInMeasurementModeWithSmallSample() {
        let attempts = [
            attempt(daysAgo: 2, correct: true, impact: 2),
            attempt(daysAgo: 1, correct: false, impact: -2)
        ]

        let style = WhatToPlayStatsAnalyzer.playStyle(for: attempts)

        XCTAssertEqual(style.kind, .measuring)
        XCTAssertEqual(style.title, "أسلوبك تحت القياس".localized)
    }

    func testPlayStyleRecognizesExpertAlignedDecisions() {
        let attempts = [
            attempt(daysAgo: 5, correct: true, impact: 4),
            attempt(daysAgo: 4, correct: true, impact: 2),
            attempt(daysAgo: 3, correct: true, impact: 3),
            attempt(daysAgo: 2, correct: true, impact: 1),
            attempt(daysAgo: 1, correct: false, impact: 0)
        ]

        let style = WhatToPlayStatsAnalyzer.playStyle(for: attempts)

        XCTAssertEqual(style.kind, .expertAligned)
        XCTAssertEqual(style.title, "قريب من الخبير".localized)
    }

    func testPlayStyleRecognizesFoundationalNeeds() {
        let attempts = [
            attempt(daysAgo: 4, correct: false, impact: -8),
            attempt(daysAgo: 3, correct: false, impact: -6),
            attempt(daysAgo: 2, correct: true, impact: 2),
            attempt(daysAgo: 1, correct: false, impact: -4)
        ]

        let style = WhatToPlayStatsAnalyzer.playStyle(for: attempts)

        XCTAssertEqual(style.kind, .foundational)
        XCTAssertEqual(style.title, "تحتاج تأسيس".localized)
    }

    func testPlayStyleRecognizesCautiousPointLeak() {
        let attempts = [
            attempt(daysAgo: 4, correct: true, impact: -4),
            attempt(daysAgo: 3, correct: true, impact: -2),
            attempt(daysAgo: 2, correct: true, impact: -1),
            attempt(daysAgo: 1, correct: false, impact: -5)
        ]

        let style = WhatToPlayStatsAnalyzer.playStyle(for: attempts)

        XCTAssertEqual(style.kind, .cautious)
        XCTAssertEqual(style.title, "لاعب حذر".localized)
    }

    func testPlayStyleFallsBackToInconsistentReading() {
        let attempts = [
            attempt(daysAgo: 4, correct: true, impact: 3),
            attempt(daysAgo: 3, correct: false, impact: -4),
            attempt(daysAgo: 2, correct: true, impact: 2),
            attempt(daysAgo: 1, correct: false, impact: -1)
        ]

        let style = WhatToPlayStatsAnalyzer.playStyle(for: attempts)

        XCTAssertEqual(style.kind, .inconsistent)
        XCTAssertEqual(style.title, "قراءة متذبذبة".localized)
    }

    func testDecisionPatternReportsNoData() {
        let pattern = WhatToPlayStatsAnalyzer.decisionPattern(for: [])

        XCTAssertEqual(pattern.kind, .noData)
        XCTAssertEqual(pattern.inspectedAttempts, 0)
        XCTAssertEqual(pattern.affectedAttempts, 0)
        XCTAssertEqual(pattern.title, "نمط قراراتك غير معروف".localized)
    }

    func testDecisionPatternReportsCleanRecentChoices() {
        let attempts = [
            attempt(daysAgo: 3, correct: true, impact: 4),
            attempt(daysAgo: 2, correct: true, impact: 2),
            attempt(daysAgo: 1, correct: true, impact: 1)
        ]

        let pattern = WhatToPlayStatsAnalyzer.decisionPattern(for: attempts)

        XCTAssertEqual(pattern.kind, .clean)
        XCTAssertEqual(pattern.inspectedAttempts, 3)
        XCTAssertEqual(pattern.affectedAttempts, 0)
        XCTAssertEqual(pattern.title, "قراراتك الأخيرة نظيفة".localized)
    }

    func testDecisionPatternRecognizesUsefulAlternatives() {
        let attempts = [
            attempt(daysAgo: 4, correct: true, impact: 3),
            attempt(daysAgo: 3, correct: false, impact: 2),
            attempt(daysAgo: 2, correct: false, impact: 0),
            attempt(daysAgo: 1, correct: false, impact: -1)
        ]

        let pattern = WhatToPlayStatsAnalyzer.decisionPattern(for: attempts)

        XCTAssertEqual(pattern.kind, .usefulAlternatives)
        XCTAssertEqual(pattern.inspectedAttempts, 4)
        XCTAssertEqual(pattern.affectedAttempts, 2)
        XCTAssertEqual(pattern.title, "اختيارات قريبة من الأفضل".localized)
    }

    func testDecisionPatternRecognizesPointLeaks() {
        let attempts = [
            attempt(daysAgo: 4, correct: false, impact: -5),
            attempt(daysAgo: 3, correct: false, impact: -2),
            attempt(daysAgo: 2, correct: false, impact: 1),
            attempt(daysAgo: 1, correct: true, impact: 3)
        ]

        let pattern = WhatToPlayStatsAnalyzer.decisionPattern(for: attempts)

        XCTAssertEqual(pattern.kind, .pointLeaks)
        XCTAssertEqual(pattern.inspectedAttempts, 4)
        XCTAssertEqual(pattern.affectedAttempts, 2)
        XCTAssertEqual(pattern.title, "أخطاء مكلفة".localized)
    }

    func testDecisionPatternUsesRecentLimit() {
        let attempts = [
            attempt(daysAgo: 5, correct: false, impact: -10),
            attempt(daysAgo: 4, correct: false, impact: -10),
            attempt(daysAgo: 3, correct: true, impact: 3),
            attempt(daysAgo: 2, correct: true, impact: 2),
            attempt(daysAgo: 1, correct: true, impact: 1)
        ]

        let pattern = WhatToPlayStatsAnalyzer.decisionPattern(for: attempts, limit: 3)

        XCTAssertEqual(pattern.kind, .clean)
        XCTAssertEqual(pattern.inspectedAttempts, 3)
    }

    func testTrainingSessionPlanStartsWithShortFoundation() {
        let plan = WhatToPlayStatsAnalyzer.trainingSessionPlan(for: [])

        XCTAssertEqual(plan.difficulty, .easy)
        XCTAssertEqual(plan.scenarioCount, 3)
        XCTAssertEqual(plan.targetAccuracyPercent, 60)
        XCTAssertEqual(plan.targetAverageExpectedImpact, 0)
        XCTAssertEqual(plan.title, "جلسة تأسيس قصيرة".localized)
    }

    func testNextTrainingSessionSeedIsStableForSameAttemptsAndPlan() {
        let plan = WhatToPlayStatsAnalyzer.trainingSessionPlan(for: [])

        let first = WhatToPlayStatsAnalyzer.nextTrainingSessionSeed(for: [], plan: plan)
        let second = WhatToPlayStatsAnalyzer.nextTrainingSessionSeed(for: [], plan: plan)

        XCTAssertEqual(first, second)
        XCTAssertEqual(first, 9_003_600)
    }

    func testNextTrainingSessionSeedAdvancesOnlyForMatchingPlanAttempts() {
        let plan = sessionPlan(difficulty: .medium, focusKind: .trumpPressure, count: 4, target: 70, impactTarget: 1)
        let attempts = [
            attempt(daysAgo: 4, difficulty: .easy, correct: true, impact: 2, focusKind: .trumpPressure),
            attempt(daysAgo: 3, difficulty: .medium, correct: false, impact: -2, focusKind: .openingLead),
            attempt(daysAgo: 2, difficulty: .medium, correct: true, impact: 3, focusKind: .trumpPressure),
            attempt(daysAgo: 1, difficulty: .medium, correct: false, impact: -1, focusKind: .trumpPressure)
        ]

        let seed = WhatToPlayStatsAnalyzer.nextTrainingSessionSeed(for: attempts, plan: plan)

        XCTAssertEqual(seed, 10_204_703)
    }

    func testTrainingSessionPlanPrioritizesReviewWhenRecentAttemptsNeedIt() {
        let attempts = [
            attempt(daysAgo: 4, difficulty: .medium, correct: true, impact: 5, bestImpact: 5, focusKind: .openingLead),
            attempt(daysAgo: 3, difficulty: .medium, correct: false, impact: -6, bestImpact: 4, focusKind: .trumpPressure),
            attempt(daysAgo: 2, difficulty: .medium, correct: false, impact: -4, bestImpact: 2, focusKind: .trumpPressure),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: -5, bestImpact: -5, focusKind: .openingLead)
        ]

        let plan = WhatToPlayStatsAnalyzer.trainingSessionPlan(for: attempts)

        XCTAssertEqual(plan.title, "جلسة مراجعة مركزة".localized)
        XCTAssertEqual(plan.focusKind, WhatToPlayScenarioFocusKind.trumpPressure)
        XCTAssertEqual(plan.scenarioCount, 3)
        XCTAssertEqual(plan.targetAverageExpectedImpact, 0)
        XCTAssertEqual(plan.successMetric, "هدف الجلسة: لا تكرر نفس سبب الخطأ مرتين.".localized)
    }

    func testTrainingSessionPlanRaisesLevelForExpertAlignedStyle() {
        let attempts = [
            attempt(daysAgo: 6, difficulty: .easy, correct: true, impact: 4),
            attempt(daysAgo: 5, difficulty: .easy, correct: true, impact: 4),
            attempt(daysAgo: 4, difficulty: .medium, correct: true, impact: 3),
            attempt(daysAgo: 3, difficulty: .medium, correct: true, impact: 3),
            attempt(daysAgo: 2, difficulty: .hard, correct: true, impact: 2),
            attempt(daysAgo: 1, difficulty: .hard, correct: false, impact: 0)
        ]

        let plan = WhatToPlayStatsAnalyzer.trainingSessionPlan(for: attempts)

        XCTAssertEqual(plan.title, "جلسة رفع المستوى".localized)
        XCTAssertEqual(plan.scenarioCount, 5)
        XCTAssertEqual(plan.targetAccuracyPercent, 80)
        XCTAssertEqual(plan.targetAverageExpectedImpact, 2)
    }

    func testTrainingSessionPlanTargetsPointLeakForCautiousStyle() {
        let attempts = [
            attempt(daysAgo: 4, correct: true, impact: -4),
            attempt(daysAgo: 3, correct: true, impact: -2),
            attempt(daysAgo: 2, correct: true, impact: -1),
            attempt(daysAgo: 1, correct: false, impact: -5)
        ]

        let plan = WhatToPlayStatsAnalyzer.trainingSessionPlan(for: attempts)

        XCTAssertEqual(plan.title, "جلسة تقليل النزيف".localized)
        XCTAssertEqual(plan.targetAverageExpectedImpact, 0)
        XCTAssertEqual(plan.successMetric, "هدف الجلسة: متوسط أثر غير سلبي.".localized)
    }

    func testTrainingSessionPlanStabilizesInconsistentReading() {
        let attempts = [
            attempt(daysAgo: 6, correct: true, impact: 3),
            attempt(daysAgo: 5, correct: false, impact: -2),
            attempt(daysAgo: 4, correct: false, impact: -2),
            attempt(daysAgo: 3, correct: true, impact: 4),
            attempt(daysAgo: 2, correct: true, impact: 2),
            attempt(daysAgo: 1, correct: false, impact: -1)
        ]

        let plan = WhatToPlayStatsAnalyzer.trainingSessionPlan(for: attempts)

        XCTAssertEqual(plan.title, "جلسة تثبيت القراءة".localized)
        XCTAssertEqual(plan.scenarioCount, 4)
        XCTAssertEqual(plan.targetAverageExpectedImpact, 1)
        XCTAssertEqual(plan.successMetric, "هدف الجلسة: 3 إجابات صحيحة من 4.".localized)
    }

    func testNextScenarioRecommendationUsesFocusTrainingPriorityWhenAvailable() {
        let attempts = [
            attempt(daysAgo: 6, correct: false, impact: -1, bestImpact: 1, focusKind: .openingLead),
            attempt(daysAgo: 5, correct: true, impact: 1, bestImpact: 1, focusKind: .openingLead),
            attempt(daysAgo: 4, correct: false, impact: -8, bestImpact: 4, focusKind: .trumpPressure),
            attempt(daysAgo: 3, correct: true, impact: 2, bestImpact: 2, focusKind: .trumpPressure),
            attempt(daysAgo: 2, correct: false, impact: -3, bestImpact: 2, focusKind: .followSuit),
            attempt(daysAgo: 1, correct: true, impact: 2, bestImpact: 2, focusKind: .followSuit)
        ]

        let recommendation = WhatToPlayStatsAnalyzer.nextScenarioRecommendation(for: attempts)

        XCTAssertEqual(recommendation.focusKind, .trumpPressure)
        XCTAssertEqual(recommendation.title, "الموقف القادم".localized)
        XCTAssertEqual(recommendation.iconName, "crown.fill")
        XCTAssertTrue(recommendation.detail.contains("ضغط الحكم".localized))
    }

    func testNextScenarioRecommendationFallsBackToSessionPlanWithoutFocusPriority() {
        let recommendation = WhatToPlayStatsAnalyzer.nextScenarioRecommendation(for: [])

        XCTAssertEqual(recommendation.difficulty, .easy)
        XCTAssertNil(recommendation.focusKind)
        XCTAssertEqual(recommendation.title, "الموقف القادم".localized)
        XCTAssertEqual(recommendation.iconName, "play.rectangle.fill")
    }

    func testTrainingSessionProgressStartsNotStartedWithoutMatchingAttempts() {
        let plan = sessionPlan(difficulty: .hard, count: 3, target: 67)
        let attempts = [
            attempt(daysAgo: 1, difficulty: .easy, correct: true, impact: 2)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.state, .notStarted)
        XCTAssertEqual(progress.completedAttempts, 0)
        XCTAssertEqual(progress.targetAttempts, 3)
        XCTAssertFalse(progress.accuracyTargetMet)
        XCTAssertEqual(progress.correctAttemptsNeededForTarget, 2)
        XCTAssertEqual(progress.totalExpectedImpact, 0)
        XCTAssertEqual(progress.averageExpectedImpact, 0)
        XCTAssertFalse(progress.impactTargetMet)
        XCTAssertEqual(progress.averageExpectedImpactGap, 0)
        XCTAssertEqual(progress.valueCapturePercent, 0)
        XCTAssertEqual(progress.valueCaptureAttempts, 0)
        XCTAssertEqual(progress.impactTitle, "الأثر غير محسوب بعد".localized)
        XCTAssertEqual(progress.impactIconName, "chart.line.uptrend.xyaxis")
        XCTAssertNil(progress.reviewItem)
        XCTAssertEqual(progress.remainingAttempts, 3)
        XCTAssertEqual(progress.title, "ابدأ الجلسة".localized)
        XCTAssertEqual(progress.nextStepTitle, "الخطوة التالية".localized)
        XCTAssertEqual(progress.nextStepIconName, "play.circle.fill")
        XCTAssertEqual(progress.gradePercent, 0)
        XCTAssertEqual(progress.gradeAccuracyComponent, 0)
        XCTAssertEqual(progress.gradeImpactComponent, 0)
        XCTAssertEqual(progress.gradeTitle, "لا يوجد تقييم بعد".localized)
        XCTAssertEqual(progress.gradeReasonTitle, "سبب التقييم".localized)
        XCTAssertEqual(progress.gradeReasonDetail, "لا توجد محاولة في هذه الجلسة حتى الآن.".localized)
    }

    func testTrainingSessionProgressCountsRecentMatchingDifficultyOnly() {
        let plan = sessionPlan(difficulty: .medium, count: 4, target: 75)
        let attempts = [
            attempt(daysAgo: 5, difficulty: .easy, correct: false, impact: -6, bestImpact: 8),
            attempt(daysAgo: 4, difficulty: .hard, correct: true, impact: 4, bestImpact: 4),
            attempt(daysAgo: 3, difficulty: .medium, correct: true, impact: 4, bestImpact: 4),
            attempt(daysAgo: 2, difficulty: .medium, correct: false, impact: -2, bestImpact: 5),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: 3, bestImpact: 3)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.state, .inProgress)
        XCTAssertEqual(progress.completedAttempts, 3)
        XCTAssertEqual(progress.correctAttempts, 2)
        XCTAssertEqual(progress.accuracyPercent, 67)
        XCTAssertFalse(progress.accuracyTargetMet)
        XCTAssertEqual(progress.correctAttemptsNeededForTarget, 1)
        XCTAssertEqual(progress.totalExpectedImpact, 5)
        XCTAssertEqual(progress.averageExpectedImpact, 2)
        XCTAssertTrue(progress.impactTargetMet)
        XCTAssertEqual(progress.averageExpectedImpactGap, 0)
        XCTAssertEqual(progress.valueCaptureAttempts, 3)
        XCTAssertEqual(progress.valueCapturePercent, 58)
        XCTAssertEqual(progress.impactTitle, "أثر الجلسة رابح".localized)
        XCTAssertEqual(progress.impactIconName, "checkmark.seal.fill")
        XCTAssertEqual(progress.reviewItem?.seed, 2)
        XCTAssertEqual(progress.remainingAttempts, 1)
        XCTAssertEqual(progress.nextStepTitle, "أكمل الدفعة".localized)
        XCTAssertEqual(progress.nextStepIconName, "timer.circle.fill")
        XCTAssertEqual(progress.gradePercent, 69)
        XCTAssertEqual(progress.gradeAccuracyComponent, 67)
        XCTAssertEqual(progress.gradeImpactComponent, 70)
        XCTAssertEqual(progress.gradeTitle, "جلسة تحتاج تثبيت".localized)
        XCTAssertEqual(progress.gradeReasonTitle, "التقييم متوازن".localized)
    }

    func testTrainingSessionProgressNextStepCountsNeededCorrectAnswers() {
        let plan = sessionPlan(difficulty: .medium, count: 5, target: 60)
        let attempts = [
            attempt(daysAgo: 2, difficulty: .medium, correct: true, impact: 2),
            attempt(daysAgo: 1, difficulty: .medium, correct: false, impact: -1)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.state, .inProgress)
        XCTAssertEqual(progress.remainingAttempts, 3)
        XCTAssertEqual(progress.nextStepTitle, "أكمل الدفعة".localized)
        XCTAssertEqual(progress.nextStepIconName, "timer.circle.fill")
        XCTAssertTrue(progress.nextStepDetail.contains("2"))
    }

    func testTrainingSessionProgressNextStepWarnsWhenAccuracyTargetIsUnreachable() {
        let plan = sessionPlan(difficulty: .medium, count: 4, target: 75)
        let attempts = [
            attempt(daysAgo: 3, difficulty: .medium, correct: false, impact: -3),
            attempt(daysAgo: 2, difficulty: .medium, correct: true, impact: 2),
            attempt(daysAgo: 1, difficulty: .medium, correct: false, impact: -2)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.state, .inProgress)
        XCTAssertEqual(progress.remainingAttempts, 1)
        XCTAssertEqual(progress.nextStepTitle, "هدف الدقة تعثر".localized)
        XCTAssertEqual(progress.nextStepIconName, "exclamationmark.triangle.fill")
    }

    func testTrainingSessionProgressCountsMatchingDifficultyAndFocusOnly() {
        let plan = sessionPlan(difficulty: .medium, focusKind: .trumpPressure, count: 3, target: 67)
        let attempts = [
            attempt(daysAgo: 5, difficulty: .medium, correct: false, impact: -6, focusKind: .openingLead),
            attempt(daysAgo: 4, difficulty: .hard, correct: true, impact: 4, focusKind: .trumpPressure),
            attempt(daysAgo: 3, difficulty: .medium, correct: true, impact: 4, focusKind: .trumpPressure),
            attempt(daysAgo: 2, difficulty: .medium, correct: false, impact: -2),
            attempt(daysAgo: 1, difficulty: .medium, correct: false, impact: -3, focusKind: .trumpPressure)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.state, .inProgress)
        XCTAssertEqual(progress.completedAttempts, 2)
        XCTAssertEqual(progress.correctAttempts, 1)
        XCTAssertEqual(progress.accuracyPercent, 50)
        XCTAssertFalse(progress.accuracyTargetMet)
        XCTAssertEqual(progress.correctAttemptsNeededForTarget, 1)
        XCTAssertEqual(progress.totalExpectedImpact, 1)
        XCTAssertEqual(progress.averageExpectedImpact, 1)
        XCTAssertTrue(progress.impactTargetMet)
        XCTAssertEqual(progress.averageExpectedImpactGap, 0)
        XCTAssertEqual(progress.valueCaptureAttempts, 0)
        XCTAssertEqual(progress.valueCapturePercent, 0)
        XCTAssertEqual(progress.reviewItem?.seed, 1)
        XCTAssertEqual(progress.remainingAttempts, 1)
    }

    func testTrainingSessionProgressAchievesTargetWhenPlannedBatchPasses() {
        let plan = sessionPlan(difficulty: .easy, count: 3, target: 67)
        let attempts = [
            attempt(daysAgo: 4, difficulty: .easy, correct: false, impact: -8),
            attempt(daysAgo: 3, difficulty: .easy, correct: true, impact: 2),
            attempt(daysAgo: 2, difficulty: .easy, correct: true, impact: 4),
            attempt(daysAgo: 1, difficulty: .easy, correct: false, impact: -1)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.state, .achieved)
        XCTAssertEqual(progress.completedAttempts, 3)
        XCTAssertEqual(progress.correctAttempts, 2)
        XCTAssertEqual(progress.accuracyPercent, 67)
        XCTAssertTrue(progress.accuracyTargetMet)
        XCTAssertEqual(progress.correctAttemptsNeededForTarget, 0)
        XCTAssertEqual(progress.totalExpectedImpact, 5)
        XCTAssertEqual(progress.averageExpectedImpact, 2)
        XCTAssertTrue(progress.impactTargetMet)
        XCTAssertEqual(progress.averageExpectedImpactGap, 0)
        XCTAssertEqual(progress.reviewItem?.seed, 1)
        XCTAssertEqual(progress.title, "هدف الجلسة تحقق".localized)
        XCTAssertEqual(progress.nextStepTitle, "انتقل للتحدي التالي".localized)
        XCTAssertEqual(progress.gradePercent, 69)
        XCTAssertEqual(progress.gradeAccuracyComponent, 67)
        XCTAssertEqual(progress.gradeImpactComponent, 70)
        XCTAssertEqual(progress.gradeTitle, "جلسة تحتاج تثبيت".localized)
        XCTAssertEqual(progress.gradeReasonTitle, "التقييم متوازن".localized)
    }

    func testTrainingSessionProgressRequiresImpactTargetForSuccess() {
        let plan = sessionPlan(difficulty: .easy, count: 3, target: 67, impactTarget: 2)
        let attempts = [
            attempt(daysAgo: 3, difficulty: .easy, correct: true, impact: 1),
            attempt(daysAgo: 2, difficulty: .easy, correct: true, impact: 1),
            attempt(daysAgo: 1, difficulty: .easy, correct: false, impact: 0)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.state, .needsRepeat)
        XCTAssertTrue(progress.accuracyTargetMet)
        XCTAssertFalse(progress.impactTargetMet)
        XCTAssertEqual(progress.correctAttemptsNeededForTarget, 0)
        XCTAssertEqual(progress.averageExpectedImpact, 1)
        XCTAssertEqual(progress.averageExpectedImpactGap, 1)
        XCTAssertEqual(progress.detail, "أكملتها بدقة كافية، لكن متوسط الأثر أقل من هدف الخطة؛ راجع الاختيارات القريبة قبل تكرارها.".localized)
        XCTAssertEqual(progress.nextStepTitle, "راجع جودة القرار".localized)
        XCTAssertEqual(progress.gradePercent, 54)
        XCTAssertEqual(progress.gradeAccuracyComponent, 67)
        XCTAssertEqual(progress.gradeImpactComponent, 40)
        XCTAssertEqual(progress.gradeTitle, "جلسة تحتاج تثبيت".localized)
        XCTAssertEqual(progress.gradeReasonTitle, "الأثر يخفض التقييم".localized)
    }

    func testTrainingSessionProgressRequestsRepeatWhenAccuracyMissesTarget() {
        let plan = sessionPlan(difficulty: .hard, count: 4, target: 75)
        let attempts = [
            attempt(daysAgo: 4, difficulty: .hard, correct: true, impact: 3),
            attempt(daysAgo: 3, difficulty: .hard, correct: false, impact: -3),
            attempt(daysAgo: 2, difficulty: .hard, correct: true, impact: 2),
            attempt(daysAgo: 1, difficulty: .hard, correct: false, impact: -5)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.state, .needsRepeat)
        XCTAssertEqual(progress.completedAttempts, 4)
        XCTAssertEqual(progress.correctAttempts, 2)
        XCTAssertEqual(progress.accuracyPercent, 50)
        XCTAssertFalse(progress.accuracyTargetMet)
        XCTAssertEqual(progress.correctAttemptsNeededForTarget, 1)
        XCTAssertEqual(progress.totalExpectedImpact, -3)
        XCTAssertEqual(progress.averageExpectedImpact, -1)
        XCTAssertFalse(progress.impactTargetMet)
        XCTAssertEqual(progress.averageExpectedImpactGap, 1)
        XCTAssertEqual(progress.impactTitle, "أثر الجلسة سلبي".localized)
        XCTAssertEqual(progress.impactIconName, "exclamationmark.triangle.fill")
        XCTAssertEqual(progress.reviewItem?.seed, 1)
        XCTAssertEqual(progress.remainingAttempts, 0)
        XCTAssertEqual(progress.title, "أعد الجلسة".localized)
        XCTAssertEqual(progress.nextStepTitle, "أعد نفس الخطة".localized)
        XCTAssertEqual(progress.gradePercent, 45)
        XCTAssertEqual(progress.gradeAccuracyComponent, 50)
        XCTAssertEqual(progress.gradeImpactComponent, 40)
        XCTAssertEqual(progress.gradeTitle, "جلسة تحتاج إعادة".localized)
        XCTAssertEqual(progress.gradeReasonTitle, "التقييم متوازن".localized)
    }

    func testTrainingSessionGradeReasonIdentifiesAccuracyWeakness() {
        let plan = sessionPlan(difficulty: .medium, count: 4, target: 75)
        let attempts = [
            attempt(daysAgo: 4, difficulty: .medium, correct: false, impact: 5),
            attempt(daysAgo: 3, difficulty: .medium, correct: false, impact: 5),
            attempt(daysAgo: 2, difficulty: .medium, correct: true, impact: 5),
            attempt(daysAgo: 1, difficulty: .medium, correct: false, impact: 5)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.state, .needsRepeat)
        XCTAssertEqual(progress.gradePercent, 63)
        XCTAssertEqual(progress.gradeAccuracyComponent, 25)
        XCTAssertEqual(progress.gradeImpactComponent, 100)
        XCTAssertEqual(progress.gradeReasonTitle, "الدقة تخفض التقييم".localized)
    }

    func testTrainingSessionProgressReviewItemComesFromCurrentPlannedBatch() {
        let plan = sessionPlan(difficulty: .medium, focusKind: .followSuit, count: 3, target: 67)
        let attempts = [
            attempt(daysAgo: 8, difficulty: .medium, correct: false, impact: -20, bestImpact: 10, focusKind: .followSuit),
            attempt(daysAgo: 7, difficulty: .hard, correct: false, impact: -12, bestImpact: 8, focusKind: .followSuit),
            attempt(daysAgo: 6, difficulty: .medium, correct: false, impact: -10, bestImpact: 6, focusKind: .trumpPressure),
            attempt(daysAgo: 3, difficulty: .medium, correct: true, impact: 3, bestImpact: 3, focusKind: .followSuit),
            attempt(daysAgo: 2, difficulty: .medium, correct: false, impact: -3, bestImpact: 4, focusKind: .followSuit),
            attempt(daysAgo: 1, difficulty: .medium, correct: false, impact: -1, bestImpact: 2, focusKind: .followSuit)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.completedAttempts, 3)
        XCTAssertEqual(progress.reviewItem?.seed, 2)
        XCTAssertEqual(progress.reviewItem?.lostExpectedPoints, 7)
        XCTAssertEqual(progress.reviewItem?.focusKind, .followSuit)
    }

    func testCoachingTipForEmptyAttemptsEncouragesBaseline() {
        let tip = WhatToPlayStatsAnalyzer.coachingTip(for: [])

        XCTAssertEqual(tip.title, "ابدأ القياس".localized)
        XCTAssertEqual(tip.iconName, "target")
    }

    func testCoachingTipForLowAccuracyFocusesOnSlowingDown() {
        let attempts = [
            attempt(daysAgo: 3, correct: false, impact: 2),
            attempt(daysAgo: 2, correct: false, impact: 2),
            attempt(daysAgo: 1, correct: true, impact: 2)
        ]

        let tip = WhatToPlayStatsAnalyzer.coachingTip(for: attempts)

        XCTAssertEqual(tip.title, "خفف السرعة".localized)
    }

    func testCoachingTipForNegativeImpactFocusesOnPointLoss() {
        let attempts = [
            attempt(daysAgo: 3, correct: true, impact: -6),
            attempt(daysAgo: 2, correct: true, impact: -2),
            attempt(daysAgo: 1, correct: false, impact: -4)
        ]

        let tip = WhatToPlayStatsAnalyzer.coachingTip(for: attempts)

        XCTAssertEqual(tip.title, "قلل نزيف النقاط".localized)
    }

    func testCoachingTipForCurrentStreakEncouragesHarderPractice() {
        let attempts = [
            attempt(daysAgo: 3, correct: true, impact: 4),
            attempt(daysAgo: 2, correct: true, impact: 2),
            attempt(daysAgo: 1, correct: true, impact: 3)
        ]

        let tip = WhatToPlayStatsAnalyzer.coachingTip(for: attempts)

        XCTAssertEqual(tip.title, "سلسلة ممتازة".localized)
    }

    private func sessionPlan(
        difficulty: WhatToPlayDifficulty,
        focusKind: WhatToPlayScenarioFocusKind? = nil,
        count: Int,
        target: Int,
        impactTarget: Int = 0
    ) -> WhatToPlayTrainingSessionPlan {
        WhatToPlayTrainingSessionPlan(
            difficulty: difficulty,
            focusKind: focusKind,
            scenarioCount: count,
            targetAccuracyPercent: target,
            targetAverageExpectedImpact: impactTarget,
            title: "خطة اختبار",
            detail: "تفاصيل اختبار",
            successMetric: "هدف اختبار",
            iconName: "target"
        )
    }

    private func attempt(
        daysAgo: TimeInterval,
        correct: Bool,
        impact: Int,
        bestImpact: Int? = nil,
        selectedRank: Int? = nil,
        focusKind: WhatToPlayScenarioFocusKind? = nil,
        outcome: WhatToPlayOptionOutcome? = nil
    ) -> WhatToPlayAttempt {
        attempt(
            daysAgo: daysAgo,
            difficulty: .medium,
            correct: correct,
            impact: impact,
            bestImpact: bestImpact,
            selectedRank: selectedRank,
            focusKind: focusKind,
            outcome: outcome
        )
    }

    private func attempt(
        daysAgo: TimeInterval,
        difficulty: WhatToPlayDifficulty,
        correct: Bool,
        impact: Int,
        bestImpact: Int? = nil,
        selectedRank: Int? = nil,
        secondBestCard: PlayingCard? = nil,
        secondBestImpact: Int? = nil,
        focusKind: WhatToPlayScenarioFocusKind? = nil,
        outcome: WhatToPlayOptionOutcome? = nil
    ) -> WhatToPlayAttempt {
        WhatToPlayAttempt(
            createdAt: Date(timeIntervalSince1970: 2_000_000 - daysAgo * 86_400),
            difficulty: difficulty,
            seed: UInt64(Int(daysAgo)),
            selectedCard: PlayingCard(suit: .clubs, rank: .seven),
            bestCard: PlayingCard(suit: .clubs, rank: .seven),
            secondBestCard: secondBestCard,
            isCorrect: correct,
            selectedRank: selectedRank,
            expectedImpact: impact,
            bestExpectedImpact: bestImpact,
            secondBestExpectedImpact: secondBestImpact,
            focusKind: focusKind,
            outcome: outcome
        )
    }

    private func expectedFirstReviewStep(for focus: WhatToPlayScenarioFocusKind) -> String {
        switch focus {
        case .openingLead:
            "قارن هل افتتاحك يكشف قوة يدك مبكرًا أو يحفظها للأكلة القادمة.".localized
        case .followSuit:
            "راجع اللون المطلوب أولًا، ثم اسأل هل تستطيع ربح الأكلة أم يجب تقليل خسارتها.".localized
        case .trumpPressure:
            "افحص الحكم الموجود على الطاولة قبل رمي ورقة عالية أو حكم أعلى.".localized
        case .narrowChoice:
            "عندما تكون الخيارات قليلة، رتّبها حسب أقل خسارة لا حسب أعلى ورقة.".localized
        }
    }
}
