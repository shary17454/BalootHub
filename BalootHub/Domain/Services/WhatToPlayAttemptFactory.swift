import BalootEngine
import Foundation

enum WhatToPlayAttemptFactory {
    enum ShareCodeAttemptError: Error, Equatable {
        case invalidCode
        case missingSelectedCard
        case selectedCardUnavailable
    }

    static func makeAttempt(
        scenario: WhatToPlayScenario,
        evaluated option: WhatToPlayOption
    ) -> WhatToPlayAttempt? {
        guard let bestCard = scenario.bestOption?.card else { return nil }
        let bestSimulationOption = WhatToPlayTrainer.bestProjectedOption(in: scenario.options)
        let secondBestSimulationOption = WhatToPlayTrainer.secondBestProjectedOption(in: scenario.options)

        return WhatToPlayAttempt(
            difficulty: scenario.difficulty,
            seed: scenario.seed,
            selectedCard: option.card,
            bestCard: bestCard,
            secondBestCard: scenario.secondBestOption?.card,
            bestSimulationCard: bestSimulationOption?.card,
            secondBestSimulationCard: secondBestSimulationOption?.card,
            isCorrect: option.isExpertChoice,
            selectedRank: option.rank,
            expectedImpact: option.expectedImpact,
            bestExpectedImpact: scenario.bestOption?.expectedImpact,
            secondBestExpectedImpact: scenario.secondBestOption?.expectedImpact,
            projectedTeamPoints: option.projectedTeamPoints,
            bestProjectedTeamPoints: bestSimulationOption?.projectedTeamPoints,
            secondBestProjectedTeamPoints: secondBestSimulationOption?.projectedTeamPoints,
            focusKind: scenario.context.focusKind,
            gameMode: scenario.state.mode,
            outcome: option.outcome,
            impactBreakdown: option.impactBreakdown,
            simulation: option.simulation,
            scenarioContext: scenario.context
        )
    }

    static func makeAttempt(code: String) async throws -> WhatToPlayAttempt {
        guard let extractedCode = WhatToPlayScenarioCode.extractCode(from: code),
              let parsed = WhatToPlayScenarioCode.parse(extractedCode)
        else {
            throw ShareCodeAttemptError.invalidCode
        }
        guard let selectedCard = parsed.selectedCard else {
            throw ShareCodeAttemptError.missingSelectedCard
        }

        let scenario = try await WhatToPlayScenarioLoader.generate(code: extractedCode)
        guard let option = scenario.options.first(where: { $0.card == selectedCard }) else {
            throw ShareCodeAttemptError.selectedCardUnavailable
        }
        guard let attempt = makeAttempt(scenario: scenario, evaluated: option) else {
            throw ShareCodeAttemptError.selectedCardUnavailable
        }

        return attempt
    }
}
