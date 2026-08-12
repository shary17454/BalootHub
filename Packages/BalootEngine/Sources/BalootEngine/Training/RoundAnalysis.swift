import Foundation

/// تحليل قرار واحد داخل جولة مكتملة أو قابلة للإعادة.
public struct RoundDecisionAnalysis: Identifiable, Sendable, Equatable {
    public let stepIndex: Int
    public let trickNumber: Int
    public let playerID: Player.ID
    public let playedCard: PlayingCard
    public let bestCard: PlayingCard
    public let secondBestCard: PlayingCard?
    public let selectedRank: Int
    public let expectedImpact: Int
    public let bestExpectedImpact: Int
    public let estimatedLostPoints: Int
    public let explanation: String

    public var id: String {
        "\(stepIndex)-\(playedCard.suit.rawValue)-\(playedCard.rank.rawValue)"
    }

    public var matchedExpert: Bool {
        selectedRank == 1
    }
}

/// تحليل قرار مزايدة واحد داخل جولة قابلة للإعادة.
public struct RoundBiddingDecisionAnalysis: Identifiable, Sendable, Equatable {
    public let stepIndex: Int
    public let playerID: Player.ID
    public let bid: Bid
    public let recommendedBid: Bid
    public let legalBids: [Bid]
    public let handStrengthScore: Int
    public let estimatedLostPoints: Int
    public let explanation: String

    public var id: String {
        "\(stepIndex)-\(bid)"
    }

    public var matchedRecommendation: Bool {
        bid == recommendedBid
    }
}

/// تقرير تحليل الجولة بعد انتهائها.
public struct RoundAnalysisReport: Sendable, Equatable {
    public let playerID: Player.ID
    public let scoreOutOf100: Int
    public let decisions: [RoundDecisionAnalysis]
    public let biddingDecisions: [RoundBiddingDecisionAnalysis]
    public let bestDecision: RoundDecisionAnalysis?
    public let worstDecision: RoundDecisionAnalysis?
    public let totalEstimatedLostPoints: Int
    public let tacticalMistakes: [String]
    public let strengths: [String]
    public let weaknesses: [String]
    public let tips: [String]

    public var expertMatchRate: Double {
        guard !decisions.isEmpty else { return 0 }
        let matches = decisions.filter(\.matchedExpert).count
        return Double(matches) / Double(decisions.count)
    }
}

/// يعيد تشغيل الجولة من سجل الأفعال ويقارن قرارات لاعب محدد بقرار الخبير.
public enum RoundAnalyzer {
    public enum AnalysisError: Error, Sendable, Equatable {
        case playerNotFound
        case noReplayActions
        case noPlayableDecisions
    }

