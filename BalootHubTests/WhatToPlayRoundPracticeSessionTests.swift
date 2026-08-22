import XCTest
import BalootEngine
@testable import BalootHub

final class WhatToPlayRoundPracticeSessionTests: XCTestCase {
    func testProgressCountsOnlyAttemptsInsideSeedBatch() {
        let plan = sessionPlan(difficulty: .hard, focusKind: .narrowChoice, seedBase: 900, count: 3)
        let attempts = [
            attempt(daysAgo: 5, difficulty: .hard, correct: true, impact: 4, focusKind: .narrowChoice, seed: 899),
            attempt(daysAgo: 4, difficulty: .hard, correct: true, impact: 4, focusKind: .narrowChoice, seed: 900),
            attempt(daysAgo: 3, difficulty: .hard, correct: false, impact: -2, focusKind: .openingLead, seed: 901),
            attempt(daysAgo: 2, difficulty: .hard, correct: false, impact: -1, focusKind: .narrowChoice, seed: 902),
            attempt(daysAgo: 1, difficulty: .hard, correct: true, impact: 5, focusKind: .narrowChoice, seed: 903)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.state, .inProgress)
        XCTAssertEqual(progress.completedAttempts, 2)
        XCTAssertEqual(progress.correctAttempts, 1)
        XCTAssertEqual(progress.remainingAttempts, 1)
        XCTAssertEqual(progress.totalExpectedImpact, 3)
    }

    func testNextSeedUsesFirstUnattemptedSeedInBatch() {
        let plan = sessionPlan(difficulty: .expert, seedBase: 1_200, count: 4)
        let attempts = [
            attempt(daysAgo: 4, difficulty: .expert, correct: true, impact: 3, seed: 1_200),
            attempt(daysAgo: 3, difficulty: .expert, correct: true, impact: 2, seed: 1_202),
            attempt(daysAgo: 2, difficulty: .expert, correct: true, impact: 2, seed: 1_204),
            attempt(daysAgo: 1, difficulty: .hard, correct: true, impact: 2, seed: 1_201)
        ]

        let seed = WhatToPlayStatsAnalyzer.nextTrainingSessionSeed(for: attempts, plan: plan)

        XCTAssertEqual(seed, 1_201)
    }

    func testProgressUsesLatestAttemptWhenSeedIsRetriedCorrectly() {
        let plan = sessionPlan(difficulty: .hard, focusKind: .narrowChoice, seedBase: 900, count: 3)
        let attempts = [
            attempt(daysAgo: 3, difficulty: .hard, correct: false, impact: -3, focusKind: .narrowChoice, seed: 900),
            attempt(daysAgo: 2, difficulty: .hard, correct: true, impact: 4, focusKind: .narrowChoice, seed: 901),
            attempt(daysAgo: 1, difficulty: .hard, correct: true, impact: 6, focusKind: .narrowChoice, seed: 900)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)
        let nextSeed = WhatToPlayStatsAnalyzer.nextTrainingSessionSeed(for: attempts, plan: plan)

        XCTAssertEqual(progress.completedAttempts, 2)
        XCTAssertEqual(progress.correctAttempts, 2)
        XCTAssertEqual(progress.totalExpectedImpact, 10)
        XCTAssertEqual(progress.remainingAttempts, 1)
        XCTAssertEqual(nextSeed, 902)
    }

