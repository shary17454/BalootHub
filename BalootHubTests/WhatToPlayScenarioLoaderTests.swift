import XCTest
import BalootEngine
@testable import BalootHub

final class WhatToPlayScenarioLoaderTests: XCTestCase {
    func testLoaderGeneratesScenarioWithRequestedSeedAndDifficulty() async throws {
        let scenario = try await WhatToPlayScenarioLoader.generate(seed: 2026, difficulty: .medium)

        XCTAssertEqual(scenario.seed, 2026)
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
}
