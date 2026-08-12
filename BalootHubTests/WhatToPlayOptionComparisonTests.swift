import XCTest
import BalootEngine
@testable import BalootHub

final class WhatToPlayOptionComparisonTests: XCTestCase {
    func testSummaryShowsBestAndSecondBestOptions() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let sorted = scenario.options.sorted {
            if $0.rank != $1.rank { return $0.rank < $1.rank }
            if $0.card.suit.ordinal != $1.card.suit.ordinal { return $0.card.suit.ordinal < $1.card.suit.ordinal }
            return $0.card.rank.ordinal < $1.card.rank.ordinal
        }
        let best = try XCTUnwrap(sorted.first)
        let second = try XCTUnwrap(sorted.dropFirst().first)

        let summary = WhatToPlayOptionComparison.summary(for: scenario)

        XCTAssertEqual(summary.bestCard, best.card)
        XCTAssertEqual(summary.bestExpectedImpact, best.expectedImpact)
        XCTAssertEqual(summary.bestProjectedTeamPoints, best.projectedTeamPoints)
        XCTAssertEqual(summary.secondBestCard, second.card)
        XCTAssertEqual(summary.secondBestExpectedImpact, second.expectedImpact)
        XCTAssertEqual(summary.secondBestProjectedTeamPoints, second.projectedTeamPoints)
        XCTAssertEqual(summary.bestToSecondGap, max(0, best.expectedImpact - second.expectedImpact))
        XCTAssertNil(summary.selectedCard)
        XCTAssertNil(summary.selectedExpectedImpact)
        XCTAssertNil(summary.selectedProjectedTeamPoints)
        XCTAssertNil(summary.selectedLostExpectedPoints)
        XCTAssertNil(summary.decisionQuality)
        XCTAssertTrue(summary.hasSecondBest)
    }

    func testSummaryClassifiesSelectedDecisionQuality() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)
        let best = try XCTUnwrap(scenario.bestOption)
        let costly = try XCTUnwrap(
            scenario.options
                .filter { $0.card != best.card }
                .max { lhs, rhs in
                    let bestImpact = best.expectedImpact
                    return max(0, bestImpact - lhs.expectedImpact) < max(0, bestImpact - rhs.expectedImpact)
                }
        )

        let bestSummary = WhatToPlayOptionComparison.summary(for: scenario, selectedCard: best.card)
        let costlySummary = WhatToPlayOptionComparison.summary(for: scenario, selectedCard: costly.card)

        XCTAssertEqual(bestSummary.selectedCard, best.card)
        XCTAssertEqual(bestSummary.selectedExpectedImpact, best.expectedImpact)
        XCTAssertEqual(bestSummary.selectedProjectedTeamPoints, best.projectedTeamPoints)
        XCTAssertEqual(bestSummary.selectedLostExpectedPoints, 0)
        XCTAssertEqual(bestSummary.decisionQuality, .expertMatch)
        XCTAssertEqual(bestSummary.decisionQuality?.title, "مطابق للخبير".localized)
        XCTAssertFalse(bestSummary.decisionQuality?.systemImage.isEmpty ?? true)

        let expectedLost = max(0, best.expectedImpact - costly.expectedImpact)
        XCTAssertEqual(costlySummary.selectedCard, costly.card)
        XCTAssertEqual(costlySummary.selectedExpectedImpact, costly.expectedImpact)
        XCTAssertEqual(costlySummary.selectedProjectedTeamPoints, costly.projectedTeamPoints)
        XCTAssertEqual(costlySummary.selectedLostExpectedPoints, expectedLost)
        if expectedLost <= 2 {
            XCTAssertEqual(costlySummary.decisionQuality, .close)
        } else if expectedLost <= 8 {
            XCTAssertEqual(costlySummary.decisionQuality, .acceptable)
        } else {
            XCTAssertEqual(costlySummary.decisionQuality, .costly)
        }
    }

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

    func testRowsPreserveProjectedTeamPointsForEveryOption() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let selected = try XCTUnwrap(scenario.bestOption)

        let rows = WhatToPlayOptionComparison.rows(for: scenario, selectedCard: selected.card)

        XCTAssertEqual(rows.count, scenario.options.count)
        for row in rows {
            let option = try XCTUnwrap(scenario.options.first { $0.card == row.card })
            XCTAssertEqual(row.projectedTeamPoints, option.projectedTeamPoints)
        }
    }

    func testRowsPreserveImpactBreakdownForEveryOption() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let selected = try XCTUnwrap(scenario.bestOption)

        let rows = WhatToPlayOptionComparison.rows(for: scenario, selectedCard: selected.card)

        XCTAssertEqual(rows.count, scenario.options.count)
        for row in rows {
            let option = try XCTUnwrap(scenario.options.first { $0.card == row.card })
            XCTAssertEqual(row.impactBreakdown, option.impactBreakdown)
            XCTAssertFalse(row.impactDetail.isEmpty)
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

    func testRowsPreserveSimulationSummaryForEveryOption() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)
        let selected = try XCTUnwrap(scenario.bestOption)

        let rows = WhatToPlayOptionComparison.rows(for: scenario, selectedCard: selected.card)

        XCTAssertEqual(rows.count, scenario.options.count)
        for row in rows {
            let option = try XCTUnwrap(scenario.options.first { $0.card == row.card })
            XCTAssertFalse(row.simulationSummary.isEmpty)
            if option.simulation.completedTrickWinnerID == nil {
                XCTAssertTrue(row.simulationSummary.contains("تبقى الأكلة مفتوحة".localized))
                XCTAssertNil(row.simulationTeamResult)
                XCTAssertNil(row.simulationTrickPoints)
            } else {
                XCTAssertEqual(row.simulationSummary, "تكتمل الأكلة وتنتقل للفائز.".localized)
                XCTAssertEqual(
                    row.simulationTeamResult,
                    option.simulation.completedTrickWonByPlayerTeam.map { $0 ? "لفريقك".localized : "للخصم".localized }
                )
                XCTAssertEqual(row.simulationTrickPoints, option.simulation.completedTrickPoints)
            }
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
