import Foundation

/// سياسة قرار المزايدة والمضاعفة، معاملاتها قابلة للضبط.
///
/// فصل السياسة عن الوكيل هو ما يجعل «مستويات» و«شخصيات» الذكاء الاصطناعي اختلافًا
/// حقيقيًا في التفكير لا أخطاءً عشوائية مصطنعة: كل شخصية تضبط نفس المعاملات بقيم
/// مختلفة فتُنتج سلوك مزايدة مختلفًا ومتّسقًا مع نفسه.
public struct BiddingPolicy: Sendable, Equatable {
    /// أدنى تقييم يبرّر شراء صن.
    public var sunThreshold: Int
    /// أدنى تقييم يبرّر شراء حكم.
    public var hokumThreshold: Int
    /// ترجيح إضافي للصن (شخصية «متخصص صن»).
    public var sunBias: Int
    /// ترجيح إضافي للحكم (شخصية «متخصص حكم»).
    public var hokumBias: Int
    /// خفض العتبات: قيمة أعلى ⇒ مخاطرة أكبر وشراء أجرأ.
    public var riskTolerance: Int
    /// أدنى تقييم يبرّر طلب الدبل على المشتري.
    public var doubleThreshold: Int
    /// هل تصعّد هذه الشخصية المضاعفة (ثري/فور/قهوة)؟
    public var escalatesMultiplier: Bool
    /// هل يخفي هذا الوكيل مشاريعه الصغيرة تكتيكيًا؟
    public var hidesSmallProjects: Bool

    public init(
        sunThreshold: Int = 30,
        hokumThreshold: Int = 34,
        sunBias: Int = 0,
        hokumBias: Int = 0,
        riskTolerance: Int = 0,
        doubleThreshold: Int = 40,
        escalatesMultiplier: Bool = false,
        hidesSmallProjects: Bool = false
    ) {
        self.sunThreshold = sunThreshold
        self.hokumThreshold = hokumThreshold
        self.sunBias = sunBias
        self.hokumBias = hokumBias
        self.riskTolerance = riskTolerance
        self.doubleThreshold = doubleThreshold
        self.escalatesMultiplier = escalatesMultiplier
        self.hidesSmallProjects = hidesSmallProjects
    }

    /// السياسة المتوازنة الافتراضية.
    public static let standard = BiddingPolicy()

    // MARK: - قرار المزايدة

    /// يختار مزايدة من بين المزايدات القانونية فقط.
    ///
    /// القرار حتمي: نفس اليد ونفس الحالة تعطي نفس المزايدة دائمًا، وهو شرط لصحة
    /// الـReplay ولإمكانية اختبار سلوك كل شخصية.
    public func chooseBid(hand: [PlayingCard], legalBids: [Bid], state: GameState) -> Bid {
        guard !legalBids.isEmpty else { return .pass }
        guard legalBids.contains(where: \.isBuy) else { return .pass }

        // شراء الشريك لا يُنافَس عليه إلا بفارق واضح: المزايدة فوق الشريك تُضعف
        // الفريق بدل أن تقوّيه.
        let partnerHoldsBuy = partnerOwnsCurrentBuy(state: state)

        let purchaseHand = Self.purchaseEvaluationHand(hand: hand, state: state)
        let evaluation = HandEvaluator.evaluate(hand: purchaseHand)
        var best: (bid: Bid, margin: Int)?

        for bid in legalBids where bid.isBuy {
            guard let score = score(for: bid, hand: purchaseHand, evaluation: evaluation) else { continue }
            let threshold = self.threshold(for: bid, state: state) + (partnerHoldsBuy ? partnerOverbidPenalty : 0)
            let margin = score - threshold
            guard margin >= 0 else { continue }
            if best == nil || margin > best!.margin { best = (bid, margin) }
        }

        return best?.bid ?? .pass
    }

    /// اليد المعروفة التي يملكها اللاعب عند تقييم الشراء في دورة المزايدة الكاملة.
    ///
    /// في البلوت الكامل لا يشتري اللاعب بخمس أوراق فقط: المشتري يأخذ الورقة المكشوفة
    /// بعد استقرار الشراء. لذلك يجب أن تدخل هذه الورقة في تقييم شراء الصن/الحكم،
    /// وإلا سيمرّر الوكيل يدًا صالحة لمجرد أن الورقة التي ستدخل يده لم تُحسب.
    static func purchaseEvaluationHand(hand: [PlayingCard], state: GameState) -> [PlayingCard] {
        guard state.rules.biddingStyle == .full,
              state.phase == .bidding,
              let upCard = state.bidding.upCard,
              !hand.contains(upCard)
        else { return hand }

        return hand + [upCard]
    }

    /// فارق إضافي مطلوب للمزايدة فوق شراء الشريك.
    private var partnerOverbidPenalty: Int { 12 }

