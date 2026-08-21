import XCTest
import SwiftData
import BalootEngine
@testable import BalootHub

final class WhatToPlayStatsAnalyzerTests: XCTestCase {
    func testSummaryCalculatesAccuracyStreaksAndAverageImpact() {
        let attempts = [
            attempt(daysAgo: 4, correct: true, impact: 10),
            attempt(daysAgo: 3, correct: true, impact: 4),
            attempt(daysAgo: 2, correct: false, impact: -8),
            attempt(daysAgo: 1, correct: true, impact: 2)
        ]

        let summary = WhatToPlayStatsAnalyzer.summarize(attempts: attempts)

        XCTAssertEqual(summary.attempts, 4)
        XCTAssertEqual(summary.correct, 3)
        XCTAssertEqual(summary.accuracyPercent, 75)
        XCTAssertEqual(summary.bestStreak, 2)
        XCTAssertEqual(summary.currentStreak, 1)
        XCTAssertEqual(summary.averageExpectedImpact, 2)
        XCTAssertEqual(summary.lostExpectedPoints, 0)
        XCTAssertEqual(summary.averageLostExpectedPoints, 0)
        XCTAssertEqual(summary.lostAgainstSecondBestPoints, 0)
        XCTAssertEqual(summary.secondBestComparisonAttempts, 0)
        XCTAssertEqual(summary.averageSecondBestGap, 0)
        XCTAssertEqual(summary.valueCapturePercent, 0)
        XCTAssertEqual(summary.valueCaptureAttempts, 0)
        XCTAssertEqual(summary.projectedTeamPointAttempts, 0)
        XCTAssertEqual(summary.averageProjectedTeamPoints, 0)
        XCTAssertEqual(summary.lostProjectedTeamPoints, 0)
        XCTAssertEqual(summary.averageLostProjectedTeamPoints, 0)
        XCTAssertEqual(summary.projectedSecondBestComparisonAttempts, 0)
        XCTAssertEqual(summary.lostProjectedAgainstSecondBestPoints, 0)
        XCTAssertEqual(summary.averageProjectedSecondBestGap, 0)
    }

    func testSummaryAccumulatesLostExpectedPointsWhenBestImpactIsKnown() {
        let attempts = [
            attempt(daysAgo: 3, correct: true, impact: 4, bestImpact: 4),
            attempt(daysAgo: 2, correct: false, impact: -3, bestImpact: 5),
            attempt(daysAgo: 1, correct: false, impact: 2, bestImpact: 6)
        ]

        let summary = WhatToPlayStatsAnalyzer.summarize(attempts: attempts)

        XCTAssertEqual(summary.lostExpectedPoints, 12)
        XCTAssertEqual(summary.averageLostExpectedPoints, 4)
        XCTAssertEqual(summary.valueCaptureAttempts, 3)
        XCTAssertEqual(summary.valueCapturePercent, 40)
    }

    func testSummaryAccumulatesGapAgainstSecondBestWhenKnown() {
        let attempts = [
            attempt(daysAgo: 3, correct: true, impact: 6, bestImpact: 8, secondBestImpact: 6),
            attempt(daysAgo: 2, correct: false, impact: 1, bestImpact: 7, secondBestImpact: 5),
            attempt(daysAgo: 1, correct: false, impact: -2, bestImpact: 4)
        ]

        let summary = WhatToPlayStatsAnalyzer.summarize(attempts: attempts)

        XCTAssertEqual(summary.secondBestComparisonAttempts, 2)
        XCTAssertEqual(summary.lostAgainstSecondBestPoints, 4)
        XCTAssertEqual(summary.averageSecondBestGap, 2)
        XCTAssertEqual(summary.lostExpectedPoints, 14)
    }

    func testSummaryValueCaptureClampsSelectedImpactAndIgnoresNonPositiveBest() {
        let attempts = [
            attempt(daysAgo: 3, correct: true, impact: 10, bestImpact: 6),
            attempt(daysAgo: 2, correct: false, impact: 3, bestImpact: 0),
            attempt(daysAgo: 1, correct: false, impact: -4, bestImpact: 4)
        ]

        let summary = WhatToPlayStatsAnalyzer.summarize(attempts: attempts)

        XCTAssertEqual(summary.valueCaptureAttempts, 2)
        XCTAssertEqual(summary.valueCapturePercent, 60)
    }

    func testSummaryTracksProjectedTeamPointLossWhenKnown() {
        let attempts = [
            attempt(
                daysAgo: 3,
                correct: true,
                impact: 4,
                projectedTeamPoints: 82,
                bestProjectedTeamPoints: 82,
                secondBestProjectedTeamPoints: 78
            ),
            attempt(
                daysAgo: 2,
                correct: false,
                impact: -3,
                projectedTeamPoints: 64,
                bestProjectedTeamPoints: 76,
                secondBestProjectedTeamPoints: 70
            ),
            attempt(daysAgo: 1, correct: false, impact: 2, projectedTeamPoints: 70)
        ]

        let summary = WhatToPlayStatsAnalyzer.summarize(attempts: attempts)

        XCTAssertEqual(summary.projectedTeamPointAttempts, 3)
        XCTAssertEqual(summary.averageProjectedTeamPoints, 72)
        XCTAssertEqual(summary.lostProjectedTeamPoints, 12)
        XCTAssertEqual(summary.averageLostProjectedTeamPoints, 6)
        XCTAssertEqual(summary.projectedSecondBestComparisonAttempts, 2)
        XCTAssertEqual(summary.lostProjectedAgainstSecondBestPoints, 6)
        XCTAssertEqual(summary.averageProjectedSecondBestGap, 3)
    }

    func testSimulationChoiceSummaryClassifiesBestSecondAndOtherSimulationPicks() {
        let bestSimulation = PlayingCard(suit: .hearts, rank: .ace)
        let secondSimulation = PlayingCard(suit: .diamonds, rank: .king)
        let outsideSimulation = PlayingCard(suit: .clubs, rank: .seven)
        let attempts = [
            attempt(
                daysAgo: 4,
                correct: true,
                impact: 4,
                selectedCard: bestSimulation,
                bestSimulationCard: bestSimulation,
                secondBestSimulationCard: secondSimulation
            ),
            attempt(
                daysAgo: 3,
                correct: false,
                impact: 2,
                selectedCard: secondSimulation,
                bestSimulationCard: bestSimulation,
                secondBestSimulationCard: secondSimulation
            ),
            attempt(
                daysAgo: 2,
                correct: false,
                impact: -1,
                selectedCard: outsideSimulation,
                bestSimulationCard: bestSimulation,
                secondBestSimulationCard: secondSimulation
            ),
            attempt(daysAgo: 1, correct: false, impact: 1)
        ]

        let summary = WhatToPlayStatsAnalyzer.simulationChoiceSummary(for: attempts)

        XCTAssertEqual(summary.trackedAttempts, 3)
        XCTAssertEqual(summary.bestSimulationPicks, 1)
        XCTAssertEqual(summary.secondBestSimulationPicks, 1)
        XCTAssertEqual(summary.otherPicks, 1)
        XCTAssertEqual(summary.bestSimulationPickPercent, 33)
        XCTAssertEqual(summary.secondBestSimulationPickPercent, 33)
        XCTAssertEqual(summary.otherPickPercent, 33)
    }

    func testDecisionHighlightsReturnBestImpactAndWorstLoss() {
        let bestCard = PlayingCard(suit: .hearts, rank: .ace)
        let worstCard = PlayingCard(suit: .spades, rank: .seven)
        let secondSimulationWorstCard = PlayingCard(suit: .diamonds, rank: .jack)
        let attempts = [
            attempt(daysAgo: 3, correct: true, impact: 4, bestImpact: 4, selectedCard: PlayingCard(suit: .clubs, rank: .ten)),
            attempt(daysAgo: 2, correct: true, impact: 9, bestImpact: 9, selectedCard: bestCard),
            attempt(daysAgo: 1, correct: false, impact: 3, bestImpact: 5, selectedCard: worstCard, projectedTeamPoints: 54, bestProjectedTeamPoints: 76),
            attempt(daysAgo: 0, correct: false, impact: 4, bestImpact: 5, selectedCard: secondSimulationWorstCard, projectedTeamPoints: 50, bestProjectedTeamPoints: 52, secondBestProjectedTeamPoints: 80)
        ]

        let best = WhatToPlayStatsAnalyzer.bestDecisionHighlight(for: attempts)
        let worst = WhatToPlayStatsAnalyzer.worstDecisionHighlight(for: attempts)

        XCTAssertEqual(best?.selectedCard, bestCard)
        XCTAssertEqual(best?.expectedImpact, 9)
        XCTAssertEqual(worst?.selectedCard, secondSimulationWorstCard)
        XCTAssertEqual(worst?.lostExpectedPoints, 1)
        XCTAssertEqual(worst?.lostProjectedTeamPoints, 2)
        XCTAssertEqual(worst?.lostProjectedAgainstSecondBestPoints, 30)
        XCTAssertEqual(worst?.totalLoss, 30)
    }

    func testValueProgressDetectsImprovement() {
        let attempts = [
            attempt(daysAgo: 8, correct: false, impact: 1, bestImpact: 10),
            attempt(daysAgo: 7, correct: false, impact: 2, bestImpact: 10),
            attempt(daysAgo: 6, correct: false, impact: 2, bestImpact: 10),
            attempt(daysAgo: 5, correct: false, impact: 3, bestImpact: 10),
            attempt(daysAgo: 4, correct: true, impact: 8, bestImpact: 10),
            attempt(daysAgo: 3, correct: true, impact: 9, bestImpact: 10),
            attempt(daysAgo: 2, correct: true, impact: 10, bestImpact: 10),
            attempt(daysAgo: 1, correct: true, impact: 9, bestImpact: 10)
        ]

        let progress = WhatToPlayStatsAnalyzer.valueProgress(attempts: attempts, window: 4)

        XCTAssertEqual(progress?.direction, .improving)
        XCTAssertEqual(progress?.earlyCapturePercent, 20)
        XCTAssertEqual(progress?.recentCapturePercent, 90)
        XCTAssertEqual(progress?.deltaPercent, 70)
        XCTAssertEqual(progress?.inspectedAttempts, 8)
    }

    func testValueProgressDetectsDecline() {
        let attempts = [
            attempt(daysAgo: 8, correct: true, impact: 10, bestImpact: 10),
            attempt(daysAgo: 7, correct: true, impact: 9, bestImpact: 10),
            attempt(daysAgo: 6, correct: true, impact: 8, bestImpact: 10),
            attempt(daysAgo: 5, correct: true, impact: 9, bestImpact: 10),
            attempt(daysAgo: 4, correct: false, impact: 3, bestImpact: 10),
            attempt(daysAgo: 3, correct: false, impact: 2, bestImpact: 10),
            attempt(daysAgo: 2, correct: false, impact: 1, bestImpact: 10),
            attempt(daysAgo: 1, correct: false, impact: -3, bestImpact: 10)
        ]

        let progress = WhatToPlayStatsAnalyzer.valueProgress(attempts: attempts, window: 4)

        XCTAssertEqual(progress?.direction, .declining)
        XCTAssertEqual(progress?.earlyCapturePercent, 90)
        XCTAssertEqual(progress?.recentCapturePercent, 15)
        XCTAssertEqual(progress?.deltaPercent, -75)
    }

    func testValueProgressRequiresEnoughValueAttempts() {
        let attempts = [
            attempt(daysAgo: 3, correct: true, impact: 4, bestImpact: 4),
            attempt(daysAgo: 2, correct: true, impact: 3, bestImpact: 3),
            attempt(daysAgo: 1, correct: false, impact: -2, bestImpact: nil)
        ]

        XCTAssertNil(WhatToPlayStatsAnalyzer.valueProgress(attempts: attempts, window: 2))
    }

    func testOutcomeSummaryCountsTrackedDecisionOutcomes() {
        let attempts = [
            attempt(daysAgo: 5, correct: true, impact: 5, outcome: .winsTrick),
            attempt(daysAgo: 4, correct: false, impact: -6, outcome: .losesTrick),
            attempt(daysAgo: 3, correct: false, impact: 0, outcome: .leadsTrick),
            attempt(daysAgo: 2, correct: true, impact: 1, outcome: .developsTrick),
            attempt(daysAgo: 1, correct: false, impact: -1)
        ]

        let summary = WhatToPlayStatsAnalyzer.outcomeSummary(for: attempts)

        XCTAssertEqual(summary.trackedAttempts, 4)
        XCTAssertEqual(summary.winningTrickAttempts, 1)
        XCTAssertEqual(summary.losingTrickAttempts, 1)
        XCTAssertEqual(summary.openTrickAttempts, 2)
        XCTAssertEqual(summary.winningPercent, 25)
        XCTAssertEqual(summary.losingPercent, 25)
    }

    func testOutcomeSummaryIgnoresLegacyAttemptsWithoutOutcome() {
        let attempts = [
            attempt(daysAgo: 2, correct: true, impact: 5),
            attempt(daysAgo: 1, correct: false, impact: -6)
        ]

        XCTAssertEqual(WhatToPlayStatsAnalyzer.outcomeSummary(for: attempts), .empty)
    }

    func testOutcomeInsightWaitsForEnoughTrackedAttempts() {
        let summary = WhatToPlayOutcomeSummary(
            trackedAttempts: 2,
            winningTrickAttempts: 1,
            losingTrickAttempts: 1,
            openTrickAttempts: 0
        )

        XCTAssertNil(WhatToPlayStatsAnalyzer.outcomeInsight(for: summary))
    }

    func testOutcomeInsightWarnsWhenLosingTricksOften() {
        let summary = WhatToPlayOutcomeSummary(
            trackedAttempts: 4,
            winningTrickAttempts: 1,
            losingTrickAttempts: 2,
            openTrickAttempts: 1
        )

        let insight = WhatToPlayStatsAnalyzer.outcomeInsight(for: summary)

        XCTAssertEqual(insight?.title, "خسارة الأكلة متكررة".localized)
        XCTAssertEqual(insight?.iconName, "exclamationmark.triangle.fill")
    }

    func testOutcomeInsightRecognizesWinningTricksOften() {
        let summary = WhatToPlayOutcomeSummary(
            trackedAttempts: 4,
            winningTrickAttempts: 2,
            losingTrickAttempts: 1,
            openTrickAttempts: 1
        )

        let insight = WhatToPlayStatsAnalyzer.outcomeInsight(for: summary)

        XCTAssertEqual(insight?.title, "تحسم الأكلات بثبات".localized)
        XCTAssertEqual(insight?.iconName, "checkmark.seal.fill")
    }

    func testOutcomeInsightDetectsOpenTrickPattern() {
        let summary = WhatToPlayOutcomeSummary(
            trackedAttempts: 5,
            winningTrickAttempts: 1,
            losingTrickAttempts: 1,
            openTrickAttempts: 3
        )

        let insight = WhatToPlayStatsAnalyzer.outcomeInsight(for: summary)

        XCTAssertEqual(insight?.title, "قراراتك تترك الأكلة مفتوحة".localized)
        XCTAssertEqual(insight?.iconName, "ellipsis.circle.fill")
    }

    func testOutcomeInsightFallsBackToBalancedPattern() {
        let summary = WhatToPlayOutcomeSummary(
            trackedAttempts: 5,
            winningTrickAttempts: 2,
            losingTrickAttempts: 1,
            openTrickAttempts: 2
        )

        let insight = WhatToPlayStatsAnalyzer.outcomeInsight(for: summary)

        XCTAssertEqual(insight?.title, "نتائج قراراتك متوازنة".localized)
        XCTAssertEqual(insight?.iconName, "scale.3d")
    }

    func testAttemptPersistsInSwiftDataSchemaAndRestoresCards() throws {
        let configuration = ModelConfiguration(schema: PersistenceController.appSchema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PersistenceController.appSchema, configurations: [configuration])
        let context = ModelContext(container)
        let selected = PlayingCard(suit: .spades, rank: .ace)
        let best = PlayingCard(suit: .hearts, rank: .jack)
        let secondBest = PlayingCard(suit: .diamonds, rank: .ace)
        let breakdown = WhatToPlayOptionImpactBreakdown(
            playedCardPoints: 11,
            immediateImpact: -25,
            trickPointsSwing: -25,
            completesTrick: true,
            winsForPlayerTeam: false,
            preservesLead: false
        )
        let nextPlayerID = UUID()
        let simulation = WhatToPlayOptionSimulation(
            phaseAfterPlay: .playing,
            currentTrickCardCount: 0,
            completedTrickWinnerID: UUID(),
            completedTrickWinnerTeamID: UUID(),
            completedTrickWonByPlayerTeam: false,
            completedTrickPoints: 25,
            nextTurnPlayerID: nextPlayerID,
            playerRemainingCards: 4,
            actionHistoryCount: 18
        )
        let scenarioContext = WhatToPlayScenarioContext(
            trickNumber: 5,
            isLeading: false,
            requiredSuit: .hearts,
            playedCardCount: 3,
            legalOptionCount: 2,
            mode: .hokum,
            trumpSuit: .spades,
            hasTrumpInCurrentTrick: true,
            playerTeamTrickPoints: 44,
            opponentTeamTrickPoints: 39,
            playerTeamPointMargin: 5,
            focusKind: .trumpPressure
        )
        let attempt = WhatToPlayAttempt(
            difficulty: .hard,
            seed: 2_026,
            selectedCard: selected,
            bestCard: best,
            secondBestCard: secondBest,
            bestSimulationCard: best,
            secondBestSimulationCard: secondBest,
            isCorrect: false,
            selectedRank: 3,
            expectedImpact: -6,
            bestExpectedImpact: 4,
            secondBestExpectedImpact: 2,
            projectedTeamPoints: 58,
            bestProjectedTeamPoints: 74,
            secondBestProjectedTeamPoints: 68,
            focusKind: .trumpPressure,
            gameMode: .hokum,
            outcome: .losesTrick,
            impactBreakdown: breakdown,
            simulation: simulation,
            scenarioContext: scenarioContext
        )

        context.insert(attempt)
        try context.save()

        let saved = try XCTUnwrap(try context.fetch(FetchDescriptor<WhatToPlayAttempt>()).first)
        XCTAssertEqual(saved.difficulty, .hard)
        XCTAssertEqual(saved.seedValue, 2_026)
        XCTAssertEqual(saved.seedRaw, "2026")
        XCTAssertEqual(saved.replaySeed, 2_026)
        XCTAssertEqual(saved.selectedCard, selected)
        XCTAssertEqual(saved.bestCard, best)
        XCTAssertEqual(saved.secondBestCard, secondBest)
        XCTAssertEqual(saved.bestSimulationCard, best)
        XCTAssertEqual(saved.secondBestSimulationCard, secondBest)
        XCTAssertFalse(saved.isCorrect)
        XCTAssertEqual(saved.selectedRank, 3)
        XCTAssertEqual(saved.expectedImpact, -6)
        XCTAssertEqual(saved.bestExpectedImpact, 4)
        XCTAssertEqual(saved.secondBestExpectedImpact, 2)
        XCTAssertEqual(saved.lostExpectedPoints, 10)
        XCTAssertEqual(saved.projectedTeamPoints, 58)
        XCTAssertEqual(saved.bestProjectedTeamPoints, 74)
        XCTAssertEqual(saved.secondBestProjectedTeamPoints, 68)
        XCTAssertEqual(saved.lostProjectedTeamPoints, 16)
        XCTAssertEqual(saved.lostProjectedAgainstSecondBestPoints, 10)
        XCTAssertEqual(saved.focusKind, .trumpPressure)
        XCTAssertEqual(saved.gameMode, .hokum)
        XCTAssertEqual(saved.outcome, .losesTrick)
        XCTAssertEqual(saved.impactBreakdown, breakdown)
        XCTAssertEqual(saved.selectedCardPoints, 11)
        XCTAssertEqual(saved.selectedImmediateImpact, -25)
        XCTAssertEqual(saved.selectedTrickPointsSwing, -25)
        XCTAssertEqual(saved.selectedCompletesTrick, true)
        XCTAssertEqual(saved.selectedWinsForPlayerTeam, false)
        XCTAssertEqual(saved.selectedPreservesLead, false)
        XCTAssertEqual(saved.simulationPhaseAfterPlay, .playing)
        XCTAssertEqual(saved.simulationCurrentTrickCardCount, 0)
        XCTAssertEqual(saved.simulationCompletedTrickWonByPlayerTeam, false)
        XCTAssertEqual(saved.simulationCompletedTrickPoints, 25)
        XCTAssertEqual(saved.simulationNextTurnPlayerIDRaw, nextPlayerID.uuidString)
        XCTAssertEqual(saved.simulationPlayerRemainingCards, 4)
        XCTAssertEqual(saved.simulationActionHistoryCount, 18)
        XCTAssertEqual(saved.contextTrickNumber, 5)
        XCTAssertEqual(saved.contextIsLeading, false)
        XCTAssertEqual(saved.contextRequiredSuit, .hearts)
        XCTAssertEqual(saved.contextTrumpSuit, .spades)
        XCTAssertEqual(saved.contextHasTrumpInCurrentTrick, true)
        XCTAssertEqual(saved.contextPlayedCardCount, 3)
        XCTAssertEqual(saved.contextLegalOptionCount, 2)
        XCTAssertEqual(saved.contextPlayerTeamTrickPoints, 44)
        XCTAssertEqual(saved.contextOpponentTeamTrickPoints, 39)
        XCTAssertEqual(saved.scenarioContext, scenarioContext)
    }

    func testAttemptStoresFullUInt64SeedForExactReplay() {
        let largeSeed = UInt64.max
        let attempt = WhatToPlayAttempt(
            difficulty: .medium,
            seed: largeSeed,
            selectedCard: PlayingCard(suit: .clubs, rank: .seven),
            bestCard: PlayingCard(suit: .clubs, rank: .eight),
            isCorrect: false,
            expectedImpact: -1
        )

        XCTAssertEqual(attempt.seedValue, Int64.max)
        XCTAssertEqual(attempt.seedRaw, "\(UInt64.max)")
        XCTAssertEqual(attempt.replaySeed, largeSeed)
    }

    func testAttemptReplaySeedFallsBackForLegacyRows() {
        let attempt = WhatToPlayAttempt(
            difficulty: .medium,
            seed: 42,
            selectedCard: PlayingCard(suit: .clubs, rank: .seven),
            bestCard: PlayingCard(suit: .clubs, rank: .eight),
            isCorrect: false,
            expectedImpact: -1
        )
        attempt.seedRaw = nil

        XCTAssertEqual(attempt.replaySeed, 42)
    }

    func testAttemptWithoutBestExpectedImpactKeepsBackwardCompatibleZeroLoss() {
        let attempt = WhatToPlayAttempt(
            difficulty: .medium,
            seed: 99,
            selectedCard: PlayingCard(suit: .clubs, rank: .seven),
            bestCard: PlayingCard(suit: .clubs, rank: .ace),
            isCorrect: false,
            expectedImpact: -4
        )

        XCTAssertNil(attempt.bestExpectedImpact)
        XCTAssertEqual(attempt.lostExpectedPoints, 0)
        XCTAssertNil(attempt.projectedTeamPoints)
        XCTAssertNil(attempt.bestProjectedTeamPoints)
        XCTAssertNil(attempt.secondBestProjectedTeamPoints)
        XCTAssertEqual(attempt.lostProjectedTeamPoints, 0)
        XCTAssertEqual(attempt.lostProjectedAgainstSecondBestPoints, 0)
    }

    func testAttemptWithoutOutcomeKeepsBackwardCompatibleNilOutcome() {
        let attempt = WhatToPlayAttempt(
            difficulty: .medium,
            seed: 99,
            selectedCard: PlayingCard(suit: .clubs, rank: .seven),
            bestCard: PlayingCard(suit: .clubs, rank: .ace),
            isCorrect: false,
            expectedImpact: -4
        )

        XCTAssertNil(attempt.outcomeRaw)
        XCTAssertNil(attempt.outcome)
    }

    func testAttemptWithoutImpactBreakdownKeepsBackwardCompatibleNilBreakdown() {
        let attempt = WhatToPlayAttempt(
            difficulty: .medium,
            seed: 99,
            selectedCard: PlayingCard(suit: .clubs, rank: .seven),
            bestCard: PlayingCard(suit: .clubs, rank: .ace),
            isCorrect: false,
            expectedImpact: -4
        )

        XCTAssertNil(attempt.selectedCardPoints)
        XCTAssertNil(attempt.selectedImmediateImpact)
        XCTAssertNil(attempt.selectedTrickPointsSwing)
        XCTAssertNil(attempt.selectedCompletesTrick)
        XCTAssertNil(attempt.selectedWinsForPlayerTeam)
        XCTAssertNil(attempt.selectedPreservesLead)
        XCTAssertNil(attempt.impactBreakdown)
    }

    func testAttemptWithoutSecondBestKeepsBackwardCompatibleNilSecondBest() {
        let attempt = WhatToPlayAttempt(
            difficulty: .medium,
            seed: 99,
            selectedCard: PlayingCard(suit: .clubs, rank: .seven),
            bestCard: PlayingCard(suit: .clubs, rank: .ace),
            isCorrect: false,
            expectedImpact: -4
        )

        XCTAssertNil(attempt.secondBestSuitRaw)
        XCTAssertNil(attempt.secondBestRankRaw)
        XCTAssertNil(attempt.secondBestCard)
        XCTAssertNil(attempt.secondBestExpectedImpact)
    }

    func testAttemptWithoutSelectedRankKeepsBackwardCompatibleNilRank() {
        let attempt = WhatToPlayAttempt(
            difficulty: .medium,
            seed: 99,
            selectedCard: PlayingCard(suit: .clubs, rank: .seven),
            bestCard: PlayingCard(suit: .clubs, rank: .ace),
            isCorrect: false,
            expectedImpact: -4
        )

        XCTAssertNil(attempt.selectedRank)
    }

    func testAttemptWithoutSimulationKeepsBackwardCompatibleNilSimulation() {
        let attempt = WhatToPlayAttempt(
            difficulty: .medium,
            seed: 99,
            selectedCard: PlayingCard(suit: .clubs, rank: .seven),
            bestCard: PlayingCard(suit: .clubs, rank: .ace),
            isCorrect: false,
            expectedImpact: -4
        )

        XCTAssertNil(attempt.simulationPhaseAfterPlayRaw)
        XCTAssertNil(attempt.simulationPhaseAfterPlay)
        XCTAssertNil(attempt.simulationCurrentTrickCardCount)
        XCTAssertNil(attempt.simulationCompletedTrickWonByPlayerTeam)
        XCTAssertNil(attempt.simulationCompletedTrickPoints)
        XCTAssertNil(attempt.simulationNextTurnPlayerIDRaw)
        XCTAssertNil(attempt.simulationPlayerRemainingCards)
        XCTAssertNil(attempt.simulationActionHistoryCount)
        XCTAssertNil(attempt.secondBestSimulationCard)
    }

    func testAttemptWithoutScenarioContextKeepsBackwardCompatibleNilContext() {
        let attempt = WhatToPlayAttempt(
            difficulty: .medium,
            seed: 99,
            selectedCard: PlayingCard(suit: .clubs, rank: .seven),
            bestCard: PlayingCard(suit: .clubs, rank: .ace),
            isCorrect: false,
            expectedImpact: -4
        )

        XCTAssertFalse(attempt.hasScenarioContext)
        XCTAssertNil(attempt.scenarioContext)
    }

    func testChoiceRankSummaryCountsExpertSecondBestAndFarChoices() {
        let attempts = [
            attempt(daysAgo: 5, correct: true, impact: 4, selectedRank: 1),
            attempt(daysAgo: 4, correct: false, impact: 2, selectedRank: 2),
            attempt(daysAgo: 3, correct: false, impact: 1, selectedRank: 2),
            attempt(daysAgo: 2, correct: false, impact: -4, selectedRank: 4),
            attempt(daysAgo: 1, correct: false, impact: -3)
        ]

        let summary = WhatToPlayStatsAnalyzer.choiceRankSummary(for: attempts)

        XCTAssertEqual(summary.trackedAttempts, 4)
        XCTAssertEqual(summary.expertPicks, 1)
        XCTAssertEqual(summary.secondBestPicks, 2)
        XCTAssertEqual(summary.farPicks, 1)
        XCTAssertEqual(summary.expertPickPercent, 25)
        XCTAssertEqual(summary.nearMissPercent, 50)
        XCTAssertEqual(summary.farPickPercent, 25)
    }

    func testChoiceRankSummaryIgnoresLegacyAttemptsWithoutRank() {
        let attempts = [
            attempt(daysAgo: 2, correct: true, impact: 5),
            attempt(daysAgo: 1, correct: false, impact: -6)
        ]

        XCTAssertEqual(WhatToPlayStatsAnalyzer.choiceRankSummary(for: attempts), .empty)
    }

