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

    func testScenarioCodeParsesPromptAndReviewedDecision() {
        let prompt = WhatToPlayScenarioCode.parse("WTP-2026-medium-openingLead-P")
        let reviewed = WhatToPlayScenarioCode.parse("WTP-2026-hard-trumpPressure-C37")

        XCTAssertEqual(prompt?.seed, 2_026)
        XCTAssertEqual(prompt?.difficulty, .medium)
        XCTAssertEqual(prompt?.focusKind, .openingLead)
        XCTAssertNil(prompt?.selectedCard)
        XCTAssertEqual(reviewed?.seed, 2_026)
        XCTAssertEqual(reviewed?.difficulty, .hard)
        XCTAssertEqual(reviewed?.focusKind, .trumpPressure)
        XCTAssertEqual(reviewed?.selectedCard, PlayingCard(suit: .spades, rank: .ace))
    }

    func testScenarioCodeRejectsMalformedValues() {
        XCTAssertNil(WhatToPlayScenarioCode.parse("WTP-2026-medium-openingLead"))
        XCTAssertNil(WhatToPlayScenarioCode.parse("BAD-2026-medium-openingLead-P"))
        XCTAssertNil(WhatToPlayScenarioCode.parse("WTP-x-medium-openingLead-P"))
        XCTAssertNil(WhatToPlayScenarioCode.parse("WTP-2026-impossible-openingLead-P"))
        XCTAssertNil(WhatToPlayScenarioCode.parse("WTP-2026-medium-unknownFocus-P"))
        XCTAssertNil(WhatToPlayScenarioCode.parse("WTP-2026-medium-openingLead-C99"))
    }
}
