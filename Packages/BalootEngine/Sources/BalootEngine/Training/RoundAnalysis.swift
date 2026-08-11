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

/// تقرير تحليل الجولة بعد انتهائها.
public struct RoundAnalysisReport: Sendable, Equatable {
    public let playerID: Player.ID
    public let scoreOutOf100: Int
    public let decisions: [RoundDecisionAnalysis]
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

        for (index, action) in actions.enumerated() {
            if case .playCard(let actorID, let card) = action,
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

        guard !decisions.isEmpty else { throw AnalysisError.noPlayableDecisions }

        let totalLost = decisions.reduce(0) { $0 + $1.estimatedLostPoints }
        let nonExpertPenalty = decisions.filter { !$0.matchedExpert }.count * 4
        let score = max(0, min(100, 100 - (totalLost * 2) - nonExpertPenalty))

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
            bestDecision: bestDecision,
            worstDecision: worstDecision,
            totalEstimatedLostPoints: totalLost,
            tacticalMistakes: tacticalMistakes(from: decisions),
            strengths: strengths(from: decisions),
            weaknesses: weaknesses(from: decisions),
            tips: tips(from: decisions)
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

    private static func resettableInitialState(from state: GameState) -> GameState {
        GameState(
            players: state.players,
            teams: state.teams,
            rules: state.rules,
            dealerSeat: state.dealerSeat,
            roundNumber: state.roundNumber
        )
    }

    private static func tacticalMistakes(from decisions: [RoundDecisionAnalysis]) -> [String] {
        decisions
            .filter { !$0.matchedExpert }
            .sorted { lhs, rhs in
                if lhs.estimatedLostPoints != rhs.estimatedLostPoints { return lhs.estimatedLostPoints > rhs.estimatedLostPoints }
                return lhs.stepIndex < rhs.stepIndex
            }
            .prefix(3)
            .map { decision in
                "في الأكلة \(decision.trickNumber)، لعبت \(decision.playedCard.displayLabel) بينما اختيار الخبير \(decision.bestCard.displayLabel)."
            }
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

    private static func weaknesses(from decisions: [RoundDecisionAnalysis]) -> [String] {
        let costly = decisions.filter { $0.estimatedLostPoints > 0 }
        guard !costly.isEmpty else { return ["لا توجد نقطة ضعف واضحة في القرارات المحللة."] }
        return ["توجد \(costly.count) قرارات كان يمكن أن تحقق أثرًا نقطيًا أفضل حسب تحليل الخبير."]
    }

    private static func tips(from decisions: [RoundDecisionAnalysis]) -> [String] {
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
}
