import BalootEngine

enum RoundReplayNavigator {
    static func previousTrickStep(initialState: GameState, actions: [GameAction], currentStep: Int) -> Int {
        let step = min(actions.count, max(0, currentStep))
        let snapshot = replay(initialState: initialState, actions: actions, upTo: step)
        let currentTricks = snapshot.completedTricks.count
        var best = 0
        guard step > 0 else { return 0 }

        for candidate in 0..<step {
            let candidateState = replay(initialState: initialState, actions: actions, upTo: candidate)
            if candidateState.completedTricks.count < currentTricks {
                best = candidate
            }
        }

        return best
    }

    static func nextTrickStep(initialState: GameState, actions: [GameAction], currentStep: Int) -> Int {
        let step = min(actions.count, max(0, currentStep))
        let snapshot = replay(initialState: initialState, actions: actions, upTo: step)
        let currentTricks = snapshot.completedTricks.count
        guard step < actions.count else { return actions.count }

        for candidate in (step + 1)...actions.count {
            let candidateState = replay(initialState: initialState, actions: actions, upTo: candidate)
            if candidateState.completedTricks.count > currentTricks || candidate == actions.count {
                return candidate
            }
        }

        return actions.count
    }

    private static func replay(initialState: GameState, actions: [GameAction], upTo step: Int) -> GameState {
        (try? GameEngine.replay(initialState: initialState, actions: actions, upTo: step)) ?? initialState
    }
}
