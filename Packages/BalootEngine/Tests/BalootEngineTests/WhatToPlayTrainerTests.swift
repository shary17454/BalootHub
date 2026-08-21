import Testing
@testable import BalootEngine

@Suite("مدرب وش تلعب")
struct WhatToPlayTrainerTests {
    @Test("مستويات وش تلعب تزيد عمق تحليل الخبير تدريجيًا")
    func difficultySamplesIncreaseWithExpertLevel() {
        #expect(WhatToPlayDifficulty.easy.expertSamples < WhatToPlayDifficulty.medium.expertSamples)
        #expect(WhatToPlayDifficulty.medium.expertSamples < WhatToPlayDifficulty.hard.expertSamples)
        #expect(WhatToPlayDifficulty.hard.expertSamples < WhatToPlayDifficulty.expert.expertSamples)
    }

    @Test("مستوى الخبير يولد موقفًا حقيقيًا قابلًا للتقييم")
    func expertDifficultyGeneratesPlayableScenario() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .expert)

        #expect(scenario.difficulty == .expert)
        #expect(scenario.state.phase == .playing)
        #expect(!scenario.options.isEmpty)
        #expect(scenario.options.contains { $0.isExpertChoice })
    }

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

    @Test("الموقف الافتراضي يأتي من مزايدة بلوت كاملة لا من اختيار مبسط")
    func generatedScenarioUsesFullBiddingByDefault() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .easy)

        #expect(scenario.state.rules.biddingStyle == .full)
        #expect(scenario.state.actionHistory.contains {
            if case .placeBid = $0 { return true }
            return false
        })
        #expect(!scenario.state.actionHistory.contains {
            if case .chooseMode = $0 { return true }
            return false
        })
        #expect(scenario.state.bidding.declarerID != nil)
        #expect(scenario.state.mode != nil)
    }

    @Test("كل مزايدة في موقف التدريب قانونية لصاحب الدور عند إعادة التشغيل")
    func generatedScenarioBidsAreLegalForActingPlayer() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        var replay = scenario.initialState

        for action in scenario.state.actionHistory {
            if case .placeBid(let playerID, let bid) = action {
                #expect(replay.currentTurnPlayerID == playerID)
                #expect(GameEngine.legalBids(for: playerID, state: replay).contains(bid))
            }
            replay = try GameEngine.apply(action, to: replay)
        }
    }

    @Test("سيناريو التدريب يحمل لقطة البداية الأصلية لإعادة التشغيل")
    func generatedScenarioCarriesOriginalInitialStateForReplay() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)

        #expect(scenario.initialState.phase == .setup)
        #expect(scenario.initialState.actionHistory.isEmpty)
        #expect(scenario.initialState.players == scenario.state.players)
        #expect(scenario.initialState.teams == scenario.state.teams)
        #expect(scenario.initialState.rules == scenario.state.rules)

        let replayed = try GameEngine.replay(
            initialState: scenario.initialState,
            actions: scenario.state.actionHistory
        )

        #expect(replayed.phase == scenario.state.phase)
        #expect(replayed.currentTurnPlayerID == scenario.state.currentTurnPlayerID)
        #expect(replayed.hands == scenario.state.hands)
        #expect(trickSnapshot(replayed.currentTrick) == trickSnapshot(scenario.state.currentTrick))
        #expect(trickSnapshots(replayed.completedTricks) == trickSnapshots(scenario.state.completedTricks))
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

    @Test("طلب نمط محدد يولد موقف صن أو حكم من نفس دورة البلوت")
    func generationHonorsPreferredModeDeterministically() throws {
        for mode in GameMode.allCases {
            let first = try WhatToPlayTrainer.generateScenario(
                seed: 2_026,
                difficulty: .easy,
                preferredMode: mode
            )
            let second = try WhatToPlayTrainer.generateScenario(
                seed: 2_026,
                difficulty: .easy,
                preferredMode: mode
            )

            #expect(first.state.mode == mode)
            #expect(second.state.mode == mode)
            #expect(first.seed == second.seed)
            #expect(first.options.map(\.card) == second.options.map(\.card))
            #expect(first.state.actionHistory.contains {
                if case .placeBid = $0 { return true }
                return false
            })
        }
    }

    @Test("طلب صن مع لون حكم عالق يتجاهل اللون ولا يعطل التوليد")
    func generationIgnoresTrumpSuitWhenSunIsRequested() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(
            seed: 2_026,
            difficulty: .easy,
            preferredMode: .sun,
            preferredTrumpSuit: .spades
        )

        #expect(scenario.state.mode == .sun)
        #expect(scenario.state.trumpSuit == nil)
        #expect(scenario.context.mode == .sun)
        #expect(scenario.context.trumpSuit == nil)
        #expect(!scenario.options.isEmpty)
    }

    @Test("طلب لون حكم محدد يولد موقف حكم مطابقًا بشكل حتمي")
    func generationHonorsPreferredTrumpSuitDeterministically() throws {
        for suit in Suit.allCases {
            let first = try WhatToPlayTrainer.generateScenario(
                seed: 2_026,
                difficulty: .easy,
                preferredMode: .hokum,
                preferredTrumpSuit: suit
            )
            let second = try WhatToPlayTrainer.generateScenario(
                seed: 2_026,
                difficulty: .easy,
                preferredMode: .hokum,
                preferredTrumpSuit: suit
            )

            #expect(first.state.mode == .hokum)
            #expect(second.state.mode == .hokum)
            #expect(first.state.trumpSuit == suit)
            #expect(second.state.trumpSuit == suit)
            #expect(first.context.trumpSuit == suit)
            #expect(second.context.trumpSuit == suit)
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

    @Test("Replay قرار التدريب يعيد الجولة حتى الورقة المختارة")
    func decisionReplayRebuildsScenarioAndSelectedCard() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)
        let selected = try #require(scenario.options.last?.card)
        let replay = try #require(WhatToPlayTrainer.decisionReplay(for: selected, in: scenario))

        #expect(replay.initialState.actionHistory.isEmpty)
        #expect(replay.initialState.players == scenario.initialState.players)
        #expect(replay.initialState.teams == scenario.initialState.teams)
        #expect(replay.initialState.dealerSeat == scenario.initialState.dealerSeat)
        #expect(replay.initialState.roundNumber == scenario.initialState.roundNumber)

        let replayedScenario = try GameEngine.replay(
            initialState: replay.initialState,
            actions: Array(replay.actions.dropLast())
        )
        let replayedDecision = try GameEngine.replay(
            initialState: replay.initialState,
            actions: replay.actions
        )
        let directDecision = try GameEngine.apply(
            .playCard(playerID: scenario.playerID, card: selected),
            to: scenario.state
        )

        #expect(replay.selectedCard == selected)
        #expect(replay.playerID == scenario.playerID)
        #expect(replayedScenario.phase == scenario.state.phase)
        #expect(replayedScenario.currentTurnPlayerID == scenario.state.currentTurnPlayerID)
        #expect(replayedScenario.hands[scenario.playerID] == scenario.state.hands[scenario.playerID])
        #expect(trickSnapshot(replayedScenario.currentTrick) == trickSnapshot(scenario.state.currentTrick))
        #expect(trickSnapshots(replayedScenario.completedTricks) == trickSnapshots(scenario.state.completedTricks))
        #expect(replayedDecision.currentTurnPlayerID == directDecision.currentTurnPlayerID)
        #expect(replayedDecision.hands[scenario.playerID] == directDecision.hands[scenario.playerID])
        #expect(trickSnapshot(replayedDecision.currentTrick) == trickSnapshot(directDecision.currentTrick))
        #expect(trickSnapshots(replayedDecision.completedTricks) == trickSnapshots(directDecision.completedTricks))
        #expect(replayedDecision.actionHistory == directDecision.actionHistory)
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

    @Test("محاكاة كل خيار تطابق الحالة الناتجة من تطبيق الورقة على المحرك")
    func optionSimulationMatchesEngineResult() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)

        for option in scenario.options {
            let after = try GameEngine.apply(.playCard(playerID: scenario.playerID, card: option.card), to: scenario.state)
            let completedTrick = after.completedTricks.last
            let winnerID = completedTrick?.winnerPlayerID
            let winnerTeamID = winnerID.flatMap { after.player(id: $0)?.teamID }
            let playerTeamID = try #require(scenario.state.player(id: scenario.playerID)?.teamID)
            let completedTrickPoints = completedTrick?.playedCards.reduce(0) {
                $0 + $1.card.points(mode: scenario.state.mode ?? .sun, trumpSuit: scenario.state.trumpSuit)
            } ?? 0

            #expect(option.simulation.phaseAfterPlay == after.phase)
            #expect(option.simulation.currentTrickCardCount == (after.currentTrick?.playedCards.count ?? 0))
            #expect(option.simulation.completedTrickWinnerID == winnerID)
            #expect(option.simulation.completedTrickWinnerTeamID == winnerTeamID)
            #expect(option.simulation.completedTrickWonByPlayerTeam == winnerTeamID.map { $0 == playerTeamID })
            #expect(option.simulation.completedTrickPoints == completedTrickPoints)
            #expect(option.simulation.nextTurnPlayerID == after.currentTurnPlayerID)
            #expect(option.simulation.playerRemainingCards == (after.hands[scenario.playerID]?.count ?? 0))
            #expect(option.simulation.actionHistoryCount == after.actionHistory.count)
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

    @Test("توقع نقاط الفريق لكل خيار حتمي مع نفس البذرة")
    func optionProjectedTeamPointsAreDeterministic() throws {
        let first = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)
        let second = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)

        #expect(first.options.map(\.projectedTeamPoints) == second.options.map(\.projectedTeamPoints))
    }

    @Test("توقع نقاط الفريق يطابق استكمال الجولة من المحرك بعد فرض الورقة")
    func optionProjectedTeamPointsMatchesEnginePlayout() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)
        let player = try #require(scenario.state.player(id: scenario.playerID))

        for option in scenario.options {
            #expect(
                option.projectedTeamPoints == projectedTeamPoints(
                    afterPlaying: option.card,
                    by: player,
                    in: scenario.state
                )
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

    @Test("شرح الخيار يذكر ترتيب الخبير والفارق العددي عن الأفضل")
    func optionExplanationIncludesRankAndBestGap() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)
        let best = try #require(scenario.bestOption)
        let alternative = try #require(scenario.options.first { !$0.isExpertChoice })
        let expectedProjectionGap = max(0, best.projectedTeamPoints - alternative.projectedTeamPoints)

        #expect(best.explanation.contains("رقم 1"))
        #expect(best.explanation.contains("أعلى تقييم"))
        #expect(alternative.explanation.contains("فارق"))
        #expect(alternative.explanation.contains("\(expectedProjectionGap)"))
        #expect(alternative.explanation.contains("المحاكاة"))
    }

    @Test("شرح الخيار يعطي أولوية لخسارة المحاكاة العالية")
    func optionExplanationPrioritizesHighSimulationLoss() throws {
        var matchedOption: WhatToPlayOption?

        for seed in 1...300 {
            let scenario = try WhatToPlayTrainer.generateScenario(seed: UInt64(seed), difficulty: .hard)
            guard let best = scenario.bestOption else { continue }
            if let option = scenario.options.first(where: {
                !$0.isExpertChoice
                    && max(0, best.projectedTeamPoints - $0.projectedTeamPoints) > max(2, abs($0.expectedImpact))
            }) {
                matchedOption = option
                break
            }
        }

        let option = try #require(matchedOption)
        #expect(option.explanation.contains("يخسر بعد استكمال الجولة"))
        #expect(option.explanation.contains("نقاط المحاكاة"))
        #expect(!option.explanation.contains("خيار جيد"))
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
        let player = try #require(scenario.state.player(id: scenario.playerID))
        let playerPoints = scenario.state.teamTrickPoints[player.teamID] ?? 0
        let opponentPoints = scenario.state.teams
            .filter { $0.id != player.teamID }
            .reduce(0) { $0 + (scenario.state.teamTrickPoints[$1.id] ?? 0) }
        #expect(scenario.context.playerTeamTrickPoints == playerPoints)
        #expect(scenario.context.opponentTeamTrickPoints == opponentPoints)
        #expect(scenario.context.playerTeamPointMargin == playerPoints - opponentPoints)
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

    @Test("عوامل قرار الموقف تأتي من المحرك بترتيب ثابت")
    func decisionFactorsDescribeScenarioInStableOrder() {
        let context = WhatToPlayScenarioContext(
            trickNumber: 3,
            isLeading: false,
            requiredSuit: .clubs,
            playedCardCount: 2,
            legalOptionCount: 2,
            mode: .hokum,
            trumpSuit: .hearts,
            hasTrumpInCurrentTrick: true,
            focusKind: .trumpPressure
        )

        #expect(WhatToPlayTrainer.decisionFactors(context: context) == [
            WhatToPlayDecisionFactor(kind: .requiredSuit, suit: .clubs),
            WhatToPlayDecisionFactor(kind: .trumpOnTable, suit: .hearts),
            WhatToPlayDecisionFactor(kind: .trickProgress, count: 2),
            WhatToPlayDecisionFactor(kind: .narrowChoice, count: 2)
        ])
    }

    @Test("عوامل القرار تفرق بين افتتاح الصن والحكم المحفوظ")
    func decisionFactorsSeparateSunOpeningFromAvailableTrump() {
        let sunContext = WhatToPlayScenarioContext(
            trickNumber: 1,
            isLeading: true,
            requiredSuit: nil,
            playedCardCount: 0,
            legalOptionCount: 5,
            mode: .sun,
            trumpSuit: nil,
            hasTrumpInCurrentTrick: false,
            focusKind: .openingLead
        )
        let hokumContext = WhatToPlayScenarioContext(
            trickNumber: 1,
            isLeading: true,
            requiredSuit: nil,
            playedCardCount: 0,
            legalOptionCount: 5,
            mode: .hokum,
            trumpSuit: .spades,
            hasTrumpInCurrentTrick: false,
            focusKind: .openingLead
        )

        #expect(WhatToPlayTrainer.decisionFactors(context: sunContext).map(\.kind) == [
            .openingLead,
            .sunMode,
            .trickProgress,
            .flexibleChoice
        ])
        #expect(WhatToPlayTrainer.decisionFactors(context: hokumContext).map(\.kind) == [
            .openingLead,
            .trumpAvailable,
            .trickProgress,
            .flexibleChoice
        ])
        #expect(WhatToPlayTrainer.decisionFactors(context: hokumContext)[1].suit == .spades)
    }

    private func trickSnapshots(_ tricks: [Trick]) -> [[String]] {
        tricks.map { trickSnapshot($0) }
    }

    private func trickSnapshot(_ trick: Trick?) -> [String] {
        guard let trick else { return [] }
        return trick.playedCards.map { "\($0.playerID.uuidString):\($0.card.suit.rawValue):\($0.card.rank.rawValue)" }
            + ["leader:\(trick.leaderSeat.rawValue)", "winner:\(trick.winnerPlayerID?.uuidString ?? "nil")"]
    }

    private func projectedTeamPoints(afterPlaying card: PlayingCard, by player: Player, in state: GameState) -> Int {
        guard var current = try? GameEngine.apply(.playCard(playerID: player.id, card: card), to: state) else {
            return Int.min
        }

        let policy = SmartBalootAgent()
        var steps = 0
        while current.phase == .playing, steps < 40 {
            steps += 1
            guard let playerID = current.currentTurnPlayerID,
                  let hand = current.hands[playerID], !hand.isEmpty
            else { break }

            let legal = GameEngine.legalCards(for: playerID, state: current)
            guard !legal.isEmpty else { break }

            let selected = policy.chooseCard(hand: hand, legalCards: legal, state: current)
            guard let next = try? GameEngine.apply(.playCard(playerID: playerID, card: selected), to: current) else {
                break
            }
            current = next
        }

        if current.phase == .scoring, let finished = try? GameEngine.apply(.finishRound, to: current) {
            current = finished
        }

        return current.lastRoundResult?.teamPoints[player.teamID]
            ?? current.teamTrickPoints[player.teamID]
            ?? 0
    }
}
