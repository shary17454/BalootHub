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

    @Test("مؤشر مراجعة المزايدة يتفعل عند فاقد مزايدة مؤثر")
    func biddingReviewFlagRequiresMeaningfulBiddingLoss() {
        let team = Team(name: "أ")
        let player = Player(name: "لاعب", kind: .human, seat: .south, teamID: team.id)
        let decision = RoundBiddingDecisionAnalysis(
            stepIndex: 1,
            playerID: player.id,
            bid: .pass,
            recommendedBid: .sun,
            legalBids: [.pass, .sun],
            handStrengthScore: 42,
            estimatedLostPoints: 6,
            explanation: "اختبار"
        )
        let report = RoundAnalysisReport(
            playerID: player.id,
            scoreOutOf100: 70,
            decisions: [],
            biddingDecisions: [decision],
            projectOpportunities: [],
            multiplierDecisions: [],
            bestDecision: nil,
            worstDecision: nil,
            totalEstimatedLostPoints: 6,
            tacticalMistakes: [],
            strengths: [],
            weaknesses: [],
            tips: []
        )

        #expect(report.biddingMistakeCount == 1)
        #expect(report.biddingLostPoints == 6)
        #expect(report.needsBiddingReview)
    }

    @Test("أولوية مراجعة الجولة تبدأ بأكبر فاقد مؤثر")
    func primaryReviewPriorityUsesLargestMeaningfulLoss() {
        let team = Team(name: "أ")
        let player = Player(name: "لاعب", kind: .human, seat: .south, teamID: team.id)
        let playDecision = RoundDecisionAnalysis(
            stepIndex: 4,
            trickNumber: 2,
            playerID: player.id,
            playedCard: PlayingCard(suit: .clubs, rank: .seven),
            bestCard: PlayingCard(suit: .clubs, rank: .ace),
            secondBestCard: nil,
            selectedRank: 3,
            expectedImpact: -2,
            bestExpectedImpact: 8,
            estimatedLostPoints: 10,
            explanation: "اختبار"
        )
        let biddingDecision = RoundBiddingDecisionAnalysis(
            stepIndex: 1,
            playerID: player.id,
            bid: .pass,
            recommendedBid: .sun,
            legalBids: [.pass, .sun],
            handStrengthScore: 42,
            estimatedLostPoints: 6,
            explanation: "اختبار"
        )
        let report = RoundAnalysisReport(
            playerID: player.id,
            scoreOutOf100: 70,
            decisions: [playDecision],
            biddingDecisions: [biddingDecision],
            projectOpportunities: [],
            multiplierDecisions: [],
            bestDecision: nil,
            worstDecision: playDecision,
            totalEstimatedLostPoints: 16,
            tacticalMistakes: [],
            strengths: [],
            weaknesses: [],
            tips: []
        )

        #expect(report.playLostPoints == 10)
        #expect(report.needsPlayReview)
        #expect(report.primaryReviewPriority == .play)
    }

    @Test("أولوية مراجعة الجولة تستخدم ترتيبًا ثابتًا عند التعادل")
    func primaryReviewPriorityUsesStableTieOrder() {
        let team = Team(name: "أ")
        let player = Player(name: "لاعب", kind: .human, seat: .south, teamID: team.id)
        let biddingDecision = RoundBiddingDecisionAnalysis(
            stepIndex: 1,
            playerID: player.id,
            bid: .pass,
            recommendedBid: .sun,
            legalBids: [.pass, .sun],
            handStrengthScore: 42,
            estimatedLostPoints: 8,
            explanation: "اختبار"
        )
        let projectOpportunity = RoundProjectOpportunityAnalysis(
            stepIndex: 2,
            playerID: player.id,
            availableProjects: [Project(kind: .fifty, teamID: player.teamID, playerID: player.id, cards: [], points: 8)],
            declaredProjects: [],
            missedProjects: [Project(kind: .fifty, teamID: player.teamID, playerID: player.id, cards: [], points: 8)],
            estimatedLostPoints: 8,
            explanation: "اختبار"
        )
        let report = RoundAnalysisReport(
            playerID: player.id,
            scoreOutOf100: 70,
            decisions: [],
            biddingDecisions: [biddingDecision],
            projectOpportunities: [projectOpportunity],
            multiplierDecisions: [],
            bestDecision: nil,
            worstDecision: nil,
            totalEstimatedLostPoints: 16,
            tacticalMistakes: [],
            strengths: [],
            weaknesses: [],
            tips: []
        )

        #expect(report.primaryReviewPriority == RoundReviewPriority.bidding)
    }

    @Test("أولوية مراجعة الجولة تكون none عند عدم وجود فاقد")
    func primaryReviewPriorityIsNoneWithoutLoss() {
        let team = Team(name: "أ")
        let player = Player(name: "لاعب", kind: .human, seat: .south, teamID: team.id)
        let report = RoundAnalysisReport(
            playerID: player.id,
            scoreOutOf100: 100,
            decisions: [],
            biddingDecisions: [],
            projectOpportunities: [],
            multiplierDecisions: [],
            bestDecision: nil,
            worstDecision: nil,
            totalEstimatedLostPoints: 0,
            tacticalMistakes: [],
            strengths: [],
            weaknesses: [],
            tips: []
        )

        #expect(report.playLostPoints == 0)
        #expect(report.needsPlayReview == false)
        #expect(report.primaryReviewPriority == .none)
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
        #expect(report.biddingMistakeCount == 1)
        #expect(report.biddingLostPoints == report.biddingDecisions.first?.estimatedLostPoints)
        #expect(report.needsBiddingReview == (report.biddingLostPoints >= 4))
        #expect(report.tacticalMistakes.contains { $0.contains("في المزايدة") })
        #expect(report.tips.contains { $0.contains("راجع قرار المزايدة") })
        #expect(report.scoreOutOf100 < 100)
    }

    @Test("تحليل المزايدة يحسب الورقة المكشوفة ضمن يد المشتري")
    func biddingAnalysisIncludesUpCardForPurchaseEvaluation() throws {
        var rules = BalootRulesConfiguration.standard
        rules.multipliersEnabled = false
        rules.projectsRequireDeclaration = false

        let initial = GameState.newLocalMatch(rules: rules)
        var state = try GameEngine.apply(.dealCards(seed: 31), to: initial)
        let playerID = try #require(state.currentTurnPlayerID)
        state.bidding.upCard = PlayingCard(suit: .spades, rank: .queen)
        state.hands[playerID] = [
            PlayingCard(suit: .spades, rank: .jack),
            PlayingCard(suit: .spades, rank: .nine),
            PlayingCard(suit: .hearts, rank: .seven),
            PlayingCard(suit: .diamonds, rank: .eight),
            PlayingCard(suit: .clubs, rank: .seven)
        ]
        let biddingSnapshot = state

        state = try GameEngine.apply(.placeBid(playerID: playerID, bid: .hokum(suit: .spades)), to: state)

        let report = try RoundAnalyzer.analyze(
            initialState: biddingSnapshot,
            actions: [.placeBid(playerID: playerID, bid: .hokum(suit: .spades))],
            playerID: playerID
        )

        let decision = try #require(report.biddingDecisions.first)
        #expect(decision.bid == .hokum(suit: .spades))
        #expect(decision.recommendedBid == .hokum(suit: .spades))
        #expect(decision.matchedRecommendation)
    }

    @Test("تحليل الجولة يرصد فرص المشاريع التي لم تُعلن")
    func missedProjectDeclarationIsReportedAsLostOpportunity() throws {
        let scenario = try missedProjectScenario()

        var state = scenario.state
        state = try GameEngine.apply(.declareProjects(playerID: scenario.playerID, projects: []), to: state)

        let report = try RoundAnalyzer.analyze(
            initialState: scenario.initial,
            actions: state.actionHistory,
            playerID: scenario.playerID
        )

        let opportunity = try #require(report.projectOpportunities.first)
        #expect(opportunity.playerID == scenario.playerID)
        #expect(opportunity.availableProjects == scenario.availableProjects)
        #expect(opportunity.declaredProjects.isEmpty)
        #expect(opportunity.missedProjects == scenario.availableProjects)
        #expect(opportunity.capturedAllProjects == false)
        #expect(opportunity.estimatedLostPoints == scenario.availableProjects.reduce(0) { $0 + $1.points })
        #expect(report.projectMistakeCount == 1)
        #expect(report.projectLostPoints == opportunity.estimatedLostPoints)
        #expect(report.needsProjectReview)
        #expect(report.totalEstimatedLostPoints >= opportunity.estimatedLostPoints)
        #expect(report.tacticalMistakes.contains { $0.contains("فوّت إعلان مشروع") })
        #expect(report.weaknesses.contains { $0.contains("نقطة مشاريع") })
        #expect(report.tips.contains { $0.contains("قبل أول أكلة") })
    }

    @Test("تحليل الجولة يرصد قرار مضاعفة مخالفًا للتوصية")
    func nonRecommendedMultiplierDecisionIsReported() throws {
        let scenario = try multiplierScenarioRecommendingDouble()

        let final = try GameEngine.apply(.passMultiplier(playerID: scenario.playerID), to: scenario.state)
        let report = try RoundAnalyzer.analyze(
            initialState: scenario.state,
            actions: [.passMultiplier(playerID: scenario.playerID)],
            playerID: scenario.playerID
        )

        let decision = try #require(report.multiplierDecisions.first)
        #expect(final.bidding.doublingPasses == 1)
        #expect(decision.playerID == scenario.playerID)
        #expect(decision.selectedAction == .pass)
        #expect(decision.recommendedAction == .raise(.double))
        #expect(decision.legalActions.contains(.raise(.double)))
        #expect(decision.matchedRecommendation == false)
        #expect(decision.estimatedLostPoints > 0)
        #expect(report.multiplierMistakeCount == 1)
        #expect(report.multiplierLostPoints == decision.estimatedLostPoints)
        #expect(report.needsMultiplierReview)
        #expect(report.totalEstimatedLostPoints == decision.estimatedLostPoints)
        #expect(report.tacticalMistakes.contains { $0.contains("في المضاعفة") })
        #expect(report.weaknesses.contains { $0.contains("قرارات مضاعفة") })
        #expect(report.tips.contains { $0.contains("راجع قرار المضاعفة") })
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

    private func missedProjectScenario() throws -> (
        initial: GameState,
        state: GameState,
        playerID: Player.ID,
        availableProjects: [Project]
    ) {
        var rules = BalootRulesConfiguration.standard
        rules.multipliersEnabled = false
        rules.projectsRequireDeclaration = true

        for seed in UInt64(1)...300 {
            let initial = GameState.newLocalMatch(rules: rules)
            var state = try GameEngine.apply(.dealCards(seed: seed), to: initial)
            let buyerID = try #require(state.currentTurnPlayerID)
            let upSuit = try #require(state.bidding.upCard?.suit)
            state = try GameEngine.apply(.placeBid(playerID: buyerID, bid: .hokum(suit: upSuit)), to: state)
            for _ in 0..<3 {
                state = try GameEngine.apply(.placeBid(playerID: try #require(state.currentTurnPlayerID), bid: .pass), to: state)
            }

            guard state.phase == .declaring,
                  state.currentTurnPlayerID == buyerID else { continue }
            let available = GameEngine.declarableProjects(for: buyerID, state: state)
            if !available.isEmpty {
                return (initial, state, buyerID, available)
            }
        }

        throw RoundAnalyzer.AnalysisError.noPlayableDecisions
    }

    private func multiplierScenarioRecommendingDouble() throws -> (state: GameState, playerID: Player.ID) {
        var state = GameState.newLocalMatch(rules: .standard)
        state = try GameEngine.apply(.dealCards(seed: 17), to: state)
        let buyerID = try #require(state.currentTurnPlayerID)
        let upSuit = try #require(state.bidding.upCard?.suit)
        state = try GameEngine.apply(.placeBid(playerID: buyerID, bid: .hokum(suit: upSuit)), to: state)
        for _ in 0..<3 {
            state = try GameEngine.apply(.placeBid(playerID: try #require(state.currentTurnPlayerID), bid: .pass), to: state)
        }

        let playerID = try #require(state.currentTurnPlayerID)
        let hand: [PlayingCard] = [
            PlayingCard(suit: upSuit, rank: .jack),
            PlayingCard(suit: upSuit, rank: .nine),
            PlayingCard(suit: upSuit, rank: .ace),
            PlayingCard(suit: .hearts, rank: .ace),
            PlayingCard(suit: .diamonds, rank: .ace)
        ]
        state.hands[playerID] = hand

        #expect(GameEngine.legalMultiplierActions(for: playerID, state: state).contains(.raise(.double)))
        #expect(BiddingPolicy.standard.chooseMultiplierAction(hand: hand, state: state) == .raise(.double))
        return (state, playerID)
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
