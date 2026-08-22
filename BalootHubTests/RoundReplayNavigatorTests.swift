import XCTest
import BalootEngine
@testable import BalootHub

final class RoundReplayNavigatorTests: XCTestCase {
    func testNextTrickStepAdvancesToFirstCompletedTrickBoundary() throws {
        let replay = try makeCompletedReplay(seed: 2_026)

        let next = RoundReplayNavigator.nextTrickStep(
            initialState: replay.initial,
            actions: replay.actions,
            currentStep: 1
        )
        let state = try GameEngine.replay(initialState: replay.initial, actions: replay.actions, upTo: next)

        XCTAssertGreaterThan(next, 1)
        XCTAssertEqual(state.completedTricks.count, 1)
    }

    func testPreviousTrickStepReturnsStableEarlierBoundary() throws {
        let replay = try makeCompletedReplay(seed: 2_026)
        let secondBoundary = RoundReplayNavigator.nextTrickStep(
            initialState: replay.initial,
            actions: replay.actions,
            currentStep: RoundReplayNavigator.nextTrickStep(
                initialState: replay.initial,
                actions: replay.actions,
                currentStep: 1
            )
        )

        let previous = RoundReplayNavigator.previousTrickStep(
            initialState: replay.initial,
            actions: replay.actions,
            currentStep: secondBoundary
        )
        let state = try GameEngine.replay(initialState: replay.initial, actions: replay.actions, upTo: previous)

        XCTAssertLessThan(previous, secondBoundary)
        XCTAssertLessThan(state.completedTricks.count, 2)
    }

    func testReplayNavigationClampsOutOfRangeSteps() throws {
        let replay = try makeCompletedReplay(seed: 77)

        XCTAssertEqual(
            RoundReplayNavigator.previousTrickStep(
                initialState: replay.initial,
                actions: replay.actions,
                currentStep: -10
            ),
            0
        )
        XCTAssertEqual(
            RoundReplayNavigator.nextTrickStep(
                initialState: replay.initial,
                actions: replay.actions,
                currentStep: replay.actions.count + 20
            ),
            replay.actions.count
        )
    }

    func testReplayShareSummaryIsDeterministic() throws {
        let replay = try makeCompletedReplay(seed: 2_026)

        XCTAssertEqual(
            RoundReplayShareSummary.text(initialState: replay.initial, actions: replay.actions),
            RoundReplayShareSummary.text(initialState: replay.initial, actions: replay.actions)
        )
    }

    func testReplayShareSummaryIncludesRoundEventsAndScore() throws {
        let replay = try makeCompletedReplay(seed: 1_445)
        let summary = RoundReplayShareSummary.text(initialState: replay.initial, actions: replay.actions)

        XCTAssertTrue(summary.contains("Replay"))
        XCTAssertTrue(summary.contains("الجولة") || summary.contains("Round"))
        XCTAssertTrue(summary.contains("الموزّع".localized))
        XCTAssertTrue(summary.contains(replay.initial.player(at: replay.initial.dealerSeat)?.name ?? ""))
        XCTAssertTrue(summary.contains("المزايدة") || summary.contains("Bidding"))
        XCTAssertTrue(summary.contains("الجولة 1:") || summary.contains("الجولة 2:"))
        XCTAssertTrue(summary.contains("الأكلات") || summary.contains("Tricks"))
        XCTAssertTrue(summary.contains("نقاط الأكلة") || summary.contains("Trick points"))
        XCTAssertTrue(summary.contains("الفائز بالأكلة") || summary.contains("Trick winner"))
        XCTAssertTrue(summary.contains("النتيجة") || summary.contains("Score"))
        XCTAssertTrue(summary.contains("1."))
        XCTAssertTrue(summary.contains("فريقنا"))
        XCTAssertTrue(summary.contains("الخصم"))
        XCTAssertTrue(summary.contains("لعب") || summary.contains("played"))
        XCTAssertTrue(summary.contains("تحليل قرارات الخبير".localized))
    }

    func testReplayShareSummaryIncludesExpertDecisionReviewWhenAvailable() throws {
        let replay = try makeReplayWithCostlyDecision()
        let summary = RoundReplayShareSummary.text(initialState: replay.initial, actions: replay.actions)

        XCTAssertTrue(summary.contains("تحليل قرارات الخبير".localized))
        XCTAssertTrue(summary.contains("أفضل قرار".localized))
        XCTAssertTrue(summary.contains("الفاقد المتوقع".localized))
    }