    func testDecisionQualitySummaryCountsLossBands() {
        let attempts = [
            attempt(daysAgo: 6, correct: true, impact: 10, bestImpact: 10),
            attempt(daysAgo: 5, correct: false, impact: 8, bestImpact: 10),
            attempt(daysAgo: 4, correct: false, impact: 4, bestImpact: 10),
            attempt(daysAgo: 3, correct: false, impact: -2, bestImpact: 10),
            attempt(daysAgo: 2, correct: false, impact: 5),
            attempt(daysAgo: 1, correct: true, impact: 12, bestImpact: 10)
        ]

        let summary = WhatToPlayStatsAnalyzer.decisionQualitySummary(for: attempts)

        XCTAssertEqual(summary.trackedAttempts, 5)
        XCTAssertEqual(summary.expertMatches, 2)
        XCTAssertEqual(summary.closeDecisions, 1)
        XCTAssertEqual(summary.acceptableDecisions, 1)
        XCTAssertEqual(summary.costlyDecisions, 1)
        XCTAssertEqual(summary.strongPercent, 60)
        XCTAssertEqual(summary.costlyPercent, 20)
    }

    func testAttemptDecisionQualityUsesSavedExpectedImpacts() {
        let expert = attempt(daysAgo: 4, correct: true, impact: 6, bestImpact: 10)
        let close = attempt(daysAgo: 3, correct: false, impact: 8, bestImpact: 10)
        let acceptable = attempt(daysAgo: 2, correct: false, impact: 4, bestImpact: 10)
        let costly = attempt(daysAgo: 1, correct: false, impact: 1, bestImpact: 10)
        let legacy = attempt(daysAgo: 0, correct: false, impact: 1)

        XCTAssertEqual(expert.decisionQuality, .expertMatch)
        XCTAssertEqual(close.decisionQuality, .close)
        XCTAssertEqual(acceptable.decisionQuality, .acceptable)
        XCTAssertEqual(costly.decisionQuality, .costly)
        XCTAssertNil(legacy.decisionQuality)
    }

    func testAttemptDecisionQualityUsesSavedProjectedLossWhenLarger() {
        let projectedCostly = attempt(
            daysAgo: 1,
            correct: false,
            impact: 9,
            bestImpact: 10,
            projectedTeamPoints: 52,
            bestProjectedTeamPoints: 68
        )

        XCTAssertEqual(projectedCostly.lostExpectedPoints, 1)
        XCTAssertEqual(projectedCostly.lostProjectedTeamPoints, 16)
        XCTAssertEqual(projectedCostly.decisionQuality, .costly)

        let summary = WhatToPlayStatsAnalyzer.decisionQualitySummary(for: [projectedCostly])
        XCTAssertEqual(summary.trackedAttempts, 1)
        XCTAssertEqual(summary.costlyDecisions, 1)
    }

    func testAttemptDecisionQualityUsesSavedSecondSimulationLossWhenLarger() {
        let secondSimulationCostly = attempt(
            daysAgo: 1,
            correct: false,
            impact: 9,
            bestImpact: 10,
            projectedTeamPoints: 66,
            bestProjectedTeamPoints: 68,
            secondBestProjectedTeamPoints: 82
        )

        XCTAssertEqual(secondSimulationCostly.lostExpectedPoints, 1)
        XCTAssertEqual(secondSimulationCostly.lostProjectedTeamPoints, 2)
        XCTAssertEqual(secondSimulationCostly.lostProjectedAgainstSecondBestPoints, 16)
        XCTAssertEqual(secondSimulationCostly.decisionQuality, .costly)

        let summary = WhatToPlayStatsAnalyzer.decisionQualitySummary(for: [secondSimulationCostly])
        XCTAssertEqual(summary.trackedAttempts, 1)
        XCTAssertEqual(summary.costlyDecisions, 1)
    }

    func testDecisionQualitySummaryIgnoresLegacyAttemptsWithoutBestImpact() {
        let attempts = [
            attempt(daysAgo: 2, correct: true, impact: 5),
            attempt(daysAgo: 1, correct: false, impact: -6)
        ]

        XCTAssertEqual(WhatToPlayStatsAnalyzer.decisionQualitySummary(for: attempts), .empty)
    }

    func testDecisionQualityInsightWaitsForEnoughTrackedAttempts() {
        let summary = WhatToPlayDecisionQualitySummary(
            trackedAttempts: 2,
            expertMatches: 1,
            closeDecisions: 1,
            acceptableDecisions: 0,
            costlyDecisions: 0
        )

        XCTAssertNil(WhatToPlayStatsAnalyzer.decisionQualityInsight(for: summary))
    }

    func testDecisionQualityInsightWarnsAboutCostlyDecisions() {
        let summary = WhatToPlayDecisionQualitySummary(
            trackedAttempts: 10,
            expertMatches: 2,
            closeDecisions: 2,
            acceptableDecisions: 2,
            costlyDecisions: 4
        )

        let insight = WhatToPlayStatsAnalyzer.decisionQualityInsight(for: summary)

        XCTAssertEqual(insight?.kind, .costly)
        XCTAssertEqual(insight?.title, "قرارات مكلفة متكررة".localized)
        XCTAssertEqual(insight?.iconName, "exclamationmark.triangle.fill")
    }

    func testDecisionQualityInsightRecognizesStrongChoices() {
        let summary = WhatToPlayDecisionQualitySummary(
            trackedAttempts: 10,
            expertMatches: 5,
            closeDecisions: 3,
            acceptableDecisions: 2,
            costlyDecisions: 0
        )

        let insight = WhatToPlayStatsAnalyzer.decisionQualityInsight(for: summary)

        XCTAssertEqual(insight?.kind, .strong)
        XCTAssertEqual(insight?.title, "قراراتك قوية".localized)
        XCTAssertEqual(insight?.iconName, "checkmark.seal.fill")
    }

    func testDecisionQualityInsightFallsBackToMixedQuality() {
        let summary = WhatToPlayDecisionQualitySummary(
            trackedAttempts: 10,
            expertMatches: 3,
            closeDecisions: 2,
            acceptableDecisions: 4,
            costlyDecisions: 1
        )

        let insight = WhatToPlayStatsAnalyzer.decisionQualityInsight(for: summary)

        XCTAssertEqual(insight?.kind, .mixed)
        XCTAssertEqual(insight?.title, "قراراتك متوسطة الجودة".localized)
        XCTAssertEqual(insight?.iconName, "gauge.with.dots.needle.50percent")
    }

    func testChoiceRankInsightWaitsForEnoughTrackedAttempts() {
        let summary = WhatToPlayChoiceRankSummary(
            trackedAttempts: 2,
            expertPicks: 1,
            secondBestPicks: 1,
            farPicks: 0
        )

        XCTAssertNil(WhatToPlayStatsAnalyzer.choiceRankInsight(for: summary))
    }

    func testChoiceRankInsightRecognizesExpertAlignment() {
        let summary = WhatToPlayChoiceRankSummary(
            trackedAttempts: 10,
            expertPicks: 7,
            secondBestPicks: 2,
            farPicks: 1
        )

        let insight = WhatToPlayStatsAnalyzer.choiceRankInsight(for: summary)

        XCTAssertEqual(insight?.kind, .expertAligned)
        XCTAssertEqual(insight?.title, "اختياراتك قريبة من الخبير".localized)
        XCTAssertEqual(insight?.iconName, "checkmark.seal.fill")
    }

    func testChoiceRankInsightRecognizesFarChoices() {
        let summary = WhatToPlayChoiceRankSummary(
            trackedAttempts: 6,
            expertPicks: 1,
            secondBestPicks: 1,
            farPicks: 4
        )

        let insight = WhatToPlayStatsAnalyzer.choiceRankInsight(for: summary)

        XCTAssertEqual(insight?.kind, .farChoices)
        XCTAssertEqual(insight?.title, "اختياراتك بعيدة عن التحليل".localized)
        XCTAssertEqual(insight?.iconName, "exclamationmark.triangle.fill")
    }

    func testChoiceRankInsightFallsBackToNearMisses() {
        let summary = WhatToPlayChoiceRankSummary(
            trackedAttempts: 6,
            expertPicks: 2,
            secondBestPicks: 3,
            farPicks: 1
        )

        let insight = WhatToPlayStatsAnalyzer.choiceRankInsight(for: summary)

        XCTAssertEqual(insight?.kind, .nearMisses)
        XCTAssertEqual(insight?.title, "أخطاؤك قريبة وقابلة للتصحيح".localized)
        XCTAssertEqual(insight?.iconName, "2.circle.fill")
    }

    func testRecentAttemptsReturnsNewestFirstWithLimit() {
        let attempts = [
            attempt(daysAgo: 5, correct: true, impact: 0),
            attempt(daysAgo: 4, correct: true, impact: 1),
            attempt(daysAgo: 3, correct: false, impact: 2),
            attempt(daysAgo: 2, correct: true, impact: 3),
            attempt(daysAgo: 1, correct: false, impact: 4)
        ]

        let recent = WhatToPlayStatsAnalyzer.recentAttempts(attempts, limit: 3)

        XCTAssertEqual(recent.map(\.expectedImpact), [4, 3, 2])
    }

    func testRecentAttemptsRejectsZeroLimit() {
        XCTAssertTrue(WhatToPlayStatsAnalyzer.recentAttempts([attempt(daysAgo: 1, correct: true, impact: 0)], limit: 0).isEmpty)
    }

    func testReviewQueueReturnsWorstIncorrectAttemptsFirst() {
        let attempts = [
            attempt(daysAgo: 5, difficulty: .easy, correct: false, impact: -2),
            attempt(daysAgo: 4, difficulty: .medium, correct: true, impact: -20),
            attempt(daysAgo: 3, difficulty: .hard, correct: false, impact: -8),
            attempt(daysAgo: 2, difficulty: .medium, correct: false, impact: 1),
            attempt(daysAgo: 1, difficulty: .easy, correct: false, impact: -5)
        ]

        let queue = WhatToPlayStatsAnalyzer.reviewQueue(for: attempts, limit: 3)

        XCTAssertEqual(queue.map(\.expectedImpact), [-8, -5, -2])
        XCTAssertEqual(queue.first?.difficulty, .hard)
        XCTAssertEqual(queue.first?.seed, 3)
        XCTAssertEqual(queue.first?.title, "راجع اختيارًا مكلفًا".localized)
    }

    func testReviewQueuePrioritizesLargestLostExpectedPointsWhenKnown() {
        let attempts = [
            attempt(daysAgo: 3, difficulty: .easy, correct: false, impact: -5, bestImpact: -1),
            attempt(daysAgo: 2, difficulty: .hard, correct: false, impact: 2, bestImpact: 14),
            attempt(daysAgo: 1, difficulty: .medium, correct: false, impact: -9, bestImpact: -8)
        ]

        let queue = WhatToPlayStatsAnalyzer.reviewQueue(for: attempts, limit: 3)

        XCTAssertEqual(queue.map(\.lostExpectedPoints), [12, 4, 1])
        XCTAssertEqual(queue.first?.difficulty, .hard)
        XCTAssertEqual(queue.first?.expectedImpact, 2)
    }

    func testReviewQueueLabelsPositiveLargeGapAsMissedOpportunity() {
        let attempts = [
            attempt(daysAgo: 1, difficulty: .hard, correct: false, impact: 3, bestImpact: 12)
        ]

        let item = WhatToPlayStatsAnalyzer.reviewQueue(for: attempts).first

        XCTAssertEqual(item?.title, "راجع فرصة ضائعة".localized)
        XCTAssertEqual(item?.detail, "\("قرارك لم يكن خاسرًا مباشرة، لكنه ضيّع نقاطًا متوقعة عن اختيار الخبير".localized): 9. \("راجع لماذا كانت الورقة الأفضل أعلى قيمة.".localized)")
        XCTAssertEqual(item?.iconName, "arrow.up.right.circle.fill")
    }

    func testReviewQueueCarriesLostExpectedPoints() {
        let attempts = [
            attempt(daysAgo: 1, correct: false, impact: -4, bestImpact: 3)
        ]

        let queue = WhatToPlayStatsAnalyzer.reviewQueue(for: attempts)

        XCTAssertEqual(queue.first?.lostExpectedPoints, 7)
        XCTAssertEqual(queue.first?.valueLossSeverity, .high)
        XCTAssertEqual(queue.first?.valueLossTitle, "خسارة قيمة عالية".localized)
    }

    func testReviewQueueCarriesProjectedPointLoss() {
        let secondBestSimulationCard = PlayingCard(suit: .diamonds, rank: .jack)
        let attempts = [
            attempt(
                daysAgo: 1,
                correct: false,
                impact: 2,
                bestImpact: 4,
                secondBestSimulationCard: secondBestSimulationCard,
                projectedTeamPoints: 61,
                bestProjectedTeamPoints: 74,
                secondBestProjectedTeamPoints: 68
            )
        ]

        let item = WhatToPlayStatsAnalyzer.reviewQueue(for: attempts).first

        XCTAssertEqual(item?.projectedTeamPoints, 61)
        XCTAssertEqual(item?.lostProjectedTeamPoints, 13)
        XCTAssertEqual(item?.secondBestSimulationCard, secondBestSimulationCard)
        XCTAssertEqual(item?.secondBestProjectedTeamPoints, 68)
        XCTAssertEqual(item?.lostProjectedAgainstSecondBestPoints, 7)
        XCTAssertEqual(item?.valueLossSeverity, .high)
        XCTAssertEqual(item?.valueLossTitle, "خسارة قيمة عالية".localized)
    }

    func testReviewQueueExplainsSecondBestSimulationPathChoice() throws {
        let selected = PlayingCard(suit: .diamonds, rank: .king)
        let bestSimulation = PlayingCard(suit: .hearts, rank: .ace)
        let item = try XCTUnwrap(
            WhatToPlayStatsAnalyzer.reviewQueue(
                for: [
                    attempt(
                        daysAgo: 1,
                        correct: false,
                        impact: 2,
                        bestImpact: 5,
                        selectedCard: selected,
                        bestSimulationCard: bestSimulation,
                        secondBestSimulationCard: selected,
                        projectedTeamPoints: 64,
                        bestProjectedTeamPoints: 76,
                        secondBestProjectedTeamPoints: 72
                    )
                ]
            ).first
        )

        XCTAssertEqual(item.simulationChoiceTitle, "اخترت ثاني مسار محاكاة".localized)
        XCTAssertTrue(item.simulationChoiceDetail?.contains("12") ?? false)
        XCTAssertEqual(item.simulationChoiceIconName, "2.circle.fill")
    }

    func testReviewQueueExplainsOutsideSimulationPathChoice() throws {
        let selected = PlayingCard(suit: .clubs, rank: .seven)
        let item = try XCTUnwrap(
            WhatToPlayStatsAnalyzer.reviewQueue(
                for: [
                    attempt(
                        daysAgo: 1,
                        correct: false,
                        impact: -1,
                        bestImpact: 5,
                        selectedCard: selected,
                        bestSimulationCard: PlayingCard(suit: .hearts, rank: .ace),
                        secondBestSimulationCard: PlayingCard(suit: .diamonds, rank: .king),
                        projectedTeamPoints: 48,
                        bestProjectedTeamPoints: 80,
                        secondBestProjectedTeamPoints: 72
                    )
                ]
            ).first
        )

        XCTAssertEqual(item.simulationChoiceTitle, "خارج أفضل مسارات المحاكاة".localized)
        XCTAssertTrue(item.simulationChoiceDetail?.contains("ليس أفضل ولا ثاني أفضل".localized) ?? false)
        XCTAssertEqual(item.simulationChoiceIconName, "point.3.connected.trianglepath.dotted")
    }

    func testReviewQueueSeverityUsesSecondSimulationLossWhenLarger() throws {
        let item = try XCTUnwrap(
            WhatToPlayStatsAnalyzer.reviewQueue(
                for: [
                    attempt(
                        daysAgo: 1,
                        correct: false,
                        impact: 3,
                        bestImpact: 4,
                        projectedTeamPoints: 70,
                        bestProjectedTeamPoints: 72,
                        secondBestProjectedTeamPoints: 82
                    )
                ]
            ).first
        )

        XCTAssertEqual(item.lostExpectedPoints, 1)
        XCTAssertEqual(item.lostProjectedTeamPoints, 2)
        XCTAssertEqual(item.lostProjectedAgainstSecondBestPoints, 12)
        XCTAssertEqual(item.valueLossSeverity, .high)
        XCTAssertEqual(item.valueLossTitle, "خسارة قيمة عالية".localized)
    }

    func testReviewQueueUsesSecondSimulationLossAsTieBreaker() {
        let farFromSecondSimulation = attempt(
            daysAgo: 2,
            correct: false,
            impact: 3,
            bestImpact: 4,
            projectedTeamPoints: 70,
            bestProjectedTeamPoints: 80,
            secondBestProjectedTeamPoints: 78
        )
        let closeToSecondSimulation = attempt(
            daysAgo: 1,
            correct: false,
            impact: -2,
            bestImpact: 5,
            projectedTeamPoints: 70,
            bestProjectedTeamPoints: 80,
            secondBestProjectedTeamPoints: 71
        )

        let queue = WhatToPlayStatsAnalyzer.reviewQueue(
            for: [closeToSecondSimulation, farFromSecondSimulation],
            limit: 2
        )

        XCTAssertEqual(queue.first?.seed, farFromSecondSimulation.replaySeed)
        XCTAssertEqual(queue.first?.lostProjectedTeamPoints, 10)
        XCTAssertEqual(queue.first?.lostProjectedAgainstSecondBestPoints, 8)
        XCTAssertEqual(queue.last?.lostProjectedAgainstSecondBestPoints, 1)
    }

    func testAttemptStoresScenarioContextForReplayableReview() {
        let context = WhatToPlayScenarioContext(
            trickNumber: 4,
            isLeading: false,
            requiredSuit: .hearts,
            playedCardCount: 2,
            legalOptionCount: 3,
            mode: .hokum,
            trumpSuit: .spades,
            hasTrumpInCurrentTrick: true,
            playerTeamTrickPoints: 28,
            opponentTeamTrickPoints: 35,
            playerTeamPointMargin: -7,
            focusKind: .trumpPressure
        )

        let stored = attempt(daysAgo: 1, correct: false, impact: -4, scenarioContext: context)

        XCTAssertTrue(stored.hasScenarioContext)
        XCTAssertEqual(stored.contextTrickNumber, 4)
        XCTAssertEqual(stored.contextIsLeading, false)
        XCTAssertEqual(stored.contextRequiredSuit, Suit.hearts)
        XCTAssertEqual(stored.contextTrumpSuit, Suit.spades)
        XCTAssertEqual(stored.contextHasTrumpInCurrentTrick, true)
        XCTAssertEqual(stored.contextPlayedCardCount, 2)
        XCTAssertEqual(stored.contextLegalOptionCount, 3)
        XCTAssertEqual(stored.contextPlayerTeamTrickPoints, 28)
        XCTAssertEqual(stored.contextOpponentTeamTrickPoints, 35)
    }

    func testReviewQueueCarriesScenarioContextForMistakeReview() throws {
        let context = WhatToPlayScenarioContext(
            trickNumber: 6,
            isLeading: true,
            requiredSuit: nil,
            playedCardCount: 0,
            legalOptionCount: 5,
            mode: .hokum,
            trumpSuit: .clubs,
            hasTrumpInCurrentTrick: false,
            playerTeamTrickPoints: 42,
            opponentTeamTrickPoints: 21,
            playerTeamPointMargin: 21,
            focusKind: .openingLead
        )
        let stored = attempt(
            daysAgo: 1,
            correct: false,
            impact: -3,
            bestImpact: 4,
            scenarioContext: context
        )

        let item = try XCTUnwrap(WhatToPlayStatsAnalyzer.reviewQueue(for: [stored]).first)

        XCTAssertEqual(item.contextTrickNumber, 6)
        XCTAssertEqual(item.contextIsLeading, true)
        XCTAssertNil(item.contextRequiredSuit)
        XCTAssertEqual(item.contextTrumpSuit, .clubs)
        XCTAssertEqual(item.contextHasTrumpInCurrentTrick, false)
        XCTAssertEqual(item.contextPlayedCardCount, 0)
        XCTAssertEqual(item.contextLegalOptionCount, 5)
        XCTAssertEqual(item.contextPlayerTeamTrickPoints, 42)
        XCTAssertEqual(item.contextOpponentTeamTrickPoints, 21)
        XCTAssertEqual(item.scenarioContext, context)
    }

    func testAttemptWithoutTrumpContextKeepsBackwardCompatibleNilValues() {
        let stored = attempt(daysAgo: 1, correct: false, impact: -4)

        XCTAssertNil(stored.contextTrumpSuitRaw)
        XCTAssertNil(stored.contextTrumpSuit)
        XCTAssertNil(stored.contextHasTrumpInCurrentTrick)
    }

    func testReviewQueueUsesProjectedLossAsTieBreaker() {
        let attempts = [
            attempt(daysAgo: 2, correct: false, impact: 1, bestImpact: 5, projectedTeamPoints: 70, bestProjectedTeamPoints: 72),
            attempt(daysAgo: 1, correct: false, impact: 1, bestImpact: 5, projectedTeamPoints: 55, bestProjectedTeamPoints: 70)
        ]

        let queue = WhatToPlayStatsAnalyzer.reviewQueue(for: attempts, limit: 2)

        XCTAssertEqual(queue.map(\.lostExpectedPoints), [4, 4])
        XCTAssertEqual(queue.map(\.lostProjectedTeamPoints), [15, 2])
    }

    func testReviewQueuePrioritizesLargeSimulationLossOverImmediateGap() {
        let attempts = [
            attempt(daysAgo: 2, correct: false, impact: 0, bestImpact: 10, projectedTeamPoints: 70, bestProjectedTeamPoints: 72),
            attempt(daysAgo: 1, correct: false, impact: 4, bestImpact: 6, projectedTeamPoints: 50, bestProjectedTeamPoints: 68)
        ]

        let queue = WhatToPlayStatsAnalyzer.reviewQueue(for: attempts, limit: 2)

        XCTAssertEqual(queue.map(\.lostProjectedTeamPoints), [18, 2])
        XCTAssertEqual(queue.map(\.lostExpectedPoints), [2, 10])
    }

    func testReviewQueueUsesExactReplaySeed() throws {
        let attempt = attempt(daysAgo: 1, correct: false, impact: -4, bestImpact: 3, seed: UInt64.max)

        let item = try XCTUnwrap(WhatToPlayStatsAnalyzer.reviewQueue(for: [attempt]).first)

        XCTAssertEqual(item.seed, UInt64.max)
    }

    func testReviewQueueClassifiesMediumValueLoss() throws {
        let item = try XCTUnwrap(
            WhatToPlayStatsAnalyzer.reviewQueue(
                for: [attempt(daysAgo: 1, correct: false, impact: 2, bestImpact: 6)]
            ).first
        )

        XCTAssertEqual(item.lostExpectedPoints, 4)
        XCTAssertEqual(item.valueLossSeverity, .medium)
        XCTAssertEqual(item.valueLossTitle, "خسارة قيمة متوسطة".localized)
    }

    func testReviewPriorityUsesProjectedLossWhenExpectedGapIsSmall() throws {
        let item = try XCTUnwrap(
            WhatToPlayStatsAnalyzer.reviewQueue(
                for: [
                    attempt(
                        daysAgo: 1,
                        correct: false,
                        impact: 2,
                        bestImpact: 4,
                        projectedTeamPoints: 60,
                        bestProjectedTeamPoints: 70
                    )
                ]
            ).first
        )

        let priority = WhatToPlayStatsAnalyzer.reviewPriority(for: item)

        XCTAssertEqual(priority.title, "المحاكاة ترجّح المراجعة".localized)
        XCTAssertTrue(priority.detail.contains("\("خسرت بعد استكمال الجولة".localized): 10"))
        XCTAssertEqual(priority.iconName, "chart.bar.xaxis")
    }

    func testReviewPriorityUsesSecondSimulationLossWhenExpectedGapIsSmall() throws {
        let item = try XCTUnwrap(
            WhatToPlayStatsAnalyzer.reviewQueue(
                for: [
                    attempt(
                        daysAgo: 1,
                        correct: false,
                        impact: 2,
                        bestImpact: 4,
                        projectedTeamPoints: 60,
                        secondBestProjectedTeamPoints: 72
                    )
                ]
            ).first
        )

        let priority = WhatToPlayStatsAnalyzer.reviewPriority(for: item)

        XCTAssertEqual(priority.title, "المحاكاة ترجّح المراجعة".localized)
        XCTAssertTrue(priority.detail.contains("\("خسرت بعد استكمال الجولة".localized): 12"))
        XCTAssertTrue(priority.detail.contains("\("فاقد ثاني محاكاة".localized): 12"))
        XCTAssertEqual(priority.iconName, "chart.bar.xaxis")
    }

    func testReviewQueueCarriesSecondBestForReplayReview() {
        let secondBest = PlayingCard(suit: .diamonds, rank: .ace)
        let attempts = [
            attempt(
                daysAgo: 1,
                difficulty: .hard,
                correct: false,
                impact: -4,
                bestImpact: 3,
                secondBestCard: secondBest,
                secondBestImpact: 1
            )
        ]

        let queue = WhatToPlayStatsAnalyzer.reviewQueue(for: attempts)

        XCTAssertEqual(queue.first?.secondBestCard, secondBest)
        XCTAssertEqual(queue.first?.secondBestExpectedImpact, 1)
    }

    func testReviewQueueCarriesScenarioFocusForReplay() {
        let attempts = [
            attempt(
                daysAgo: 1,
                difficulty: .medium,
                correct: false,
                impact: -4,
                bestImpact: 3,
                focusKind: .followSuit
            )
        ]

        let queue = WhatToPlayStatsAnalyzer.reviewQueue(for: attempts)

        XCTAssertEqual(queue.first?.focusKind, .followSuit)
    }

    func testReviewQueueCarriesGameModeForReplay() {
        let attempts = [
            attempt(
                daysAgo: 1,
                difficulty: .medium,
                correct: false,
                impact: -4,
                bestImpact: 3,
                gameMode: .hokum
            )
        ]

        let queue = WhatToPlayStatsAnalyzer.reviewQueue(for: attempts)

        XCTAssertEqual(queue.first?.gameMode, .hokum)
    }

    func testReviewQueueCarriesCompletedTrickSimulationOutcome() throws {
        let winnerID = UUID()
        let simulation = WhatToPlayOptionSimulation(
            phaseAfterPlay: .playing,
            currentTrickCardCount: 0,
            completedTrickWinnerID: winnerID,
            completedTrickWinnerTeamID: UUID(),
            completedTrickWonByPlayerTeam: false,
            completedTrickPoints: 18,
            nextTurnPlayerID: winnerID,
            playerRemainingCards: 4,
            actionHistoryCount: 12
        )

        let item = try XCTUnwrap(
            WhatToPlayStatsAnalyzer.reviewQueue(
                for: [
                    attempt(
                        daysAgo: 1,
                        correct: false,
                        impact: -6,
                        bestImpact: 2,
                        simulation: simulation
                    )
                ]
            ).first
        )

        XCTAssertEqual(item.simulationSummary, "تكتمل الأكلة وتنتقل للفائز.".localized)
        XCTAssertEqual(item.simulationTeamResult, "للخصم".localized)
        XCTAssertEqual(item.simulationTrickPoints, 18)
    }

    func testReviewQueueCarriesOpenTrickSimulationOutcome() throws {
        let simulation = WhatToPlayOptionSimulation(
            phaseAfterPlay: .playing,
            currentTrickCardCount: 2,
            completedTrickWinnerID: nil,
            completedTrickWinnerTeamID: nil,
            completedTrickWonByPlayerTeam: nil,
            completedTrickPoints: 0,
            nextTurnPlayerID: UUID(),
            playerRemainingCards: 5,
            actionHistoryCount: 10
        )

        let item = try XCTUnwrap(
            WhatToPlayStatsAnalyzer.reviewQueue(
                for: [
                    attempt(
                        daysAgo: 1,
                        correct: false,
                        impact: -2,
                        bestImpact: 3,
                        simulation: simulation
                    )
                ]
            ).first
        )

        XCTAssertEqual(item.simulationSummary, "\("تبقى الأكلة مفتوحة".localized) · 2 \("أوراق على الطاولة".localized)")
        XCTAssertNil(item.simulationTeamResult)
        XCTAssertNil(item.simulationTrickPoints)
    }

    func testReviewQueueKeepsBackwardCompatibleNilSimulationOutcome() throws {
        let item = try XCTUnwrap(
            WhatToPlayStatsAnalyzer.reviewQueue(
                for: [
                    attempt(daysAgo: 1, correct: false, impact: -4, bestImpact: 2)
                ]
            ).first
        )

        XCTAssertNil(item.simulationSummary)
        XCTAssertNil(item.simulationTeamResult)
        XCTAssertNil(item.simulationTrickPoints)
    }

    func testReviewQueueCarriesOpponentClosureTacticalReason() throws {
        let item = try XCTUnwrap(
            WhatToPlayStatsAnalyzer.reviewQueue(
                for: [
                    attempt(
                        daysAgo: 1,
                        correct: false,
                        impact: -7,
                        bestImpact: 2,
                        impactBreakdown: .opponentTrickClosure(points: 16)
                    )
                ]
            ).first
        )

        XCTAssertEqual(item.tacticalReasonTitle, "تغلق الأكلة للخصم".localized)
        XCTAssertEqual(item.tacticalReasonIconName, "flag.slash.fill")
        XCTAssertNotNil(item.tacticalReasonDetail)
    }