    public static func analyze(
        initialState: GameState,
        actions: [GameAction],
        playerID: Player.ID,
        difficulty: WhatToPlayDifficulty = .hard
    ) throws -> RoundAnalysisReport {
        guard initialState.player(id: playerID) != nil else { throw AnalysisError.playerNotFound }
        guard !actions.isEmpty else { throw AnalysisError.noReplayActions }

        var state = initialState
        state.actionHistory = []
        var decisions: [RoundDecisionAnalysis] = []
        var biddingDecisions: [RoundBiddingDecisionAnalysis] = []

        for (index, action) in actions.enumerated() {
            if case .placeBid(let actorID, let bid) = action,
               actorID == playerID,
               state.phase == .bidding,
               let decision = biddingDecisionAnalysis(
                    stepIndex: index,
                    playerID: actorID,
                    bid: bid,
                    state: state
               ) {
                biddingDecisions.append(decision)
            } else if case .chooseMode(let actorID, let mode, let trumpSuit) = action,
                      actorID == playerID,
                      state.phase == .bidding,
                      let decision = simpleBiddingDecisionAnalysis(
                        stepIndex: index,
                        playerID: actorID,
                        mode: mode,
                        trumpSuit: trumpSuit,
                        state: state
                      ) {
                biddingDecisions.append(decision)
            } else if case .playCard(let actorID, let card) = action,
                      actorID == playerID,
                      state.phase == .playing {
                if let decision = try decisionAnalysis(
                    stepIndex: index,
                    playerID: actorID,
                    playedCard: card,
                    state: state,
                    difficulty: difficulty
                ) {
                    decisions.append(decision)
                }
            }

            state = try GameEngine.apply(action, to: state)
        }

        guard !decisions.isEmpty || !biddingDecisions.isEmpty else { throw AnalysisError.noPlayableDecisions }

        let playLost = decisions.reduce(0) { $0 + $1.estimatedLostPoints }
        let biddingLost = biddingDecisions.reduce(0) { $0 + $1.estimatedLostPoints }
        let totalLost = playLost + biddingLost
        let nonExpertPenalty = decisions.filter { !$0.matchedExpert }.count * 4
        let biddingPenalty = biddingDecisions.filter { !$0.matchedRecommendation }.count * 8
        let score = max(0, min(100, 100 - (totalLost * 2) - nonExpertPenalty - biddingPenalty))

        let bestDecision = decisions
            .sorted { lhs, rhs in
                if lhs.matchedExpert != rhs.matchedExpert { return lhs.matchedExpert && !rhs.matchedExpert }
                if lhs.expectedImpact != rhs.expectedImpact { return lhs.expectedImpact > rhs.expectedImpact }
                return lhs.stepIndex < rhs.stepIndex
            }
            .first

        let worstDecision = decisions
            .sorted { lhs, rhs in
                if lhs.estimatedLostPoints != rhs.estimatedLostPoints { return lhs.estimatedLostPoints > rhs.estimatedLostPoints }
                if lhs.selectedRank != rhs.selectedRank { return lhs.selectedRank > rhs.selectedRank }
                return lhs.stepIndex < rhs.stepIndex
            }
            .first

        return RoundAnalysisReport(
            playerID: playerID,
            scoreOutOf100: score,
            decisions: decisions,
            biddingDecisions: biddingDecisions,
            bestDecision: bestDecision,
            worstDecision: worstDecision,
            totalEstimatedLostPoints: totalLost,
            tacticalMistakes: tacticalMistakes(from: decisions, biddingDecisions: biddingDecisions),
            strengths: strengths(from: decisions),
            weaknesses: weaknesses(from: decisions, biddingDecisions: biddingDecisions),
            tips: tips(from: decisions, biddingDecisions: biddingDecisions)
        )
    }

    public static func analyze(
        finalState: GameState,
        playerID: Player.ID,
        difficulty: WhatToPlayDifficulty = .hard
    ) throws -> RoundAnalysisReport {
        try analyze(initialState: resettableInitialState(from: finalState), actions: finalState.actionHistory, playerID: playerID, difficulty: difficulty)
    }

    private static func decisionAnalysis(
        stepIndex: Int,
        playerID: Player.ID,
        playedCard: PlayingCard,
        state: GameState,
        difficulty: WhatToPlayDifficulty
    ) throws -> RoundDecisionAnalysis? {
        let options = try WhatToPlayTrainer.analyzeOptions(state: state, playerID: playerID, difficulty: difficulty)
        guard let selected = options.first(where: { $0.card == playedCard }),
              let best = options.first(where: { $0.rank == 1 })
        else { return nil }

        let lost = max(0, best.expectedImpact - selected.expectedImpact)
        return RoundDecisionAnalysis(
            stepIndex: stepIndex,
            trickNumber: state.completedTricks.count + 1,
            playerID: playerID,
            playedCard: playedCard,
            bestCard: best.card,
            secondBestCard: options.first(where: { $0.rank == 2 })?.card,
            selectedRank: selected.rank,
            expectedImpact: selected.expectedImpact,
            bestExpectedImpact: best.expectedImpact,
            estimatedLostPoints: lost,
            explanation: selected.explanation
        )
    }

