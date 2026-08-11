import Foundation

/// تحليل يد بلوت مفتوحة لأغراض التدريب وقرار الشراء.
public struct HandAnalysis: Sendable, Equatable {
    public enum Confidence: String, Sendable, Codable, CaseIterable {
        case low
        case medium
        case high
    }

    public let hand: [PlayingCard]
    public let evaluation: HandEvaluation
    public let recommendedBid: Bid
    public let confidence: Confidence
    public let projects: [Project]
    public let totalProjectPoints: Int

    public var bestTrumpSuit: Suit? {
        if case .hokum(let suit) = recommendedBid { return suit }
        return evaluation.bestHokum?.suit
    }

    public var strengthScore: Int {
        switch recommendedBid {
        case .pass:
            return evaluation.bestScore == Int.min ? 0 : evaluation.bestScore
        case .sun:
            return evaluation.sunScore
        case .hokum(let suit):
            return evaluation.hokumScores[suit] ?? 0
        }
    }
}

/// أداة تحليل اليد اليدوي. لا تعتمد على حالة واجهة أو أرقام عشوائية.
public enum HandAnalyzer {
    private static let analysisTeamID = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!
    private static let analysisPlayerID = UUID(uuidString: "00000000-0000-0000-0000-000000000201")!

    /// يحلل اليد ويقترح هل الأفضل تمرير، شراء صن، أو شراء حكم بلون معيّن.
    ///
    /// المنطق مبني على نفس ``HandEvaluator`` و``BiddingPolicy`` اللذين يستخدمهما
    /// اللاعب الآلي في المزايدة، حتى لا تعطي أداة التدريب نصيحة تخالف سلوك المحرك.
    public static func analyze(
        hand: [PlayingCard],
        rules: BalootRulesConfiguration = .standard,
        policy: BiddingPolicy = .standard
    ) -> HandAnalysis {
        let normalized = normalizedHand(hand)
        let evaluation = HandEvaluator.evaluate(hand: normalized)
        let recommended = recommendation(for: normalized, evaluation: evaluation, policy: policy)
        let projects = detectableProjects(for: normalized, recommendedBid: recommended, rules: rules)
        let projectPoints = projects.reduce(0) { $0 + $1.points }
        let confidence = confidence(for: recommended, evaluation: evaluation, policy: policy, projectPoints: projectPoints)

        return HandAnalysis(
            hand: normalized,
            evaluation: evaluation,
            recommendedBid: recommended,
            confidence: confidence,
            projects: projects,
            totalProjectPoints: projectPoints
        )
    }

    private static func normalizedHand(_ hand: [PlayingCard]) -> [PlayingCard] {
        Array(Set(hand)).sorted { lhs, rhs in
            if lhs.suit.ordinal != rhs.suit.ordinal { return lhs.suit.ordinal < rhs.suit.ordinal }
            return lhs.rank.sequenceOrder < rhs.rank.sequenceOrder
        }
    }

    private static func recommendation(for hand: [PlayingCard], evaluation: HandEvaluation, policy: BiddingPolicy) -> Bid {
        var bestBid: Bid = .pass
        var bestMargin = 0

        let sunMargin = evaluation.sunScore + policy.sunBias - (policy.sunThreshold - policy.riskTolerance)
        if sunMargin >= bestMargin {
            bestBid = .sun
            bestMargin = sunMargin
        }

        if let bestHokum = evaluation.bestHokum, bestHokum.score != Int.min {
            let hokumMargin = bestHokum.score + policy.hokumBias - (policy.hokumThreshold - policy.riskTolerance)
            if hokumMargin > bestMargin {
                bestBid = .hokum(suit: bestHokum.suit)
                bestMargin = hokumMargin
            }
        }

        return bestBid
    }

    private static func detectableProjects(
        for hand: [PlayingCard],
        recommendedBid: Bid,
        rules: BalootRulesConfiguration
    ) -> [Project] {
        let player = Player(
            id: analysisPlayerID,
            name: "Analyzer",
            kind: .human,
            seat: .south,
            teamID: analysisTeamID
        )
        let mode = recommendedBid.mode ?? .sun
        let trumpSuit = recommendedBid.trumpSuit
        return ProjectDetector.detect(
            hand: hand,
            player: player,
            mode: mode,
            trumpSuit: trumpSuit,
            rules: rules
        )
    }

    private static func confidence(
        for recommendedBid: Bid,
        evaluation: HandEvaluation,
        policy: BiddingPolicy,
        projectPoints: Int
    ) -> HandAnalysis.Confidence {
        let margin: Int
        switch recommendedBid {
        case .pass:
            let bestHokum = evaluation.bestHokum?.score == Int.min ? nil : evaluation.bestHokum?.score
            let bestBuyScore = max(evaluation.sunScore, bestHokum ?? Int.min)
            let closestThreshold = min(policy.sunThreshold, policy.hokumThreshold)
            margin = closestThreshold - bestBuyScore
        case .sun:
            margin = evaluation.sunScore - policy.sunThreshold + projectPoints / 10
        case .hokum(let suit):
            margin = (evaluation.hokumScores[suit] ?? 0) - policy.hokumThreshold + projectPoints / 10
        }

        if margin >= 12 { return .high }
        if margin >= 4 { return .medium }
        return .low
    }
}
