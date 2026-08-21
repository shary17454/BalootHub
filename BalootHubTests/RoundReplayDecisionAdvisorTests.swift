import XCTest
import BalootEngine
@testable import BalootHub

final class RoundReplayDecisionAdvisorTests: XCTestCase {
    func testHintIsNilBeforePlayableDecision() throws {
        let replay = try makeCompletedReplay(seed: 1_410)

        XCTAssertNil(RoundReplayDecisionAdvisor.hint(
            initialState: replay.initial,
            actions: replay.actions,
            currentStep: 1
        ))
    }

    func testHintExplainsCurrentReplayPlayCardDecision() throws {
        let replay = try makeCompletedReplay(seed: 1_410)
        let playStep = try XCTUnwrap(firstPlayCardStep(in: replay.actions))

        let hint = try XCTUnwrap(RoundReplayDecisionAdvisor.hint(
            initialState: replay.initial,
            actions: replay.actions,
            currentStep: playStep
        ))
        let beforePlay = try GameEngine.replay(initialState: replay.initial, actions: replay.actions, upTo: playStep - 1)
        let legal = GameEngine.legalCards(for: hint.playerID, state: beforePlay)

        XCTAssertEqual(hint.stepIndex, playStep - 1)
        XCTAssertEqual(hint.trickNumber, beforePlay.completedTricks.count + 1)
        XCTAssertTrue(legal.contains(hint.playedCard))
        XCTAssertTrue(legal.contains(hint.bestCard))
        XCTAssertGreaterThanOrEqual(hint.selectedRank, 1)
        XCTAssertGreaterThanOrEqual(hint.estimatedImmediateLostPoints, 0)
        XCTAssertGreaterThanOrEqual(hint.estimatedProjectedLostPoints, 0)
        XCTAssertGreaterThanOrEqual(hint.estimatedLostPoints, 0)
        XCTAssertEqual(hint.estimatedLostPoints, max(hint.estimatedImmediateLostPoints, hint.estimatedProjectedLostPoints))
        XCTAssertFalse(hint.explanation.isEmpty)
    }

    func testHintUsesProjectedRoundLossWhenItExceedsImmediateLoss() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2, difficulty: .hard)
        let selected = try XCTUnwrap(scenario.options.first {
            $0.card.suit == .diamonds && $0.card.rank == .queen
        })
        let replay = try XCTUnwrap(WhatToPlayTrainer.decisionReplay(for: selected.card, in: scenario))

        let hint = try XCTUnwrap(RoundReplayDecisionAdvisor.hint(
            initialState: replay.initialState,
            actions: replay.actions,
            currentStep: replay.actions.count
        ))

        XCTAssertEqual(hint.playedCard, selected.card)
        XCTAssertGreaterThan(hint.estimatedProjectedLostPoints, hint.estimatedImmediateLostPoints)
        XCTAssertEqual(hint.estimatedLostPoints, hint.estimatedProjectedLostPoints)
    }

    func testHintIsDeterministicForSameReplayStep() throws {
        let replay = try makeCompletedReplay(seed: 2_027)
        let playStep = try XCTUnwrap(firstPlayCardStep(in: replay.actions))

        XCTAssertEqual(
            RoundReplayDecisionAdvisor.hint(initialState: replay.initial, actions: replay.actions, currentStep: playStep),
            RoundReplayDecisionAdvisor.hint(initialState: replay.initial, actions: replay.actions, currentStep: playStep)
        )
    }

    private func firstPlayCardStep(in actions: [GameAction]) -> Int? {
        actions.firstIndex {
            if case .playCard = $0 { return true }
            return false
        }.map { $0 + 1 }
    }

    private func makeCompletedReplay(seed: UInt64) throws -> (initial: GameState, actions: [GameAction]) {
        let initial = makeAIMatch()
        var state = try GameEngine.apply(.dealCards(seed: seed), to: initial)
        state = try GameEngine.advanceAIPlayers(state: state, agent: ProfiledBalootAgent(profile: AIProfile(
            id: "replay.advisor",
            level: .pro,
            personality: .balanced,
            avatarSystemName: "person"
        )))

        XCTAssertEqual(state.phase, .finished)
        return (initial, state.actionHistory)
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
