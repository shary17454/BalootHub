import XCTest
import BalootEngine
@testable import BalootHub

final class WhatToPlayScenarioCodeTests: XCTestCase {
    func testAttemptScenarioCodeIsStableAndUsesFullReplaySeed() {
        let attempt = WhatToPlayAttempt(
            difficulty: .hard,
            seed: UInt64.max,
            selectedCard: PlayingCard(suit: .spades, rank: .ace),
            bestCard: PlayingCard(suit: .hearts, rank: .jack),
            isCorrect: false,
            expectedImpact: -6,
            focusKind: .trumpPressure
        )

        XCTAssertEqual(attempt.replaySeed, UInt64.max)
        XCTAssertEqual(attempt.scenarioCode, "WTP-\(UInt64.max)-hard-trumpPressure-C37")
    }

    func testReviewQueueCarriesScenarioCodeForReplayAndSharing() {
        let attempt = WhatToPlayAttempt(
            createdAt: Date(timeIntervalSince1970: 1),
            difficulty: .medium,
            seed: 2_026,
            selectedCard: PlayingCard(suit: .hearts, rank: .ace),
            bestCard: PlayingCard(suit: .clubs, rank: .ace),
            isCorrect: false,
            expectedImpact: -4,
            bestExpectedImpact: 3,
            focusKind: .followSuit
        )

        let item = WhatToPlayStatsAnalyzer.reviewQueue(for: [attempt]).first

        XCTAssertEqual(item?.scenarioCode, "WTP-2026-medium-followSuit-C07")
    }
}
