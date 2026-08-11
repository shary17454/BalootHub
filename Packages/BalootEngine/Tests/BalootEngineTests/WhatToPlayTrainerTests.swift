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
        #expect(first.context == second.context)
    }

    @Test("طلب تركيز محدد يولد موقفًا مطابقًا له بشكل حتمي")
    func generationHonorsPreferredFocusDeterministically() throws {
        for focusKind in WhatToPlayScenarioFocusKind.allCases {
            let first = try WhatToPlayTrainer.generateScenario(
                seed: 2_026,
                difficulty: .easy,
                preferredFocus: focusKind
            )
            let second = try WhatToPlayTrainer.generateScenario(
                seed: 2_026,
                difficulty: .easy,
                preferredFocus: focusKind
            )

            #expect(first.context.focusKind == focusKind)
            #expect(second.context.focusKind == focusKind)
            #expect(first.seed == second.seed)
            #expect(first.options.map(\.card) == second.options.map(\.card))
            #expect(first.bestOption?.card == second.bestOption?.card)
        }
    }

    @Test("تقييم اختيار المستخدم يعيد خيارًا معروفًا من نفس الموقف")
    func evaluatesUserChoiceAgainstScenarioOptions() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)
        let card = try #require(scenario.options.last?.card)

        let result = WhatToPlayTrainer.evaluateChoice(card: card, in: scenario)

        #expect(result?.card == card)
        #expect(result?.rank == scenario.options.count)
    }

    @Test("نتيجة كل خيار تطابق تطبيق الورقة على المحرك")
    func optionOutcomeMatchesEngineResult() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)
        let player = try #require(scenario.state.player(id: scenario.playerID))
        let wasLeading = scenario.state.currentTrick?.playedCards.isEmpty ?? true

        for option in scenario.options {
            let after = try GameEngine.apply(.playCard(playerID: scenario.playerID, card: option.card), to: scenario.state)
            let expected: WhatToPlayOptionOutcome
            if let last = after.completedTricks.last,
               let winnerID = last.winnerPlayerID,
               let winner = after.player(id: winnerID) {
                expected = winner.teamID == player.teamID ? .winsTrick : .losesTrick
            } else {
                expected = wasLeading ? .leadsTrick : .developsTrick
            }

            #expect(option.outcome == expected)
        }
    }

    @Test("سياق الموقف يطابق حالة الأكلة الحالية")
    func scenarioContextMatchesCurrentTrickState() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let trick = scenario.state.currentTrick

        #expect(scenario.context.trickNumber == scenario.state.completedTricks.count + 1)
        #expect(scenario.context.isLeading == (trick?.playedCards.isEmpty ?? true))
        #expect(scenario.context.requiredSuit == trick?.requiredSuit)
        #expect(scenario.context.playedCardCount == (trick?.playedCards.count ?? 0))
        #expect(scenario.context.legalOptionCount == scenario.options.count)
        #expect(scenario.context.mode == scenario.state.mode)
        #expect(scenario.context.trumpSuit == scenario.state.trumpSuit)
        #expect(
            scenario.context.focusKind == WhatToPlayTrainer.scenarioFocusKind(
                isLeading: scenario.context.isLeading,
                requiredSuit: scenario.context.requiredSuit,
                hasTrumpInCurrentTrick: scenario.context.hasTrumpInCurrentTrick,
                legalOptionCount: scenario.context.legalOptionCount
            )
        )
    }

    @Test("سياق الموقف يكتشف وجود الحكم على الطاولة في حكم فقط")
    func scenarioContextDetectsTrumpOnTableOnlyInHokum() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let hasTrump: Bool
        if scenario.state.mode == .hokum, let trumpSuit = scenario.state.trumpSuit {
            hasTrump = scenario.state.currentTrick?.playedCards.contains { $0.card.suit == trumpSuit } ?? false
        } else {
            hasTrump = false
        }

        #expect(scenario.context.hasTrumpInCurrentTrick == hasTrump)
    }

    @Test("تركيز الموقف يعطي أولوية لضغط الحكم ثم اللون المطلوب ثم ضيق الخيارات")
    func scenarioFocusPrioritizesActionablePressure() {
        #expect(
            WhatToPlayTrainer.scenarioFocusKind(
                isLeading: false,
                requiredSuit: .clubs,
                hasTrumpInCurrentTrick: true,
                legalOptionCount: 2
            ) == .trumpPressure
        )
        #expect(
            WhatToPlayTrainer.scenarioFocusKind(
                isLeading: false,
                requiredSuit: .clubs,
                hasTrumpInCurrentTrick: false,
                legalOptionCount: 2
            ) == .followSuit
        )
        #expect(
            WhatToPlayTrainer.scenarioFocusKind(
                isLeading: true,
                requiredSuit: nil,
                hasTrumpInCurrentTrick: false,
                legalOptionCount: 2
            ) == .narrowChoice
        )
        #expect(
            WhatToPlayTrainer.scenarioFocusKind(
                isLeading: true,
                requiredSuit: nil,
                hasTrumpInCurrentTrick: false,
                legalOptionCount: 4
            ) == .openingLead
        )
    }
}