    func testReviewQueueCarriesPointDumpTacticalReason() throws {
        let item = try XCTUnwrap(
            WhatToPlayStatsAnalyzer.reviewQueue(
                for: [
                    attempt(
                        daysAgo: 1,
                        correct: false,
                        impact: -4,
                        bestImpact: 2,
                        impactBreakdown: .unprotectedPointDump(points: 10)
                    )
                ]
            ).first
        )

        XCTAssertEqual(item.tacticalReasonTitle, "ترمي نقاطًا بلا حماية".localized)
        XCTAssertEqual(item.tacticalReasonIconName, "drop.triangle.fill")
    }

    func testReviewQueueCarriesCostlyOpeningTacticalReason() throws {
        let item = try XCTUnwrap(
            WhatToPlayStatsAnalyzer.reviewQueue(
                for: [
                    attempt(
                        daysAgo: 1,
                        correct: false,
                        impact: -3,
                        bestImpact: 2,
                        impactBreakdown: .costlyOpeningLead(points: 4)
                    )
                ]
            ).first
        )

        XCTAssertEqual(item.tacticalReasonTitle, "افتتاح مكلف".localized)
        XCTAssertEqual(item.tacticalReasonIconName, "arrow.up.forward.circle.fill")
    }

    func testReviewPriorityMarksNegativeImpactAsHighPriority() throws {
        let item = try XCTUnwrap(
            WhatToPlayStatsAnalyzer.reviewQueue(
                for: [attempt(daysAgo: 1, correct: false, impact: -4, bestImpact: 3)]
            ).first
        )

        let priority = WhatToPlayStatsAnalyzer.reviewPriority(for: item)

        XCTAssertEqual(priority.title, "أولوية عالية".localized)
        XCTAssertEqual(priority.iconName, "exclamationmark.triangle.fill")
        XCTAssertTrue(priority.detail.contains("-4"))
    }

    func testReviewPriorityMarksPositiveGapAsMissedValue() throws {
        let item = try XCTUnwrap(
            WhatToPlayStatsAnalyzer.reviewQueue(
                for: [attempt(daysAgo: 1, correct: false, impact: 3, bestImpact: 12)]
            ).first
        )

        let priority = WhatToPlayStatsAnalyzer.reviewPriority(for: item)

        XCTAssertEqual(priority.title, "فرصة قيمة ضاعت".localized)
        XCTAssertEqual(priority.iconName, "arrow.up.right.circle.fill")
        XCTAssertTrue(priority.detail.contains("9"))
    }

    func testReviewPriorityMarksSmallGapAsTacticalDifference() throws {
        let item = try XCTUnwrap(
            WhatToPlayStatsAnalyzer.reviewQueue(
                for: [attempt(daysAgo: 1, correct: false, impact: 4, bestImpact: 5)]
            ).first
        )

        let priority = WhatToPlayStatsAnalyzer.reviewPriority(for: item)

        XCTAssertEqual(priority.title, "فرق تكتيكي قريب".localized)
        XCTAssertEqual(priority.iconName, "2.circle.fill")
    }

    func testReviewQueueUsesRecentTieBreakerForEqualImpact() {
        let attempts = [
            attempt(daysAgo: 3, correct: false, impact: -4),
            attempt(daysAgo: 1, correct: false, impact: -4)
        ]

        let queue = WhatToPlayStatsAnalyzer.reviewQueue(for: attempts)

        XCTAssertEqual(queue.first?.createdAt, attempts[1].createdAt)
    }

    func testReviewQueueReturnsEmptyForCorrectAttemptsOrZeroLimit() {
        let attempts = [
            attempt(daysAgo: 2, correct: true, impact: -10),
            attempt(daysAgo: 1, correct: true, impact: 4)
        ]

        XCTAssertTrue(WhatToPlayStatsAnalyzer.reviewQueue(for: attempts).isEmpty)
        XCTAssertTrue(WhatToPlayStatsAnalyzer.reviewQueue(for: [attempt(daysAgo: 1, correct: false, impact: -4)], limit: 0).isEmpty)
    }

    func testSummariesByDifficultySkipEmptyLevelsAndPreserveDifficultyOrder() {
        let attempts = [
            attempt(daysAgo: 3, difficulty: .hard, correct: true, impact: 4),
            attempt(daysAgo: 2, difficulty: .easy, correct: false, impact: -2),
            attempt(daysAgo: 1, difficulty: .hard, correct: false, impact: -6)
        ]

        let summaries = WhatToPlayStatsAnalyzer.summariesByDifficulty(attempts)

        XCTAssertEqual(summaries.map(\.difficulty), [.easy, .hard])
        XCTAssertEqual(summaries.first?.summary.accuracyPercent, 0)
        XCTAssertEqual(summaries.last?.summary.attempts, 2)
        XCTAssertEqual(summaries.last?.summary.accuracyPercent, 50)
    }

    func testSummariesByScenarioFocusSkipLegacyAttemptsAndPreserveFocusOrder() {
        let attempts = [
            attempt(daysAgo: 4, difficulty: .easy, correct: true, impact: 4, bestImpact: 4, focusKind: .trumpPressure),
            attempt(daysAgo: 3, difficulty: .easy, correct: false, impact: -2, bestImpact: 3, focusKind: .openingLead),
            attempt(daysAgo: 2, difficulty: .medium, correct: false, impact: -4, bestImpact: 2, focusKind: .trumpPressure),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: 1)
        ]

        let summaries = WhatToPlayStatsAnalyzer.summariesByScenarioFocus(attempts)

