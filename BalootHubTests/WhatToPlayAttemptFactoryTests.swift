import XCTest
import BalootEngine
@testable import BalootHub

final class WhatToPlayAttemptFactoryTests: XCTestCase {
    func testFactoryBuildsReviewedAttemptFromShareCode() async throws {
        let scenario = try await WhatToPlayScenarioLoader.generate(
            seed: 2026,
            difficulty: .easy,
            preferredFocus: .followSuit
        )
        let selected = try XCTUnwrap(scenario.options.last)
        let bestProjected = try XCTUnwrap(WhatToPlayTrainer.bestProjectedOption(in: scenario.options))
        let code = WhatToPlayShareCard.content(for: scenario, selectedOption: selected).scenarioCode

        let attempt = try await WhatToPlayAttemptFactory.makeAttempt(code: code)

        XCTAssertEqual(attempt.replaySeed, scenario.seed)
        XCTAssertEqual(attempt.difficulty, scenario.difficulty)
        XCTAssertEqual(attempt.focusKind, scenario.context.focusKind)
        XCTAssertEqual(attempt.selectedCard, selected.card)
        XCTAssertEqual(attempt.bestCard, scenario.bestOption?.card)
        XCTAssertEqual(attempt.secondBestCard, scenario.secondBestOption?.card)
        XCTAssertEqual(attempt.bestSimulationCard, bestProjected.card)
        XCTAssertEqual(attempt.expectedImpact, selected.expectedImpact)
        XCTAssertEqual(attempt.projectedTeamPoints, selected.projectedTeamPoints)
        XCTAssertEqual(attempt.bestProjectedTeamPoints, bestProjected.projectedTeamPoints)
        XCTAssertEqual(
            attempt.secondBestProjectedTeamPoints,
            WhatToPlayTrainer.secondBestProjectedOption(in: scenario.options)?.projectedTeamPoints
        )
        XCTAssertEqual(attempt.scenarioCode, code)
    }

    func testFactoryStoresSecondBestSimulationPointsFromProjectedRanking() async throws {
        var matchingScenario: WhatToPlayScenario?
        for seed in 2026..<2_080 {
            let scenario = try await WhatToPlayScenarioLoader.generate(
                seed: UInt64(seed),
                difficulty: .easy
            )
            let projectedSecond = WhatToPlayTrainer.secondBestProjectedOption(in: scenario.options)
            guard projectedSecond != nil,
                  projectedSecond?.card != scenario.secondBestOption?.card
            else { continue }

            matchingScenario = scenario
            break
        }

        let scenario = try XCTUnwrap(
            matchingScenario,
            "يجب أن يحتوي نطاق البذور المحدد موقفًا يختلف فيه ترتيب المحاكاة عن ترتيب الخبير"
        )
        let selected = try XCTUnwrap(scenario.options.last)
        let attempt = try XCTUnwrap(WhatToPlayAttemptFactory.makeAttempt(scenario: scenario, evaluated: selected))

        XCTAssertEqual(
            attempt.secondBestProjectedTeamPoints,
            WhatToPlayTrainer.secondBestProjectedOption(in: scenario.options)?.projectedTeamPoints
        )
        XCTAssertNotEqual(
            attempt.secondBestProjectedTeamPoints,
            scenario.secondBestOption?.projectedTeamPoints
        )
    }

    func testFactoryBuildsReviewedHokumAttemptFromShareCodeWithTrumpSuit() async throws {
        let scenario = try await WhatToPlayScenarioLoader.generate(
            seed: 2026,
            difficulty: .easy,
            preferredFocus: .trumpPressure,
            preferredMode: .hokum,
            preferredTrumpSuit: .spades
        )
        let selected = try XCTUnwrap(scenario.options.last)
        let code = WhatToPlayShareCard.content(for: scenario, selectedOption: selected).scenarioCode

        let attempt = try await WhatToPlayAttemptFactory.makeAttempt(code: code)

        XCTAssertEqual(attempt.replaySeed, scenario.seed)
        XCTAssertEqual(attempt.gameMode, .hokum)
        XCTAssertEqual(attempt.contextTrumpSuit, .spades)
        XCTAssertEqual(attempt.focusKind, .trumpPressure)
        XCTAssertEqual(attempt.selectedCard, selected.card)
        XCTAssertEqual(attempt.scenarioCode, code)
    }

    func testFactoryRejectsPromptCodeWithoutReviewedSelection() async throws {
        let scenario = try await WhatToPlayScenarioLoader.generate(
            seed: 2026,
            difficulty: .easy,
            preferredFocus: .followSuit
        )
        let promptCode = WhatToPlayShareCard.content(for: scenario).scenarioCode

        do {
            _ = try await WhatToPlayAttemptFactory.makeAttempt(code: promptCode)
            XCTFail("كان يجب رفض رمز السؤال لأنه لا يحتوي اختيارًا مراجعًا")
        } catch let error as WhatToPlayAttemptFactory.ShareCodeAttemptError {
            XCTAssertEqual(error, .missingSelectedCard)
        } catch {
            XCTFail("خطأ غير متوقع: \(error)")
        }
    }

    func testFactoryRejectsMalformedShareCode() async {
        do {
            _ = try await WhatToPlayAttemptFactory.makeAttempt(code: "WTP-invalid")
            XCTFail("كان يجب رفض رمز المشاركة غير الصالح")
        } catch let error as WhatToPlayAttemptFactory.ShareCodeAttemptError {
            XCTAssertEqual(error, .invalidCode)
        } catch {
            XCTFail("خطأ غير متوقع: \(error)")
        }
    }
}