    private static func biddingDecisionAnalysis(
        stepIndex: Int,
        playerID: Player.ID,
        bid: Bid,
        state: GameState
    ) -> RoundBiddingDecisionAnalysis? {
        guard let hand = state.hands[playerID] else { return nil }
        let legal = GameEngine.legalBids(state: state)
        guard legal.contains(bid) else { return nil }
        let analysis = HandAnalyzer.analyze(hand: hand, rules: state.rules, legalBids: legal)
        return RoundBiddingDecisionAnalysis(
            stepIndex: stepIndex,
            playerID: playerID,
            bid: bid,
            recommendedBid: analysis.recommendedBid,
            legalBids: legal,
            handStrengthScore: analysis.strengthScore,
            estimatedLostPoints: biddingLostPoints(bid: bid, recommendedBid: analysis.recommendedBid, analysis: analysis),
            explanation: biddingExplanation(bid: bid, recommendedBid: analysis.recommendedBid, handStrengthScore: analysis.strengthScore)
        )
    }

    private static func simpleBiddingDecisionAnalysis(
        stepIndex: Int,
        playerID: Player.ID,
        mode: GameMode,
        trumpSuit: Suit?,
        state: GameState
    ) -> RoundBiddingDecisionAnalysis? {
        guard let hand = state.hands[playerID] else { return nil }
        let bid: Bid = mode == .sun ? .sun : .hokum(suit: trumpSuit ?? .hearts)
        let legal: [Bid] = [.pass, .sun] + Suit.allCases.map { Bid.hokum(suit: $0) }
        let analysis = HandAnalyzer.analyze(hand: hand, rules: state.rules, legalBids: legal)
        return RoundBiddingDecisionAnalysis(
            stepIndex: stepIndex,
            playerID: playerID,
            bid: bid,
            recommendedBid: analysis.recommendedBid,
            legalBids: legal,
            handStrengthScore: analysis.strengthScore,
            estimatedLostPoints: biddingLostPoints(bid: bid, recommendedBid: analysis.recommendedBid, analysis: analysis),
            explanation: biddingExplanation(bid: bid, recommendedBid: analysis.recommendedBid, handStrengthScore: analysis.strengthScore)
        )
    }

    private static func resettableInitialState(from state: GameState) -> GameState {
        GameState(
            players: state.players,
            teams: state.teams,
            rules: state.rules,
            dealerSeat: state.dealerSeat,
            roundNumber: state.roundNumber
        )
    }

    private static func tacticalMistakes(
        from decisions: [RoundDecisionAnalysis],
        biddingDecisions: [RoundBiddingDecisionAnalysis]
    ) -> [String] {
        let biddingMistakes = biddingDecisions
            .filter { !$0.matchedRecommendation }
            .prefix(2)
            .map { decision in
                "في المزايدة، اخترت \(bidLabel(decision.bid)) بينما تقييم اليد يقترح \(bidLabel(decision.recommendedBid))."
            }

        let playMistakes = decisions
            .filter { !$0.matchedExpert }
            .sorted { lhs, rhs in
                if lhs.estimatedLostPoints != rhs.estimatedLostPoints { return lhs.estimatedLostPoints > rhs.estimatedLostPoints }
                return lhs.stepIndex < rhs.stepIndex
            }
            .prefix(3 - min(2, biddingMistakes.count))
            .map { decision in
                "في الأكلة \(decision.trickNumber)، لعبت \(decision.playedCard.displayLabel) بينما اختيار الخبير \(decision.bestCard.displayLabel)."
            }

        return Array(biddingMistakes) + playMistakes
    }

    private static func strengths(from decisions: [RoundDecisionAnalysis]) -> [String] {
        var result: [String] = []
        let matches = decisions.filter(\.matchedExpert).count
        if matches > 0 {
            result.append("وافقت قرار الخبير في \(matches) من \(decisions.count) قرارات محللة.")
        }
        if decisions.allSatisfy({ $0.estimatedLostPoints == 0 }) {
            result.append("لم يظهر قرار تسبب بخسارة نقاط متوقعة في الأكلات المحللة.")
        }
        return result.isEmpty ? ["توجد قرارات قابلة للتحسين، لكن الجولة أصبحت قابلة للتحليل خطوة بخطوة."] : result
    }