    private func partnerOwnsCurrentBuy(state: GameState) -> Bool {
        guard let buyerID = state.bidding.currentBuy?.playerID,
              let currentID = state.currentTurnPlayerID,
              let buyer = state.player(id: buyerID),
              let current = state.player(id: currentID) else { return false }
        return buyer.id != current.id && buyer.teamID == current.teamID
    }

    private func score(for bid: Bid, hand: [PlayingCard], evaluation: HandEvaluation) -> Int? {
        switch bid {
        case .pass:
            return nil
        case .sun:
            return evaluation.sunScore + sunBias
        case .hokum(let suit):
            let raw = HandEvaluator.hokumScore(hand: hand, trumpSuit: suit)
            guard raw != Int.min else { return nil }
            return raw + hokumBias
        }
    }

    private func threshold(for bid: Bid, state: GameState) -> Int {
        let base: Int
        switch bid {
        case .sun: base = sunThreshold
        case .hokum: base = hokumThreshold
        case .pass: base = Int.max
        }

        // آخر متكلم في جولة الأشكال: التمرير يُلغي الجولة كلها بلا نقاط لأحد، فيُخفَّض
        // سقف الشراء قليلًا بدل إهدار توزيعة كاملة.
        let isLastChance = state.bidding.stage == .secondRound
            && state.bidding.actionsInCurrentRound == state.players.count - 1
            && state.bidding.currentBuy == nil
        return base - riskTolerance - (isLastChance ? 6 : 0)
    }

    // MARK: - قرار المضاعفة

    /// يقرر المضاعفة أو التمرير أو القفل حسب قوة اليد في النمط المشترى.
    public func chooseMultiplierAction(hand: [PlayingCard], state: GameState) -> MultiplierDecision {
        guard let mode = state.bidding.mode,
              let currentID = state.currentTurnPlayerID,
              let current = state.player(id: currentID) else { return .pass }

        // القفل: نملك المضاعفة الحالية ولا نريد تصعيد الخصم عليها.
        if state.bidding.multiplier != .none,
           current.teamID == state.bidding.multiplierRequesterTeamID {
            return state.rules.lockEnabled && !escalatesMultiplier ? .lock : escalate(state: state, hand: hand, mode: mode)
        }

        guard let next = state.bidding.multiplier.next, next <= state.rules.maximumMultiplier else {
            return .pass
        }

        let strength = defensiveStrength(hand: hand, mode: mode, trumpSuit: state.bidding.trumpSuit)
        let required = state.bidding.multiplier == .none
            ? doubleThreshold - riskTolerance
            : doubleThreshold - riskTolerance + escalationSurcharge

        guard strength >= required else { return .pass }
        guard state.bidding.multiplier == .none || escalatesMultiplier else { return .pass }
        return .raise(next)
    }

    /// تصعيد إضافي يتطلب يدًا أقوى: كل درجة فوق الدبل تضاعف الخسارة عند الخطأ.
    private var escalationSurcharge: Int { 10 }

    private func escalate(state: GameState, hand: [PlayingCard], mode: GameMode) -> MultiplierDecision {
        guard let next = state.bidding.multiplier.next, next <= state.rules.maximumMultiplier else { return .pass }
        let strength = defensiveStrength(hand: hand, mode: mode, trumpSuit: state.bidding.trumpSuit)
        return strength >= doubleThreshold - riskTolerance + escalationSurcharge ? .raise(next) : .pass
    }

    /// قوة اليد **دفاعيًا**: قدرتها على إسقاط المشتري لا على الشراء.
    ///
    /// تختلف عن تقييم الشراء: طول الحكم عديم القيمة لمن لا يملك الحكم، بينما الآسات
    /// وأوراق الحكم العالية هي ما يُسقط المشتري فعلًا.
    private func defensiveStrength(hand: [PlayingCard], mode: GameMode, trumpSuit: Suit?) -> Int {
        var score = 0
        for card in hand {
            switch card.rank {
            case .ace: score += 11
            case .ten: score += 6
            case .king: score += 3
            default: break
            }
        }
        if mode == .hokum, let trumpSuit {
            let trumps = hand.filter { $0.suit == trumpSuit }
            if trumps.contains(where: { $0.rank == .jack }) { score += 14 }
            if trumps.contains(where: { $0.rank == .nine }) { score += 9 }
            score += max(0, trumps.count - 2) * 3
        }
        return score
    }

    // MARK: - إعلان المشاريع

    /// يختار المشاريع التي تُعلَن. الإخفاء التكتيكي يقتصر على «سرا» وحدها: كتمان
    /// مشروع كبير خسارة مؤكدة لنقاطه مقابل مكسب معلوماتي لا يوازيها.
    public func chooseProjectsToDeclare(available: [Project], state: GameState) -> [Project] {
        guard hidesSmallProjects else { return available }
        let hasBigProject = available.contains { $0.kind != .sira && $0.kind != .belot }
        guard !hasBigProject else { return available }
        return available.filter { $0.kind != .sira }
    }
}
