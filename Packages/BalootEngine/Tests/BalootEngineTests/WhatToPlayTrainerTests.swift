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
        #expect(first.blockedCards == second.blockedCards)
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

    @Test("الأوراق غير القانونية في الموقف تأتي من سبب رفض المحرك نفسه")
    func blockedCardsUseEngineInvalidMoveReasons() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(
            seed: 2026,
            difficulty: .easy,
            preferredFocus: .followSuit
        )
        let hand = try #require(scenario.state.hands[scenario.playerID])
        let legalCards = Set(scenario.options.map(\.card))
        let blockedCards = Set(scenario.blockedCards.map(\.card))

        #expect(!scenario.blockedCards.isEmpty)
        #expect(blockedCards.isDisjoint(with: legalCards))
        #expect(blockedCards.count + legalCards.count == hand.count)

        for blocked in scenario.blockedCards {
            #expect(GameEngine.invalidMoveReason(playerID: scenario.playerID, card: blocked.card, state: scenario.state) == blocked.reason)
        }
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

    @Test("تفكيك أثر الخيار هو مصدر expectedImpact نفسه")
    func optionImpactBreakdownDrivesExpectedImpact() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)

        for option in scenario.options {
            #expect(option.expectedImpact == option.impactBreakdown.signedImpact)
            #expect(
                WhatToPlayTrainer.impactBreakdown(
                    of: option.card,
                    by: scenario.playerID,
                    in: scenario.state
                ) == option.impactBreakdown
            )
        }
    }

    @Test("تفكيك الأكلة المكتملة يحدد لمن تذهب نقاط الطاولة")
    func completedTrickBreakdownTracksTeamSwing() throws {
        var state = GameState.newLocalHumanMatch(rules: .simpleBidding)
        let south = try #require(state.player(at: .south))
        let west = try #require(state.player(at: .west))
        let north = try #require(state.player(at: .north))
        let east = try #require(state.player(at: .east))
        let winningCard = PlayingCard(suit: .hearts, rank: .ace)

        state.phase = .playing
        state.mode = .sun
        state.currentTurnPlayerID = south.id
        state.hands[south.id] = [winningCard]
        state.currentTrick = Trick(
            playedCards: [
                PlayedCard(playerID: west.id, card: PlayingCard(suit: .hearts, rank: .seven)),
                PlayedCard(playerID: north.id, card: PlayingCard(suit: .hearts, rank: .king)),
                PlayedCard(playerID: east.id, card: PlayingCard(suit: .hearts, rank: .ten))
            ],
            leaderSeat: .west
        )

        let option = try #require(try WhatToPlayTrainer.analyzeOptions(state: state, playerID: south.id).first)

        #expect(option.card == winningCard)
        #expect(option.impactBreakdown.completesTrick)
        #expect(option.impactBreakdown.winsForPlayerTeam == true)
        #expect(option.impactBreakdown.playedCardPoints == 11)
        #expect(option.impactBreakdown.trickPointsSwing == 25)
        #expect(option.expectedImpact == 25)
    }

    @Test("تفكيك الأثر لا يقبل ورقة غير قانونية")
    func impactBreakdownRejectsIllegalCard() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(
            seed: 2026,
            difficulty: .easy,
            preferredFocus: .followSuit
        )
        let blocked = try #require(scenario.blockedCards.first?.card)

        #expect(
            WhatToPlayTrainer.impactBreakdown(
                of: blocked,
                by: scenario.playerID,
                in: scenario.state
            ) == nil
        )
    }

    @Test("سبب نتيجة الخيار يشرح نوع الأثر التكتيكي")
    func optionOutcomeReasonExplainsOutcome() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)

        for option in scenario.options {
            #expect(!option.outcomeReason.isEmpty)
            switch option.outcome {
            case .leadsTrick:
                #expect(option.outcomeReason.contains("تبدأ الأكلة"))
            case .developsTrick:
                #expect(option.outcomeReason.contains("لا تحسم الأكلة"))
            case .winsTrick:
                #expect(option.outcomeReason.contains("لفريقك"))
            case .losesTrick:
                #expect(option.outcomeReason.contains("لصالح الخصم"))
            }
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
