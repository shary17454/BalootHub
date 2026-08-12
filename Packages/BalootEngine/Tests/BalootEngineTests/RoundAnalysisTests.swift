import Testing
@testable import BalootEngine

@Suite("تحليل الجولة بعد النهاية")
struct RoundAnalysisTests {
    @Test("يحلل قرارات لاعب من سجل أفعال قابل للإعادة")
    func analyzesPlayerDecisionsFromReplayActions() throws {
        let (initial, state) = try playableAIMatch(startingSeed: 2_026, level: .expert)
        let playerID = try #require(firstPlayerWhoPlayed(in: state.actionHistory))

        let report = try RoundAnalyzer.analyze(initialState: initial, actions: state.actionHistory, playerID: playerID)

        #expect(!report.decisions.isEmpty)
        #expect(report.scoreOutOf100 >= 0)
        #expect(report.scoreOutOf100 <= 100)
        #expect(report.bestDecision != nil)
        #expect(report.worstDecision != nil)
    }

    @Test("تحليل الجولة يلتقط قرارات المزايدة من سجل الأفعال")
    func analyzesBiddingDecisionsFromReplayActions() throws {
        let (initial, state) = try playableAIMatch(startingSeed: 2_026, level: .expert)
        let playerID = try #require(firstPlayerWhoBid(in: state.actionHistory))

        let report = try RoundAnalyzer.analyze(initialState: initial, actions: state.actionHistory, playerID: playerID)

        #expect(!report.biddingDecisions.isEmpty)
        #expect(report.biddingDecisions.allSatisfy { $0.playerID == playerID })
        #expect(report.biddingDecisions.allSatisfy { $0.legalBids.contains($0.bid) })
    }

    @Test("نفس سجل الأفعال يعطي نفس تقرير التحليل")
    func analysisIsDeterministic() throws {
        let (initial, state) = try playableAIMatch(startingSeed: 77, level: .pro)
        let playerID = try #require(firstPlayerWhoPlayed(in: state.actionHistory))

        let first = try RoundAnalyzer.analyze(initialState: initial, actions: state.actionHistory, playerID: playerID)
        let second = try RoundAnalyzer.analyze(initialState: initial, actions: state.actionHistory, playerID: playerID)

        #expect(first == second)
    }

    @Test("اختيار غير الأفضل يظهر في أسوأ قرار")
    func nonExpertChoiceCanBeReportedAsWorstDecision() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)
        let chosen = try #require(scenario.options.last)
        var actions = scenario.state.actionHistory
        actions.append(.playCard(playerID: scenario.playerID, card: chosen.card))

        let report = try RoundAnalyzer.analyze(
            initialState: resettableInitialState(from: scenario.state),
            actions: actions,
            playerID: scenario.playerID
        )

        #expect(report.worstDecision?.playedCard == chosen.card)
        #expect(report.worstDecision?.selectedRank == chosen.rank)
        #expect(report.tacticalMistakes.isEmpty == chosen.isExpertChoice)
    }

    @Test("مخالفة توصية المزايدة تظهر في الأخطاء والنصائح")
    func nonRecommendedBidIsReportedAsTacticalMistake() throws {
        var rules = BalootRulesConfiguration.standard
        rules.multipliersEnabled = false
        rules.projectsRequireDeclaration = false

        let initial = GameState.newLocalMatch(rules: rules)
        var state = try GameEngine.apply(.dealCards(seed: 14), to: initial)
        let playerID = try #require(state.currentTurnPlayerID)
        let legal = GameEngine.legalBids(state: state)
        let hand = try #require(state.hands[playerID])
        let recommended = HandAnalyzer.analyze(hand: hand, rules: state.rules, legalBids: legal).recommendedBid
        let forced = try #require(legal.first { $0 != recommended })

        state = try GameEngine.apply(.placeBid(playerID: playerID, bid: forced), to: state)

        let report = try RoundAnalyzer.analyze(
            initialState: initial,
            actions: state.actionHistory,
            playerID: playerID
        )

        #expect(report.decisions.isEmpty)
        #expect(report.biddingDecisions.count == 1)
        #expect(report.biddingDecisions.first?.bid == forced)
        #expect(report.biddingDecisions.first?.recommendedBid == recommended)
        #expect(report.biddingDecisions.first?.matchedRecommendation == false)
        #expect((report.biddingDecisions.first?.estimatedLostPoints ?? 0) > 0)
        #expect(report.totalEstimatedLostPoints == report.biddingDecisions.first?.estimatedLostPoints)
        #expect(report.tacticalMistakes.contains { $0.contains("في المزايدة") })
        #expect(report.tips.contains { $0.contains("راجع قرار المزايدة") })
        #expect(report.scoreOutOf100 < 100)
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

    private func playableAIMatch(startingSeed: UInt64, level: AIProfile.Level) throws -> (GameState, GameState) {
        for offset in 0..<40 {
            let initial = makeAIMatch()
            var state = try GameEngine.apply(.dealCards(seed: startingSeed &+ UInt64(offset)), to: initial)
            state = try GameEngine.advanceAIPlayers(state: state, agent: profiledAgent(level))
            if firstPlayerWhoPlayed(in: state.actionHistory) != nil {
                return (initial, state)
            }
        }
        throw RoundAnalyzer.AnalysisError.noPlayableDecisions
    }

    private func profiledAgent(_ level: AIProfile.Level) -> ProfiledBalootAgent {
        ProfiledBalootAgent(profile: AIProfile(
            id: "round.analysis.\(level.rawValue)",
            level: level,
            personality: .balanced,
            avatarSystemName: "person"
        ))
    }

    private func firstPlayerWhoPlayed(in actions: [GameAction]) -> Player.ID? {
        for action in actions {
            if case .playCard(let playerID, _) = action {
                return playerID
            }
        }
        return nil
    }

    private func firstPlayerWhoBid(in actions: [GameAction]) -> Player.ID? {
        for action in actions {
            if case .placeBid(let playerID, _) = action {
                return playerID
            }
        }
        return nil
    }

    private func resettableInitialState(from state: GameState) -> GameState {
        GameState(
            players: state.players,
            teams: state.teams,
            rules: state.rules,
            dealerSeat: state.dealerSeat,
            roundNumber: state.roundNumber
        )
    }
}
