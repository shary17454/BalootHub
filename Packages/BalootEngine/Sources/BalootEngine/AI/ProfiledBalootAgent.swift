import Foundation

/// وكيل آلي مبني فوق ``AIProfile``: يركّب سياسة لعب حسب المستوى وسياسة مزايدة حسب الشخصية.
///
/// هذا هو الوكيل الوحيد الذي ينبغي أن تستخدمه الواجهة. الوكلاء الثلاثة الأساسيون
/// (``SimpleBalootAgent`` و``SmartBalootAgent`` و``ExpertBalootAgent``) صاروا
/// **سياسات لعب** تُركَّب هنا، لا خصومًا يُختارون مباشرة: بناء خصم مستقل لكل شخصية
/// كان سيُنتج ثمانية محركات لعب متوازية يستحيل إبقاؤها متسقة.
public struct ProfiledBalootAgent: BalootAgent, Sendable {
    public let profile: AIProfile
    private let playPolicy: BalootAgent
    private let biddingPolicy: BiddingPolicy

    public init(profile: AIProfile) {
        self.profile = profile
        self.biddingPolicy = profile.biddingPolicy
        self.playPolicy = Self.makePlayPolicy(for: profile.level)
    }

    /// سياسة اللعب حسب عمق التحليل المطلوب للمستوى.
    private static func makePlayPolicy(for level: AIProfile.Level) -> BalootAgent {
        let samples = level.monteCarloSamples
        guard samples > 0 else {
            return level.tracksCardMemory ? SmartBalootAgent() : SimpleBalootAgent()
        }
        return ExpertBalootAgent(samples: samples)
    }

    // MARK: - اللعب

    public func chooseCard(hand: [PlayingCard], legalCards: [PlayingCard], state: GameState) -> PlayingCard {
        playPolicy.chooseCard(hand: hand, legalCards: legalCards, state: state)
    }

    public func chooseMode(hand: [PlayingCard], state: GameState) -> (mode: GameMode, trumpSuit: Suit?) {
        // النمط المبسّط لا يسمح بالتمرير، فنشتق القرار من نفس تقييم اليد المستخدم
        // في المزايدة الكاملة بدل سياسة ثانية قد تناقضها.
        let evaluation = HandEvaluator.evaluate(hand: hand)
        let sun = evaluation.sunScore + biddingPolicy.sunBias
        guard let best = evaluation.bestHokum, best.score != Int.min else { return (.sun, nil) }
        let hokum = best.score + biddingPolicy.hokumBias
        return hokum > sun ? (.hokum, best.suit) : (.sun, nil)
    }

    // MARK: - المزايدة

    public func chooseBid(hand: [PlayingCard], legalBids: [Bid], state: GameState) -> Bid {
        biddingPolicy.chooseBid(hand: hand, legalBids: legalBids, state: state)
    }

    public func chooseMultiplierAction(hand: [PlayingCard], state: GameState) -> MultiplierDecision {
        biddingPolicy.chooseMultiplierAction(hand: hand, state: state)
    }

    public func chooseProjectsToDeclare(available: [Project], state: GameState) -> [Project] {
        biddingPolicy.chooseProjectsToDeclare(available: available, state: state)
    }
}