        XCTAssertEqual(summaries.map(\.focusKind), [.openingLead, .trumpPressure])
        XCTAssertEqual(summaries.first?.summary.lostExpectedPoints, 5)
        XCTAssertEqual(summaries.last?.summary.attempts, 2)
        XCTAssertEqual(summaries.last?.summary.accuracyPercent, 50)
        XCTAssertEqual(summaries.last?.summary.lostExpectedPoints, 6)
    }

    func testSummariesByGameModeSkipLegacyAttemptsAndPreserveModeOrder() {
        let attempts = [
            attempt(daysAgo: 4, difficulty: .easy, correct: true, impact: 4, bestImpact: 4, gameMode: .hokum),
            attempt(daysAgo: 3, difficulty: .easy, correct: false, impact: -2, bestImpact: 3, gameMode: .sun),
            attempt(daysAgo: 2, difficulty: .medium, correct: false, impact: -4, bestImpact: 2, gameMode: .hokum),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: 1)
        ]

        let summaries = WhatToPlayStatsAnalyzer.summariesByGameMode(attempts)

        XCTAssertEqual(summaries.map(\.mode), [.sun, .hokum])
        XCTAssertEqual(summaries.first?.summary.attempts, 1)
        XCTAssertEqual(summaries.first?.summary.accuracyPercent, 0)
        XCTAssertEqual(summaries.last?.summary.attempts, 2)
        XCTAssertEqual(summaries.last?.summary.accuracyPercent, 50)
        XCTAssertEqual(summaries.last?.summary.lostExpectedPoints, 6)
    }

    func testFocusGameModePicksWeakestModeWithEnoughAttempts() {
        let attempts = [
            attempt(daysAgo: 5, correct: true, impact: 4, bestImpact: 4, gameMode: .sun),
            attempt(daysAgo: 4, correct: true, impact: 3, bestImpact: 3, gameMode: .sun),
            attempt(daysAgo: 3, correct: false, impact: -4, bestImpact: 3, gameMode: .hokum),
            attempt(daysAgo: 2, correct: true, impact: 2, bestImpact: 2, gameMode: .hokum),
            attempt(daysAgo: 1, correct: false, impact: -2, bestImpact: 1)
        ]

        let focus = WhatToPlayStatsAnalyzer.focusGameMode(attempts)

        XCTAssertEqual(focus?.mode, .hokum)
        XCTAssertEqual(focus?.summary.accuracyPercent, 50)
        XCTAssertEqual(focus?.summary.lostExpectedPoints, 7)
    }

    func testGameModeTrainingPriorityUsesProjectedLossBeforeExpectedLoss() {
        let attempts = [
            attempt(daysAgo: 6, correct: false, impact: 1, bestImpact: 5, gameMode: .sun, projectedTeamPoints: 70, bestProjectedTeamPoints: 74),
            attempt(daysAgo: 5, correct: true, impact: 3, bestImpact: 3, gameMode: .sun, projectedTeamPoints: 78, bestProjectedTeamPoints: 78),
            attempt(daysAgo: 4, correct: false, impact: 2, bestImpact: 5, gameMode: .hokum, projectedTeamPoints: 54, bestProjectedTeamPoints: 76),
            attempt(daysAgo: 3, correct: true, impact: 3, bestImpact: 3, gameMode: .hokum, projectedTeamPoints: 82, bestProjectedTeamPoints: 82)
        ]

        let priority = WhatToPlayStatsAnalyzer.gameModeTrainingPriority(for: attempts)

        XCTAssertEqual(priority?.mode, .hokum)
        XCTAssertEqual(priority?.summary.lostExpectedPoints, 3)
        XCTAssertEqual(priority?.summary.lostProjectedTeamPoints, 22)
        XCTAssertEqual(priority?.title, "\("أولوية التدريب".localized): \("حكم".localized)")
        XCTAssertEqual(priority?.iconName, "crown.fill")
        XCTAssertTrue(priority?.detail.contains("سبب الترشيح من المحاكاة".localized) ?? false)
    }

    func testGameModeTrainingPriorityUsesSecondProjectedLossBeforeProjectedLoss() {
        let attempts = [
            attempt(daysAgo: 6, correct: false, impact: 3, bestImpact: 5, gameMode: .sun, projectedTeamPoints: 70, bestProjectedTeamPoints: 72, secondBestProjectedTeamPoints: 94),
            attempt(daysAgo: 5, correct: true, impact: 3, bestImpact: 3, gameMode: .sun, projectedTeamPoints: 78, bestProjectedTeamPoints: 78, secondBestProjectedTeamPoints: 78),
            attempt(daysAgo: 4, correct: false, impact: 1, bestImpact: 5, gameMode: .hokum, projectedTeamPoints: 54, bestProjectedTeamPoints: 76, secondBestProjectedTeamPoints: 76),
            attempt(daysAgo: 3, correct: true, impact: 3, bestImpact: 3, gameMode: .hokum, projectedTeamPoints: 82, bestProjectedTeamPoints: 82, secondBestProjectedTeamPoints: 82)
        ]

        let priority = WhatToPlayStatsAnalyzer.gameModeTrainingPriority(for: attempts)

        XCTAssertEqual(priority?.mode, .sun)
        XCTAssertEqual(priority?.summary.lostExpectedPoints, 2)
        XCTAssertEqual(priority?.summary.lostProjectedTeamPoints, 2)
        XCTAssertEqual(priority?.summary.lostProjectedAgainstSecondBestPoints, 24)
        XCTAssertTrue(priority?.detail.contains("فاقد ثاني محاكاة".localized) ?? false)
    }

    func testGameModeTrainingPriorityUsesExpectedLossWhenProjectionIsTied() {
        let attempts = [
            attempt(daysAgo: 6, correct: false, impact: -1, bestImpact: 1, gameMode: .sun, projectedTeamPoints: 70, bestProjectedTeamPoints: 76),
            attempt(daysAgo: 5, correct: true, impact: 3, bestImpact: 3, gameMode: .sun, projectedTeamPoints: 80, bestProjectedTeamPoints: 80),
            attempt(daysAgo: 4, correct: false, impact: -4, bestImpact: 3, gameMode: .hokum, projectedTeamPoints: 66, bestProjectedTeamPoints: 72),
            attempt(daysAgo: 3, correct: true, impact: 2, bestImpact: 2, gameMode: .hokum, projectedTeamPoints: 78, bestProjectedTeamPoints: 78)
        ]

        let priority = WhatToPlayStatsAnalyzer.gameModeTrainingPriority(for: attempts)

        XCTAssertEqual(priority?.mode, .hokum)
        XCTAssertEqual(priority?.summary.lostExpectedPoints, 7)
        XCTAssertEqual(priority?.summary.lostProjectedTeamPoints, 6)
        XCTAssertTrue(priority?.detail.contains("متوسط النقاط الضائعة".localized) ?? false)
    }

    func testGameModeTrainingPriorityReturnsNilWhenModesArePerfect() {
        let attempts = [
            attempt(daysAgo: 4, correct: true, impact: 2, bestImpact: 2, gameMode: .sun),
            attempt(daysAgo: 3, correct: true, impact: 3, bestImpact: 3, gameMode: .sun),
            attempt(daysAgo: 2, correct: true, impact: 2, bestImpact: 2, gameMode: .hokum),
            attempt(daysAgo: 1, correct: true, impact: 3, bestImpact: 3, gameMode: .hokum)
        ]

        XCTAssertNil(WhatToPlayStatsAnalyzer.gameModeTrainingPriority(for: attempts))
    }

    func testSummariesByTrumpSuitSkipSunAndLegacyAttemptsAndPreserveSuitOrder() {
        let attempts = [
            attempt(daysAgo: 5, correct: true, impact: 4, bestImpact: 4, gameMode: .hokum, scenarioContext: hokumContext(trumpSuit: .spades)),
            attempt(daysAgo: 4, correct: false, impact: -3, bestImpact: 3, gameMode: .sun, scenarioContext: hokumContext(trumpSuit: .hearts)),
            attempt(daysAgo: 3, correct: false, impact: -2, bestImpact: 4, gameMode: .hokum, scenarioContext: hokumContext(trumpSuit: .hearts)),
            attempt(daysAgo: 2, correct: true, impact: 2, bestImpact: 2, gameMode: .hokum, scenarioContext: hokumContext(trumpSuit: .hearts)),
            attempt(daysAgo: 1, correct: false, impact: -1, bestImpact: 2, gameMode: .hokum)
        ]

        let summaries = WhatToPlayStatsAnalyzer.summariesByTrumpSuit(attempts)

        XCTAssertEqual(summaries.map(\.suit), [.hearts, .spades])
        XCTAssertEqual(summaries.first?.summary.attempts, 2)
        XCTAssertEqual(summaries.first?.summary.accuracyPercent, 50)
        XCTAssertEqual(summaries.first?.summary.lostExpectedPoints, 6)
        XCTAssertEqual(summaries.last?.summary.attempts, 1)
        XCTAssertEqual(summaries.last?.summary.accuracyPercent, 100)
    }

    func testTrumpSuitTrainingPriorityUsesProjectedLossBeforeExpectedLoss() {
        let attempts = [
            attempt(daysAgo: 6, correct: false, impact: -4, bestImpact: 4, gameMode: .hokum, projectedTeamPoints: 50, bestProjectedTeamPoints: 56, scenarioContext: hokumContext(trumpSuit: .hearts)),
            attempt(daysAgo: 5, correct: true, impact: 3, bestImpact: 3, gameMode: .hokum, projectedTeamPoints: 62, bestProjectedTeamPoints: 62, scenarioContext: hokumContext(trumpSuit: .hearts)),
            attempt(daysAgo: 4, correct: false, impact: 1, bestImpact: 4, gameMode: .hokum, projectedTeamPoints: 44, bestProjectedTeamPoints: 70, scenarioContext: hokumContext(trumpSuit: .spades)),
            attempt(daysAgo: 3, correct: true, impact: 2, bestImpact: 2, gameMode: .hokum, projectedTeamPoints: 72, bestProjectedTeamPoints: 72, scenarioContext: hokumContext(trumpSuit: .spades))
        ]

        let priority = WhatToPlayStatsAnalyzer.trumpSuitTrainingPriority(for: attempts)

        XCTAssertEqual(priority?.suit, .spades)
        XCTAssertEqual(priority?.summary.lostExpectedPoints, 3)
        XCTAssertEqual(priority?.summary.lostProjectedTeamPoints, 26)
        XCTAssertEqual(priority?.title, "\("أولوية التدريب".localized): \("حكم".localized) \(Suit.spades.spokenName)")
        XCTAssertEqual(priority?.iconName, "suit.spade.fill")
        XCTAssertTrue(priority?.detail.contains("سبب الترشيح من المحاكاة".localized) ?? false)
    }

    func testTrumpSuitTrainingPriorityUsesSecondProjectedLossBeforeProjectedLoss() {
        let attempts = [
            attempt(daysAgo: 6, correct: false, impact: 2, bestImpact: 4, gameMode: .hokum, projectedTeamPoints: 50, bestProjectedTeamPoints: 52, secondBestProjectedTeamPoints: 82, scenarioContext: hokumContext(trumpSuit: .hearts)),
            attempt(daysAgo: 5, correct: true, impact: 3, bestImpact: 3, gameMode: .hokum, projectedTeamPoints: 62, bestProjectedTeamPoints: 62, secondBestProjectedTeamPoints: 62, scenarioContext: hokumContext(trumpSuit: .hearts)),
            attempt(daysAgo: 4, correct: false, impact: 1, bestImpact: 4, gameMode: .hokum, projectedTeamPoints: 44, bestProjectedTeamPoints: 70, secondBestProjectedTeamPoints: 70, scenarioContext: hokumContext(trumpSuit: .spades)),
            attempt(daysAgo: 3, correct: true, impact: 2, bestImpact: 2, gameMode: .hokum, projectedTeamPoints: 72, bestProjectedTeamPoints: 72, secondBestProjectedTeamPoints: 72, scenarioContext: hokumContext(trumpSuit: .spades))
        ]

        let priority = WhatToPlayStatsAnalyzer.trumpSuitTrainingPriority(for: attempts)

        XCTAssertEqual(priority?.suit, .hearts)
        XCTAssertEqual(priority?.summary.lostProjectedTeamPoints, 2)
        XCTAssertEqual(priority?.summary.lostProjectedAgainstSecondBestPoints, 32)
        XCTAssertTrue(priority?.detail.contains("فاقد ثاني محاكاة".localized) ?? false)
    }

    func testTrumpSuitTrainingPriorityReturnsNilWhenTrumpSuitsArePerfect() {
        let attempts = [
            attempt(daysAgo: 4, correct: true, impact: 2, bestImpact: 2, gameMode: .hokum, scenarioContext: hokumContext(trumpSuit: .hearts)),
            attempt(daysAgo: 3, correct: true, impact: 3, bestImpact: 3, gameMode: .hokum, scenarioContext: hokumContext(trumpSuit: .hearts)),
            attempt(daysAgo: 2, correct: true, impact: 2, bestImpact: 2, gameMode: .hokum, scenarioContext: hokumContext(trumpSuit: .clubs)),
            attempt(daysAgo: 1, correct: true, impact: 3, bestImpact: 3, gameMode: .hokum, scenarioContext: hokumContext(trumpSuit: .clubs))
        ]

        XCTAssertNil(WhatToPlayStatsAnalyzer.trumpSuitTrainingPriority(for: attempts))
    }

    func testFocusScenarioKindPicksWeakestTrainingFocus() {
        let attempts = [
            attempt(daysAgo: 6, difficulty: .easy, correct: true, impact: 3, bestImpact: 3, focusKind: .openingLead),
            attempt(daysAgo: 5, difficulty: .easy, correct: false, impact: -1, bestImpact: 2, focusKind: .openingLead),
            attempt(daysAgo: 4, difficulty: .medium, correct: false, impact: -8, bestImpact: 4, focusKind: .trumpPressure),
            attempt(daysAgo: 3, difficulty: .medium, correct: true, impact: 2, bestImpact: 2, focusKind: .trumpPressure),
            attempt(daysAgo: 2, difficulty: .hard, correct: false, impact: -3, bestImpact: 2, focusKind: .followSuit),
            attempt(daysAgo: 1, difficulty: .hard, correct: false, impact: -2, bestImpact: 1, focusKind: .followSuit)
        ]

        let focus = WhatToPlayStatsAnalyzer.focusScenarioKind(attempts)

        XCTAssertEqual(focus?.focusKind, .followSuit)
        XCTAssertEqual(focus?.summary.accuracyPercent, 0)
        XCTAssertEqual(focus?.summary.lostExpectedPoints, 8)
    }

    func testFocusScenarioKindUsesLostPointsAsTieBreaker() {
        let attempts = [
            attempt(daysAgo: 4, difficulty: .easy, correct: false, impact: -4, bestImpact: 1, focusKind: .openingLead),
            attempt(daysAgo: 3, difficulty: .easy, correct: true, impact: 1, bestImpact: 1, focusKind: .openingLead),
            attempt(daysAgo: 2, difficulty: .medium, correct: false, impact: -9, bestImpact: 3, focusKind: .trumpPressure),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: 3, bestImpact: 3, focusKind: .trumpPressure)
        ]

        let focus = WhatToPlayStatsAnalyzer.focusScenarioKind(attempts)

        XCTAssertEqual(focus?.focusKind, .trumpPressure)
        XCTAssertEqual(focus?.summary.accuracyPercent, 50)
        XCTAssertEqual(focus?.summary.lostExpectedPoints, 12)
    }

    func testFocusDifficultyRequiresMinimumAttemptsAndPicksLowestAccuracy() {
        let attempts = [
            attempt(daysAgo: 5, difficulty: .easy, correct: false, impact: -20),
            attempt(daysAgo: 4, difficulty: .medium, correct: true, impact: 4),
            attempt(daysAgo: 3, difficulty: .medium, correct: false, impact: -2),
            attempt(daysAgo: 2, difficulty: .hard, correct: false, impact: -8),
            attempt(daysAgo: 1, difficulty: .hard, correct: false, impact: -6)
        ]

        let focus = WhatToPlayStatsAnalyzer.focusDifficulty(attempts)

        XCTAssertEqual(focus?.difficulty, .hard)
        XCTAssertEqual(focus?.summary.accuracyPercent, 0)
    }

    func testFocusDifficultyReturnsNilWithoutEnoughAttempts() {
        let attempts = [
            attempt(daysAgo: 1, difficulty: .easy, correct: false, impact: -10)
        ]

        XCTAssertNil(WhatToPlayStatsAnalyzer.focusDifficulty(attempts))
    }

    func testFocusDifficultyUsesExpectedImpactAsTieBreaker() {
        let attempts = [
            attempt(daysAgo: 4, difficulty: .medium, correct: true, impact: 0),
            attempt(daysAgo: 3, difficulty: .medium, correct: false, impact: -10),
            attempt(daysAgo: 2, difficulty: .hard, correct: true, impact: 6),
            attempt(daysAgo: 1, difficulty: .hard, correct: false, impact: 0)
        ]

        let focus = WhatToPlayStatsAnalyzer.focusDifficulty(attempts)

        XCTAssertEqual(focus?.difficulty, .medium)
        XCTAssertEqual(focus?.summary.accuracyPercent, 50)
        XCTAssertEqual(focus?.summary.averageExpectedImpact, -5)
    }

    func testDifficultyImpactInsightRequiresEnoughSamples() {
        let attempts = [
            attempt(daysAgo: 1, difficulty: .hard, correct: false, impact: -10)
        ]

        XCTAssertNil(WhatToPlayStatsAnalyzer.difficultyImpactInsight(for: attempts))
    }

    func testDifficultyImpactInsightFindsWorstExpectedImpactDifficulty() {
        let attempts = [
            attempt(daysAgo: 6, difficulty: .easy, correct: true, impact: 2),
            attempt(daysAgo: 5, difficulty: .easy, correct: false, impact: 0),
            attempt(daysAgo: 4, difficulty: .medium, correct: true, impact: -2),
            attempt(daysAgo: 3, difficulty: .medium, correct: false, impact: -6),
            attempt(daysAgo: 2, difficulty: .hard, correct: false, impact: -1),
            attempt(daysAgo: 1, difficulty: .hard, correct: true, impact: 1)
        ]

        let insight = WhatToPlayStatsAnalyzer.difficultyImpactInsight(for: attempts)

        XCTAssertEqual(insight?.difficulty, .medium)
        XCTAssertEqual(insight?.averageExpectedImpact, -4)
        XCTAssertEqual(insight?.attempts, 2)
        XCTAssertEqual(insight?.title, "أكبر نزيف حسب الصعوبة".localized)
    }

    func testDifficultyImpactInsightReportsNoLeakWhenAveragesAreNonNegative() {
        let attempts = [
            attempt(daysAgo: 4, difficulty: .easy, correct: true, impact: 2),
            attempt(daysAgo: 3, difficulty: .easy, correct: false, impact: 0),
            attempt(daysAgo: 2, difficulty: .medium, correct: true, impact: 4),
            attempt(daysAgo: 1, difficulty: .medium, correct: false, impact: 0)
        ]

        let insight = WhatToPlayStatsAnalyzer.difficultyImpactInsight(for: attempts)

        XCTAssertEqual(insight?.difficulty, .easy)
        XCTAssertEqual(insight?.averageExpectedImpact, 1)
        XCTAssertEqual(insight?.title, "لا يوجد نزيف واضح".localized)
    }

    func testPerformanceTrendDetectsImprovement() {
        let attempts = [
            attempt(daysAgo: 6, correct: false, impact: -6),
            attempt(daysAgo: 5, correct: false, impact: -4),
            attempt(daysAgo: 4, correct: false, impact: -2),
            attempt(daysAgo: 3, correct: true, impact: 2),
            attempt(daysAgo: 2, correct: true, impact: 4),
            attempt(daysAgo: 1, correct: true, impact: 6)
        ]

        let trend = WhatToPlayStatsAnalyzer.performanceTrend(attempts: attempts, recentWindow: 3)

        XCTAssertEqual(trend?.direction, .improving)
        XCTAssertEqual(trend?.recentAccuracyPercent, 100)
        XCTAssertEqual(trend?.previousAccuracyPercent, 0)
    }

    func testPerformanceTrendDetectsDecline() {
        let attempts = [
            attempt(daysAgo: 6, correct: true, impact: 6),
            attempt(daysAgo: 5, correct: true, impact: 4),
            attempt(daysAgo: 4, correct: true, impact: 2),
            attempt(daysAgo: 3, correct: false, impact: -2),
            attempt(daysAgo: 2, correct: false, impact: -4),
            attempt(daysAgo: 1, correct: false, impact: -6)
        ]

        let trend = WhatToPlayStatsAnalyzer.performanceTrend(attempts: attempts, recentWindow: 3)

        XCTAssertEqual(trend?.direction, .declining)
        XCTAssertEqual(trend?.recentAccuracyPercent, 0)
        XCTAssertEqual(trend?.previousAccuracyPercent, 100)
    }

    func testPerformanceTrendDetectsStablePerformance() {
        let attempts = [
            attempt(daysAgo: 6, correct: true, impact: 2),
            attempt(daysAgo: 5, correct: false, impact: -2),
            attempt(daysAgo: 4, correct: true, impact: 2),
            attempt(daysAgo: 3, correct: true, impact: 2),
            attempt(daysAgo: 2, correct: false, impact: -2),
            attempt(daysAgo: 1, correct: true, impact: 2)
        ]

        let trend = WhatToPlayStatsAnalyzer.performanceTrend(attempts: attempts, recentWindow: 3)

        XCTAssertEqual(trend?.direction, .stable)
        XCTAssertEqual(trend?.recentAccuracyPercent, 67)
        XCTAssertEqual(trend?.previousAccuracyPercent, 67)
    }

    func testPerformanceTrendReturnsNilWithoutEnoughAttempts() {
        let attempts = [
            attempt(daysAgo: 3, correct: true, impact: 2),
            attempt(daysAgo: 2, correct: false, impact: -2),
            attempt(daysAgo: 1, correct: true, impact: 2)
        ]

        XCTAssertNil(WhatToPlayStatsAnalyzer.performanceTrend(attempts: attempts, recentWindow: 3))
    }

    func testPracticeRecommendationStartsEasyWithoutAttempts() {
        let recommendation = WhatToPlayStatsAnalyzer.practiceRecommendation(for: [])

        XCTAssertEqual(recommendation.difficulty, .easy)
        XCTAssertEqual(recommendation.title, "ابدأ من السهل".localized)
    }

    func testPracticeRecommendationUsesWeakFocusDifficulty() {
        let attempts = [
            attempt(daysAgo: 5, difficulty: .easy, correct: true, impact: 4),
            attempt(daysAgo: 4, difficulty: .easy, correct: true, impact: 4),
            attempt(daysAgo: 3, difficulty: .hard, correct: false, impact: -8),
            attempt(daysAgo: 2, difficulty: .hard, correct: false, impact: -6),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: 2)
        ]

        let recommendation = WhatToPlayStatsAnalyzer.practiceRecommendation(for: attempts)

        XCTAssertEqual(recommendation.difficulty, .hard)
        XCTAssertEqual(recommendation.title, "درّب نقطة الضعف".localized)
    }

    func testPracticeRecommendationRaisesChallengeAfterStrongStreak() {
        let attempts = [
            attempt(daysAgo: 4, difficulty: .easy, correct: true, impact: 4),
            attempt(daysAgo: 3, difficulty: .easy, correct: true, impact: 4),
            attempt(daysAgo: 2, difficulty: .easy, correct: true, impact: 4),
            attempt(daysAgo: 1, difficulty: .easy, correct: true, impact: 4)
        ]

        let recommendation = WhatToPlayStatsAnalyzer.practiceRecommendation(for: attempts)

        XCTAssertEqual(recommendation.difficulty, .medium)
        XCTAssertEqual(recommendation.title, "ارفع التحدي".localized)
    }

    func testPracticeRecommendationKeepsDifficultyWhenAverageLostValueIsHigh() {
        let attempts = [
            attempt(daysAgo: 4, difficulty: .medium, correct: false, impact: -8, bestImpact: 8),
            attempt(daysAgo: 3, difficulty: .medium, correct: true, impact: 4, bestImpact: 4),
            attempt(daysAgo: 2, difficulty: .medium, correct: true, impact: 4, bestImpact: 4),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: 4, bestImpact: 4)
        ]

        let recommendation = WhatToPlayStatsAnalyzer.practiceRecommendation(for: attempts)

        XCTAssertEqual(recommendation.difficulty, .medium)
        XCTAssertEqual(recommendation.title, "راجع القيمة قبل الصعوبة".localized)
    }

    func testPracticeRecommendationPrioritizesSimulationLoss() {
        let attempts = [
            attempt(daysAgo: 4, difficulty: .medium, correct: false, impact: 2, bestImpact: 4, projectedTeamPoints: 54, bestProjectedTeamPoints: 72),
            attempt(daysAgo: 3, difficulty: .medium, correct: true, impact: 3, bestImpact: 3, projectedTeamPoints: 70, bestProjectedTeamPoints: 70),
            attempt(daysAgo: 2, difficulty: .medium, correct: false, impact: 2, bestImpact: 4, projectedTeamPoints: 58, bestProjectedTeamPoints: 74),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: 3, bestImpact: 3, projectedTeamPoints: 76, bestProjectedTeamPoints: 76)
        ]

        let recommendation = WhatToPlayStatsAnalyzer.practiceRecommendation(for: attempts)

        XCTAssertEqual(recommendation.difficulty, .medium)
        XCTAssertEqual(recommendation.title, "قلّل القرارات المكلفة".localized)
        XCTAssertEqual(recommendation.iconName, "exclamationmark.triangle.fill")
    }

    func testPracticeRecommendationPrioritizesCostlyDecisionQuality() {
        let attempts = [
            attempt(daysAgo: 5, difficulty: .medium, correct: true, impact: 10, bestImpact: 10),
            attempt(daysAgo: 4, difficulty: .medium, correct: false, impact: -1, bestImpact: 10),
            attempt(daysAgo: 3, difficulty: .medium, correct: true, impact: 9, bestImpact: 10),
            attempt(daysAgo: 2, difficulty: .medium, correct: false, impact: -2, bestImpact: 10),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: 10, bestImpact: 10)
        ]

        let recommendation = WhatToPlayStatsAnalyzer.practiceRecommendation(for: attempts)

        XCTAssertEqual(recommendation.difficulty, .medium)
        XCTAssertEqual(recommendation.title, "قلّل القرارات المكلفة".localized)
        XCTAssertEqual(recommendation.iconName, "exclamationmark.triangle.fill")
    }

    func testPracticeRecommendationRespondsToDecline() {
        let attempts = [
            attempt(daysAgo: 6, difficulty: .medium, correct: true, impact: 5),
            attempt(daysAgo: 5, difficulty: .medium, correct: true, impact: 4),
            attempt(daysAgo: 4, difficulty: .medium, correct: true, impact: 3),
            attempt(daysAgo: 3, difficulty: .medium, correct: false, impact: -1),
            attempt(daysAgo: 2, difficulty: .medium, correct: false, impact: -2),
            attempt(daysAgo: 1, difficulty: .medium, correct: false, impact: -3)
        ]

        let recommendation = WhatToPlayStatsAnalyzer.practiceRecommendation(for: attempts)

        XCTAssertEqual(recommendation.difficulty, .medium)
        XCTAssertEqual(recommendation.title, "ارجع خطوة تكتيكية".localized)
    }

    func testDecisionInsightRecognizesExpertMatch() {
        let insight = WhatToPlayStatsAnalyzer.decisionInsight(
            selectedRank: 1,
            selectedImpact: 8,
            bestImpact: 8,
            secondBestImpact: 6
        )

        XCTAssertEqual(insight.kind, .expertMatch)
        XCTAssertEqual(insight.lostExpectedPoints, 0)
        XCTAssertEqual(insight.lostProjectedTeamPoints, 0)
        XCTAssertEqual(insight.secondBestGap, 0)
        XCTAssertEqual(insight.valueLossSeverity, .none)
        XCTAssertEqual(insight.valueLossTitle, "لا توجد خسارة قيمة".localized)
        XCTAssertEqual(insight.title, "اختيار خبير".localized)
    }

    func testDecisionInsightRecognizesCloseAlternative() {
        let insight = WhatToPlayStatsAnalyzer.decisionInsight(
            selectedRank: 2,
            selectedImpact: 6,
            bestImpact: 8,
            secondBestImpact: 6
        )

        XCTAssertEqual(insight.kind, .closeAlternative)
        XCTAssertEqual(insight.lostExpectedPoints, 2)
        XCTAssertEqual(insight.lostProjectedTeamPoints, 0)
        XCTAssertEqual(insight.secondBestGap, 0)
        XCTAssertEqual(insight.valueLossSeverity, .low)
    }

    func testDecisionInsightPrioritizesProjectedLossWhenLarger() {
        let insight = WhatToPlayStatsAnalyzer.decisionInsight(
            selectedRank: 2,
            selectedImpact: 7,
            bestImpact: 8,
            secondBestImpact: 7,
            selectedProjectedTeamPoints: 52,
            bestProjectedTeamPoints: 68
        )

        XCTAssertEqual(insight.kind, .pointLeak)
        XCTAssertEqual(insight.title, "المحاكاة ترجّح المراجعة".localized)
        XCTAssertEqual(insight.lostExpectedPoints, 1)
        XCTAssertEqual(insight.lostProjectedTeamPoints, 16)
        XCTAssertEqual(insight.valueLossSeverity, .high)
        XCTAssertTrue(insight.detail.contains("نقاط محاكاة ضائعة".localized))
    }

    func testDecisionInsightPrioritizesSecondProjectedLossWhenLarger() {
        let insight = WhatToPlayStatsAnalyzer.decisionInsight(
            selectedRank: 2,
            selectedImpact: 7,
            bestImpact: 8,
            secondBestImpact: 7,
            selectedProjectedTeamPoints: 52,
            bestProjectedTeamPoints: 54,
            secondBestProjectedTeamPoints: 68
        )

        XCTAssertEqual(insight.kind, .pointLeak)
        XCTAssertEqual(insight.title, "المحاكاة ترجّح المراجعة".localized)
        XCTAssertEqual(insight.lostExpectedPoints, 1)
        XCTAssertEqual(insight.lostProjectedTeamPoints, 2)
        XCTAssertEqual(insight.lostProjectedAgainstSecondBestPoints, 16)
        XCTAssertEqual(insight.valueLossSeverity, .high)
        XCTAssertTrue(insight.detail.contains("فاقد ثاني محاكاة".localized))
    }

    func testDecisionInsightRecognizesMissedWinningChance() {
        let insight = WhatToPlayStatsAnalyzer.decisionInsight(
            selectedRank: 4,
            selectedImpact: -3,
            bestImpact: 7,
            secondBestImpact: 2
        )

        XCTAssertEqual(insight.kind, .missedWinningChance)
        XCTAssertEqual(insight.lostExpectedPoints, 10)
        XCTAssertEqual(insight.lostProjectedTeamPoints, 0)
        XCTAssertEqual(insight.secondBestGap, 5)
        XCTAssertEqual(insight.valueLossSeverity, .high)
    }

    func testDecisionInsightRecognizesPointLeak() {
        let insight = WhatToPlayStatsAnalyzer.decisionInsight(
            selectedRank: 3,
            selectedImpact: 1,
            bestImpact: 6,
            secondBestImpact: 4
        )

        XCTAssertEqual(insight.kind, .pointLeak)
        XCTAssertEqual(insight.lostExpectedPoints, 5)
        XCTAssertEqual(insight.lostProjectedTeamPoints, 0)
        XCTAssertEqual(insight.secondBestGap, 3)
        XCTAssertEqual(insight.valueLossSeverity, .medium)
    }

    func testValueLossSeverityUsesStableThresholds() {
        XCTAssertEqual(WhatToPlayStatsAnalyzer.valueLossSeverity(for: 0), .none)
        XCTAssertEqual(WhatToPlayStatsAnalyzer.valueLossSeverity(for: 2), .low)
        XCTAssertEqual(WhatToPlayStatsAnalyzer.valueLossSeverity(for: 3), .medium)
        XCTAssertEqual(WhatToPlayStatsAnalyzer.valueLossSeverity(for: 5), .medium)
        XCTAssertEqual(WhatToPlayStatsAnalyzer.valueLossSeverity(for: 6), .high)
    }

    func testValueLossSeverityUsesSecondProjectedLossWhenLarger() {
        let severity = WhatToPlayStatsAnalyzer.valueLossSeverity(
            lostExpectedPoints: 1,
            lostProjectedTeamPoints: 2,
            lostProjectedAgainstSecondBestPoints: 9
        )

        XCTAssertEqual(severity, .high)
    }

    func testDecisionInsightKeepsSecondBestGapNilWhenUnavailable() {
        let insight = WhatToPlayStatsAnalyzer.decisionInsight(
            selectedRank: 3,
            selectedImpact: 1,
            bestImpact: 6,
            secondBestImpact: nil
        )

        XCTAssertNil(insight.secondBestGap)
    }

    func testDecisionReviewUsesScenarioFocusAndDecisionKind() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let selected = try XCTUnwrap(scenario.options.last { tacticalReasonTitle(for: $0.impactBreakdown) == nil })

        let review = try XCTUnwrap(WhatToPlayStatsAnalyzer.decisionReview(for: selected, in: scenario))

        XCTAssertEqual(review.title, "راجع القرار بهذه الطريقة".localized)
        XCTAssertEqual(review.steps.count, 3)
        XCTAssertEqual(review.steps.first, expectedFirstReviewStep(for: scenario.context.focusKind))
        XCTAssertEqual(review.steps.last, "أعد الموقف إذا كان الفارق أكثر من نقطتين متوقعتين.".localized)
    }

    func testDecisionReviewIncludesTacticalReasonForLeakingChoice() throws {
        let (scenario, selected) = try scenarioWithTacticalLeakingChoice()

        let review = try XCTUnwrap(WhatToPlayStatsAnalyzer.decisionReview(for: selected, in: scenario))
        let tacticalStep = try XCTUnwrap(review.steps.last)

        XCTAssertEqual(review.steps.count, 4)
        XCTAssertTrue(tacticalStep.contains("سبب تكتيكي".localized))
        XCTAssertTrue(tacticalStep.contains(expectedTacticalReasonTitle(for: selected.impactBreakdown)))
    }

    func testDecisionReviewUsesMissedWinningChanceRemedy() throws {
        let insight = WhatToPlayStatsAnalyzer.decisionInsight(
            selectedRank: 3,
            selectedImpact: -3,
            bestImpact: 7,
            secondBestImpact: 2
        )

        let review = WhatToPlayStatsAnalyzer.decisionReview(insight: insight, focusKind: .followSuit)

        XCTAssertEqual(review.steps.first, expectedFirstReviewStep(for: .followSuit))
        XCTAssertTrue(review.steps.contains("ابحث عن الورقة التي كانت ستحوّل الأكلة من خسارة إلى ربح.".localized))
    }

    func testNextDecisionActionReinforcesExpertMatchByFocus() {
        let insight = WhatToPlayStatsAnalyzer.decisionInsight(
            selectedRank: 1,
            selectedImpact: 8,
            bestImpact: 8,
            secondBestImpact: 5
        )
        let bestCard = PlayingCard(suit: .spades, rank: .ace)

        let action = WhatToPlayStatsAnalyzer.nextDecisionAction(
            insight: insight,
            focusKind: .trumpPressure,
            bestCard: bestCard
        )

        XCTAssertEqual(action.title, "ثبّت القراءة".localized)
        XCTAssertTrue(action.detail.contains("الحكم".localized))
        XCTAssertEqual(action.recommendedCard, bestCard)
        XCTAssertEqual(action.expectedImprovement, 0)
    }

    func testExpertMatchInsightKeepsLargeProjectedSimulationLoss() {
        let insight = WhatToPlayStatsAnalyzer.decisionInsight(
            selectedRank: 1,
            selectedImpact: 8,
            bestImpact: 8,
            secondBestImpact: 7,
            selectedProjectedTeamPoints: 52,
            bestProjectedTeamPoints: 68
        )

        let action = WhatToPlayStatsAnalyzer.nextDecisionAction(
            insight: insight,
            focusKind: .trumpPressure,
            bestCard: PlayingCard(suit: .spades, rank: .ace)
        )

        XCTAssertEqual(insight.kind, .expertMatch)
        XCTAssertEqual(insight.lostExpectedPoints, 0)
        XCTAssertEqual(insight.lostProjectedTeamPoints, 16)
        XCTAssertEqual(insight.valueLossSeverity, .high)
        XCTAssertTrue(insight.detail.contains("محاكاة".localized))
        XCTAssertEqual(action.title, "راجع المحاكاة".localized)
        XCTAssertTrue(action.detail.contains("نقاط محاكاة ضائعة".localized))
        XCTAssertEqual(action.expectedImprovement, 16)
    }

    func testScenarioDecisionActionRecommendsBestSimulationCardWhenExpertPickLeaksRoundValue() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 1, difficulty: .hard)
        let expert = try XCTUnwrap(scenario.bestOption)
        let bestSimulation = try XCTUnwrap(WhatToPlayTrainer.bestProjectedOption(in: scenario.options))
        XCTAssertNotEqual(bestSimulation.card, expert.card)
        XCTAssertGreaterThanOrEqual(max(0, bestSimulation.projectedTeamPoints - expert.projectedTeamPoints), 9)

        let insight = try XCTUnwrap(WhatToPlayStatsAnalyzer.decisionInsight(for: expert, in: scenario))
        let action = try XCTUnwrap(WhatToPlayStatsAnalyzer.nextDecisionAction(for: expert, in: scenario))

        XCTAssertEqual(insight.kind, .expertMatch)
        XCTAssertEqual(insight.lostProjectedTeamPoints, max(0, bestSimulation.projectedTeamPoints - expert.projectedTeamPoints))
        XCTAssertEqual(action.title, "راجع المحاكاة".localized)
        XCTAssertEqual(action.recommendedCard, bestSimulation.card)
        XCTAssertEqual(action.expectedImprovement, insight.lostProjectedTeamPoints)
    }

    func testNextDecisionActionTargetsMissedWinningChance() {
        let insight = WhatToPlayStatsAnalyzer.decisionInsight(
            selectedRank: 4,
            selectedImpact: -3,
            bestImpact: 7,
            secondBestImpact: 2
        )

        let action = WhatToPlayStatsAnalyzer.nextDecisionAction(
            insight: insight,
            focusKind: .followSuit,
            bestCard: PlayingCard(suit: .hearts, rank: .king)
        )

        XCTAssertEqual(action.title, "ابحث عن الورقة الرابحة".localized)
        XCTAssertTrue(action.detail.contains("تنقل الأكلة لفريقك".localized))
        XCTAssertEqual(action.expectedImprovement, insight.lostExpectedPoints)
    }

    func testNextDecisionActionKeepsSmallCloseAlternativeCoaching() {
        let insight = WhatToPlayStatsAnalyzer.decisionInsight(
            selectedRank: 2,
            selectedImpact: 6,
            bestImpact: 8,
            secondBestImpact: 6
        )

        let action = WhatToPlayStatsAnalyzer.nextDecisionAction(
            insight: insight,
            focusKind: .narrowChoice,
            bestCard: PlayingCard(suit: .diamonds, rank: .ace)
        )

        XCTAssertEqual(action.title, "درّب الفارق الصغير".localized)
        XCTAssertTrue(action.detail.contains("نقطة أو نقطتين"))
        XCTAssertEqual(action.expectedImprovement, 2)
    }

    func testNextDecisionActionUsesProjectedLossWhenItIsLarger() {
        let insight = WhatToPlayStatsAnalyzer.decisionInsight(
            selectedRank: 2,
            selectedImpact: 7,
            bestImpact: 8,
            secondBestImpact: 7,
            selectedProjectedTeamPoints: 52,
            bestProjectedTeamPoints: 68
        )

        let action = WhatToPlayStatsAnalyzer.nextDecisionAction(
            insight: insight,
            focusKind: .narrowChoice,
            bestCard: PlayingCard(suit: .diamonds, rank: .ace)
        )

        XCTAssertEqual(action.title, "راجع أثر الجولة".localized)
        XCTAssertTrue(action.detail.contains("خسر بعد استكمال الجولة".localized))
        XCTAssertTrue(action.detail.contains("\("نقاط محاكاة ضائعة".localized): 16"))
        XCTAssertEqual(action.expectedImprovement, 16)
    }

    func testNextDecisionActionNamesSecondSimulationLossWhenItIsLarger() {
        let insight = WhatToPlayStatsAnalyzer.decisionInsight(
            selectedRank: 2,
            selectedImpact: 7,
            bestImpact: 8,
            secondBestImpact: 7,
            selectedProjectedTeamPoints: 52,
            bestProjectedTeamPoints: 54,
            secondBestProjectedTeamPoints: 68
        )

        let action = WhatToPlayStatsAnalyzer.nextDecisionAction(
            insight: insight,
            focusKind: .narrowChoice,
            bestCard: PlayingCard(suit: .diamonds, rank: .ace)
        )

        XCTAssertEqual(action.title, "راجع أثر الجولة".localized)
        XCTAssertTrue(action.detail.contains("خسر بعد استكمال الجولة".localized))
        XCTAssertTrue(action.detail.contains("\("فاقد ثاني محاكاة".localized): 16"))
        XCTAssertFalse(action.detail.contains("\("نقاط محاكاة ضائعة".localized): 2"))
        XCTAssertEqual(action.expectedImprovement, 16)
    }

    func testNextDecisionActionDoesNotCallLargeSecondBestGapSmall() {
        let insight = WhatToPlayStatsAnalyzer.decisionInsight(
            selectedRank: 2,
            selectedImpact: 1,
            bestImpact: 8,
            secondBestImpact: 1
        )

        let action = WhatToPlayStatsAnalyzer.nextDecisionAction(
            insight: insight,
            focusKind: .narrowChoice,
            bestCard: PlayingCard(suit: .diamonds, rank: .ace)
        )

        XCTAssertEqual(action.title, "راجع القيمة الضائعة".localized)
        XCTAssertTrue(action.detail.contains("\("الفارق عن اختيار الخبير".localized): 7"))
        XCTAssertFalse(action.detail.contains("نقطة أو نقطتين"))
        XCTAssertEqual(action.expectedImprovement, 7)
    }

    func testRetryPromptIsNilForExpertMatch() throws {
        let insight = WhatToPlayStatsAnalyzer.decisionInsight(
            selectedRank: 1,
            selectedImpact: 8,
            bestImpact: 8,
            secondBestImpact: 6
        )

        let prompt = WhatToPlayStatsAnalyzer.retryPrompt(insight: insight)

        XCTAssertNil(prompt)
    }

    func testRetryPromptExplainsUncountedRetryForLargeMiss() {
        let insight = WhatToPlayStatsAnalyzer.decisionInsight(
            selectedRank: 4,
            selectedImpact: -3,
            bestImpact: 7,
            secondBestImpact: 2
        )

        let prompt = WhatToPlayStatsAnalyzer.retryPrompt(insight: insight)

        XCTAssertEqual(prompt?.title, "أعد نفس الموقف".localized)
        XCTAssertTrue(prompt?.detail.contains("لن تُحسب الإعادة".localized) == true)
        XCTAssertEqual(prompt?.iconName, "arrow.counterclockwise.circle.fill")
        XCTAssertNil(prompt?.recommendedCard)
        XCTAssertEqual(prompt?.expectedImprovement, 10)
    }

    func testRetryPromptExplainsSmallGapPractice() {
        let insight = WhatToPlayStatsAnalyzer.decisionInsight(
            selectedRank: 2,
            selectedImpact: 6,
            bestImpact: 8,
            secondBestImpact: 6
        )

        let prompt = WhatToPlayStatsAnalyzer.retryPrompt(insight: insight)

        XCTAssertEqual(prompt?.title, "أعد نفس الموقف".localized)
        XCTAssertTrue(prompt?.detail.contains("الفرق بسيط".localized) == true)
        XCTAssertEqual(prompt?.expectedImprovement, 2)
    }

    func testRetryPromptUsesProjectedLossWhenItIsLarger() {
        let insight = WhatToPlayStatsAnalyzer.decisionInsight(
            selectedRank: 2,
            selectedImpact: 7,
            bestImpact: 8,
            secondBestImpact: 7,
            selectedProjectedTeamPoints: 52,
            bestProjectedTeamPoints: 68
        )

        let prompt = WhatToPlayStatsAnalyzer.retryPrompt(insight: insight)

        XCTAssertEqual(prompt?.title, "أعد نفس الموقف".localized)
        XCTAssertTrue(prompt?.detail.contains("لن تُحسب الإعادة".localized) == true)
        XCTAssertFalse(prompt?.detail.contains("الفرق بسيط".localized) == true)
        XCTAssertEqual(prompt?.expectedImprovement, 16)
    }

    func testRetryPromptUsesSecondProjectedLossWhenItIsLarger() {
        let insight = WhatToPlayStatsAnalyzer.decisionInsight(
            selectedRank: 2,
            selectedImpact: 7,
            bestImpact: 8,
            secondBestImpact: 7,
            selectedProjectedTeamPoints: 52,
            bestProjectedTeamPoints: 54,
            secondBestProjectedTeamPoints: 68
        )

        let prompt = WhatToPlayStatsAnalyzer.retryPrompt(insight: insight)

        XCTAssertEqual(prompt?.title, "أعد نفس الموقف".localized)
        XCTAssertTrue(prompt?.detail.contains("لن تُحسب الإعادة".localized) == true)
        XCTAssertTrue(prompt?.detail.contains("فاقد ثاني محاكاة".localized) == true)
        XCTAssertEqual(prompt?.expectedImprovement, 16)
    }

    func testRetryPromptForScenarioCarriesBestCardAndExpectedImprovement() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)
        let best = try XCTUnwrap(scenario.bestOption)
        let bestSimulation = try XCTUnwrap(WhatToPlayTrainer.bestProjectedOption(in: scenario.options))
        let selected = try XCTUnwrap(
            scenario.options.first {
                $0.card != best.card
                    && max(
                        max(0, best.expectedImpact - $0.expectedImpact),
                        max(0, bestSimulation.projectedTeamPoints - $0.projectedTeamPoints)
                    ) > 0
            }
        )

        let prompt = try XCTUnwrap(WhatToPlayStatsAnalyzer.retryPrompt(for: selected, in: scenario))
        let expectedLost = max(0, best.expectedImpact - selected.expectedImpact)
        let expectedProjectedLost = max(0, bestSimulation.projectedTeamPoints - selected.projectedTeamPoints)
        let expectedImprovement = max(expectedLost, expectedProjectedLost)

        XCTAssertEqual(prompt.recommendedCard, expectedProjectedLost > expectedLost ? bestSimulation.card : best.card)
        XCTAssertEqual(prompt.expectedImprovement, expectedImprovement)
    }

    func testReplayContextExplainsExpertChoice() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let selected = try XCTUnwrap(scenario.bestOption)
        let bestSimulation = try XCTUnwrap(WhatToPlayTrainer.bestProjectedOption(in: scenario.options))
        let secondBestSimulation = try XCTUnwrap(WhatToPlayTrainer.secondBestProjectedOption(in: scenario.options))

        let context = WhatToPlayStatsAnalyzer.replayContext(for: selected, in: scenario)
        let expectedLoss = max(0, bestSimulation.projectedTeamPoints - selected.projectedTeamPoints)
        let expectedSecondLoss = max(0, secondBestSimulation.projectedTeamPoints - selected.projectedTeamPoints)

        XCTAssertTrue(context.isExpertChoice)
        XCTAssertEqual(context.lostProjectedTeamPoints, expectedLoss)
        XCTAssertEqual(context.lostProjectedAgainstSecondBestPoints, expectedSecondLoss)
        XCTAssertTrue(context.text.contains("\("الورقة".localized): \(selected.card.accessibilityName)"))
        XCTAssertTrue(context.text.contains("\("نقاط فريقك بعد المحاكاة".localized): \(selected.projectedTeamPoints)") && context.text.contains(expectedLoss == 0 ? "اختيار الخبير".localized : "\("نقاط محاكاة ضائعة".localized): \(expectedLoss)"))
    }

    func testReplayContextExplainsProjectedLoss() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)
        let selected = try XCTUnwrap(scenario.options.last)
        let bestSimulation = try XCTUnwrap(WhatToPlayTrainer.bestProjectedOption(in: scenario.options))
        let secondBestSimulation = try XCTUnwrap(WhatToPlayTrainer.secondBestProjectedOption(in: scenario.options))

        let context = WhatToPlayStatsAnalyzer.replayContext(for: selected, in: scenario)

        XCTAssertFalse(context.isExpertChoice)
        XCTAssertEqual(context.lostProjectedTeamPoints, max(0, bestSimulation.projectedTeamPoints - selected.projectedTeamPoints))
        XCTAssertEqual(
            context.lostProjectedAgainstSecondBestPoints,
            max(0, secondBestSimulation.projectedTeamPoints - selected.projectedTeamPoints)
        )
        XCTAssertTrue(context.text.contains("\("نقاط محاكاة ضائعة".localized): \(context.lostProjectedTeamPoints)") && context.text.contains("\("الأثر المتوقع".localized): \(selected.expectedImpact >= 0 ? "+\(selected.expectedImpact)" : "\(selected.expectedImpact)")"))
    }

    func testScenarioBriefExplainsFollowSuitContext() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(
            seed: 2026,
            difficulty: .easy,
            preferredFocus: .followSuit
        )

        let brief = WhatToPlayStatsAnalyzer.scenarioBrief(for: scenario)

        XCTAssertEqual(brief.title, "التزم باللون المطلوب".localized)
        XCTAssertEqual(brief.iconName, "suit.club.fill")
        if let requiredSuit = scenario.context.requiredSuit {
            XCTAssertTrue(brief.detail.contains(requiredSuit.spokenName))
        }
    }

    func testScenarioBriefExplainsNarrowChoiceContext() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(
            seed: 2026,
            difficulty: .easy,
            preferredFocus: .narrowChoice
        )

        let brief = WhatToPlayStatsAnalyzer.scenarioBrief(for: scenario)

        XCTAssertEqual(brief.title, "خياراتك محدودة".localized)
        XCTAssertEqual(brief.iconName, "2.circle.fill")
        XCTAssertTrue(brief.detail.contains("\(scenario.context.legalOptionCount)"))
    }

    func testPreDecisionChecklistExplainsOpeningLead() {
        let context = WhatToPlayScenarioContext(
            trickNumber: 1,
            isLeading: true,
            requiredSuit: nil,
            playedCardCount: 0,
            legalOptionCount: 5,
            mode: .sun,
            trumpSuit: nil,
            hasTrumpInCurrentTrick: false,
            focusKind: .openingLead
        )

        let checklist = WhatToPlayStatsAnalyzer.preDecisionChecklist(context: context)

        XCTAssertEqual(checklist.title, "افحص قبل اللعب".localized)
        XCTAssertEqual(checklist.iconName, "checklist")
        XCTAssertEqual(checklist.items.count, 4)
        XCTAssertTrue(checklist.items[0].contains("تبدأ الأكلة".localized))
        XCTAssertTrue(checklist.items[1].contains("صن".localized))
    }

    func testPreDecisionChecklistExplainsRequiredSuitAndTrumpPressure() {
        let context = WhatToPlayScenarioContext(
            trickNumber: 4,
            isLeading: false,
            requiredSuit: .clubs,
            playedCardCount: 2,
            legalOptionCount: 3,
            mode: .hokum,
            trumpSuit: .hearts,
            hasTrumpInCurrentTrick: true,
            focusKind: .trumpPressure
        )

        let checklist = WhatToPlayStatsAnalyzer.preDecisionChecklist(context: context)

        XCTAssertEqual(checklist.items.count, 4)
        XCTAssertTrue(checklist.items[0].contains(Suit.clubs.spokenName))
        XCTAssertTrue(checklist.items[1].contains(Suit.hearts.spokenName))
        XCTAssertTrue(checklist.items[1].contains("الحكم موجود على الطاولة".localized))
        XCTAssertTrue(checklist.items[2].contains("2"))
    }

    func testPreDecisionChecklistCallsOutNarrowChoices() {
        let context = WhatToPlayScenarioContext(
            trickNumber: 5,
            isLeading: false,
            requiredSuit: .spades,
            playedCardCount: 3,
            legalOptionCount: 2,
            mode: .sun,
            trumpSuit: nil,
            hasTrumpInCurrentTrick: false,
            focusKind: .narrowChoice
        )

        let checklist = WhatToPlayStatsAnalyzer.preDecisionChecklist(context: context)

        XCTAssertTrue(checklist.items.last?.contains("خياراتك قليلة".localized) == true)
    }

    func testMasteryStartsAtZeroWithoutAttempts() {
        let mastery = WhatToPlayStatsAnalyzer.mastery(for: [])

        XCTAssertEqual(mastery.level, .starting)
        XCTAssertEqual(mastery.score, 0)
        XCTAssertEqual(mastery.title, "بداية التدريب".localized)
    }

    func testMasteryDetectsBuildingLevel() {
        let attempts = [
            attempt(daysAgo: 4, correct: true, impact: 0),
            attempt(daysAgo: 3, correct: false, impact: 0),
            attempt(daysAgo: 2, correct: false, impact: 0),
            attempt(daysAgo: 1, correct: true, impact: 0)
        ]

        let mastery = WhatToPlayStatsAnalyzer.mastery(for: attempts)

        XCTAssertEqual(mastery.level, .building)
        XCTAssertEqual(mastery.score, 44)
    }

    func testMasteryDetectsConfidentLevel() {
        let attempts = [
            attempt(daysAgo: 4, correct: true, impact: 0),
            attempt(daysAgo: 3, correct: false, impact: 0),
            attempt(daysAgo: 2, correct: true, impact: 0),
            attempt(daysAgo: 1, correct: true, impact: 0)
        ]

        let mastery = WhatToPlayStatsAnalyzer.mastery(for: attempts)

        XCTAssertEqual(mastery.level, .confident)
        XCTAssertEqual(mastery.score, 63)
    }

    func testMasteryDetectsSharpLevel() {
        let attempts = [
            attempt(daysAgo: 5, correct: true, impact: 10),
            attempt(daysAgo: 4, correct: true, impact: 10),
            attempt(daysAgo: 3, correct: true, impact: 10),
            attempt(daysAgo: 2, correct: true, impact: 10),
            attempt(daysAgo: 1, correct: true, impact: 10)
        ]

        let mastery = WhatToPlayStatsAnalyzer.mastery(for: attempts)

        XCTAssertEqual(mastery.level, .sharp)
        XCTAssertEqual(mastery.score, 100)
    }

    func testMasteryMilestoneTargetsBuildingFromStartingScore() {
        let attempts = [
            attempt(daysAgo: 2, correct: false, impact: -10),
            attempt(daysAgo: 1, correct: false, impact: -10)
        ]

        let milestone = WhatToPlayStatsAnalyzer.masteryMilestone(for: attempts)

        XCTAssertEqual(milestone?.targetScore, 35)
        XCTAssertEqual(milestone?.targetTitle, "تبني القراءة".localized)
        XCTAssertEqual(milestone?.pointsRemaining, 35)
    }

    func testMasteryMilestoneTargetsConfidentFromBuildingScore() {
        let attempts = [
            attempt(daysAgo: 4, correct: true, impact: 0),
            attempt(daysAgo: 3, correct: false, impact: 0),
            attempt(daysAgo: 2, correct: false, impact: 0),
            attempt(daysAgo: 1, correct: true, impact: 0)
        ]

        let milestone = WhatToPlayStatsAnalyzer.masteryMilestone(for: attempts)

        XCTAssertEqual(milestone?.targetScore, 60)
        XCTAssertEqual(milestone?.targetTitle, "متمكن".localized)
        XCTAssertEqual(milestone?.pointsRemaining, 16)
    }

    func testMasteryMilestoneReturnsNilAfterSharpLevel() {
        let attempts = [
            attempt(daysAgo: 5, correct: true, impact: 10),
            attempt(daysAgo: 4, correct: true, impact: 10),
            attempt(daysAgo: 3, correct: true, impact: 10),
            attempt(daysAgo: 2, correct: true, impact: 10),
            attempt(daysAgo: 1, correct: true, impact: 10)
        ]

        XCTAssertNil(WhatToPlayStatsAnalyzer.masteryMilestone(for: attempts))
    }

    func testPracticeCoverageReportsMissingDifficulties() {
        let attempts = [
            attempt(daysAgo: 2, difficulty: .easy, correct: true, impact: 2),
            attempt(daysAgo: 1, difficulty: .easy, correct: false, impact: -2)
        ]

        let coverage = WhatToPlayStatsAnalyzer.practiceCoverage(for: attempts)

        XCTAssertFalse(coverage.isBalanced)
        XCTAssertEqual(coverage.sampledDifficulties, 1)
        XCTAssertEqual(coverage.totalDifficulties, 4)
        XCTAssertEqual(coverage.missingDifficulties, [.medium, .hard, .expert])
        XCTAssertEqual(coverage.title, "أكمل تغطية التدريب".localized)
    }

    func testPracticeCoverageRequiresMinimumAttemptsPerDifficulty() {
        let attempts = [
            attempt(daysAgo: 5, difficulty: .easy, correct: true, impact: 2),
            attempt(daysAgo: 4, difficulty: .easy, correct: true, impact: 2),
            attempt(daysAgo: 3, difficulty: .medium, correct: true, impact: 2),
            attempt(daysAgo: 2, difficulty: .hard, correct: true, impact: 2),
            attempt(daysAgo: 1, difficulty: .expert, correct: true, impact: 2)
        ]

        let coverage = WhatToPlayStatsAnalyzer.practiceCoverage(for: attempts)

        XCTAssertFalse(coverage.isBalanced)
        XCTAssertEqual(coverage.sampledDifficulties, 1)
        XCTAssertEqual(coverage.missingDifficulties, [.medium, .hard, .expert])
    }

    func testPracticeCoverageReportsBalancedCoverage() {
        let attempts = [
            attempt(daysAgo: 8, difficulty: .easy, correct: true, impact: 2),
            attempt(daysAgo: 7, difficulty: .easy, correct: false, impact: -2),
            attempt(daysAgo: 6, difficulty: .medium, correct: true, impact: 2),
            attempt(daysAgo: 5, difficulty: .medium, correct: false, impact: -2),
            attempt(daysAgo: 4, difficulty: .hard, correct: true, impact: 2),
            attempt(daysAgo: 3, difficulty: .hard, correct: false, impact: -2)
        ] + expertCoverageAttempts()

        let coverage = WhatToPlayStatsAnalyzer.practiceCoverage(for: attempts)

        XCTAssertTrue(coverage.isBalanced)
        XCTAssertEqual(coverage.sampledDifficulties, 4)
        XCTAssertTrue(coverage.missingDifficulties.isEmpty)
        XCTAssertEqual(coverage.title, "تغطية متوازنة".localized)
    }

    func testScenarioFocusCoverageReportsMissingFocusKinds() {
        let attempts = [
            attempt(daysAgo: 3, difficulty: .easy, correct: true, impact: 2, focusKind: .openingLead),
            attempt(daysAgo: 2, difficulty: .easy, correct: false, impact: -2, focusKind: .openingLead),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: 1, focusKind: .trumpPressure)
        ]

        let coverage = WhatToPlayStatsAnalyzer.scenarioFocusCoverage(for: attempts)

        XCTAssertFalse(coverage.isBalanced)
        XCTAssertEqual(coverage.sampledFocusKinds, 1)
        XCTAssertEqual(coverage.totalFocusKinds, 4)
        XCTAssertEqual(coverage.missingFocusKinds, [.followSuit, .trumpPressure, .narrowChoice])
        XCTAssertEqual(coverage.title, "أكمل أنواع المواقف".localized)
    }

    func testScenarioFocusCoverageReportsBalancedCoverage() {
        let attempts = [
            attempt(daysAgo: 8, difficulty: .easy, correct: true, impact: 2, focusKind: .openingLead),
            attempt(daysAgo: 7, difficulty: .easy, correct: false, impact: -2, focusKind: .openingLead),
            attempt(daysAgo: 6, difficulty: .medium, correct: true, impact: 2, focusKind: .followSuit),
            attempt(daysAgo: 5, difficulty: .medium, correct: false, impact: -2, focusKind: .followSuit),
            attempt(daysAgo: 4, difficulty: .hard, correct: true, impact: 2, focusKind: .trumpPressure),
            attempt(daysAgo: 3, difficulty: .hard, correct: false, impact: -2, focusKind: .trumpPressure),
            attempt(daysAgo: 2, difficulty: .easy, correct: true, impact: 2, focusKind: .narrowChoice),
            attempt(daysAgo: 1, difficulty: .easy, correct: false, impact: -2, focusKind: .narrowChoice)
        ]

        let coverage = WhatToPlayStatsAnalyzer.scenarioFocusCoverage(for: attempts)

        XCTAssertTrue(coverage.isBalanced)
        XCTAssertEqual(coverage.sampledFocusKinds, 4)
        XCTAssertTrue(coverage.missingFocusKinds.isEmpty)
        XCTAssertEqual(coverage.title, "تغطية مواقف متوازنة".localized)
    }

    func testGameModeCoverageReportsMissingModes() {
        let attempts = [
            attempt(daysAgo: 2, correct: true, impact: 2, gameMode: .sun),
            attempt(daysAgo: 1, correct: false, impact: -2, gameMode: .sun)
        ]

        let coverage = WhatToPlayStatsAnalyzer.gameModeCoverage(for: attempts)

        XCTAssertFalse(coverage.isBalanced)
        XCTAssertEqual(coverage.sampledModes, 1)
        XCTAssertEqual(coverage.totalModes, 2)
        XCTAssertEqual(coverage.missingModes, [.hokum])
        XCTAssertEqual(coverage.title, "وازن تدريب الصن والحكم".localized)
    }

    func testGameModeCoverageReportsBalancedModes() {
        let attempts = [
            attempt(daysAgo: 4, correct: true, impact: 2, gameMode: .sun),
            attempt(daysAgo: 3, correct: false, impact: -2, gameMode: .sun),
            attempt(daysAgo: 2, correct: true, impact: 2, gameMode: .hokum),
            attempt(daysAgo: 1, correct: false, impact: -2, gameMode: .hokum)
        ]

        let coverage = WhatToPlayStatsAnalyzer.gameModeCoverage(for: attempts)

        XCTAssertTrue(coverage.isBalanced)
        XCTAssertEqual(coverage.sampledModes, 2)
        XCTAssertTrue(coverage.missingModes.isEmpty)
        XCTAssertEqual(coverage.title, "تغطية الصن والحكم متوازنة".localized)
    }

    func testTrumpSuitCoverageReportsMissingHokumSuitsOnly() {
        let attempts = [
            attempt(daysAgo: 6, correct: true, impact: 2, gameMode: .sun, scenarioContext: hokumContext(trumpSuit: .hearts)),
            attempt(daysAgo: 5, correct: true, impact: 2, gameMode: .hokum, scenarioContext: hokumContext(trumpSuit: .hearts)),
            attempt(daysAgo: 4, correct: false, impact: -2, gameMode: .hokum, scenarioContext: hokumContext(trumpSuit: .hearts)),
            attempt(daysAgo: 3, correct: true, impact: 2, gameMode: .hokum, scenarioContext: hokumContext(trumpSuit: .clubs))
        ]

        let coverage = WhatToPlayStatsAnalyzer.trumpSuitCoverage(for: attempts)

        XCTAssertFalse(coverage.isBalanced)
        XCTAssertEqual(coverage.sampledSuits, 1)
        XCTAssertEqual(coverage.totalSuits, 4)
        XCTAssertEqual(coverage.missingSuits, [.diamonds, .clubs, .spades])
        XCTAssertEqual(coverage.title, "وازن ألوان الحكم".localized)
    }

    func testTrumpSuitCoverageReportsBalancedSuits() {
        let attempts = [
            attempt(daysAgo: 8, correct: true, impact: 2, gameMode: .hokum, scenarioContext: hokumContext(trumpSuit: .hearts)),
            attempt(daysAgo: 7, correct: false, impact: -2, gameMode: .hokum, scenarioContext: hokumContext(trumpSuit: .hearts)),
            attempt(daysAgo: 6, correct: true, impact: 2, gameMode: .hokum, scenarioContext: hokumContext(trumpSuit: .diamonds)),
            attempt(daysAgo: 5, correct: false, impact: -2, gameMode: .hokum, scenarioContext: hokumContext(trumpSuit: .diamonds)),
            attempt(daysAgo: 4, correct: true, impact: 2, gameMode: .hokum, scenarioContext: hokumContext(trumpSuit: .clubs)),
            attempt(daysAgo: 3, correct: false, impact: -2, gameMode: .hokum, scenarioContext: hokumContext(trumpSuit: .clubs)),
            attempt(daysAgo: 2, correct: true, impact: 2, gameMode: .hokum, scenarioContext: hokumContext(trumpSuit: .spades)),
            attempt(daysAgo: 1, correct: false, impact: -2, gameMode: .hokum, scenarioContext: hokumContext(trumpSuit: .spades))
        ]

        let coverage = WhatToPlayStatsAnalyzer.trumpSuitCoverage(for: attempts)

        XCTAssertTrue(coverage.isBalanced)
        XCTAssertEqual(coverage.sampledSuits, 4)
        XCTAssertTrue(coverage.missingSuits.isEmpty)
        XCTAssertEqual(coverage.title, "تغطية ألوان الحكم متوازنة".localized)
    }

    func testFocusTrainingPriorityUsesLargestLostPointsByFocus() {
        let attempts = [
            attempt(daysAgo: 6, correct: false, impact: -1, bestImpact: 1, focusKind: .openingLead),
            attempt(daysAgo: 5, correct: true, impact: 1, bestImpact: 1, focusKind: .openingLead),
            attempt(daysAgo: 4, correct: false, impact: -8, bestImpact: 4, focusKind: .trumpPressure),
            attempt(daysAgo: 3, correct: true, impact: 2, bestImpact: 2, focusKind: .trumpPressure),
            attempt(daysAgo: 2, correct: false, impact: -3, bestImpact: 2, focusKind: .followSuit),
            attempt(daysAgo: 1, correct: true, impact: 2, bestImpact: 2, focusKind: .followSuit)
        ]

        let priority = WhatToPlayStatsAnalyzer.focusTrainingPriority(for: attempts)

        XCTAssertEqual(priority?.focusKind, .trumpPressure)
        XCTAssertEqual(priority?.summary.lostExpectedPoints, 12)
        XCTAssertEqual(priority?.title, "\("أولوية التدريب".localized): \("ضغط الحكم".localized)")
        XCTAssertEqual(priority?.iconName, "crown.fill")
    }

    func testFocusTrainingPriorityUsesWorstAccuracyWhenLostPointsTie() {
        let attempts = [
            attempt(daysAgo: 6, correct: false, impact: -1, bestImpact: 3, focusKind: .openingLead),
            attempt(daysAgo: 5, correct: true, impact: 1, bestImpact: 1, focusKind: .openingLead),
            attempt(daysAgo: 4, correct: false, impact: -2, bestImpact: 2, focusKind: .followSuit),
            attempt(daysAgo: 3, correct: false, impact: 0, bestImpact: 0, focusKind: .followSuit)
        ]

        let priority = WhatToPlayStatsAnalyzer.focusTrainingPriority(for: attempts)

        XCTAssertEqual(priority?.focusKind, .followSuit)
        XCTAssertEqual(priority?.summary.lostExpectedPoints, 4)
        XCTAssertEqual(priority?.summary.accuracyPercent, 0)
    }

    func testFocusTrainingPriorityUsesProjectedLossWhenExpectedLossTies() {
        let attempts = [
            attempt(daysAgo: 6, correct: false, impact: 1, bestImpact: 5, focusKind: .openingLead, projectedTeamPoints: 72, bestProjectedTeamPoints: 74),
            attempt(daysAgo: 5, correct: true, impact: 3, bestImpact: 3, focusKind: .openingLead, projectedTeamPoints: 80, bestProjectedTeamPoints: 80),
            attempt(daysAgo: 4, correct: false, impact: 1, bestImpact: 5, focusKind: .followSuit, projectedTeamPoints: 58, bestProjectedTeamPoints: 74),
            attempt(daysAgo: 3, correct: true, impact: 3, bestImpact: 3, focusKind: .followSuit, projectedTeamPoints: 78, bestProjectedTeamPoints: 78)
        ]

        let priority = WhatToPlayStatsAnalyzer.focusTrainingPriority(for: attempts)

        XCTAssertEqual(priority?.focusKind, .followSuit)
        XCTAssertEqual(priority?.summary.lostExpectedPoints, 4)
        XCTAssertEqual(priority?.summary.lostProjectedTeamPoints, 16)
        XCTAssertTrue(priority?.detail.contains("سبب الترشيح من المحاكاة".localized) ?? false)
    }

    func testFocusTrainingPriorityUsesSecondProjectedLossWhenExpectedLossTies() {
        let attempts = [
            attempt(daysAgo: 6, correct: false, impact: 1, bestImpact: 5, focusKind: .openingLead, projectedTeamPoints: 72, bestProjectedTeamPoints: 74, secondBestProjectedTeamPoints: 92),
            attempt(daysAgo: 5, correct: true, impact: 3, bestImpact: 3, focusKind: .openingLead, projectedTeamPoints: 80, bestProjectedTeamPoints: 80, secondBestProjectedTeamPoints: 80),
            attempt(daysAgo: 4, correct: false, impact: 1, bestImpact: 5, focusKind: .followSuit, projectedTeamPoints: 58, bestProjectedTeamPoints: 74, secondBestProjectedTeamPoints: 74),
            attempt(daysAgo: 3, correct: true, impact: 3, bestImpact: 3, focusKind: .followSuit, projectedTeamPoints: 78, bestProjectedTeamPoints: 78, secondBestProjectedTeamPoints: 78)
        ]

        let priority = WhatToPlayStatsAnalyzer.focusTrainingPriority(for: attempts)

        XCTAssertEqual(priority?.focusKind, .openingLead)
        XCTAssertEqual(priority?.summary.lostExpectedPoints, 4)
        XCTAssertEqual(priority?.summary.lostProjectedTeamPoints, 2)
        XCTAssertEqual(priority?.summary.lostProjectedAgainstSecondBestPoints, 20)
        XCTAssertTrue(priority?.detail.contains("فاقد ثاني محاكاة".localized) ?? false)
    }

    func testFocusTrainingPriorityWaitsForEnoughAttemptsPerFocus() {
        let attempts = [
            attempt(daysAgo: 2, correct: false, impact: -10, bestImpact: 5, focusKind: .trumpPressure),
            attempt(daysAgo: 1, correct: true, impact: 2, bestImpact: 2, focusKind: .openingLead)
        ]

        XCTAssertNil(WhatToPlayStatsAnalyzer.focusTrainingPriority(for: attempts))
    }

    func testFocusTrainingPriorityReturnsNilWhenFocusedPerformanceIsPerfect() {
        let attempts = [
            attempt(daysAgo: 4, correct: true, impact: 2, bestImpact: 2, focusKind: .openingLead),
            attempt(daysAgo: 3, correct: true, impact: 3, bestImpact: 3, focusKind: .openingLead),
            attempt(daysAgo: 2, correct: true, impact: 2, bestImpact: 2, focusKind: .followSuit),
            attempt(daysAgo: 1, correct: true, impact: 3, bestImpact: 3, focusKind: .followSuit)
        ]

        XCTAssertNil(WhatToPlayStatsAnalyzer.focusTrainingPriority(for: attempts))
    }

    func testSessionPulseReportsNoData() {
        let pulse = WhatToPlayStatsAnalyzer.sessionPulse(for: [])

        XCTAssertEqual(pulse.state, .noData)
        XCTAssertEqual(pulse.inspectedAttempts, 0)
        XCTAssertEqual(pulse.title, "لا توجد جلسة بعد".localized)
    }

    func testSessionPulseReportsWarmingUpBeforeWindowIsReady() {
        let attempts = [
            attempt(daysAgo: 2, correct: true, impact: 2),
            attempt(daysAgo: 1, correct: false, impact: -2)
        ]

        let pulse = WhatToPlayStatsAnalyzer.sessionPulse(for: attempts, window: 3)

        XCTAssertEqual(pulse.state, .warmingUp)
        XCTAssertEqual(pulse.inspectedAttempts, 2)
        XCTAssertEqual(pulse.title, "بداية جلسة".localized)
    }

    func testSessionPulseReportsFocusedRecentWindow() {
        let attempts = [
            attempt(daysAgo: 4, correct: false, impact: -10),
            attempt(daysAgo: 3, correct: true, impact: 2),
            attempt(daysAgo: 2, correct: true, impact: 3),
            attempt(daysAgo: 1, correct: true, impact: 4)
        ]

        let pulse = WhatToPlayStatsAnalyzer.sessionPulse(for: attempts, window: 3)

        XCTAssertEqual(pulse.state, .focused)
        XCTAssertEqual(pulse.inspectedAttempts, 3)
        XCTAssertEqual(pulse.title, "جلسة مركزة".localized)
    }

    func testSessionPulseReportsReviewNeededForRecentMistakes() {
        let attempts = [
            attempt(daysAgo: 4, correct: true, impact: 5),
            attempt(daysAgo: 3, correct: false, impact: -2),
            attempt(daysAgo: 2, correct: false, impact: -4),
            attempt(daysAgo: 1, correct: true, impact: -6)
        ]

        let pulse = WhatToPlayStatsAnalyzer.sessionPulse(for: attempts, window: 3)

        XCTAssertEqual(pulse.state, .reviewNeeded)
        XCTAssertEqual(pulse.inspectedAttempts, 3)
        XCTAssertEqual(pulse.title, "توقف للمراجعة".localized)
    }

    func testMicroDrillStartsWithBaselinePlanWithoutAttempts() {
        let drill = WhatToPlayStatsAnalyzer.microDrill(for: [])

        XCTAssertEqual(drill.title, "خطة البداية".localized)
        XCTAssertEqual(drill.steps.count, 3)
        XCTAssertEqual(drill.steps.first, "ابدأ بمستوى سهل".localized)
        XCTAssertEqual(drill.seed, 8_000_000)
        XCTAssertEqual(drill.difficulty, .easy)
        XCTAssertNil(drill.focusKind)
        XCTAssertNil(drill.recommendedCard)
        XCTAssertEqual(drill.expectedImprovement, 0)
    }

    func testMicroDrillPrioritizesReviewWhenSessionNeedsReview() {
        let attempts = [
            attempt(daysAgo: 3, difficulty: .easy, correct: false, impact: -4, bestImpact: 0),
            attempt(daysAgo: 2, difficulty: .hard, correct: false, impact: -6, bestImpact: 5),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: -2, bestImpact: -2)
        ]

        let drill = WhatToPlayStatsAnalyzer.microDrill(for: attempts)

        XCTAssertEqual(drill.title, "خطة المراجعة".localized)
        XCTAssertEqual(drill.steps.first, "\("أعد موقف".localized) \("صعب".localized) · \("نقاط متوقعة ضائعة".localized): 11")
        XCTAssertEqual(drill.reviewItem?.difficulty, .hard)
        XCTAssertEqual(drill.reviewItem?.lostExpectedPoints, 11)
        XCTAssertEqual(drill.seed, 2)
        XCTAssertEqual(drill.difficulty, .hard)
        XCTAssertEqual(drill.recommendedCard, PlayingCard(suit: .clubs, rank: .seven))
        XCTAssertEqual(drill.expectedImprovement, 11)
    }

    func testMicroDrillPrioritizesHighValueReviewBeforeCoverage() {
        let attempts = [
            attempt(daysAgo: 5, difficulty: .easy, correct: false, impact: 2, bestImpact: 11, focusKind: .trumpPressure),
            attempt(daysAgo: 4, difficulty: .easy, correct: true, impact: 3),
            attempt(daysAgo: 3, difficulty: .easy, correct: true, impact: 3),
            attempt(daysAgo: 2, difficulty: .easy, correct: true, impact: 3),
            attempt(daysAgo: 1, difficulty: .easy, correct: true, impact: 3)
        ]

        let drill = WhatToPlayStatsAnalyzer.microDrill(for: attempts)

        XCTAssertEqual(drill.title, "خطة المراجعة".localized)
        XCTAssertEqual(drill.steps.first, "\("خسارة قيمة عالية".localized): 9")
        XCTAssertEqual(drill.reviewItem?.lostExpectedPoints, 9)
        XCTAssertEqual(drill.difficulty, .easy)
        XCTAssertEqual(drill.focusKind, .trumpPressure)
        XCTAssertEqual(drill.seed, 5)
    }

    func testMicroDrillUsesProjectedLossWhenRoundSimulationIsCostly() {
        let attempts = [
            attempt(daysAgo: 5, difficulty: .easy, correct: false, impact: 2, bestImpact: 4, focusKind: .followSuit, projectedTeamPoints: 55, bestProjectedTeamPoints: 70, seed: 44),
            attempt(daysAgo: 4, difficulty: .easy, correct: true, impact: 3, projectedTeamPoints: 63, bestProjectedTeamPoints: 63),
            attempt(daysAgo: 3, difficulty: .medium, correct: true, impact: 3, projectedTeamPoints: 66, bestProjectedTeamPoints: 66),
            attempt(daysAgo: 2, difficulty: .hard, correct: true, impact: 3, projectedTeamPoints: 68, bestProjectedTeamPoints: 68),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: 3, projectedTeamPoints: 69, bestProjectedTeamPoints: 69)
        ]

        let drill = WhatToPlayStatsAnalyzer.microDrill(for: attempts)

        XCTAssertEqual(drill.title, "خطة محاكاة القرار".localized)
        XCTAssertEqual(drill.steps.first, "\("أعد موقف".localized) \("سهل".localized) · \("نقاط محاكاة ضائعة".localized): 15")
        XCTAssertTrue(drill.steps.contains("قارن نتيجة الجولة لا الأكلة فقط".localized))
        XCTAssertEqual(drill.reviewItem?.lostExpectedPoints, 2)
        XCTAssertEqual(drill.reviewItem?.lostProjectedTeamPoints, 15)
        XCTAssertEqual(drill.seed, 44)
        XCTAssertEqual(drill.difficulty, .easy)
        XCTAssertEqual(drill.focusKind, .followSuit)
        XCTAssertEqual(drill.recommendedCard, PlayingCard(suit: .clubs, rank: .seven))
        XCTAssertEqual(drill.expectedImprovement, 15)
    }

    func testMicroDrillUsesSecondSimulationLossWhenItExplainsReview() {
        let simulationCard = PlayingCard(suit: .hearts, rank: .ace)
        let attempts = [
            attempt(
                daysAgo: 5,
                difficulty: .easy,
                correct: false,
                impact: 2,
                bestImpact: 4,
                focusKind: .followSuit,
                bestSimulationCard: simulationCard,
                projectedTeamPoints: 55,
                secondBestProjectedTeamPoints: 64,
                seed: 45
            ),
            attempt(daysAgo: 4, difficulty: .easy, correct: true, impact: 3, projectedTeamPoints: 63, bestProjectedTeamPoints: 63),
            attempt(daysAgo: 3, difficulty: .medium, correct: true, impact: 3, projectedTeamPoints: 66, bestProjectedTeamPoints: 66),
            attempt(daysAgo: 2, difficulty: .hard, correct: true, impact: 3, projectedTeamPoints: 68, bestProjectedTeamPoints: 68),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: 3, projectedTeamPoints: 69, bestProjectedTeamPoints: 69)
        ]

        let drill = WhatToPlayStatsAnalyzer.microDrill(for: attempts)

        XCTAssertEqual(drill.title, "خطة محاكاة القرار".localized)
        XCTAssertEqual(drill.steps.first, "\("أعد موقف".localized) \("سهل".localized) · \("فاقد ثاني محاكاة".localized): 9")
        XCTAssertEqual(drill.reviewItem?.lostExpectedPoints, 2)
        XCTAssertEqual(drill.reviewItem?.lostProjectedTeamPoints, 0)
        XCTAssertEqual(drill.reviewItem?.lostProjectedAgainstSecondBestPoints, 9)
        XCTAssertEqual(drill.seed, 45)
        XCTAssertEqual(drill.recommendedCard, simulationCard)
        XCTAssertEqual(drill.expectedImprovement, 9)
    }

    func testMicroDrillTargetsCostlyDecisionPatternBeforeCoverage() {
        let attempts = [
            attempt(daysAgo: 5, difficulty: .easy, correct: true, impact: 10, bestImpact: 10, focusKind: .openingLead),
            attempt(daysAgo: 4, difficulty: .easy, correct: false, impact: -1, bestImpact: 10, focusKind: .followSuit),
            attempt(daysAgo: 3, difficulty: .easy, correct: true, impact: 9, bestImpact: 10, focusKind: .trumpPressure),
            attempt(daysAgo: 2, difficulty: .easy, correct: false, impact: -2, bestImpact: 10, focusKind: .narrowChoice),
            attempt(daysAgo: 1, difficulty: .easy, correct: true, impact: 10, bestImpact: 10, focusKind: .openingLead)
        ]

        let drill = WhatToPlayStatsAnalyzer.microDrill(for: attempts)

        XCTAssertEqual(drill.title, "خطة المراجعة".localized)
        XCTAssertEqual(drill.steps.first, "\("خسارة قيمة عالية".localized): 12")
        XCTAssertEqual(drill.iconName, "drop.fill")
        XCTAssertEqual(drill.difficulty, .easy)
        XCTAssertEqual(drill.seed, 2)
    }

    func testMicroDrillTargetsCoverageBeforeGenericPractice() {
        let attempts = [
            attempt(daysAgo: 3, difficulty: .easy, correct: true, impact: 3),
            attempt(daysAgo: 2, difficulty: .easy, correct: true, impact: 3),
            attempt(daysAgo: 1, difficulty: .easy, correct: true, impact: 3)
        ]

        let drill = WhatToPlayStatsAnalyzer.microDrill(for: attempts)

        XCTAssertEqual(drill.title, "خطة التوازن".localized)
        XCTAssertEqual(drill.steps.first, "أكمل المستويات الناقصة".localized)
        XCTAssertEqual(drill.seed, 9_000_003)
        XCTAssertEqual(drill.difficulty, .medium)
        XCTAssertNil(drill.focusKind)
    }

    func testMicroDrillTargetsMissingFocusCoverageAfterDifficultyCoverage() {
        let attempts = [
            attempt(daysAgo: 6, difficulty: .easy, correct: true, impact: 0, focusKind: .openingLead),
            attempt(daysAgo: 5, difficulty: .easy, correct: false, impact: 0, bestImpact: 0, focusKind: .openingLead),
            attempt(daysAgo: 4, difficulty: .medium, correct: true, impact: 0, focusKind: .openingLead),
            attempt(daysAgo: 3, difficulty: .medium, correct: false, impact: 0, bestImpact: 0, focusKind: .openingLead),
            attempt(daysAgo: 2, difficulty: .hard, correct: true, impact: 0, focusKind: .openingLead),
            attempt(daysAgo: 1, difficulty: .hard, correct: true, impact: 0, focusKind: .openingLead)
        ] + expertCoverageAttempts(focusKind: .openingLead)

        let drill = WhatToPlayStatsAnalyzer.microDrill(for: attempts)

        XCTAssertEqual(drill.title, "خطة أنواع المواقف".localized)
        XCTAssertEqual(drill.steps.first, "\("استهدف نوع موقف ناقص".localized): \("اتباع اللون".localized)")
        XCTAssertEqual(drill.seed, 9_100_008)
        XCTAssertEqual(drill.difficulty, .medium)
        XCTAssertEqual(drill.focusKind, .followSuit)
    }

    func testMicroDrillSkipsAttemptedSeedForSameTarget() {
        let collidingSeed: UInt64 = 9_100_009
        let attempts = [
            attempt(daysAgo: 7, difficulty: .easy, correct: true, impact: 0, focusKind: .openingLead),
            attempt(daysAgo: 6, difficulty: .easy, correct: false, impact: 0, bestImpact: 0, focusKind: .openingLead),
            attempt(daysAgo: 5, difficulty: .medium, correct: true, impact: 0, focusKind: .openingLead),
            attempt(daysAgo: 4, difficulty: .medium, correct: false, impact: 0, bestImpact: 0, focusKind: .openingLead),
            attempt(daysAgo: 3, difficulty: .hard, correct: true, impact: 0, focusKind: .openingLead),
            attempt(daysAgo: 2, difficulty: .hard, correct: true, impact: 0, focusKind: .openingLead),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: 0, focusKind: .followSuit, seed: collidingSeed)
        ] + expertCoverageAttempts(focusKind: .openingLead)

        let drill = WhatToPlayStatsAnalyzer.microDrill(for: attempts)

        XCTAssertEqual(drill.title, "خطة أنواع المواقف".localized)
        XCTAssertEqual(drill.difficulty, .medium)
        XCTAssertEqual(drill.focusKind, .followSuit)
        XCTAssertEqual(drill.seed, collidingSeed + 1)
    }

    func testMicroDrillTargetsMissingGameModeAfterDifficultyAndFocusCoverage() {
        let attempts = [
            attempt(daysAgo: 8, difficulty: .easy, correct: true, impact: 1, focusKind: .openingLead, gameMode: .sun),
            attempt(daysAgo: 7, difficulty: .easy, correct: true, impact: 1, focusKind: .followSuit, gameMode: .sun),
            attempt(daysAgo: 6, difficulty: .medium, correct: true, impact: 1, focusKind: .trumpPressure, gameMode: .sun),
            attempt(daysAgo: 5, difficulty: .medium, correct: true, impact: 1, focusKind: .narrowChoice, gameMode: .sun),
            attempt(daysAgo: 4, difficulty: .hard, correct: true, impact: 1, focusKind: .openingLead, gameMode: .sun),
            attempt(daysAgo: 3, difficulty: .hard, correct: true, impact: 1, focusKind: .followSuit, gameMode: .sun),
            attempt(daysAgo: 2, difficulty: .easy, correct: true, impact: 1, focusKind: .trumpPressure, gameMode: .sun),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: 1, focusKind: .narrowChoice, gameMode: .sun)
        ] + expertCoverageAttempts(gameMode: .sun)

        let drill = WhatToPlayStatsAnalyzer.microDrill(for: attempts)

        XCTAssertEqual(drill.title, "خطة الصن والحكم".localized)
        XCTAssertEqual(drill.steps.first, "\("استهدف نمطًا ناقصًا".localized): \("حكم".localized)")
        XCTAssertEqual(drill.gameMode, .hokum)
        XCTAssertEqual(drill.seed, 11_010_010)
        XCTAssertNotNil(drill.difficulty)
        XCTAssertNil(drill.focusKind)
    }

    func testMicroDrillTargetsMissingTrumpSuitAfterModeCoverage() {
        let attempts = [
            attempt(daysAgo: 8, difficulty: .easy, correct: true, impact: 1, focusKind: .openingLead, gameMode: .sun),
            attempt(daysAgo: 7, difficulty: .easy, correct: true, impact: 1, focusKind: .followSuit, gameMode: .sun),
            attempt(daysAgo: 6, difficulty: .medium, correct: true, impact: 1, focusKind: .trumpPressure, gameMode: .hokum, scenarioContext: hokumContext(trumpSuit: .spades)),
            attempt(daysAgo: 5, difficulty: .medium, correct: true, impact: 1, focusKind: .narrowChoice, gameMode: .hokum, scenarioContext: hokumContext(trumpSuit: .spades)),
            attempt(daysAgo: 4, difficulty: .hard, correct: true, impact: 1, focusKind: .openingLead, gameMode: .hokum, scenarioContext: hokumContext(trumpSuit: .spades)),
            attempt(daysAgo: 3, difficulty: .hard, correct: true, impact: 1, focusKind: .followSuit, gameMode: .hokum, scenarioContext: hokumContext(trumpSuit: .spades)),
            attempt(daysAgo: 2, difficulty: .easy, correct: true, impact: 1, focusKind: .trumpPressure, gameMode: .hokum, scenarioContext: hokumContext(trumpSuit: .spades)),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: 1, focusKind: .narrowChoice, gameMode: .hokum, scenarioContext: hokumContext(trumpSuit: .spades))
        ] + expertCoverageAttempts(gameMode: .hokum)

        let drill = WhatToPlayStatsAnalyzer.microDrill(for: attempts)

        XCTAssertEqual(drill.title, "خطة ألوان الحكم".localized)
        XCTAssertEqual(drill.steps.first, "\("استهدف حكم".localized): \(Suit.hearts.spokenName)")
        XCTAssertEqual(drill.gameMode, .hokum)
        XCTAssertEqual(drill.trumpSuit, .hearts)
        XCTAssertNotNil(drill.seed)
        XCTAssertNil(drill.focusKind)
    }

    func testMicroDrillRaisesChallengeForSharpBalancedPlayer() {
        let attempts = [
            attempt(daysAgo: 8, difficulty: .easy, correct: true, impact: 10, focusKind: .openingLead, gameMode: .hokum),
            attempt(daysAgo: 7, difficulty: .easy, correct: true, impact: 10, focusKind: .followSuit, gameMode: .sun),
            attempt(daysAgo: 6, difficulty: .medium, correct: true, impact: 10, focusKind: .trumpPressure, gameMode: .sun),
            attempt(daysAgo: 5, difficulty: .medium, correct: true, impact: 10, focusKind: .narrowChoice, gameMode: .sun),
            attempt(daysAgo: 4, difficulty: .hard, correct: true, impact: 10, focusKind: .openingLead, gameMode: .sun),
            attempt(daysAgo: 3, difficulty: .hard, correct: true, impact: 10, focusKind: .followSuit, gameMode: .hokum),
            attempt(daysAgo: 2, difficulty: .easy, correct: true, impact: 10, focusKind: .trumpPressure, gameMode: .sun),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: 10, focusKind: .narrowChoice, gameMode: .sun)
        ] + expertCoverageAttempts(impact: 10)

        let drill = WhatToPlayStatsAnalyzer.microDrill(for: attempts)

        XCTAssertEqual(drill.title, "خطة التحدي".localized)
        XCTAssertEqual(drill.steps.first, "\("ابدأ بالمستوى المقترح".localized): \("خبير".localized)")
        XCTAssertEqual(drill.seed, 11_200_010)
        XCTAssertEqual(drill.difficulty, .expert)
        XCTAssertEqual(drill.focusKind, .trumpPressure)
    }

    func testMicroDrillFallsBackToContinuationPlan() {
        let attempts = [
            attempt(daysAgo: 8, difficulty: .easy, correct: true, impact: 0, focusKind: .openingLead, gameMode: .hokum),
            attempt(daysAgo: 7, difficulty: .easy, correct: false, impact: 0, focusKind: .followSuit, gameMode: .sun),
            attempt(daysAgo: 6, difficulty: .medium, correct: true, impact: 0, focusKind: .trumpPressure, gameMode: .sun),
            attempt(daysAgo: 5, difficulty: .medium, correct: false, impact: 0, focusKind: .narrowChoice, gameMode: .sun),
            attempt(daysAgo: 4, difficulty: .hard, correct: true, impact: 0, focusKind: .openingLead, gameMode: .sun),
            attempt(daysAgo: 3, difficulty: .hard, correct: false, impact: 0, focusKind: .followSuit, gameMode: .hokum),
            attempt(daysAgo: 2, difficulty: .easy, correct: true, impact: 0, focusKind: .trumpPressure, gameMode: .sun),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: 0, focusKind: .narrowChoice, gameMode: .sun)
        ] + expertCoverageAttempts(correctSecond: false)

        let drill = WhatToPlayStatsAnalyzer.microDrill(for: attempts)

        XCTAssertEqual(drill.title, "خطة الاستمرار".localized)
        XCTAssertEqual(drill.steps.first, "ابدأ بالمستوى المقترح".localized)
        XCTAssertNotNil(drill.seed)
        XCTAssertNotNil(drill.difficulty)
    }

    func testPlayStyleStaysInMeasurementModeWithSmallSample() {
        let attempts = [
            attempt(daysAgo: 2, correct: true, impact: 2),
            attempt(daysAgo: 1, correct: false, impact: -2)
        ]

        let style = WhatToPlayStatsAnalyzer.playStyle(for: attempts)

        XCTAssertEqual(style.kind, .measuring)
        XCTAssertEqual(style.title, "أسلوبك تحت القياس".localized)
    }

    func testPlayStyleRecognizesExpertAlignedDecisions() {
        let attempts = [
            attempt(daysAgo: 5, correct: true, impact: 4),
            attempt(daysAgo: 4, correct: true, impact: 2),
            attempt(daysAgo: 3, correct: true, impact: 3),
            attempt(daysAgo: 2, correct: true, impact: 1),
            attempt(daysAgo: 1, correct: false, impact: 0)
        ]

        let style = WhatToPlayStatsAnalyzer.playStyle(for: attempts)

        XCTAssertEqual(style.kind, .expertAligned)
        XCTAssertEqual(style.title, "قريب من الخبير".localized)
    }

    func testPlayStyleAdviceHighlightsSecondSimulationLossWhenRepeated() {
        let attempts = [
            attempt(daysAgo: 4, correct: true, impact: 4, projectedTeamPoints: 52, bestProjectedTeamPoints: 74, secondBestProjectedTeamPoints: 70),
            attempt(daysAgo: 3, correct: true, impact: 3, projectedTeamPoints: 58, bestProjectedTeamPoints: 76, secondBestProjectedTeamPoints: 72),
            attempt(daysAgo: 2, correct: true, impact: 2, projectedTeamPoints: 60, bestProjectedTeamPoints: 78, secondBestProjectedTeamPoints: 70),
            attempt(daysAgo: 1, correct: true, impact: 1, projectedTeamPoints: 62, bestProjectedTeamPoints: 80, secondBestProjectedTeamPoints: 72)
        ]

        let style = WhatToPlayStatsAnalyzer.playStyle(for: attempts)

        XCTAssertEqual(style.kind, .expertAligned)
        XCTAssertTrue(style.advice.contains("فاقد ثاني محاكاة".localized))
        XCTAssertTrue(style.advice.contains("راجع ثاني أفضل محاكاة قبل اعتماد قرار يبدو صحيحًا.".localized))
    }

    func testPlayStyleRecognizesFoundationalNeeds() {
        let attempts = [
            attempt(daysAgo: 4, correct: false, impact: -8),
            attempt(daysAgo: 3, correct: false, impact: -6),
            attempt(daysAgo: 2, correct: true, impact: 2),
            attempt(daysAgo: 1, correct: false, impact: -4)
        ]

        let style = WhatToPlayStatsAnalyzer.playStyle(for: attempts)

        XCTAssertEqual(style.kind, .foundational)
        XCTAssertEqual(style.title, "تحتاج تأسيس".localized)
    }

    func testPlayStyleRecognizesCautiousPointLeak() {
        let attempts = [
            attempt(daysAgo: 4, correct: true, impact: -4),
            attempt(daysAgo: 3, correct: true, impact: -2),
            attempt(daysAgo: 2, correct: true, impact: -1),
            attempt(daysAgo: 1, correct: false, impact: -5)
        ]

        let style = WhatToPlayStatsAnalyzer.playStyle(for: attempts)

        XCTAssertEqual(style.kind, .cautious)
        XCTAssertEqual(style.title, "لاعب حذر".localized)
    }

    func testPlayStyleFallsBackToInconsistentReading() {
        let attempts = [
            attempt(daysAgo: 4, correct: true, impact: 3),
            attempt(daysAgo: 3, correct: false, impact: -4),
            attempt(daysAgo: 2, correct: true, impact: 2),
            attempt(daysAgo: 1, correct: false, impact: -1)
        ]

        let style = WhatToPlayStatsAnalyzer.playStyle(for: attempts)

        XCTAssertEqual(style.kind, .inconsistent)
        XCTAssertEqual(style.title, "قراءة متذبذبة".localized)
    }

    func testDecisionPatternReportsNoData() {
        let pattern = WhatToPlayStatsAnalyzer.decisionPattern(for: [])

        XCTAssertEqual(pattern.kind, .noData)
        XCTAssertEqual(pattern.inspectedAttempts, 0)
        XCTAssertEqual(pattern.affectedAttempts, 0)
        XCTAssertEqual(pattern.title, "نمط قراراتك غير معروف".localized)
    }

    func testDecisionPatternReportsCleanRecentChoices() {
        let attempts = [
            attempt(daysAgo: 3, correct: true, impact: 4),
            attempt(daysAgo: 2, correct: true, impact: 2),
            attempt(daysAgo: 1, correct: true, impact: 1)
        ]

        let pattern = WhatToPlayStatsAnalyzer.decisionPattern(for: attempts)

        XCTAssertEqual(pattern.kind, .clean)
        XCTAssertEqual(pattern.inspectedAttempts, 3)
        XCTAssertEqual(pattern.affectedAttempts, 0)
        XCTAssertEqual(pattern.title, "قراراتك الأخيرة نظيفة".localized)
    }

    func testDecisionPatternRecognizesUsefulAlternatives() {
        let attempts = [
            attempt(daysAgo: 4, correct: true, impact: 3),
            attempt(daysAgo: 3, correct: false, impact: 2),
            attempt(daysAgo: 2, correct: false, impact: 0),
            attempt(daysAgo: 1, correct: false, impact: -1)
        ]

        let pattern = WhatToPlayStatsAnalyzer.decisionPattern(for: attempts)

        XCTAssertEqual(pattern.kind, .usefulAlternatives)
        XCTAssertEqual(pattern.inspectedAttempts, 4)
        XCTAssertEqual(pattern.affectedAttempts, 2)
        XCTAssertEqual(pattern.title, "اختيارات قريبة من الأفضل".localized)
    }

    func testDecisionPatternRecognizesPointLeaks() {
        let attempts = [
            attempt(daysAgo: 4, correct: false, impact: -5),
            attempt(daysAgo: 3, correct: false, impact: -2),
            attempt(daysAgo: 2, correct: false, impact: 1),
            attempt(daysAgo: 1, correct: true, impact: 3)
        ]

        let pattern = WhatToPlayStatsAnalyzer.decisionPattern(for: attempts)

        XCTAssertEqual(pattern.kind, .pointLeaks)
        XCTAssertEqual(pattern.inspectedAttempts, 4)
        XCTAssertEqual(pattern.affectedAttempts, 2)
        XCTAssertEqual(pattern.title, "أخطاء مكلفة".localized)
    }

    func testDecisionPatternRecognizesFarRankChoices() {
        let attempts = [
            attempt(daysAgo: 4, correct: false, impact: 1, selectedRank: 4),
            attempt(daysAgo: 3, correct: false, impact: 0, selectedRank: 3),
            attempt(daysAgo: 2, correct: false, impact: 2, selectedRank: 2),
            attempt(daysAgo: 1, correct: true, impact: 3, selectedRank: 1)
        ]

        let pattern = WhatToPlayStatsAnalyzer.decisionPattern(for: attempts)

        XCTAssertEqual(pattern.kind, .farRankChoices)
        XCTAssertEqual(pattern.inspectedAttempts, 4)
        XCTAssertEqual(pattern.affectedAttempts, 2)
        XCTAssertEqual(pattern.title, "تبتعد عن أفضل خيارين".localized)
    }

    func testDecisionPatternRecognizesOpponentTrickClosureFromImpactBreakdown() {
        let attempts = [
            attempt(daysAgo: 4, correct: false, impact: -8, impactBreakdown: .opponentTrickClosure(points: 18)),
            attempt(daysAgo: 3, correct: false, impact: -3, impactBreakdown: .unprotectedPointDump(points: 10)),
            attempt(daysAgo: 2, correct: false, impact: -6, impactBreakdown: .opponentTrickClosure(points: 14)),
            attempt(daysAgo: 1, correct: true, impact: 2)
        ]

        let pattern = WhatToPlayStatsAnalyzer.decisionPattern(for: attempts)

        XCTAssertEqual(pattern.kind, .opponentTrickClosure)
        XCTAssertEqual(pattern.inspectedAttempts, 4)
        XCTAssertEqual(pattern.affectedAttempts, 2)
        XCTAssertEqual(pattern.title, "تغلق الأكلة للخصم".localized)
    }

    func testDecisionPatternRecognizesUnprotectedPointDumpFromImpactBreakdown() {
        let attempts = [
            attempt(daysAgo: 4, correct: false, impact: -4, impactBreakdown: .unprotectedPointDump(points: 10)),
            attempt(daysAgo: 3, correct: false, impact: -5, impactBreakdown: .unprotectedPointDump(points: 11)),
            attempt(daysAgo: 2, correct: false, impact: -2, impactBreakdown: .costlyOpeningLead(points: 0)),
            attempt(daysAgo: 1, correct: true, impact: 3)
        ]

        let pattern = WhatToPlayStatsAnalyzer.decisionPattern(for: attempts)

        XCTAssertEqual(pattern.kind, .unprotectedPointDump)
        XCTAssertEqual(pattern.affectedAttempts, 2)
        XCTAssertEqual(pattern.title, "ترمي نقاطًا بلا حماية".localized)
    }

    func testDecisionPatternRecognizesCostlyOpeningLeadFromImpactBreakdown() {
        let attempts = [
            attempt(daysAgo: 4, correct: false, impact: -4, impactBreakdown: .costlyOpeningLead(points: 4)),
            attempt(daysAgo: 3, correct: false, impact: -3, impactBreakdown: .costlyOpeningLead(points: 0)),
            attempt(daysAgo: 2, correct: false, impact: -1, impactBreakdown: .unprotectedPointDump(points: 10)),
            attempt(daysAgo: 1, correct: true, impact: 3)
        ]

        let pattern = WhatToPlayStatsAnalyzer.decisionPattern(for: attempts)

        XCTAssertEqual(pattern.kind, .costlyOpeningLead)
        XCTAssertEqual(pattern.affectedAttempts, 2)
        XCTAssertEqual(pattern.title, "افتتاحاتك مكلفة".localized)
    }

    func testDecisionPatternUsesRecentLimit() {
        let attempts = [
            attempt(daysAgo: 5, correct: false, impact: -10),
            attempt(daysAgo: 4, correct: false, impact: -10),
            attempt(daysAgo: 3, correct: true, impact: 3),
            attempt(daysAgo: 2, correct: true, impact: 2),
            attempt(daysAgo: 1, correct: true, impact: 1)
        ]

        let pattern = WhatToPlayStatsAnalyzer.decisionPattern(for: attempts, limit: 3)

        XCTAssertEqual(pattern.kind, .clean)
        XCTAssertEqual(pattern.inspectedAttempts, 3)
    }

    func testTrainingSessionPlanStartsWithShortFoundation() {
        let plan = WhatToPlayStatsAnalyzer.trainingSessionPlan(for: [])

        XCTAssertEqual(plan.difficulty, .easy)
        XCTAssertEqual(plan.scenarioCount, 3)
        XCTAssertEqual(plan.targetAccuracyPercent, 60)
        XCTAssertEqual(plan.targetAverageExpectedImpact, 0)
        XCTAssertNil(plan.maxCostlyDecisions)
        XCTAssertEqual(plan.title, "جلسة تأسيس قصيرة".localized)
        XCTAssertEqual(plan.rationaleTitle, "سبب اختيار الخطة: بناء خط أساس".localized)
        XCTAssertEqual(plan.rationaleIconName, "ruler.fill")
    }

    func testNextTrainingSessionSeedIsStableForSameAttemptsAndPlan() {
        let plan = WhatToPlayStatsAnalyzer.trainingSessionPlan(for: [])

        let first = WhatToPlayStatsAnalyzer.nextTrainingSessionSeed(for: [], plan: plan)
        let second = WhatToPlayStatsAnalyzer.nextTrainingSessionSeed(for: [], plan: plan)

        XCTAssertEqual(first, second)
        XCTAssertEqual(first, 9_003_600)
    }

    func testNextTrainingSessionSeedAdvancesOnlyForMatchingPlanAttempts() {
        let plan = sessionPlan(difficulty: .medium, focusKind: .trumpPressure, count: 4, target: 70, impactTarget: 1)
        let attempts = [
            attempt(daysAgo: 4, difficulty: .easy, correct: true, impact: 2, focusKind: .trumpPressure),
            attempt(daysAgo: 3, difficulty: .medium, correct: false, impact: -2, focusKind: .openingLead),
            attempt(daysAgo: 2, difficulty: .medium, correct: true, impact: 3, focusKind: .trumpPressure),
            attempt(daysAgo: 1, difficulty: .medium, correct: false, impact: -1, focusKind: .trumpPressure)
        ]

        let seed = WhatToPlayStatsAnalyzer.nextTrainingSessionSeed(for: attempts, plan: plan)

        XCTAssertEqual(seed, 10_204_703)
    }

    func testNextTrainingSessionSeedSkipsAlreadyAttemptedMatchingSeed() {
        let plan = sessionPlan(difficulty: .medium, focusKind: .trumpPressure, count: 4, target: 70, impactTarget: 1)
        let collidingSeed: UInt64 = 10_204_703
        let attempts = [
            attempt(daysAgo: 4, difficulty: .easy, correct: true, impact: 2, focusKind: .trumpPressure, seed: collidingSeed + 1),
            attempt(daysAgo: 3, difficulty: .medium, correct: false, impact: -2, focusKind: .openingLead, seed: collidingSeed + 2),
            attempt(daysAgo: 2, difficulty: .medium, correct: true, impact: 3, focusKind: .trumpPressure, seed: 7),
            attempt(daysAgo: 1, difficulty: .medium, correct: false, impact: -1, focusKind: .trumpPressure, seed: collidingSeed)
        ]

        let seed = WhatToPlayStatsAnalyzer.nextTrainingSessionSeed(for: attempts, plan: plan)

        XCTAssertEqual(seed, collidingSeed + 1)
    }

    func testNextTrainingSessionSeedIncludesTargetGameMode() {
        let sunPlan = sessionPlan(difficulty: .medium, focusKind: .trumpPressure, gameMode: .sun, count: 4, target: 70, impactTarget: 1)
        let hokumPlan = sessionPlan(difficulty: .medium, focusKind: .trumpPressure, gameMode: .hokum, count: 4, target: 70, impactTarget: 1)

        let sunSeed = WhatToPlayStatsAnalyzer.nextTrainingSessionSeed(for: [], plan: sunPlan)
        let hokumSeed = WhatToPlayStatsAnalyzer.nextTrainingSessionSeed(for: [], plan: hokumPlan)

        XCTAssertNotEqual(sunSeed, hokumSeed)
        XCTAssertEqual(sunSeed, 10_204_701)
        XCTAssertEqual(hokumSeed, 10_214_701)
    }

    func testNextTrainingSessionSeedIncludesTargetTrumpSuit() {
        let heartsPlan = sessionPlan(difficulty: .medium, focusKind: .trumpPressure, gameMode: .hokum, trumpSuit: .hearts, count: 4, target: 70, impactTarget: 1)
        let spadesPlan = sessionPlan(difficulty: .medium, focusKind: .trumpPressure, gameMode: .hokum, trumpSuit: .spades, count: 4, target: 70, impactTarget: 1)

        let heartsSeed = WhatToPlayStatsAnalyzer.nextTrainingSessionSeed(for: [], plan: heartsPlan)
        let spadesSeed = WhatToPlayStatsAnalyzer.nextTrainingSessionSeed(for: [], plan: spadesPlan)

        XCTAssertNotEqual(heartsSeed, spadesSeed)
        XCTAssertEqual(heartsSeed, 10_214_801)
        XCTAssertEqual(spadesSeed, 10_215_101)
    }

    func testTrainingSessionPlanTargetsWeakHokumSuitWhenHokumIsWeakestMode() {
        let attempts = [
            attempt(daysAgo: 6, correct: false, impact: 1, bestImpact: 4, gameMode: .hokum, projectedTeamPoints: 42, bestProjectedTeamPoints: 70, scenarioContext: hokumContext(trumpSuit: .spades)),
            attempt(daysAgo: 5, correct: true, impact: 2, bestImpact: 2, gameMode: .hokum, projectedTeamPoints: 68, bestProjectedTeamPoints: 68, scenarioContext: hokumContext(trumpSuit: .spades)),
            attempt(daysAgo: 4, correct: false, impact: 0, bestImpact: 2, gameMode: .sun, projectedTeamPoints: 70, bestProjectedTeamPoints: 72),
            attempt(daysAgo: 3, correct: true, impact: 2, bestImpact: 2, gameMode: .sun, projectedTeamPoints: 75, bestProjectedTeamPoints: 75),
            attempt(daysAgo: 2, correct: true, impact: 2, bestImpact: 2, gameMode: .hokum, scenarioContext: hokumContext(trumpSuit: .hearts))
        ]

        let plan = WhatToPlayStatsAnalyzer.trainingSessionPlan(for: attempts)

        XCTAssertEqual(plan.gameMode, .hokum)
        XCTAssertEqual(plan.trumpSuit, .spades)
        XCTAssertTrue(plan.rationaleTitle.contains("\("حكم".localized) \(Suit.spades.spokenName)"))
        XCTAssertTrue(plan.rationaleDetail.contains("\("الدقة".localized): 50%"))
        XCTAssertEqual(plan.rationaleIconName, "suit.spade.fill")
    }

    func testTrainingSessionPlanRationaleUsesSecondProjectedLossForWeakHokumSuit() {
        let attempts = [
            attempt(daysAgo: 6, correct: false, impact: 2, bestImpact: 4, gameMode: .hokum, projectedTeamPoints: 50, bestProjectedTeamPoints: 52, secondBestProjectedTeamPoints: 82, scenarioContext: hokumContext(trumpSuit: .hearts)),
            attempt(daysAgo: 5, correct: true, impact: 3, bestImpact: 3, gameMode: .hokum, projectedTeamPoints: 62, bestProjectedTeamPoints: 62, secondBestProjectedTeamPoints: 62, scenarioContext: hokumContext(trumpSuit: .hearts)),
            attempt(daysAgo: 4, correct: false, impact: 1, bestImpact: 4, gameMode: .hokum, projectedTeamPoints: 44, bestProjectedTeamPoints: 70, secondBestProjectedTeamPoints: 70, scenarioContext: hokumContext(trumpSuit: .spades)),
            attempt(daysAgo: 3, correct: true, impact: 2, bestImpact: 2, gameMode: .hokum, projectedTeamPoints: 72, bestProjectedTeamPoints: 72, secondBestProjectedTeamPoints: 72, scenarioContext: hokumContext(trumpSuit: .spades))
        ]

        let plan = WhatToPlayStatsAnalyzer.trainingSessionPlan(for: attempts)

        XCTAssertEqual(plan.gameMode, .hokum)
        XCTAssertEqual(plan.trumpSuit, .hearts)
        XCTAssertTrue(plan.rationaleTitle.contains("\("حكم".localized) \(Suit.hearts.spokenName)"))
        XCTAssertTrue(plan.rationaleDetail.contains("\("فاقد ثاني محاكاة".localized): 32"))
    }

    func testTrainingSessionProgressFiltersByTargetTrumpSuit() {
        let plan = sessionPlan(difficulty: .medium, focusKind: .trumpPressure, gameMode: .hokum, trumpSuit: .spades, count: 3, target: 67)
        let attempts = [
            attempt(daysAgo: 3, difficulty: .medium, correct: true, impact: 2, bestImpact: 2, focusKind: .trumpPressure, gameMode: .hokum, seed: 101, scenarioContext: hokumContext(trumpSuit: .hearts)),
            attempt(daysAgo: 2, difficulty: .medium, correct: false, impact: -3, bestImpact: 3, focusKind: .trumpPressure, gameMode: .hokum, seed: 202, scenarioContext: hokumContext(trumpSuit: .spades)),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: 2, bestImpact: 2, focusKind: .trumpPressure, gameMode: .hokum, seed: 303, scenarioContext: hokumContext(trumpSuit: .spades))
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.completedAttempts, 2)
        XCTAssertEqual(progress.correctAttempts, 1)
        XCTAssertEqual(progress.reviewItem?.seed, 202)
    }

    func testTrainingSessionPlanPrioritizesReviewWhenRecentAttemptsNeedIt() {
        let attempts = [
            attempt(daysAgo: 4, difficulty: .medium, correct: true, impact: 5, bestImpact: 5, focusKind: .openingLead),
            attempt(daysAgo: 3, difficulty: .medium, correct: false, impact: -6, bestImpact: 4, focusKind: .trumpPressure),
            attempt(daysAgo: 2, difficulty: .medium, correct: false, impact: -4, bestImpact: 2, focusKind: .trumpPressure),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: -5, bestImpact: -5, focusKind: .openingLead)
        ]

        let plan = WhatToPlayStatsAnalyzer.trainingSessionPlan(for: attempts)

        XCTAssertEqual(plan.title, "جلسة مراجعة مركزة".localized)
        XCTAssertEqual(plan.focusKind, WhatToPlayScenarioFocusKind.trumpPressure)
        XCTAssertEqual(plan.scenarioCount, 3)
        XCTAssertEqual(plan.targetAverageExpectedImpact, 0)
        XCTAssertEqual(plan.successMetric, "هدف الجلسة: لا تكرر نفس سبب الخطأ مرتين.".localized)
    }

    func testTrainingSessionPlanTargetsWeakestGameMode() {
        let attempts = [
            attempt(daysAgo: 5, correct: true, impact: 4, bestImpact: 4, gameMode: .sun),
            attempt(daysAgo: 4, correct: true, impact: 3, bestImpact: 3, gameMode: .sun),
            attempt(daysAgo: 3, correct: false, impact: -4, bestImpact: 3, gameMode: .hokum),
            attempt(daysAgo: 2, correct: true, impact: 2, bestImpact: 2, gameMode: .hokum),
            attempt(daysAgo: 1, correct: false, impact: -1, bestImpact: 1)
        ]

        let plan = WhatToPlayStatsAnalyzer.trainingSessionPlan(for: attempts)
        let recommendation = WhatToPlayStatsAnalyzer.nextScenarioRecommendation(for: attempts)

        XCTAssertEqual(plan.gameMode, .hokum)
        XCTAssertEqual(recommendation.gameMode, .hokum)
        XCTAssertTrue(plan.rationaleTitle.contains("حكم".localized))
        XCTAssertEqual(plan.rationaleIconName, "crown.fill")
    }

    func testTrainingSessionPlanRationaleUsesSecondProjectedLossForWeakGameMode() {
        let attempts = [
            attempt(daysAgo: 6, correct: false, impact: 3, bestImpact: 5, gameMode: .sun, projectedTeamPoints: 70, bestProjectedTeamPoints: 72, secondBestProjectedTeamPoints: 94),
            attempt(daysAgo: 5, correct: true, impact: 3, bestImpact: 3, gameMode: .sun, projectedTeamPoints: 78, bestProjectedTeamPoints: 78, secondBestProjectedTeamPoints: 78),
            attempt(daysAgo: 4, correct: false, impact: 1, bestImpact: 5, gameMode: .hokum, projectedTeamPoints: 54, bestProjectedTeamPoints: 76, secondBestProjectedTeamPoints: 76),
            attempt(daysAgo: 3, correct: true, impact: 3, bestImpact: 3, gameMode: .hokum, projectedTeamPoints: 82, bestProjectedTeamPoints: 82, secondBestProjectedTeamPoints: 82)
        ]

        let plan = WhatToPlayStatsAnalyzer.trainingSessionPlan(for: attempts)

        XCTAssertEqual(plan.gameMode, .sun)
        XCTAssertNil(plan.trumpSuit)
        XCTAssertTrue(plan.rationaleTitle.contains("صن".localized))
        XCTAssertTrue(plan.rationaleDetail.contains("\("فاقد ثاني محاكاة".localized): 24"))
    }

    func testTrainingSessionPlanRaisesLevelForExpertAlignedStyle() {
        let attempts = [
            attempt(daysAgo: 6, difficulty: .easy, correct: true, impact: 4),
            attempt(daysAgo: 5, difficulty: .easy, correct: true, impact: 4),
            attempt(daysAgo: 4, difficulty: .medium, correct: true, impact: 3),
            attempt(daysAgo: 3, difficulty: .medium, correct: true, impact: 3),
            attempt(daysAgo: 2, difficulty: .hard, correct: true, impact: 2),
            attempt(daysAgo: 1, difficulty: .hard, correct: false, impact: 0)
        ]

        let plan = WhatToPlayStatsAnalyzer.trainingSessionPlan(for: attempts)

        XCTAssertEqual(plan.title, "جلسة رفع المستوى".localized)
        XCTAssertEqual(plan.scenarioCount, 5)
        XCTAssertEqual(plan.targetAccuracyPercent, 80)
        XCTAssertEqual(plan.targetAverageExpectedImpact, 2)
    }

    func testTrainingSessionPlanReviewsValueBeforeRaisingDifficulty() {
        let attempts = [
            attempt(daysAgo: 4, difficulty: .medium, correct: false, impact: -8, bestImpact: 8),
            attempt(daysAgo: 3, difficulty: .medium, correct: true, impact: 4, bestImpact: 4),
            attempt(daysAgo: 2, difficulty: .medium, correct: true, impact: 4, bestImpact: 4),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: 4, bestImpact: 4)
        ]

        let plan = WhatToPlayStatsAnalyzer.trainingSessionPlan(for: attempts)

        XCTAssertEqual(plan.difficulty, .medium)
        XCTAssertEqual(plan.title, "جلسة مراجعة القيمة".localized)
        XCTAssertEqual(plan.scenarioCount, 4)
        XCTAssertEqual(plan.targetAccuracyPercent, 75)
        XCTAssertEqual(plan.targetAverageExpectedImpact, 1)
        XCTAssertEqual(plan.successMetric, "هدف الجلسة: متوسط نقاط ضائعة أقل من 4.".localized)
    }

    func testTrainingSessionPlanTargetsSimulationLoss() {
        let attempts = [
            attempt(daysAgo: 4, difficulty: .medium, correct: false, impact: 2, bestImpact: 4, focusKind: .followSuit, projectedTeamPoints: 54, bestProjectedTeamPoints: 72),
            attempt(daysAgo: 3, difficulty: .medium, correct: true, impact: 3, bestImpact: 3, focusKind: .followSuit, projectedTeamPoints: 70, bestProjectedTeamPoints: 70),
            attempt(daysAgo: 2, difficulty: .medium, correct: false, impact: 2, bestImpact: 4, focusKind: .followSuit, projectedTeamPoints: 58, bestProjectedTeamPoints: 74),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: 3, bestImpact: 3, focusKind: .followSuit, projectedTeamPoints: 76, bestProjectedTeamPoints: 76)
        ]

        let plan = WhatToPlayStatsAnalyzer.trainingSessionPlan(for: attempts)

        XCTAssertEqual(plan.difficulty, .medium)
        XCTAssertEqual(plan.focusKind, .followSuit)
        XCTAssertEqual(plan.title, "جلسة تقليل القرارات المكلفة".localized)
        XCTAssertEqual(plan.scenarioCount, 3)
        XCTAssertEqual(plan.targetAccuracyPercent, 67)
        XCTAssertEqual(plan.targetAverageExpectedImpact, 1)
        XCTAssertEqual(plan.successMetric, "هدف الجلسة: لا يوجد أكثر من قرار مكلف واحد.".localized)
        XCTAssertEqual(plan.iconName, "exclamationmark.triangle.fill")
    }

    func testTrainingSessionPlanTargetsCostlyDecisionQuality() {
        let attempts = [
            attempt(daysAgo: 5, difficulty: .medium, correct: true, impact: 10, bestImpact: 10, focusKind: .openingLead),
            attempt(daysAgo: 4, difficulty: .medium, correct: false, impact: -1, bestImpact: 10, focusKind: .followSuit),
            attempt(daysAgo: 3, difficulty: .medium, correct: true, impact: 9, bestImpact: 10, focusKind: .trumpPressure),
            attempt(daysAgo: 2, difficulty: .medium, correct: false, impact: -2, bestImpact: 10, focusKind: .narrowChoice),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: 10, bestImpact: 10, focusKind: .openingLead)
        ]

        let plan = WhatToPlayStatsAnalyzer.trainingSessionPlan(for: attempts)
        let recommendation = WhatToPlayStatsAnalyzer.nextScenarioRecommendation(for: attempts)

        XCTAssertEqual(plan.title, "جلسة تقليل القرارات المكلفة".localized)
        XCTAssertEqual(plan.scenarioCount, 3)
        XCTAssertEqual(plan.targetAverageExpectedImpact, 1)
        XCTAssertEqual(plan.maxCostlyDecisions, 1)
        XCTAssertEqual(plan.iconName, "exclamationmark.triangle.fill")
        XCTAssertEqual(recommendation.iconName, "exclamationmark.triangle.fill")
        XCTAssertTrue(recommendation.detail.contains("متوسط".localized))
    }

    func testTrainingSessionPlanTargetsPointLeakForCautiousStyle() {
        let attempts = [
            attempt(daysAgo: 4, correct: true, impact: -4),
            attempt(daysAgo: 3, correct: true, impact: -2),
            attempt(daysAgo: 2, correct: true, impact: -1),
            attempt(daysAgo: 1, correct: false, impact: -5)
        ]

        let plan = WhatToPlayStatsAnalyzer.trainingSessionPlan(for: attempts)

        XCTAssertEqual(plan.title, "جلسة تقليل النزيف".localized)
        XCTAssertEqual(plan.targetAverageExpectedImpact, 0)
        XCTAssertEqual(plan.successMetric, "هدف الجلسة: متوسط أثر غير سلبي.".localized)
    }

    func testTrainingSessionPlanStabilizesInconsistentReading() {
        let attempts = [
            attempt(daysAgo: 6, correct: true, impact: 3),
            attempt(daysAgo: 5, correct: false, impact: -2),
            attempt(daysAgo: 4, correct: false, impact: -2),
            attempt(daysAgo: 3, correct: true, impact: 4),
            attempt(daysAgo: 2, correct: true, impact: 2),
            attempt(daysAgo: 1, correct: false, impact: -1)
        ]

        let plan = WhatToPlayStatsAnalyzer.trainingSessionPlan(for: attempts)

        XCTAssertEqual(plan.title, "جلسة تثبيت القراءة".localized)
        XCTAssertEqual(plan.scenarioCount, 4)
        XCTAssertEqual(plan.targetAverageExpectedImpact, 1)
        XCTAssertEqual(plan.successMetric, "هدف الجلسة: 3 إجابات صحيحة من 4.".localized)
    }

    func testNextScenarioRecommendationUsesFocusTrainingPriorityWhenAvailable() {
        let attempts = [
            attempt(daysAgo: 6, correct: false, impact: -1, bestImpact: 1, focusKind: .openingLead),
            attempt(daysAgo: 5, correct: true, impact: 1, bestImpact: 1, focusKind: .openingLead),
            attempt(daysAgo: 4, correct: false, impact: -8, bestImpact: 4, focusKind: .trumpPressure),
            attempt(daysAgo: 3, correct: true, impact: 2, bestImpact: 2, focusKind: .trumpPressure),
            attempt(daysAgo: 2, correct: false, impact: -3, bestImpact: 2, focusKind: .followSuit),
            attempt(daysAgo: 1, correct: true, impact: 2, bestImpact: 2, focusKind: .followSuit)
        ]

        let recommendation = WhatToPlayStatsAnalyzer.nextScenarioRecommendation(for: attempts)

        XCTAssertEqual(recommendation.focusKind, .trumpPressure)
        XCTAssertEqual(recommendation.title, "الموقف القادم".localized)
        XCTAssertEqual(recommendation.iconName, "crown.fill")
        XCTAssertTrue(recommendation.detail.contains("ضغط الحكم".localized))
    }

    func testNextScenarioRecommendationFallsBackToSessionPlanWithoutFocusPriority() {
        let recommendation = WhatToPlayStatsAnalyzer.nextScenarioRecommendation(for: [])

        XCTAssertEqual(recommendation.difficulty, .easy)
        XCTAssertNil(recommendation.focusKind)
        XCTAssertEqual(recommendation.title, "الموقف القادم".localized)
        XCTAssertEqual(recommendation.iconName, "play.rectangle.fill")
    }

    func testTrainingSessionProgressStartsNotStartedWithoutMatchingAttempts() {
        let plan = sessionPlan(difficulty: .hard, count: 3, target: 67)
        let attempts = [
            attempt(daysAgo: 1, difficulty: .easy, correct: true, impact: 2)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.state, .notStarted)
        XCTAssertEqual(progress.completedAttempts, 0)
        XCTAssertEqual(progress.targetAttempts, 3)
        XCTAssertFalse(progress.accuracyTargetMet)
        XCTAssertEqual(progress.correctAttemptsNeededForTarget, 2)
        XCTAssertEqual(progress.bestPossibleAccuracyPercent, 100)
        XCTAssertTrue(progress.accuracyTargetReachable)
        XCTAssertEqual(progress.totalExpectedImpact, 0)
        XCTAssertEqual(progress.averageExpectedImpact, 0)
        XCTAssertNil(progress.bestExpectedImpact)
        XCTAssertNil(progress.bestExpectedImpactCard)
        XCTAssertNil(progress.bestExpectedImpactSeed)
        XCTAssertNil(progress.worstExpectedImpact)
        XCTAssertNil(progress.worstExpectedImpactCard)
        XCTAssertNil(progress.worstExpectedImpactSeed)
        XCTAssertFalse(progress.impactTargetMet)
        XCTAssertEqual(progress.averageExpectedImpactGap, 0)
        XCTAssertEqual(progress.expectedImpactNeededForTarget, 0)
        XCTAssertEqual(progress.expectedImpactNeededPerRemainingAttempt, 0)
        XCTAssertFalse(progress.impactRecoveryHighPressure)
        XCTAssertEqual(progress.lostExpectedPoints, 0)
        XCTAssertEqual(progress.averageLostExpectedPoints, 0)
        XCTAssertEqual(progress.lostProjectedTeamPoints, 0)
        XCTAssertEqual(progress.averageLostProjectedTeamPoints, 0)
        XCTAssertEqual(progress.projectedTeamPointAttempts, 0)
        XCTAssertEqual(progress.projectedSecondBestComparisonAttempts, 0)
        XCTAssertEqual(progress.lostProjectedAgainstSecondBestPoints, 0)
        XCTAssertEqual(progress.averageProjectedSecondBestGap, 0)
        XCTAssertEqual(progress.valueCapturePercent, 0)
        XCTAssertEqual(progress.valueCaptureAttempts, 0)
        XCTAssertEqual(progress.impactTitle, "الأثر غير محسوب بعد".localized)
        XCTAssertEqual(progress.impactIconName, "chart.line.uptrend.xyaxis")
        XCTAssertNil(progress.reviewItem)
        XCTAssertEqual(progress.remainingAttempts, 3)
        XCTAssertEqual(progress.title, "ابدأ الجلسة".localized)
        XCTAssertEqual(progress.nextStepTitle, "الخطوة التالية".localized)
        XCTAssertEqual(progress.nextStepIconName, "play.circle.fill")
        XCTAssertEqual(progress.gradePercent, 0)
        XCTAssertEqual(progress.gradeAccuracyComponent, 0)
        XCTAssertEqual(progress.gradeImpactComponent, 0)
        XCTAssertEqual(progress.gradeTitle, "لا يوجد تقييم بعد".localized)
        XCTAssertEqual(progress.gradeReasonTitle, "سبب التقييم".localized)
        XCTAssertEqual(progress.gradeReasonDetail, "لا توجد محاولة في هذه الجلسة حتى الآن.".localized)
    }

    func testTrainingSessionProgressCountsRecentMatchingDifficultyOnly() {
        let plan = sessionPlan(difficulty: .medium, count: 4, target: 75)
        let attempts = [
            attempt(daysAgo: 5, difficulty: .easy, correct: false, impact: -6, bestImpact: 8),
            attempt(daysAgo: 4, difficulty: .hard, correct: true, impact: 4, bestImpact: 4),
            attempt(daysAgo: 3, difficulty: .medium, correct: true, impact: 4, bestImpact: 4, selectedCard: PlayingCard(suit: .diamonds, rank: .ace)),
            attempt(daysAgo: 2, difficulty: .medium, correct: false, impact: -2, bestImpact: 5, selectedCard: PlayingCard(suit: .hearts, rank: .seven)),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: 3, bestImpact: 3, selectedCard: PlayingCard(suit: .spades, rank: .king))
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.state, .inProgress)
        XCTAssertEqual(progress.completedAttempts, 3)
        XCTAssertEqual(progress.correctAttempts, 2)
        XCTAssertEqual(progress.accuracyPercent, 67)
        XCTAssertFalse(progress.accuracyTargetMet)
        XCTAssertEqual(progress.correctAttemptsNeededForTarget, 1)
        XCTAssertEqual(progress.bestPossibleAccuracyPercent, 75)
        XCTAssertTrue(progress.accuracyTargetReachable)
        XCTAssertEqual(progress.totalExpectedImpact, 5)
        XCTAssertEqual(progress.averageExpectedImpact, 2)
        XCTAssertEqual(progress.bestExpectedImpact, 4)
        XCTAssertEqual(progress.bestExpectedImpactCard, PlayingCard(suit: .diamonds, rank: .ace))
        XCTAssertEqual(progress.bestExpectedImpactSeed, 3)
        XCTAssertEqual(progress.worstExpectedImpact, -2)
        XCTAssertEqual(progress.worstExpectedImpactCard, PlayingCard(suit: .hearts, rank: .seven))
        XCTAssertEqual(progress.worstExpectedImpactSeed, 2)
        XCTAssertTrue(progress.impactTargetMet)
        XCTAssertEqual(progress.averageExpectedImpactGap, 0)
        XCTAssertEqual(progress.expectedImpactNeededForTarget, 0)
        XCTAssertEqual(progress.expectedImpactNeededPerRemainingAttempt, 0)
        XCTAssertFalse(progress.impactRecoveryHighPressure)
        XCTAssertEqual(progress.lostExpectedPoints, 7)
        XCTAssertEqual(progress.averageLostExpectedPoints, 2)
        XCTAssertEqual(progress.lostProjectedTeamPoints, 0)
        XCTAssertEqual(progress.averageLostProjectedTeamPoints, 0)
        XCTAssertEqual(progress.projectedTeamPointAttempts, 0)
        XCTAssertEqual(progress.projectedSecondBestComparisonAttempts, 0)
        XCTAssertEqual(progress.lostProjectedAgainstSecondBestPoints, 0)
        XCTAssertEqual(progress.averageProjectedSecondBestGap, 0)
        XCTAssertEqual(progress.valueCaptureAttempts, 3)
        XCTAssertEqual(progress.valueCapturePercent, 58)
        XCTAssertEqual(progress.impactTitle, "أثر الجلسة رابح".localized)
        XCTAssertEqual(progress.impactIconName, "checkmark.seal.fill")
        XCTAssertEqual(progress.reviewItem?.seed, 2)
        XCTAssertEqual(progress.remainingAttempts, 1)
        XCTAssertEqual(progress.nextStepTitle, "أكمل الدفعة".localized)
        XCTAssertEqual(progress.nextStepIconName, "timer.circle.fill")
        XCTAssertEqual(progress.gradePercent, 69)
        XCTAssertEqual(progress.gradeAccuracyComponent, 67)
        XCTAssertEqual(progress.gradeImpactComponent, 70)
        XCTAssertEqual(progress.gradeTitle, "جلسة تحتاج تثبيت".localized)
        XCTAssertEqual(progress.gradeReasonTitle, "التقييم متوازن".localized)
    }

    func testTrainingSessionProgressFiltersByTargetGameMode() {
        let plan = sessionPlan(difficulty: .medium, gameMode: .hokum, count: 4, target: 75)
        let attempts = [
            attempt(daysAgo: 4, difficulty: .medium, correct: true, impact: 5, bestImpact: 5, gameMode: .sun),
            attempt(daysAgo: 3, difficulty: .medium, correct: true, impact: 4, bestImpact: 4, gameMode: .hokum),
            attempt(daysAgo: 2, difficulty: .medium, correct: false, impact: -3, bestImpact: 3, gameMode: .sun),
            attempt(daysAgo: 1, difficulty: .medium, correct: false, impact: -2, bestImpact: 5, gameMode: .hokum)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.completedAttempts, 2)
        XCTAssertEqual(progress.correctAttempts, 1)
        XCTAssertEqual(progress.totalExpectedImpact, 2)
        XCTAssertEqual(progress.reviewItem?.gameMode, .hokum)
    }

    func testTrainingSessionProgressCountsUniqueScenarioSeedsOnly() {
        let plan = sessionPlan(difficulty: .medium, count: 3, target: 67)
        let duplicateSeed: UInt64 = 77
        let latestDuplicateCard = PlayingCard(suit: .hearts, rank: .seven)
        let attempts = [
            attempt(daysAgo: 3, difficulty: .medium, correct: true, impact: 4, bestImpact: 4, seed: 11),
            attempt(daysAgo: 2, difficulty: .medium, correct: true, impact: 8, bestImpact: 8, selectedCard: PlayingCard(suit: .spades, rank: .ace), seed: duplicateSeed),
            attempt(daysAgo: 1, difficulty: .medium, correct: false, impact: -6, bestImpact: 4, selectedCard: latestDuplicateCard, seed: duplicateSeed)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.state, .inProgress)
        XCTAssertEqual(progress.completedAttempts, 2)
        XCTAssertEqual(progress.correctAttempts, 1)
        XCTAssertEqual(progress.bestExpectedImpact, 4)
        XCTAssertEqual(progress.worstExpectedImpact, -6)
        XCTAssertEqual(progress.worstExpectedImpactCard, latestDuplicateCard)
        XCTAssertEqual(progress.remainingAttempts, 1)
    }

    func testTrainingSessionProgressTracksProjectedLossForSessionAttemptsOnly() {
        let plan = sessionPlan(difficulty: .medium, count: 3, target: 67)
        let attempts = [
            attempt(daysAgo: 4, difficulty: .hard, correct: false, impact: -2, bestImpact: 4, projectedTeamPoints: 30, bestProjectedTeamPoints: 80, secondBestProjectedTeamPoints: 76),
            attempt(daysAgo: 3, difficulty: .medium, correct: false, impact: 1, bestImpact: 4, projectedTeamPoints: 58, bestProjectedTeamPoints: 74, secondBestProjectedTeamPoints: 70),
            attempt(daysAgo: 2, difficulty: .medium, correct: true, impact: 3, bestImpact: 3, projectedTeamPoints: 76, bestProjectedTeamPoints: 76, secondBestProjectedTeamPoints: 72),
            attempt(daysAgo: 1, difficulty: .medium, correct: false, impact: 2, bestImpact: 4, projectedTeamPoints: 60, bestProjectedTeamPoints: 72, secondBestProjectedTeamPoints: 68)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.projectedTeamPointAttempts, 3)
        XCTAssertEqual(progress.lostProjectedTeamPoints, 28)
        XCTAssertEqual(progress.averageLostProjectedTeamPoints, 9)
        XCTAssertEqual(progress.projectedSecondBestComparisonAttempts, 3)
        XCTAssertEqual(progress.lostProjectedAgainstSecondBestPoints, 20)
        XCTAssertEqual(progress.averageProjectedSecondBestGap, 7)
    }

    func testTrainingSessionGradePenalizesProjectedRoundLoss() {
        let plan = sessionPlan(difficulty: .medium, count: 3, target: 67)
        let attempts = [
            attempt(daysAgo: 3, difficulty: .medium, correct: true, impact: 4, bestImpact: 4, projectedTeamPoints: 62, bestProjectedTeamPoints: 72),
            attempt(daysAgo: 2, difficulty: .medium, correct: true, impact: 4, bestImpact: 4, projectedTeamPoints: 66, bestProjectedTeamPoints: 76),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: 4, bestImpact: 4, projectedTeamPoints: 70, bestProjectedTeamPoints: 80)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.averageLostProjectedTeamPoints, 10)
        XCTAssertEqual(progress.gradeAccuracyComponent, 100)
        XCTAssertEqual(progress.gradeImpactComponent, 50)
        XCTAssertEqual(progress.gradePercent, 75)
        XCTAssertEqual(progress.gradeReasonTitle, "المحاكاة تخفض التقييم".localized)
        XCTAssertTrue(progress.gradeReasonDetail.contains("متوسط فاقد المحاكاة".localized))
    }

    func testTrainingSessionProgressReportsImpactNeededPerRemainingAttempt() {
        let plan = sessionPlan(difficulty: .medium, count: 4, target: 50, impactTarget: 2)
        let attempts = [
            attempt(daysAgo: 2, difficulty: .medium, correct: true, impact: 1),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: 2)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.state, .inProgress)
        XCTAssertEqual(progress.expectedImpactNeededForTarget, 5)
        XCTAssertEqual(progress.expectedImpactNeededPerRemainingAttempt, 3)
        XCTAssertFalse(progress.impactRecoveryHighPressure)
        XCTAssertFalse(progress.impactTargetMet)
    }

    func testTrainingSessionProgressFlagsHighImpactRecoveryPressure() {
        let plan = sessionPlan(difficulty: .medium, count: 4, target: 50, impactTarget: 2)
        let attempts = [
            attempt(daysAgo: 2, difficulty: .medium, correct: true, impact: -4),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: 1)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.state, .inProgress)
        XCTAssertEqual(progress.expectedImpactNeededForTarget, 11)
        XCTAssertEqual(progress.expectedImpactNeededPerRemainingAttempt, 6)
        XCTAssertTrue(progress.impactRecoveryHighPressure)
    }

    func testTrainingSessionProgressNextStepCountsNeededCorrectAnswers() {
        let plan = sessionPlan(difficulty: .medium, count: 5, target: 60)
        let attempts = [
            attempt(daysAgo: 2, difficulty: .medium, correct: true, impact: 2),
            attempt(daysAgo: 1, difficulty: .medium, correct: false, impact: -1)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.state, .inProgress)
        XCTAssertEqual(progress.remainingAttempts, 3)
        XCTAssertEqual(progress.nextStepTitle, "أكمل الدفعة".localized)
        XCTAssertEqual(progress.nextStepIconName, "timer.circle.fill")
        XCTAssertTrue(progress.nextStepDetail.contains("2"))
    }

    func testTrainingSessionProgressNextStepTargetsLostValueWhileInProgress() {
        let plan = sessionPlan(difficulty: .medium, count: 4, target: 50)
        let attempts = [
            attempt(daysAgo: 2, difficulty: .medium, correct: true, impact: 1, bestImpact: 8),
            attempt(daysAgo: 1, difficulty: .medium, correct: false, impact: 2, bestImpact: 7)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.state, .inProgress)
        XCTAssertEqual(progress.averageLostExpectedPoints, 6)
        XCTAssertEqual(progress.nextStepTitle, "قلل النقاط الضائعة".localized)
        XCTAssertEqual(progress.nextStepIconName, "chart.bar.doc.horizontal.fill")
    }

    func testTrainingSessionProgressImpactExtremeCardsUseNewestAttemptOnTie() {
        let plan = sessionPlan(difficulty: .medium, count: 4, target: 50)
        let newestBest = PlayingCard(suit: .spades, rank: .ace)
        let newestWorst = PlayingCard(suit: .hearts, rank: .seven)
        let attempts = [
            attempt(daysAgo: 4, difficulty: .medium, correct: true, impact: 5, selectedCard: PlayingCard(suit: .clubs, rank: .ace)),
            attempt(daysAgo: 3, difficulty: .medium, correct: false, impact: -4, selectedCard: PlayingCard(suit: .diamonds, rank: .seven)),
            attempt(daysAgo: 2, difficulty: .medium, correct: true, impact: 5, selectedCard: newestBest),
            attempt(daysAgo: 1, difficulty: .medium, correct: false, impact: -4, selectedCard: newestWorst)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.bestExpectedImpact, 5)
        XCTAssertEqual(progress.bestExpectedImpactCard, newestBest)
        XCTAssertEqual(progress.bestExpectedImpactSeed, 2)
        XCTAssertEqual(progress.worstExpectedImpact, -4)
        XCTAssertEqual(progress.worstExpectedImpactCard, newestWorst)
        XCTAssertEqual(progress.worstExpectedImpactSeed, 1)
    }

    func testTrainingSessionProgressNextStepWarnsWhenAccuracyTargetIsUnreachable() {
        let plan = sessionPlan(difficulty: .medium, count: 4, target: 75)
        let attempts = [
            attempt(daysAgo: 3, difficulty: .medium, correct: false, impact: -3),
            attempt(daysAgo: 2, difficulty: .medium, correct: true, impact: 2),
            attempt(daysAgo: 1, difficulty: .medium, correct: false, impact: -2)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.state, .inProgress)
        XCTAssertEqual(progress.remainingAttempts, 1)
        XCTAssertEqual(progress.bestPossibleAccuracyPercent, 50)
        XCTAssertFalse(progress.accuracyTargetReachable)
        XCTAssertEqual(progress.nextStepTitle, "هدف الدقة تعثر".localized)
        XCTAssertEqual(progress.nextStepIconName, "exclamationmark.triangle.fill")
    }

    func testTrainingSessionProgressCountsMatchingDifficultyAndFocusOnly() {
        let plan = sessionPlan(difficulty: .medium, focusKind: .trumpPressure, count: 3, target: 67)
        let attempts = [
            attempt(daysAgo: 5, difficulty: .medium, correct: false, impact: -6, focusKind: .openingLead),
            attempt(daysAgo: 4, difficulty: .hard, correct: true, impact: 4, focusKind: .trumpPressure),
            attempt(daysAgo: 3, difficulty: .medium, correct: true, impact: 4, focusKind: .trumpPressure),
            attempt(daysAgo: 2, difficulty: .medium, correct: false, impact: -2),
            attempt(daysAgo: 1, difficulty: .medium, correct: false, impact: -3, focusKind: .trumpPressure)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.state, .inProgress)
        XCTAssertEqual(progress.completedAttempts, 2)
        XCTAssertEqual(progress.correctAttempts, 1)
        XCTAssertEqual(progress.accuracyPercent, 50)
        XCTAssertFalse(progress.accuracyTargetMet)
        XCTAssertEqual(progress.correctAttemptsNeededForTarget, 1)
        XCTAssertEqual(progress.totalExpectedImpact, 1)
        XCTAssertEqual(progress.averageExpectedImpact, 1)
        XCTAssertEqual(progress.bestExpectedImpact, 4)
        XCTAssertEqual(progress.worstExpectedImpact, -3)
        XCTAssertTrue(progress.impactTargetMet)
        XCTAssertEqual(progress.averageExpectedImpactGap, 0)
        XCTAssertEqual(progress.valueCaptureAttempts, 0)
        XCTAssertEqual(progress.valueCapturePercent, 0)
        XCTAssertEqual(progress.reviewItem?.seed, 1)
        XCTAssertEqual(progress.remainingAttempts, 1)
    }

    func testTrainingSessionProgressAchievesTargetWhenPlannedBatchPasses() {
        let plan = sessionPlan(difficulty: .easy, count: 3, target: 67)
        let attempts = [
            attempt(daysAgo: 4, difficulty: .easy, correct: false, impact: -8),
            attempt(daysAgo: 3, difficulty: .easy, correct: true, impact: 2),
            attempt(daysAgo: 2, difficulty: .easy, correct: true, impact: 4),
            attempt(daysAgo: 1, difficulty: .easy, correct: false, impact: -1)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.state, .achieved)
        XCTAssertEqual(progress.completedAttempts, 3)
        XCTAssertEqual(progress.correctAttempts, 2)
        XCTAssertEqual(progress.accuracyPercent, 67)
        XCTAssertTrue(progress.accuracyTargetMet)
        XCTAssertEqual(progress.correctAttemptsNeededForTarget, 0)
        XCTAssertEqual(progress.totalExpectedImpact, 5)
        XCTAssertEqual(progress.averageExpectedImpact, 2)
        XCTAssertEqual(progress.bestExpectedImpact, 4)
        XCTAssertEqual(progress.worstExpectedImpact, -1)
        XCTAssertTrue(progress.impactTargetMet)
        XCTAssertEqual(progress.averageExpectedImpactGap, 0)
        XCTAssertEqual(progress.reviewItem?.seed, 1)
        XCTAssertEqual(progress.title, "هدف الجلسة تحقق".localized)
        XCTAssertEqual(progress.nextStepTitle, "انتقل للتحدي التالي".localized)
        XCTAssertEqual(progress.gradePercent, 69)
        XCTAssertEqual(progress.gradeAccuracyComponent, 67)
        XCTAssertEqual(progress.gradeImpactComponent, 70)
        XCTAssertEqual(progress.gradeTitle, "جلسة تحتاج تثبيت".localized)
        XCTAssertEqual(progress.gradeReasonTitle, "التقييم متوازن".localized)
    }

    func testTrainingSessionProgressRequiresImpactTargetForSuccess() {
        let plan = sessionPlan(difficulty: .easy, count: 3, target: 67, impactTarget: 2)
        let attempts = [
            attempt(daysAgo: 3, difficulty: .easy, correct: true, impact: 1),
            attempt(daysAgo: 2, difficulty: .easy, correct: true, impact: 1),
            attempt(daysAgo: 1, difficulty: .easy, correct: false, impact: 0)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.state, .needsRepeat)
        XCTAssertTrue(progress.accuracyTargetMet)
        XCTAssertFalse(progress.impactTargetMet)
        XCTAssertEqual(progress.correctAttemptsNeededForTarget, 0)
        XCTAssertEqual(progress.averageExpectedImpact, 1)
        XCTAssertEqual(progress.averageExpectedImpactGap, 1)
        XCTAssertEqual(progress.expectedImpactNeededForTarget, 4)
        XCTAssertEqual(progress.expectedImpactNeededPerRemainingAttempt, 0)
        XCTAssertFalse(progress.impactRecoveryHighPressure)
        XCTAssertEqual(progress.detail, "أكملتها بدقة كافية، لكن متوسط الأثر أقل من هدف الخطة؛ راجع الاختيارات القريبة قبل تكرارها.".localized)
        XCTAssertEqual(progress.nextStepTitle, "راجع جودة القرار".localized)
        XCTAssertEqual(progress.gradePercent, 54)
        XCTAssertEqual(progress.gradeAccuracyComponent, 67)
        XCTAssertEqual(progress.gradeImpactComponent, 40)
        XCTAssertEqual(progress.gradeTitle, "جلسة تحتاج تثبيت".localized)
        XCTAssertEqual(progress.gradeReasonTitle, "الأثر يخفض التقييم".localized)
    }

    func testTrainingSessionProgressRequiresCostlyDecisionTargetForSuccess() {
        let plan = sessionPlan(
            difficulty: .medium,
            count: 3,
            target: 67,
            maxCostlyDecisions: 0
        )
        let attempts = [
            attempt(daysAgo: 3, difficulty: .medium, correct: false, impact: 1, bestImpact: 12),
            attempt(daysAgo: 2, difficulty: .medium, correct: true, impact: 3, bestImpact: 3),
            attempt(daysAgo: 1, difficulty: .medium, correct: true, impact: 3, bestImpact: 3)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.state, .needsRepeat)
        XCTAssertEqual(progress.costlyDecisions, 1)
        XCTAssertEqual(progress.maxCostlyDecisions, 0)
        XCTAssertFalse(progress.costlyDecisionTargetMet)
        XCTAssertTrue(progress.accuracyTargetMet)
        XCTAssertTrue(progress.impactTargetMet)
        XCTAssertEqual(progress.detail, "أكملتها، لكن عدد القرارات المكلفة أعلى من هدف الخطة؛ أعدها وراجع Replay أفضل قرار.".localized)
        XCTAssertEqual(progress.nextStepTitle, "قلل القرارات المكلفة".localized)
        XCTAssertEqual(progress.nextStepIconName, "exclamationmark.triangle.fill")
    }

    func testTrainingSessionProgressRequestsRepeatWhenAccuracyMissesTarget() {
        let plan = sessionPlan(difficulty: .hard, count: 4, target: 75)
        let attempts = [
            attempt(daysAgo: 4, difficulty: .hard, correct: true, impact: 3),
            attempt(daysAgo: 3, difficulty: .hard, correct: false, impact: -3),
            attempt(daysAgo: 2, difficulty: .hard, correct: true, impact: 2),
            attempt(daysAgo: 1, difficulty: .hard, correct: false, impact: -5)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.state, .needsRepeat)
        XCTAssertEqual(progress.completedAttempts, 4)
        XCTAssertEqual(progress.correctAttempts, 2)
        XCTAssertEqual(progress.accuracyPercent, 50)
        XCTAssertFalse(progress.accuracyTargetMet)
        XCTAssertEqual(progress.correctAttemptsNeededForTarget, 1)
        XCTAssertEqual(progress.totalExpectedImpact, -3)
        XCTAssertEqual(progress.averageExpectedImpact, -1)
        XCTAssertFalse(progress.impactTargetMet)
        XCTAssertEqual(progress.averageExpectedImpactGap, 1)
        XCTAssertEqual(progress.impactTitle, "أثر الجلسة سلبي".localized)
        XCTAssertEqual(progress.impactIconName, "exclamationmark.triangle.fill")
        XCTAssertEqual(progress.reviewItem?.seed, 1)
        XCTAssertEqual(progress.remainingAttempts, 0)
        XCTAssertEqual(progress.title, "أعد الجلسة".localized)
        XCTAssertEqual(progress.nextStepTitle, "أعد نفس الخطة".localized)
        XCTAssertEqual(progress.gradePercent, 45)
        XCTAssertEqual(progress.gradeAccuracyComponent, 50)
        XCTAssertEqual(progress.gradeImpactComponent, 40)
        XCTAssertEqual(progress.gradeTitle, "جلسة تحتاج إعادة".localized)
        XCTAssertEqual(progress.gradeReasonTitle, "التقييم متوازن".localized)
    }

    func testTrainingSessionProgressRepeatStepTargetsLostValue() {
        let plan = sessionPlan(difficulty: .medium, count: 3, target: 67)
        let attempts = [
            attempt(daysAgo: 3, difficulty: .medium, correct: true, impact: 1, bestImpact: 8),
            attempt(daysAgo: 2, difficulty: .medium, correct: false, impact: 2, bestImpact: 7),
            attempt(daysAgo: 1, difficulty: .medium, correct: false, impact: 1, bestImpact: 6)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.state, .needsRepeat)
        XCTAssertEqual(progress.averageLostExpectedPoints, 6)
        XCTAssertEqual(progress.nextStepTitle, "راجع القيمة الضائعة".localized)
        XCTAssertEqual(progress.nextStepIconName, "drop.fill")
    }

    func testTrainingSessionProgressRepeatStepTargetsProjectedSecondBestLoss() {
        let plan = sessionPlan(difficulty: .medium, count: 3, target: 67)
        let attempts = [
            attempt(
                daysAgo: 3,
                difficulty: .medium,
                correct: true,
                impact: 3,
                bestImpact: 3,
                projectedTeamPoints: 40,
                secondBestProjectedTeamPoints: 48
            ),
            attempt(
                daysAgo: 2,
                difficulty: .medium,
                correct: false,
                impact: 3,
                bestImpact: 3,
                projectedTeamPoints: 41,
                secondBestProjectedTeamPoints: 49
            ),
            attempt(
                daysAgo: 1,
                difficulty: .medium,
                correct: false,
                impact: 3,
                bestImpact: 3,
                projectedTeamPoints: 42,
                secondBestProjectedTeamPoints: 50
            )
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.state, .needsRepeat)
        XCTAssertEqual(progress.averageLostExpectedPoints, 0)
        XCTAssertEqual(progress.averageProjectedSecondBestGap, 8)
        XCTAssertEqual(progress.nextStepTitle, "راجع القيمة الضائعة".localized)
        XCTAssertTrue(progress.nextStepDetail.contains("\("متوسط الضياع".localized): 8"))
    }

    func testTrainingSessionGradeReasonIdentifiesAccuracyWeakness() {
        let plan = sessionPlan(difficulty: .medium, count: 4, target: 75)
        let attempts = [
            attempt(daysAgo: 4, difficulty: .medium, correct: false, impact: 5),
            attempt(daysAgo: 3, difficulty: .medium, correct: false, impact: 5),
            attempt(daysAgo: 2, difficulty: .medium, correct: true, impact: 5),
            attempt(daysAgo: 1, difficulty: .medium, correct: false, impact: 5)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.state, .needsRepeat)
        XCTAssertEqual(progress.gradePercent, 63)
        XCTAssertEqual(progress.gradeAccuracyComponent, 25)
        XCTAssertEqual(progress.gradeImpactComponent, 100)
        XCTAssertEqual(progress.gradeReasonTitle, "الدقة تخفض التقييم".localized)
    }

    func testTrainingSessionProgressReviewItemComesFromCurrentPlannedBatch() {
        let plan = sessionPlan(difficulty: .medium, focusKind: .followSuit, count: 3, target: 67)
        let attempts = [
            attempt(daysAgo: 8, difficulty: .medium, correct: false, impact: -20, bestImpact: 10, focusKind: .followSuit),
            attempt(daysAgo: 7, difficulty: .hard, correct: false, impact: -12, bestImpact: 8, focusKind: .followSuit),
            attempt(daysAgo: 6, difficulty: .medium, correct: false, impact: -10, bestImpact: 6, focusKind: .trumpPressure),
            attempt(daysAgo: 3, difficulty: .medium, correct: true, impact: 3, bestImpact: 3, focusKind: .followSuit),
            attempt(daysAgo: 2, difficulty: .medium, correct: false, impact: -3, bestImpact: 4, focusKind: .followSuit),
            attempt(daysAgo: 1, difficulty: .medium, correct: false, impact: -1, bestImpact: 2, focusKind: .followSuit)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        XCTAssertEqual(progress.completedAttempts, 3)
        XCTAssertEqual(progress.reviewItem?.seed, 2)
        XCTAssertEqual(progress.reviewItem?.lostExpectedPoints, 7)
        XCTAssertEqual(progress.reviewItem?.focusKind, .followSuit)
    }

    func testTrainingSessionReviewStartsWithDeterministicPlanSeed() {
        let plan = sessionPlan(difficulty: .easy, focusKind: .openingLead, gameMode: .sun, count: 3, target: 67)

        let review = WhatToPlayStatsAnalyzer.trainingSessionReview(for: [], plan: plan)

        XCTAssertEqual(review.action, .start)
        XCTAssertEqual(review.title, "ابدأ خطة المدرب".localized)
        XCTAssertEqual(review.nextSeed, WhatToPlayStatsAnalyzer.nextTrainingSessionSeed(for: [], plan: plan))
        XCTAssertEqual(review.difficulty, .easy)
        XCTAssertEqual(review.focusKind, .openingLead)
        XCTAssertEqual(review.gameMode, .sun)
        XCTAssertEqual(
            review.contextLine,
            "\("المستوى".localized): \("سهل".localized) · \("تركيز التدريب".localized): \("افتتاح الأكلة".localized) · \("النمط".localized): \("صن".localized)"
        )
        XCTAssertNil(review.replaySeed)
        XCTAssertNil(review.recommendedCard)
        XCTAssertEqual(review.expectedImprovement, 0)
    }

    func testTrainingSessionReviewReplaysWorstMistakeBeforeRepeating() {
        let plan = sessionPlan(difficulty: .medium, focusKind: .followSuit, gameMode: .hokum, count: 3, target: 67)
        let attempts = [
            attempt(daysAgo: 3, difficulty: .medium, correct: true, impact: 2, bestImpact: 2, focusKind: .followSuit, gameMode: .hokum, seed: 101),
            attempt(daysAgo: 2, difficulty: .medium, correct: false, impact: -4, bestImpact: 5, focusKind: .followSuit, gameMode: .hokum, seed: 202),
            attempt(daysAgo: 1, difficulty: .medium, correct: false, impact: 1, bestImpact: 4, focusKind: .followSuit, gameMode: .hokum, seed: 303)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)
        let review = WhatToPlayStatsAnalyzer.trainingSessionReview(for: progress, attempts: attempts, plan: plan)

        XCTAssertEqual(review.action, .replayMistake)
        XCTAssertEqual(review.title, "راجع الخطأ الأعلى أثرًا".localized)
        XCTAssertEqual(review.replaySeed, progress.reviewItem?.seed)
        XCTAssertEqual(review.replaySeed, 202)
        XCTAssertEqual(review.nextSeed, 202)
        XCTAssertEqual(review.difficulty, .medium)
        XCTAssertEqual(review.focusKind, .followSuit)
        XCTAssertEqual(review.gameMode, .hokum)
        XCTAssertEqual(review.recommendedCard, PlayingCard(suit: .clubs, rank: .seven))
        XCTAssertEqual(review.expectedImprovement, 9)
        XCTAssertTrue(["\("ابدأ بإعادة موقف".localized) 202", "\("اختيارك".localized): \(PlayingCard(suit: .clubs, rank: .seven).accessibilityName)", "\("أفضل ورقة".localized): \(PlayingCard(suit: .clubs, rank: .seven).accessibilityName)", "\("الفاقد".localized): 9"].allSatisfy { review.detail.contains($0) })
        XCTAssertEqual(
            review.contextLine,
            "\("المستوى".localized): \("متوسط".localized) · \("تركيز التدريب".localized): \("اتباع اللون".localized) · \("النمط".localized): \("حكم".localized)"
        )
    }

    func testTrainingSessionReviewMovesToNextChallengeAfterAchievement() {
        let plan = sessionPlan(difficulty: .easy, count: 3, target: 67, impactTarget: 1)
        let attempts = [
            attempt(daysAgo: 3, difficulty: .easy, correct: true, impact: 2, bestImpact: 2, seed: 11),
            attempt(daysAgo: 2, difficulty: .easy, correct: true, impact: 2, bestImpact: 2, seed: 12),
            attempt(daysAgo: 1, difficulty: .easy, correct: true, impact: 2, bestImpact: 2, seed: 13)
        ]

        let review = WhatToPlayStatsAnalyzer.trainingSessionReview(for: attempts, plan: plan)

        XCTAssertEqual(review.action, .nextChallenge)
        XCTAssertEqual(review.title, "ابدأ تحدي أقوى".localized)
        XCTAssertEqual(review.difficulty, .hard)
        XCTAssertNotNil(review.nextSeed)
        XCTAssertNil(review.replaySeed)
        XCTAssertTrue(review.contextLine.contains("\("النمط".localized):"))
    }

    func testCoachingTipForEmptyAttemptsEncouragesBaseline() {
        let tip = WhatToPlayStatsAnalyzer.coachingTip(for: [])

        XCTAssertEqual(tip.title, "ابدأ القياس".localized)
        XCTAssertEqual(tip.iconName, "target")
    }

    func testCoachingTipForLowAccuracyFocusesOnSlowingDown() {
        let attempts = [
            attempt(daysAgo: 3, correct: false, impact: 2),
            attempt(daysAgo: 2, correct: false, impact: 2),
            attempt(daysAgo: 1, correct: true, impact: 2)
        ]

        let tip = WhatToPlayStatsAnalyzer.coachingTip(for: attempts)

        XCTAssertEqual(tip.title, "خفف السرعة".localized)
    }

    func testCoachingTipForNegativeImpactFocusesOnPointLoss() {
        let attempts = [
            attempt(daysAgo: 3, correct: true, impact: -6),
            attempt(daysAgo: 2, correct: true, impact: -2),
            attempt(daysAgo: 1, correct: false, impact: -4)
        ]

        let tip = WhatToPlayStatsAnalyzer.coachingTip(for: attempts)

        XCTAssertEqual(tip.title, "قلل نزيف النقاط".localized)
    }

    func testCoachingTipForFarChoiceRateFocusesOnFilteringOptions() {
        let attempts = [
            attempt(daysAgo: 4, correct: true, impact: 3, selectedRank: 1),
            attempt(daysAgo: 3, correct: false, impact: 1, selectedRank: 4),
            attempt(daysAgo: 2, correct: false, impact: 2, selectedRank: 3),
            attempt(daysAgo: 1, correct: true, impact: 2, selectedRank: 1)
        ]

        let tip = WhatToPlayStatsAnalyzer.coachingTip(for: attempts)

        XCTAssertEqual(tip.title, "صفِّ الخيارات أولًا".localized)
        XCTAssertEqual(tip.iconName, "line.3.horizontal.decrease.circle.fill")
    }

    func testCoachingTipForCurrentStreakEncouragesHarderPractice() {
        let attempts = [
            attempt(daysAgo: 3, correct: true, impact: 4),
            attempt(daysAgo: 2, correct: true, impact: 2),
            attempt(daysAgo: 1, correct: true, impact: 3)
        ]

        let tip = WhatToPlayStatsAnalyzer.coachingTip(for: attempts)

        XCTAssertEqual(tip.title, "سلسلة ممتازة".localized)
    }

    private func sessionPlan(
        difficulty: WhatToPlayDifficulty,
        focusKind: WhatToPlayScenarioFocusKind? = nil,
        gameMode: GameMode? = nil,
        trumpSuit: Suit? = nil,
        count: Int,
        target: Int,
        impactTarget: Int = 0,
        maxCostlyDecisions: Int? = nil
    ) -> WhatToPlayTrainingSessionPlan {
        WhatToPlayTrainingSessionPlan(
            difficulty: difficulty,
            focusKind: focusKind,
            gameMode: gameMode,
            trumpSuit: trumpSuit,
            scenarioCount: count,
            targetAccuracyPercent: target,
            targetAverageExpectedImpact: impactTarget,
            maxCostlyDecisions: maxCostlyDecisions,
            title: "خطة اختبار",
            detail: "تفاصيل اختبار",
            successMetric: "هدف اختبار",
            iconName: "target"
        )
    }

    private func hokumContext(trumpSuit: Suit) -> WhatToPlayScenarioContext {
        WhatToPlayScenarioContext(
            trickNumber: 3,
            isLeading: false,
            requiredSuit: .hearts,
            playedCardCount: 2,
            legalOptionCount: 3,
            mode: .hokum,
            trumpSuit: trumpSuit,
            hasTrumpInCurrentTrick: false,
            playerTeamTrickPoints: 24,
            opponentTeamTrickPoints: 18,
            playerTeamPointMargin: 6,
            focusKind: .trumpPressure
        )
    }

    private func attempt(
        daysAgo: TimeInterval,
        correct: Bool,
        impact: Int,
        bestImpact: Int? = nil,
        selectedRank: Int? = nil,
        secondBestImpact: Int? = nil,
        focusKind: WhatToPlayScenarioFocusKind? = nil,
        gameMode: GameMode? = nil,
        outcome: WhatToPlayOptionOutcome? = nil,
        impactBreakdown: WhatToPlayOptionImpactBreakdown? = nil,
        selectedCard: PlayingCard = PlayingCard(suit: .clubs, rank: .seven),
        bestSimulationCard: PlayingCard? = nil,
        secondBestSimulationCard: PlayingCard? = nil,
        simulation: WhatToPlayOptionSimulation? = nil,
        projectedTeamPoints: Int? = nil,
        bestProjectedTeamPoints: Int? = nil,
        secondBestProjectedTeamPoints: Int? = nil,
        seed: UInt64? = nil,
        scenarioContext: WhatToPlayScenarioContext? = nil
    ) -> WhatToPlayAttempt {
        attempt(
            daysAgo: daysAgo,
            difficulty: .medium,
            correct: correct,
            impact: impact,
            bestImpact: bestImpact,
            selectedRank: selectedRank,
            secondBestImpact: secondBestImpact,
            focusKind: focusKind,
            gameMode: gameMode,
            outcome: outcome,
            impactBreakdown: impactBreakdown,
            selectedCard: selectedCard,
            bestSimulationCard: bestSimulationCard,
            secondBestSimulationCard: secondBestSimulationCard,
            simulation: simulation,
            projectedTeamPoints: projectedTeamPoints,
            bestProjectedTeamPoints: bestProjectedTeamPoints,
            secondBestProjectedTeamPoints: secondBestProjectedTeamPoints,
            seed: seed,
            scenarioContext: scenarioContext
        )
    }

    private func expertCoverageAttempts(impact: Int = 2, focusKind: WhatToPlayScenarioFocusKind? = nil, gameMode: GameMode? = nil, correctSecond: Bool = true) -> [WhatToPlayAttempt] {
        [attempt(daysAgo: 0, difficulty: .expert, correct: true, impact: impact, focusKind: focusKind, gameMode: gameMode), attempt(daysAgo: 0, difficulty: .expert, correct: correctSecond, impact: impact, focusKind: focusKind, gameMode: gameMode)]
    }

    private func attempt(
        daysAgo: TimeInterval,
        difficulty: WhatToPlayDifficulty,
        correct: Bool,
        impact: Int,
        bestImpact: Int? = nil,
        selectedRank: Int? = nil,
        secondBestCard: PlayingCard? = nil,
        secondBestImpact: Int? = nil,
        focusKind: WhatToPlayScenarioFocusKind? = nil,
        gameMode: GameMode? = nil,
        outcome: WhatToPlayOptionOutcome? = nil,
        impactBreakdown: WhatToPlayOptionImpactBreakdown? = nil,
        selectedCard: PlayingCard = PlayingCard(suit: .clubs, rank: .seven),
        bestSimulationCard: PlayingCard? = nil,
        secondBestSimulationCard: PlayingCard? = nil,
        simulation: WhatToPlayOptionSimulation? = nil,
        projectedTeamPoints: Int? = nil,
        bestProjectedTeamPoints: Int? = nil,
        secondBestProjectedTeamPoints: Int? = nil,
        seed: UInt64? = nil,
        scenarioContext: WhatToPlayScenarioContext? = nil
    ) -> WhatToPlayAttempt {
        WhatToPlayAttempt(
            createdAt: Date(timeIntervalSince1970: 2_000_000 - daysAgo * 86_400),
            difficulty: difficulty,
            seed: seed ?? UInt64(Int(daysAgo)),
            selectedCard: selectedCard,
            bestCard: PlayingCard(suit: .clubs, rank: .seven),
            secondBestCard: secondBestCard,
            bestSimulationCard: bestSimulationCard,
            secondBestSimulationCard: secondBestSimulationCard,
            isCorrect: correct,
            selectedRank: selectedRank,
            expectedImpact: impact,
            bestExpectedImpact: bestImpact,
            secondBestExpectedImpact: secondBestImpact,
            projectedTeamPoints: projectedTeamPoints,
            bestProjectedTeamPoints: bestProjectedTeamPoints,
            secondBestProjectedTeamPoints: secondBestProjectedTeamPoints,
            focusKind: focusKind ?? scenarioContext?.focusKind,
            gameMode: gameMode ?? scenarioContext?.mode,
            outcome: outcome,
            impactBreakdown: impactBreakdown,
            simulation: simulation,
            scenarioContext: scenarioContext
        )
    }

    private func expectedFirstReviewStep(for focus: WhatToPlayScenarioFocusKind) -> String {
        switch focus {
        case .openingLead:
            "قارن هل افتتاحك يكشف قوة يدك مبكرًا أو يحفظها للأكلة القادمة.".localized
        case .followSuit:
            "راجع اللون المطلوب أولًا، ثم اسأل هل تستطيع ربح الأكلة أم يجب تقليل خسارتها.".localized
        case .trumpPressure:
            "افحص الحكم الموجود على الطاولة قبل رمي ورقة عالية أو حكم أعلى.".localized
        case .narrowChoice:
            "عندما تكون الخيارات قليلة، رتّبها حسب أقل خسارة لا حسب أعلى ورقة.".localized
        }
    }

    private func scenarioWithTacticalLeakingChoice() throws -> (WhatToPlayScenario, WhatToPlayOption) {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 3, difficulty: .hard)
        let selected = try XCTUnwrap(scenario.options.first { option in
            option.expectedImpact < 0 && tacticalReasonTitle(for: option.impactBreakdown) != nil
        })
        return (scenario, selected)
    }

    private func expectedTacticalReasonTitle(for breakdown: WhatToPlayOptionImpactBreakdown) -> String {
        guard let title = tacticalReasonTitle(for: breakdown) else {
            XCTFail("Expected tactical reason for generated option")
            return ""
        }
        return title
    }

    private func tacticalReasonTitle(for breakdown: WhatToPlayOptionImpactBreakdown) -> String? {
        if breakdown.completesTrick,
           breakdown.winsForPlayerTeam == false,
           breakdown.trickPointsSwing < 0 {
            return "تغلق الأكلة للخصم".localized
        }

        if !breakdown.completesTrick,
           !breakdown.preservesLead,
           breakdown.playedCardPoints > 0,
           breakdown.immediateImpact < 0 {
            return "ترمي نقاطًا بلا حماية".localized
        }

        if breakdown.preservesLead, breakdown.immediateImpact < 0 {
            return "افتتاح مكلف".localized
        }

        return nil
    }
}

private extension WhatToPlayOptionImpactBreakdown {
    static func opponentTrickClosure(points: Int) -> Self {
        WhatToPlayOptionImpactBreakdown(
            playedCardPoints: points,
            immediateImpact: -points,
            trickPointsSwing: -points,
            completesTrick: true,
            winsForPlayerTeam: false,
            preservesLead: false
        )
    }

    static func unprotectedPointDump(points: Int) -> Self {
        WhatToPlayOptionImpactBreakdown(
            playedCardPoints: points,
            immediateImpact: -points,
            trickPointsSwing: 0,
            completesTrick: false,
            winsForPlayerTeam: nil,
            preservesLead: false
        )
    }

    static func costlyOpeningLead(points: Int) -> Self {
        WhatToPlayOptionImpactBreakdown(
            playedCardPoints: points,
            immediateImpact: -max(1, points),
            trickPointsSwing: 0,
            completesTrick: false,
            winsForPlayerTeam: nil,
            preservesLead: true
        )
    }
}