    private static func weaknesses(
        from decisions: [RoundDecisionAnalysis],
        biddingDecisions: [RoundBiddingDecisionAnalysis]
    ) -> [String] {
        let costly = decisions.filter { $0.estimatedLostPoints > 0 }
        let biddingMisses = biddingDecisions.filter { !$0.matchedRecommendation }
        var result: [String] = []
        if !costly.isEmpty {
            result.append("توجد \(costly.count) قرارات كان يمكن أن تحقق أثرًا نقطيًا أفضل حسب تحليل الخبير.")
        }
        if !biddingMisses.isEmpty {
            result.append("توجد \(biddingMisses.count) قرارات مزايدة خالفت تقييم اليد وخيارات الشراء القانونية.")
        }
        return result.isEmpty ? ["لا توجد نقطة ضعف واضحة في القرارات المحللة."] : result
    }

    private static func tips(
        from decisions: [RoundDecisionAnalysis],
        biddingDecisions: [RoundBiddingDecisionAnalysis]
    ) -> [String] {
        if let biddingMiss = biddingDecisions.first(where: { !$0.matchedRecommendation }) {
            return [
                "راجع قرار المزايدة: \(bidLabel(biddingMiss.bid)) مقابل \(bidLabel(biddingMiss.recommendedBid)) حسب قوة اليد.",
                "قبل الشراء، احصر الخيارات القانونية ثم قارن قوة الصن بأفضل حكم متاح فقط."
            ]
        }

        guard let worst = decisions.max(by: {
            if $0.estimatedLostPoints != $1.estimatedLostPoints { return $0.estimatedLostPoints < $1.estimatedLostPoints }
            return $0.selectedRank < $1.selectedRank
        }) else {
            return []
        }

        if worst.matchedExpert {
            return ["استمر في مقارنة افتتاح الأكلة واختيار آخر لاعب؛ هذه المواضع أكثر ما يغيّر نتيجة الجولة."]
        }

        return [
            "راجع الأكلة \(worst.trickNumber): الفرق بين \(worst.playedCard.displayLabel) و\(worst.bestCard.displayLabel) هو أوضح موضع للتحسين.",
            "عند وجود ورقة خاسرة، لا ترمِ ورقة عالية إلا إذا كان ذلك يحمي الشريك أو يسحب حكمًا مهمًا."
        ]
    }

    private static func biddingExplanation(bid: Bid, recommendedBid: Bid, handStrengthScore: Int) -> String {
        if bid == recommendedBid {
            return "قرار المزايدة يطابق تقييم اليد الحالي بدرجة قوة \(handStrengthScore)."
        }
        return "تقييم اليد بدرجة \(handStrengthScore) يرجّح \(bidLabel(recommendedBid)) بدل \(bidLabel(bid))."
    }

    private static func biddingLostPoints(bid: Bid, recommendedBid: Bid, analysis: HandAnalysis) -> Int {
        guard bid != recommendedBid else { return 0 }
        let recommendedScore = score(for: recommendedBid, analysis: analysis)
        let selectedScore = score(for: bid, analysis: analysis)
        return max(1, recommendedScore - selectedScore)
    }

    private static func score(for bid: Bid, analysis: HandAnalysis) -> Int {
        switch bid {
        case .pass:
            return 0
        case .sun:
            return analysis.evaluation.sunScore
        case .hokum(let suit):
            let score = analysis.evaluation.hokumScores[suit] ?? 0
            return score == Int.min ? 0 : score
        }
    }

    private static func bidLabel(_ bid: Bid) -> String {
        switch bid {
        case .pass:
            return "بس"
        case .sun:
            return "صن"
        case .hokum(let suit):
            return "حكم \(suit.arabicName)"
        }
    }
}
