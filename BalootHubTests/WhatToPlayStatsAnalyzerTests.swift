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
