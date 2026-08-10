import Foundation

/// تقييم قوة اليد لأغراض المزايدة والتحليل.
///
/// مصدر حقيقة واحد يستخدمه: قرار المزايدة لدى الوكلاء الآليين، وأداة «حلّل يدي»،
/// وتحليل ما بعد الجولة. حساب القوة في ثلاثة أماكن مختلفة كان سيُنتج ثلاثة أحكام
/// متعارضة على نفس اليد، ويجعل نصيحة التطبيق تناقض لعب خصومه.
public struct HandEvaluation: Sendable, Equatable {
    /// تقييم اليد لو لُعبت صن.
    public let sunScore: Int
    /// تقييم اليد لكل لون كحكم.
    public let hokumScores: [Suit: Int]
    /// أفضل لون حكم وتقييمه.
    public let bestHokum: (suit: Suit, score: Int)?
    /// عدد الأوراق المؤكدة تقريبًا («البصوص» المطلقة: الآسات، وولد وتسعة الحكم).
    public let sureWinners: Int

    public static func == (lhs: HandEvaluation, rhs: HandEvaluation) -> Bool {
        lhs.sunScore == rhs.sunScore
            && lhs.hokumScores == rhs.hokumScores
            && lhs.bestHokum?.suit == rhs.bestHokum?.suit
            && lhs.bestHokum?.score == rhs.bestHokum?.score
            && lhs.sureWinners == rhs.sureWinners
    }

    /// أفضل تقييم متاح لهذه اليد أيًّا كان النمط.
    public var bestScore: Int {
        max(sunScore, bestHokum?.score ?? Int.min)
    }
}

/// يقيّم يدًا لغرض المزايدة. حتمي بالكامل: نفس اليد تعطي نفس التقييم دائمًا.
public enum HandEvaluator {

    /// يقيّم اليد لكل الأنماط الممكنة.
    ///
    /// - Parameter knownTrump: عند تقييم يد لجولة حكم معلومة اللون مسبقًا (الجولة
    ///   الأولى تُزايَد على لون الورقة المكشوفة فقط)، يُمرَّر اللون هنا فيُقصَر
    ///   تقييم الحكم عليه.
    public static func evaluate(hand: [PlayingCard], knownTrump: Suit? = nil) -> HandEvaluation {
        let sun = sunScore(hand: hand)

        var hokumScores: [Suit: Int] = [:]
        let candidates = knownTrump.map { [$0] } ?? Suit.allCases
        for suit in candidates {
            hokumScores[suit] = hokumScore(hand: hand, trumpSuit: suit)
        }

        // المرور على `Suit.allCases` بترتيبها الثابت لا على القاموس: ترتيب القاموس
        // غير مضمون في Swift، فاختيار الأفضل منه مباشرة كان يعطي لونًا مختلفًا بين
        // تشغيل وآخر عند تساوي لونين — وهو ما يكسر حتمية قرار الوكيل.
        var best: (suit: Suit, score: Int)?
        for suit in Suit.allCases {
            guard let score = hokumScores[suit] else { continue }
            if best == nil || score > best!.score { best = (suit, score) }
        }

        return HandEvaluation(
            sunScore: sun,
            hokumScores: hokumScores,
            bestHokum: best,
            sureWinners: sureWinners(hand: hand, trumpSuit: best?.suit)
        )
    }

    /// تقييم اليد في نمط الصن: الآسات والعشرات مصدر الأكلات، والأنواع الطويلة تسند بعضها.
    public static func sunScore(hand: [PlayingCard]) -> Int {
        var score = 0
        for card in hand {
            switch card.rank {
            case .ace: score += 11
            case .ten: score += 7
            case .king: score += 3
            case .queen: score += 1
            default: break
            }
        }
        // نوع طويل في الصن يتحول إلى أكلات بعد سحب الأوراق العالية.
        let bySuit = Dictionary(grouping: hand, by: \.suit).mapValues(\.count)
        for (_, count) in bySuit where count >= 4 {
            score += (count - 3) * 2
        }
        return score
    }

    /// تقييم اليد على أساس لون حكم محدد.
    ///
    /// يُعيد `Int.min` إن كان الحكم أقصر من ثلاث أوراق: شراء الحكم على ورقتين
    /// انتحار، وإعطاؤه تقييمًا منخفضًا فقط كان يجعله يُختار عند سوء بقية اليد.
    public static func hokumScore(hand: [PlayingCard], trumpSuit: Suit) -> Int {
        let trumps = hand.filter { $0.suit == trumpSuit }
        guard trumps.count >= 3 else { return Int.min }

        var score = trumps.count * 4
        if trumps.contains(where: { $0.rank == .jack }) { score += 13 }
        if trumps.contains(where: { $0.rank == .nine }) { score += 8 }
        if trumps.contains(where: { $0.rank == .ace }) { score += 4 }
        if trumps.contains(where: { $0.rank == .king }) && trumps.contains(where: { $0.rank == .queen }) {
            // البلوت في اليد: 20 نقطة مضمونة تُرجّح شراء هذا اللون تحديدًا.
            score += 6
        }

        for side in Suit.allCases where side != trumpSuit {
            let sideCards = hand.filter { $0.suit == side }
            if sideCards.contains(where: { $0.rank == .ace }) { score += 5 }
            // نوع جانبي فارغ أو وحيد = فرصة قطع مبكرة.
            if sideCards.count <= 1 { score += 3 }
        }
        return score
    }

    /// عدد الأوراق التي تكسب أكلة بشبه يقين في يد مفتوحة.
    public static func sureWinners(hand: [PlayingCard], trumpSuit: Suit?) -> Int {
        var count = hand.count { $0.rank == .ace }
        if let trumpSuit {
            count += hand.count { $0.suit == trumpSuit && ($0.rank == .jack || $0.rank == .nine) }
        }
        return count
    }
}
