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
