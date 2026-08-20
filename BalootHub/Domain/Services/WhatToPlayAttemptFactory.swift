import BalootEngine
import Foundation

enum WhatToPlayAttemptFactory {
    static func makeAttempt(
        scenario: WhatToPlayScenario,
        evaluated option: WhatToPlayOption
    ) -> WhatToPlayAttempt? {
        guard let bestCard = scenario.bestOption?.card else { return nil }
        let bestSimulationOption = WhatToPlayOptionComparison.bestSimulationOption(scenario.options)

        return WhatToPlayAttempt(
            difficulty: scenario.difficulty,
            seed: scenario.seed,
            selectedCard: option.card,
            bestCard: bestCard,
            secondBestCard: scenario.secondBestOption?.card,
            isCorrect: option.isExpertChoice,
            selectedRank: option.rank,
            expectedImpact: option.expectedImpact,
            bestExpectedImpact: scenario.bestOption?.expectedImpact,
            secondBestExpectedImpact: scenario.secondBestOption?.expectedImpact,
            projectedTeamPoints: option.projectedTeamPoints,
            bestProjectedTeamPoints: bestSimulationOption?.projectedTeamPoints,
            secondBestProjectedTeamPoints: scenario.secondBestOption?.projectedTeamPoints,
            focusKind: scenario.context.focusKind,
            gameMode: scenario.state.mode,
            outcome: option.outcome,
            impactBreakdown: option.impactBreakdown,
            simulation: option.simulation,
            scenarioContext: scenario.context
        )
    }
}
