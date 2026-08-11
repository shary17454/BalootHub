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
    }

    func testAttemptPersistsInSwiftDataSchemaAndRestoresCards() throws {
        let configuration = ModelConfiguration(schema: PersistenceController.appSchema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PersistenceController.appSchema, configurations: [configuration])
        let context = ModelContext(container)
        let selected = PlayingCard(suit: .spades, rank: .ace)
        let best = PlayingCard(suit: .hearts, rank: .jack)
        let attempt = WhatToPlayAttempt(
            difficulty: .hard,
            seed: 2_026,
            selectedCard: selected,
            bestCard: best,
            isCorrect: false,
            expectedImpact: -6
        )

        context.insert(attempt)
        try context.save()

        let saved = try XCTUnwrap(try context.fetch(FetchDescriptor<WhatToPlayAttempt>()).first)
        XCTAssertEqual(saved.difficulty, .hard)
        XCTAssertEqual(saved.seedValue, 2_026)
        XCTAssertEqual(saved.selectedCard, selected)
        XCTAssertEqual(saved.bestCard, best)
        XCTAssertFalse(saved.isCorrect)
        XCTAssertEqual(saved.expectedImpact, -6)
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
            attempt(daysAgo: 3, correct: false, impact: -4),
            attempt(daysAgo: 2, correct: false, impact: -6),
            attempt(daysAgo: 1, correct: true, impact: -2)
        ]

        let drill = WhatToPlayStatsAnalyzer.microDrill(for: attempts)

        XCTAssertEqual(drill.title, "خطة المراجعة".localized)
        XCTAssertEqual(drill.steps.first, "أعد قراءة بطاقة تحليل اختيارك".localized)
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
        XCTAssertEqual(plan.title, "جلسة تأسيس قصيرة".localized)
    }

    func testTrainingSessionPlanPrioritizesReviewWhenRecentAttemptsNeedIt() {
        let attempts = [
            attempt(daysAgo: 4, correct: true, impact: 5),
            attempt(daysAgo: 3, correct: false, impact: -6),
            attempt(daysAgo: 2, correct: false, impact: -4),
            attempt(daysAgo: 1, correct: true, impact: -5)
        ]

        let plan = WhatToPlayStatsAnalyzer.trainingSessionPlan(for: attempts)

        XCTAssertEqual(plan.title, "جلسة مراجعة مركزة".localized)
        XCTAssertEqual(plan.scenarioCount, 3)
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
        XCTAssertEqual(plan.successMetric, "هدف الجلسة: 3 إجابات صحيحة من 4.".localized)
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
        XCTAssertEqual(progress.remainingAttempts, 3)
        XCTAssertEqual(progress.title, "ابدأ الجلسة".localized)
    }

    func testTrainingSessionProgressCountsRecentMatchingDifficultyOnly() {
        let plan = sessionPlan(difficulty: .medium, count: 4, target: 75)
        let attempts = [
            attempt(daysAgo: 5, difficulty: .easy, correct: false, impact: -6),
            attempt(daysAgo: 4, difficulty: .hard, correct: true, impact: 4),
            attempt(daysAgo: 3, difficulty: .medium, correct: true, impact: 4),
            attempt(daysAgo: 2, difficulty: .medium, correct: false, impact: -2),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: 3)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.state, .inProgress)
        XCTAssertEqual(progress.completedAttempts, 3)
        XCTAssertEqual(progress.correctAttempts, 2)
        XCTAssertEqual(progress.accuracyPercent, 67)
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
        XCTAssertEqual(progress.title, "هدف الجلسة تحقق".localized)
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
        XCTAssertEqual(progress.remainingAttempts, 0)
        XCTAssertEqual(progress.title, "أعد الجلسة".localized)
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
        count: Int,
        target: Int
    ) -> WhatToPlayTrainingSessionPlan {
        WhatToPlayTrainingSessionPlan(
            difficulty: difficulty,
            scenarioCount: count,
            targetAccuracyPercent: target,
            title: "خطة اختبار",
            detail: "تفاصيل اختبار",
            successMetric: "هدف اختبار",
            iconName: "target"
        )
    }

    private func attempt(daysAgo: TimeInterval, correct: Bool, impact: Int) -> WhatToPlayAttempt {
        attempt(daysAgo: daysAgo, difficulty: .medium, correct: correct, impact: impact)
    }

    private func attempt(
        daysAgo: TimeInterval,
        difficulty: WhatToPlayDifficulty,
        correct: Bool,
        impact: Int
    ) -> WhatToPlayAttempt {
        WhatToPlayAttempt(
            createdAt: Date(timeIntervalSince1970: 2_000_000 - daysAgo * 86_400),
            difficulty: difficulty,
            seed: UInt64(Int(daysAgo)),
            selectedCard: PlayingCard(suit: .clubs, rank: .seven),
            bestCard: PlayingCard(suit: .clubs, rank: .seven),
            isCorrect: correct,
            expectedImpact: impact
        )
    }
}
