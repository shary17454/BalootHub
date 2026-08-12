import XCTest
import BalootEngine
@testable import BalootHub

final class WhatToPlayScenarioLoaderTests: XCTestCase {
    func testNextUnattemptedSeedSkipsSolvedSeedsForDifficultyAndAutoFocus() {
        let attempts = [
            attempt(seed: 2027, difficulty: .medium, focusKind: .openingLead),
            attempt(seed: 2028, difficulty: .medium, focusKind: .followSuit),
            attempt(seed: 2029, difficulty: .hard, focusKind: .openingLead)
        ]

        let seed = WhatToPlayScenarioLoader.nextUnattemptedSeed(
            after: 2026,
            difficulty: .medium,
            preferredFocus: nil,
            attempts: attempts
        )

        XCTAssertEqual(seed, 2029)
    }

    func testNextUnattemptedSeedOnlySkipsMatchingFocusWhenFocusIsSelected() {
        let attempts = [
            attempt(seed: 2027, difficulty: .medium, focusKind: .openingLead),
            attempt(seed: 2028, difficulty: .medium, focusKind: .followSuit)
        ]

        let seed = WhatToPlayScenarioLoader.nextUnattemptedSeed(
            after: 2026,
            difficulty: .medium,
            preferredFocus: .followSuit,
            attempts: attempts
        )

        XCTAssertEqual(seed, 2027)
    }

    func testNextUnattemptedSeedIgnoresOtherDifficulties() {
        let attempts = [
            attempt(seed: 2027, difficulty: .hard, focusKind: .openingLead),
            attempt(seed: 2028, difficulty: .hard, focusKind: .openingLead)
        ]

        let seed = WhatToPlayScenarioLoader.nextUnattemptedSeed(
            after: 2026,
            difficulty: .medium,
            preferredFocus: .openingLead,
            attempts: attempts
        )

        XCTAssertEqual(seed, 2027)
    }

    func testLoaderGeneratesScenarioWithRequestedSeedAndDifficulty() async throws {
        let scenario = try await WhatToPlayScenarioLoader.generate(seed: 2026, difficulty: .medium)
        let repeated = try await WhatToPlayScenarioLoader.generate(seed: 2026, difficulty: .medium)

        XCTAssertGreaterThanOrEqual(scenario.seed, 2026)
        XCTAssertEqual(scenario.seed, repeated.seed)
        XCTAssertEqual(scenario.difficulty, .medium)
        XCTAssertFalse(scenario.options.isEmpty)
        XCTAssertNotNil(scenario.bestOption)
    }

    func testLoaderGeneratesScenarioWithRequestedFocus() async throws {
        let scenario = try await WhatToPlayScenarioLoader.generate(
            seed: 2026,
            difficulty: .easy,
            preferredFocus: .followSuit
        )

        XCTAssertEqual(scenario.difficulty, .easy)
        XCTAssertEqual(scenario.context.focusKind, .followSuit)
        XCTAssertFalse(scenario.options.isEmpty)
    }

    private func attempt(
        seed: UInt64,
        difficulty: WhatToPlayDifficulty,
        focusKind: WhatToPlayScenarioFocusKind
    ) -> WhatToPlayAttempt {
        WhatToPlayAttempt(
            difficulty: difficulty,
            seed: seed,
            selectedCard: PlayingCard(suit: .clubs, rank: .seven),
            bestCard: PlayingCard(suit: .clubs, rank: .seven),
            isCorrect: true,
            selectedRank: 1,
            expectedImpact: 1,
            bestExpectedImpact: 1,
            focusKind: focusKind,
            outcome: .winsTrick
        )
    }
}
