import XCTest
import BalootEngine
@testable import BalootHub

final class WhatToPlayOptionComparisonTests: XCTestCase {
    func testRowsAreSortedByExpertRankAndMarkSelectedCard() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let selected = try XCTUnwrap(scenario.secondBestOption ?? scenario.bestOption)

        let rows = WhatToPlayOptionComparison.rows(for: scenario, selectedCard: selected.card)

        XCTAssertEqual(rows.map(\.rank), rows.map(\.rank).sorted())
        XCTAssertEqual(rows.first?.rank, 1)
        XCTAssertEqual(rows.filter(\.isSelected).map(\.card), [selected.card])
        XCTAssertEqual(rows.filter(\.isExpertChoice).count, 1)
    }

    func testRowsPreserveExpectedImpactForEveryOption() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let selected = try XCTUnwrap(scenario.bestOption)

        let rows = WhatToPlayOptionComparison.rows(for: scenario, selectedCard: selected.card)

        XCTAssertEqual(rows.count, scenario.options.count)
        for row in rows {
            let option = try XCTUnwrap(scenario.options.first { $0.card == row.card })
            XCTAssertEqual(row.expectedImpact, option.expectedImpact)
        }
    }

    func testRowsPreserveOutcomeForEveryOption() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let selected = try XCTUnwrap(scenario.bestOption)

        let rows = WhatToPlayOptionComparison.rows(for: scenario, selectedCard: selected.card)

        XCTAssertEqual(rows.count, scenario.options.count)
        for row in rows {
            let option = try XCTUnwrap(scenario.options.first { $0.card == row.card })
            XCTAssertEqual(row.outcome, option.outcome)
        }
    }

    func testRowsPreserveOutcomeReasonForEveryOption() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let selected = try XCTUnwrap(scenario.bestOption)

        let rows = WhatToPlayOptionComparison.rows(for: scenario, selectedCard: selected.card)

        XCTAssertEqual(rows.count, scenario.options.count)
        for row in rows {
            let option = try XCTUnwrap(scenario.options.first { $0.card == row.card })
            XCTAssertEqual(row.outcomeReason, option.outcomeReason)
            XCTAssertFalse(row.outcomeReason.isEmpty)
        }
    }

    func testRowsCalculateLostExpectedPointsAgainstBestOption() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let selected = try XCTUnwrap(scenario.options.last)
        let bestImpact = try XCTUnwrap(scenario.bestOption?.expectedImpact)

        let rows = WhatToPlayOptionComparison.rows(for: scenario, selectedCard: selected.card)

        XCTAssertEqual(rows.first?.lostExpectedPoints, 0)
        for row in rows {
            XCTAssertEqual(row.lostExpectedPoints, max(0, bestImpact - row.expectedImpact))
        }
    }

    func testRowsPreserveTacticalRationaleForEveryOption() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let selected = try XCTUnwrap(scenario.bestOption)

        let rows = WhatToPlayOptionComparison.rows(for: scenario, selectedCard: selected.card)

        XCTAssertFalse(rows.isEmpty)
        for row in rows {
            let option = try XCTUnwrap(scenario.options.first { $0.card == row.card })
            XCTAssertFalse(row.rationale.isEmpty)
            XCTAssertEqual(row.rationale, option.explanation)
        }
    }

    func testRowsTagExpertChoiceAsExpertPick() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let selected = try XCTUnwrap(scenario.bestOption)

        let rows = WhatToPlayOptionComparison.rows(for: scenario, selectedCard: selected.card)
        let expertRow = try XCTUnwrap(rows.first(where: \.isExpertChoice))

        XCTAssertEqual(expertRow.tacticalTag, .expertPick)
        XCTAssertEqual(expertRow.tacticalTag.title, "اختيار الخبير".localized)
        XCTAssertFalse(expertRow.tacticalSummary.isEmpty)
    }

    func testRowsExplainCostlyOptionsWithTacticalSummary() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)
        let selected = try XCTUnwrap(scenario.options.first { $0.expectedImpact < 0 && !$0.isExpertChoice } ?? scenario.options.last)

        let rows = WhatToPlayOptionComparison.rows(for: scenario, selectedCard: selected.card)
        let selectedRow = try XCTUnwrap(rows.first { $0.card == selected.card })

        if selected.expectedImpact < 0, !selected.isExpertChoice {
            XCTAssertEqual(selectedRow.tacticalTag, .costly)
            XCTAssertTrue(selectedRow.tacticalSummary.contains("هذا الخيار قد يكلّف فريقك نقاطًا متوقعة".localized))
        } else {
            XCTAssertFalse(selectedRow.tacticalSummary.isEmpty)
        }
    }
}