    func testReplayShareSummaryIncludesBestProjectedCardWhenSimulationDiffers() throws {
        let replay = try makeReplayWithProjectedDecision()
        let summary = RoundReplayShareSummary.text(initialState: replay.initial, actions: replay.actions)

        XCTAssertTrue(summary.contains("أفضل نتيجة محاكاة".localized))
        XCTAssertTrue(summary.contains(replay.hint.bestProjectedCard.accessibilityName))
    }

    func testReplayShareSummaryIncludesSecondProjectedCardWhenItAddsLossContext() throws {
        let replay = try makeReplayWithSecondProjectedDecision()
        let summary = RoundReplayShareSummary.text(initialState: replay.initial, actions: replay.actions)
        let secondBestProjectedCard = try XCTUnwrap(replay.hint.secondBestProjectedCard)

        XCTAssertTrue(summary.contains("ثاني نتيجة محاكاة".localized))
        XCTAssertTrue(summary.contains(secondBestProjectedCard.accessibilityName))
        XCTAssertGreaterThan(replay.hint.estimatedProjectedLostAgainstSecondBestPoints, 0)
    }

    private func makeCompletedReplay(seed: UInt64) throws -> (initial: GameState, actions: [GameAction]) {
        let initial = makeAIMatch()
        var state = try GameEngine.apply(.dealCards(seed: seed), to: initial)
        state = try GameEngine.advanceAIPlayers(state: state, agent: ProfiledBalootAgent(profile: AIProfile(
            id: "replay.navigator",
            level: .pro,
            personality: .balanced,
            avatarSystemName: "person"
        )))

        XCTAssertEqual(state.phase, .finished)
        XCTAssertGreaterThanOrEqual(state.completedTricks.count, 1)
        return (initial, state.actionHistory)
    }

    private func makeReplayWithCostlyDecision() throws -> (initial: GameState, actions: [GameAction]) {
        for seed in 1_400..<1_460 {
            let replay = try makeCompletedReplay(seed: UInt64(seed))
            let hasCostlyDecision = replay.actions.indices.contains { index in
                guard let hint = RoundReplayDecisionAdvisor.hint(
                    initialState: replay.initial,
                    actions: replay.actions,
                    currentStep: index + 1
                ) else { return false }
                return !hint.matchedExpert || hint.estimatedLostPoints > 0
            }
            if hasCostlyDecision { return replay }
        }
        XCTFail("لم يتم العثور على Replay يحتوي قرارًا يحتاج مراجعة")
        throw NSError(domain: "RoundReplayNavigatorTests", code: 1)
    }

    private func makeReplayWithProjectedDecision() throws -> (initial: GameState, actions: [GameAction], hint: RoundReplayDecisionHint) {
        for seed in 1_400..<1_520 {
            let replay = try makeCompletedReplay(seed: UInt64(seed))
            for index in replay.actions.indices {
                guard let hint = RoundReplayDecisionAdvisor.hint(
                    initialState: replay.initial,
                    actions: replay.actions,
                    currentStep: index + 1
                ) else { continue }
                if hint.bestProjectedCard != hint.bestCard || hint.estimatedProjectedLostPoints > hint.estimatedImmediateLostPoints {
                    return (replay.initial, replay.actions, hint)
                }
            }
        }
        XCTFail("لم يتم العثور على Replay يحتوي أفضل نتيجة محاكاة مختلفة")
        throw NSError(domain: "RoundReplayNavigatorTests", code: 2)
    }

    private func makeReplayWithSecondProjectedDecision() throws -> (initial: GameState, actions: [GameAction], hint: RoundReplayDecisionHint) {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)
        let secondBestProjected = try XCTUnwrap(scenario.secondBestProjectedOption)
        let option = try XCTUnwrap(scenario.options.min { lhs, rhs in
            lhs.projectedTeamPoints < rhs.projectedTeamPoints
        })
        let replay = try XCTUnwrap(WhatToPlayTrainer.decisionReplay(for: option.card, in: scenario))
        let hint = try XCTUnwrap(RoundReplayDecisionAdvisor.hint(
            initialState: replay.initialState,
            actions: replay.actions,
            currentStep: replay.actions.count
        ))

        XCTAssertEqual(hint.secondBestProjectedCard, secondBestProjected.card)
        XCTAssertGreaterThan(hint.estimatedProjectedLostAgainstSecondBestPoints, 0)
        return (replay.initialState, replay.actions, hint)
    }

    private func makeAIMatch() -> GameState {
        var state = GameState.newLocalMatch(rules: .standard)
        state.players = state.players.map { player in
            var updated = player
            updated.kind = .ai
            return updated
        }
        return state
    }
}