    func testProgressUsesLatestAttemptWhenSeedIsRetriedIncorrectly() {
        let plan = sessionPlan(difficulty: .hard, focusKind: .narrowChoice, seedBase: 900, count: 3)
        let attempts = [
            attempt(daysAgo: 3, difficulty: .hard, correct: true, impact: 5, focusKind: .narrowChoice, seed: 900),
            attempt(daysAgo: 2, difficulty: .hard, correct: true, impact: 4, focusKind: .narrowChoice, seed: 901),
            attempt(daysAgo: 1, difficulty: .hard, correct: false, impact: -2, focusKind: .narrowChoice, seed: 900)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)
        let nextSeed = WhatToPlayStatsAnalyzer.nextTrainingSessionSeed(for: attempts, plan: plan)

        XCTAssertEqual(progress.completedAttempts, 2)
        XCTAssertEqual(progress.correctAttempts, 1)
        XCTAssertEqual(progress.totalExpectedImpact, 2)
        XCTAssertEqual(progress.remainingAttempts, 1)
        XCTAssertEqual(nextSeed, 902)
    }

    func testRoundReviewSessionSourceBuildsRoundAnalysisPlanCopy() {
        let plan = WhatToPlayTrainingSessionSource.roundReview.makePlan(
            difficulty: .hard,
            focusKind: .narrowChoice,
            gameMode: .hokum,
            trumpSuit: .hearts,
            seedBase: 900,
            scenarioCount: 3
        )

        XCTAssertEqual(plan.title, "خطة من تحليل الجولة".localized)
        XCTAssertEqual(plan.rationaleTitle, "مصدر الخطة".localized)
        XCTAssertEqual(plan.rationaleIconName, "doc.text.magnifyingglass")
        XCTAssertEqual(plan.seedBase, 900)
        XCTAssertEqual(plan.scenarioCount, 3)
        XCTAssertEqual(plan.gameMode, .hokum)
        XCTAssertEqual(plan.trumpSuit, .hearts)
    }

    func testChallengeSessionSourceBuildsChallengePlanCopy() {
        let plan = WhatToPlayTrainingSessionSource.challenge.makePlan(
            difficulty: .medium,
            focusKind: .followSuit,
            gameMode: .sun,
            trumpSuit: nil,
            seedBase: 7_000_000,
            scenarioCount: 4
        )

        XCTAssertEqual(plan.title, "خطة تحدي وش تلعب".localized)
        XCTAssertEqual(plan.rationaleTitle, "مصدر التحدي".localized)
        XCTAssertEqual(plan.rationaleIconName, "calendar.badge.checkmark")
        XCTAssertEqual(plan.iconName, "brain.head.profile")
        XCTAssertEqual(plan.seedBase, 7_000_000)
        XCTAssertEqual(plan.scenarioCount, 4)
        XCTAssertEqual(plan.gameMode, .sun)
        XCTAssertNil(plan.trumpSuit)
    }

    private func sessionPlan(
        difficulty: WhatToPlayDifficulty,
        focusKind: WhatToPlayScenarioFocusKind? = nil,
        seedBase: UInt64,
        count: Int
    ) -> WhatToPlayTrainingSessionPlan {
        WhatToPlayTrainingSessionPlan(
            difficulty: difficulty,
            focusKind: focusKind,
            seedBase: seedBase,
            scenarioCount: count,
            targetAccuracyPercent: 67,
            targetAverageExpectedImpact: 0,
            title: "خطة اختبار",
            detail: "تفاصيل اختبار",
            successMetric: "هدف اختبار",
            iconName: "target"
        )
    }

    private func attempt(
        daysAgo: TimeInterval,
        difficulty: WhatToPlayDifficulty,
        correct: Bool,
        impact: Int,
        focusKind: WhatToPlayScenarioFocusKind? = nil,
        seed: UInt64
    ) -> WhatToPlayAttempt {
        WhatToPlayAttempt(
            createdAt: Date(timeIntervalSinceNow: -daysAgo * 86_400),
            difficulty: difficulty,
            seed: seed,
            selectedCard: PlayingCard(suit: .clubs, rank: .seven),
            bestCard: PlayingCard(suit: .clubs, rank: .seven),
            isCorrect: correct,
            selectedRank: correct ? 1 : 3,
            expectedImpact: impact,
            bestExpectedImpact: max(impact, 4),
            focusKind: focusKind
        )
    }
}
