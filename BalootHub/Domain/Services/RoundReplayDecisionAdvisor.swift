import BalootEngine

struct RoundReplayDecisionHint: Equatable {
    let stepIndex: Int
    let trickNumber: Int
    let playerID: Player.ID
    let playedCard: PlayingCard
    let bestCard: PlayingCard
    let secondBestCard: PlayingCard?
    let bestProjectedCard: PlayingCard
    let secondBestProjectedCard: PlayingCard?
    let selectedRank: Int
    let estimatedImmediateLostPoints: Int
    let estimatedProjectedLostPoints: Int
    let estimatedProjectedLostAgainstSecondBestPoints: Int
    let explanation: String

    var matchedExpert: Bool {
        selectedRank == 1
    }

    var estimatedLostPoints: Int {
        max(
            estimatedImmediateLostPoints,
            estimatedProjectedLostPoints,
            estimatedProjectedLostAgainstSecondBestPoints
        )
    }
}

enum RoundReplayDecisionAdvisor {
    static func hint(
        initialState: GameState,
        actions: [GameAction],
        currentStep: Int,
        difficulty: WhatToPlayDifficulty = .medium
    ) -> RoundReplayDecisionHint? {
        let step = min(actions.count, max(0, currentStep))
        guard step > 0,
              actions.indices.contains(step - 1),
              case .playCard(let playerID, let playedCard) = actions[step - 1],
              let beforePlay = try? GameEngine.replay(initialState: initialState, actions: actions, upTo: step - 1),
              beforePlay.phase == .playing,
              beforePlay.currentTurnPlayerID == playerID,
              let options = try? WhatToPlayTrainer.analyzeOptions(
                state: beforePlay,
                playerID: playerID,
                difficulty: difficulty
              ),
              let selected = options.first(where: { $0.card == playedCard }),
              let best = options.first(where: { $0.rank == 1 })
        else { return nil }

        let bestSimulation = WhatToPlayTrainer.bestProjectedOption(in: options) ?? best
        let secondBestSimulation = WhatToPlayTrainer.secondBestProjectedOption(in: options)
        let immediateLost = max(0, best.expectedImpact - selected.expectedImpact)
        let projectedLost = max(0, bestSimulation.projectedTeamPoints - selected.projectedTeamPoints)
        let projectedLostAgainstSecondBest = secondBestSimulation.map {
            max(0, $0.projectedTeamPoints - selected.projectedTeamPoints)
        } ?? 0

        return RoundReplayDecisionHint(
            stepIndex: step - 1,
            trickNumber: beforePlay.completedTricks.count + 1,
            playerID: playerID,
            playedCard: playedCard,
            bestCard: best.card,
            secondBestCard: options.first(where: { $0.rank == 2 })?.card,
            bestProjectedCard: bestSimulation.card,
            secondBestProjectedCard: secondBestSimulation?.card,
            selectedRank: selected.rank,
            estimatedImmediateLostPoints: immediateLost,
            estimatedProjectedLostPoints: projectedLost,
            estimatedProjectedLostAgainstSecondBestPoints: projectedLostAgainstSecondBest,
            explanation: selected.explanation
        )
    }
}
