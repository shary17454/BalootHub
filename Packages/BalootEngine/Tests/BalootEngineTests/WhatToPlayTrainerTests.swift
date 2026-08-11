import Testing
@testable import BalootEngine

@Suite("مدرب وش تلعب")
struct WhatToPlayTrainerTests {
    @Test("توليد الموقف يعطي دور لاعب بشري وخيارات قانونية")
    func generatedScenarioStopsAtHumanTurn() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .easy)

        #expect(scenario.state.phase == .playing)
        #expect(scenario.state.currentTurnPlayerID == scenario.playerID)
        #expect(!scenario.options.isEmpty)

        let legal = Set(GameEngine.legalCards(for: scenario.playerID, state: scenario.state))
        #expect(Set(scenario.options.map(\.card)).isSubset(of: legal))
        #expect(scenario.options.contains { $0.isExpertChoice })
    }

    @Test("نفس البذرة والصعوبة تعطيان نفس الموقف والترتيب")
    func generationIsDeterministic() throws {
        let first = try WhatToPlayTrainer.generateScenario(seed: 99, difficulty: .medium)
        let second = try WhatToPlayTrainer.generateScenario(seed: 99, difficulty: .medium)

        #expect(first.seed == second.seed)
        #expect(first.state.phase == second.state.phase)
        #expect(first.state.mode == second.state.mode)
        #expect(first.state.trumpSuit == second.state.trumpSuit)
        #expect(first.state.hands[first.playerID] == second.state.hands[second.playerID])
        #expect(first.options.map(\.card) == second.options.map(\.card))
        #expect(first.bestOption?.card == second.bestOption?.card)
    }

    @Test("تقييم اختيار المستخدم يعيد خيارًا معروفًا من نفس الموقف")
    func evaluatesUserChoiceAgainstScenarioOptions() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)
        let card = try #require(scenario.options.last?.card)

        let result = WhatToPlayTrainer.evaluateChoice(card: card, in: scenario)

        #expect(result?.card == card)
        #expect(result?.rank == scenario.options.count)
    }
}
