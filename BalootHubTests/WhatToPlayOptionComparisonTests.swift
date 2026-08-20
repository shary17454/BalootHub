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
        let bestSimulation = try XCTUnwrap(
            scenario.options.max { lhs, rhs in
                if lhs.projectedTeamPoints != rhs.projectedTeamPoints {
                    return lhs.projectedTeamPoints < rhs.projectedTeamPoints
                }
                if lhs.expectedImpact != rhs.expectedImpact {
                    return lhs.expectedImpact < rhs.expectedImpact
                }
                return lhs.rank > rhs.rank
            }
        )

        let summary = WhatToPlayOptionComparison.summary(for: scenario)

        XCTAssertEqual(summary.bestCard, best.card)
        XCTAssertEqual(summary.bestExpectedImpact, best.expectedImpact)
        XCTAssertEqual(summary.bestProjectedTeamPoints, best.projectedTeamPoints)
        XCTAssertEqual(summary.secondBestCard, second.card)
        XCTAssertEqual(summary.secondBestExpectedImpact, second.expectedImpact)
        XCTAssertEqual(summary.secondBestProjectedTeamPoints, second.projectedTeamPoints)
        XCTAssertEqual(summary.bestToSecondGap, max(0, best.expectedImpact - second.expectedImpact))
        XCTAssertEqual(summary.bestSimulationCard, bestSimulation.card)
        XCTAssertEqual(summary.bestSimulationExpectedImpact, bestSimulation.expectedImpact)
        XCTAssertEqual(summary.bestSimulationProjectedTeamPoints, bestSimulation.projectedTeamPoints)
        XCTAssertEqual(summary.expertToBestSimulationGap, max(0, bestSimulation.projectedTeamPoints - best.projectedTeamPoints))
        XCTAssertNil(summary.selectedCard)
        XCTAssertNil(summary.selectedExpectedImpact)
        XCTAssertNil(summary.selectedProjectedTeamPoints)
        XCTAssertNil(summary.selectedLostExpectedPoints)
        XCTAssertNil(summary.selectedLostProjectedTeamPoints)
        XCTAssertNil(summary.decisionQuality)
        XCTAssertEqual(summary.bestMoveConfidence, WhatToPlayBestMoveConfidence.classify(bestToSecondGap: summary.bestToSecondGap))
        XCTAssertNil(summary.nextActionTitle)
        XCTAssertNil(summary.nextActionDetail)
        XCTAssertTrue(summary.hasSecondBest)
    }

    func testBestMoveConfidenceClassifiesGapAgainstSecondBest() {
        XCTAssertNil(WhatToPlayBestMoveConfidence.classify(bestToSecondGap: nil))
        XCTAssertEqual(WhatToPlayBestMoveConfidence.classify(bestToSecondGap: 0), .tied)
        XCTAssertEqual(WhatToPlayBestMoveConfidence.classify(bestToSecondGap: 2), .narrow)
        XCTAssertEqual(WhatToPlayBestMoveConfidence.classify(bestToSecondGap: 8), .clear)
        XCTAssertEqual(WhatToPlayBestMoveConfidence.classify(bestToSecondGap: 9), .decisive)
        XCTAssertEqual(WhatToPlayBestMoveConfidence.decisive.title, "أفضلية حاسمة".localized)
        XCTAssertFalse(WhatToPlayBestMoveConfidence.narrow.detail.isEmpty)
        XCTAssertFalse(WhatToPlayBestMoveConfidence.clear.systemImage.isEmpty)
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
        XCTAssertEqual(
            bestSummary.selectedLostProjectedTeamPoints,
            max(0, (bestSummary.bestSimulationProjectedTeamPoints ?? 0) - best.projectedTeamPoints)
        )
        XCTAssertEqual(bestSummary.decisionQuality, .expertMatch)
        XCTAssertEqual(bestSummary.decisionQuality?.title, "مطابق للخبير".localized)
        XCTAssertFalse(bestSummary.decisionQuality?.systemImage.isEmpty ?? true)
        XCTAssertEqual(bestSummary.nextActionTitle, "ثبّت القراءة".localized)
        XCTAssertTrue(bestSummary.nextActionDetail?.contains(best.card.accessibilityName) ?? false)

        let expectedLost = max(0, best.expectedImpact - costly.expectedImpact)
        XCTAssertEqual(costlySummary.selectedCard, costly.card)
        XCTAssertEqual(costlySummary.selectedExpectedImpact, costly.expectedImpact)
        XCTAssertEqual(costlySummary.selectedProjectedTeamPoints, costly.projectedTeamPoints)
        XCTAssertEqual(costlySummary.selectedLostExpectedPoints, expectedLost)
        XCTAssertEqual(
            costlySummary.selectedLostProjectedTeamPoints,
            max(0, (costlySummary.bestSimulationProjectedTeamPoints ?? 0) - costly.projectedTeamPoints)
        )
        let decisiveLost = max(expectedLost, costlySummary.selectedLostProjectedTeamPoints ?? 0)
        if decisiveLost <= 2 {
            XCTAssertEqual(costlySummary.decisionQuality, .close)
        } else if decisiveLost <= 8 {
            XCTAssertEqual(costlySummary.decisionQuality, .acceptable)
        } else {
            XCTAssertEqual(costlySummary.decisionQuality, .costly)
        }
        XCTAssertNotNil(costlySummary.nextActionTitle)
        XCTAssertFalse(costlySummary.nextActionDetail?.isEmpty ?? true)
    }

    func testDecisionQualityUsesProjectedRoundLossWhenLargerThanImmediateImpact() {
        XCTAssertEqual(
            WhatToPlayDecisionQuality.classify(
                isExpertChoice: false,
                lostExpectedPoints: 1,
                lostProjectedTeamPoints: 12
            ),
            .costly
        )
    }

    func testSummaryPrioritizesSimulationReviewWhenProjectedLossIsLarger() throws {
        var matchingScenario: WhatToPlayScenario?
        var selectedOption: WhatToPlayOption?

        for seed in 1...300 {
            let scenario = try WhatToPlayTrainer.generateScenario(seed: UInt64(seed), difficulty: .hard)
            guard let best = scenario.bestOption else { continue }
            if let selected = scenario.options.first(where: {
                $0.card != best.card
                    && max(0, best.expectedImpact - $0.expectedImpact) <= 2
                    && max(0, best.projectedTeamPoints - $0.projectedTeamPoints) >= 9
            }) {
                matchingScenario = scenario
                selectedOption = selected
                break
            }
        }

        let scenario = try XCTUnwrap(matchingScenario)
        let selected = try XCTUnwrap(selectedOption)
        let summary = WhatToPlayOptionComparison.summary(for: scenario, selectedCard: selected.card)

        XCTAssertEqual(summary.decisionQuality, .costly)
        XCTAssertEqual(summary.nextActionTitle, "راجع المحاكاة".localized)
        XCTAssertTrue(summary.nextActionDetail?.contains("بعد استكمال الجولة".localized) ?? false)
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

    func testRowsCalculateProjectedPointLossForEveryOption() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)
        let selected = try XCTUnwrap(scenario.bestOption)
        let bestProjected = try XCTUnwrap(scenario.options.map(\.projectedTeamPoints).max())

        let rows = WhatToPlayOptionComparison.rows(for: scenario, selectedCard: selected.card)

        XCTAssertEqual(rows.count, scenario.options.count)
        for row in rows {
            let option = try XCTUnwrap(scenario.options.first { $0.card == row.card })
            XCTAssertEqual(row.lostProjectedTeamPoints, max(0, bestProjected - option.projectedTeamPoints))
        }
    }

    func testSummaryTracksBestSimulationResultIndependently() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)
        let expert = try XCTUnwrap(scenario.bestOption)
        let bestSimulation = try XCTUnwrap(
            scenario.options.max { lhs, rhs in
                if lhs.projectedTeamPoints != rhs.projectedTeamPoints {
                    return lhs.projectedTeamPoints < rhs.projectedTeamPoints
                }
                if lhs.expectedImpact != rhs.expectedImpact {
                    return lhs.expectedImpact < rhs.expectedImpact
                }
                return lhs.rank > rhs.rank
            }
        )

        let summary = WhatToPlayOptionComparison.summary(for: scenario, selectedCard: expert.card)
        let rows = WhatToPlayOptionComparison.rows(for: scenario, selectedCard: expert.card)

        XCTAssertEqual(summary.bestCard, expert.card)
        XCTAssertEqual(summary.bestSimulationCard, bestSimulation.card)
        XCTAssertEqual(summary.bestSimulationProjectedTeamPoints, bestSimulation.projectedTeamPoints)
        XCTAssertEqual(summary.expertToBestSimulationGap, max(0, bestSimulation.projectedTeamPoints - expert.projectedTeamPoints))
        XCTAssertEqual(summary.selectedLostProjectedTeamPoints, max(0, bestSimulation.projectedTeamPoints - expert.projectedTeamPoints))
        XCTAssertTrue(rows.first { $0.card == bestSimulation.card }?.isBestSimulationResult ?? false)
        XCTAssertEqual(rows.filter(\.isBestSimulationResult).count, 1)
    }

    func testAttemptFactoryPersistsBestSimulationProjection() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)
        let selected = try XCTUnwrap(scenario.options.last)
        let bestSimulation = try XCTUnwrap(WhatToPlayOptionComparison.bestSimulationOption(scenario.options))

        let attempt = try XCTUnwrap(WhatToPlayAttemptFactory.makeAttempt(scenario: scenario, evaluated: selected))

        XCTAssertEqual(attempt.selectedCard, selected.card)
        XCTAssertEqual(attempt.bestCard, scenario.bestOption?.card)
        XCTAssertEqual(attempt.bestSimulationCard, bestSimulation.card)
        XCTAssertEqual(attempt.bestProjectedTeamPoints, bestSimulation.projectedTeamPoints)
        XCTAssertEqual(attempt.lostProjectedTeamPoints, max(0, bestSimulation.projectedTeamPoints - selected.projectedTeamPoints))
    }

    func testAttemptKeepsBestSimulationCardOptionalForExistingRecords() throws {
        let selectedCard = PlayingCard(suit: .spades, rank: .ace)
        let expertCard = PlayingCard(suit: .hearts, rank: .jack)

        let attempt = WhatToPlayAttempt(
            difficulty: .medium,
            seed: 123,
            selectedCard: selectedCard,
            bestCard: expertCard,
            isCorrect: false,
            expectedImpact: 2,
            bestExpectedImpact: 8,
            projectedTeamPoints: 40,
            bestProjectedTeamPoints: 55
        )

        XCTAssertEqual(attempt.selectedCard, selectedCard)
        XCTAssertEqual(attempt.bestCard, expertCard)
        XCTAssertNil(attempt.bestSimulationCard)
        XCTAssertEqual(attempt.lostProjectedTeamPoints, 15)
    }

    func testReviewQueueCarriesBestSimulationCard() throws {
        let selectedCard = PlayingCard(suit: .clubs, rank: .seven)
        let expertCard = PlayingCard(suit: .hearts, rank: .jack)
        let bestSimulationCard = PlayingCard(suit: .spades, rank: .ace)
        let attempt = WhatToPlayAttempt(
            difficulty: .hard,
            seed: 45,
            selectedCard: selectedCard,
            bestCard: expertCard,
            bestSimulationCard: bestSimulationCard,
            isCorrect: false,
            expectedImpact: 2,
            bestExpectedImpact: 4,
            projectedTeamPoints: 61,
            bestProjectedTeamPoints: 74
        )

        let item = try XCTUnwrap(WhatToPlayStatsAnalyzer.reviewQueue(for: [attempt]).first)

        XCTAssertEqual(item.selectedCard, selectedCard)
        XCTAssertEqual(item.bestCard, expertCard)
        XCTAssertEqual(item.bestSimulationCard, bestSimulationCard)
        XCTAssertEqual(item.lostProjectedTeamPoints, 13)
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

    func testRowsTagProjectedRoundLossAsCostly() throws {
        var matchingScenario: WhatToPlayScenario?
        var selectedOption: WhatToPlayOption?

        for seed in 1...300 {
            let scenario = try WhatToPlayTrainer.generateScenario(seed: UInt64(seed), difficulty: .hard)
            guard let best = scenario.bestOption else { continue }
            if let option = scenario.options.first(where: {
                $0.card != best.card
                    && max(0, best.expectedImpact - $0.expectedImpact) <= 2
                    && max(0, best.projectedTeamPoints - $0.projectedTeamPoints) >= 9
            }) {
                matchingScenario = scenario
                selectedOption = option
                break
            }
        }

        let scenario = try XCTUnwrap(matchingScenario)
        let selected = try XCTUnwrap(selectedOption)
        let rows = WhatToPlayOptionComparison.rows(for: scenario, selectedCard: selected.card)
        let selectedRow = try XCTUnwrap(rows.first { $0.card == selected.card })

        XCTAssertEqual(selectedRow.tacticalTag, .costly)
        XCTAssertTrue(selectedRow.tacticalSummary.contains("هذا الخيار يخسر بعد استكمال الجولة".localized))
        XCTAssertTrue(selectedRow.tacticalSummary.contains("Replay"))
    }
}
