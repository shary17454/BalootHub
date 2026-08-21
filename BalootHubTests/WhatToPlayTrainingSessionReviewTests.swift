import XCTest
import BalootEngine
@testable import BalootHub

final class WhatToPlayTrainingSessionReviewTests: XCTestCase {
    func testReplayMistakeDetailIncludesSecondBestAndSimulationLoss() {
        let selected = PlayingCard(suit: .clubs, rank: .seven)
        let best = PlayingCard(suit: .hearts, rank: .ace)
        let second = PlayingCard(suit: .spades, rank: .king)
        let plan = WhatToPlayTrainingSessionPlan(
            difficulty: .medium,
            focusKind: .followSuit,
            gameMode: .hokum,
            scenarioCount: 2,
            targetAccuracyPercent: 100,
            targetAverageExpectedImpact: 5,
            title: "خطة".localized,
            detail: "تفصيل".localized,
            successMetric: "هدف".localized,
            iconName: "target"
        )
        let attempts = [
            attempt(seed: 10, selected: selected, best: best, second: second),
            attempt(seed: 11, selected: PlayingCard(suit: .diamonds, rank: .eight), best: best)
        ]

        let review = WhatToPlayStatsAnalyzer.trainingSessionReview(for: attempts, plan: plan)

        XCTAssertEqual(review.action, .replayMistake)
        XCTAssertEqual(review.replaySeed, 10)
        XCTAssertTrue(review.detail.contains("\("اختيارك".localized): \(selected.accessibilityName)"))
        XCTAssertTrue(review.detail.contains("\("أفضل ورقة".localized): \(best.accessibilityName)"))
        XCTAssertTrue(review.detail.contains("\("ثاني أفضل".localized): \(second.accessibilityName)"))
        XCTAssertTrue(review.detail.contains("\("أثر ثاني أفضل".localized): +5"))
        XCTAssertTrue(review.detail.contains("\("نقاط محاكاة ضائعة".localized): 12"))
    }

    private func attempt(
        seed: UInt64,
        selected: PlayingCard,
        best: PlayingCard,
        second: PlayingCard? = nil
    ) -> WhatToPlayAttempt {
        WhatToPlayAttempt(
            createdAt: Date(timeIntervalSince1970: Double(seed)),
            difficulty: .medium,
            seed: seed,
            selectedCard: selected,
            bestCard: best,
            secondBestCard: second,
            isCorrect: false,
            selectedRank: second == nil ? 3 : 4,
            expectedImpact: -4,
            bestExpectedImpact: 8,
            secondBestExpectedImpact: second == nil ? nil : 5,
            projectedTeamPoints: 50,
            bestProjectedTeamPoints: second == nil ? 55 : 62,
            focusKind: .followSuit,
            gameMode: .hokum
        )
    }
}
