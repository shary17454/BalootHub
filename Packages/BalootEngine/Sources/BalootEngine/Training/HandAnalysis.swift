import Foundation

/// تحليل يد بلوت مفتوحة لأغراض التدريب وقرار الشراء.
public struct HandAnalysis: Sendable, Equatable {
    public enum Confidence: String, Sendable, Codable, CaseIterable {
        case low
        case medium
        case high
    }

    public enum DecisionGrade: String, Sendable, Codable, CaseIterable {
        case strongBid
        case cautiousBid
        case closePass
        case clearPass
    }

    public struct BidOption: Sendable, Equatable, Identifiable {
        public let id: String
        public let bid: Bid
        public let score: Int
        public let threshold: Int
        public let margin: Int
        public let confidencePercent: Int
        public let isRecommended: Bool
        public let title: String
        public let detail: String
    }

    public let hand: [PlayingCard]
    public let evaluation: HandEvaluation
    public let recommendedBid: Bid
    /// ترتيب بدائل المزايدة القانونية حسب قوة القرار والهامش عن عتبة الشراء.
    public let bidOptions: [BidOption]
    public let confidence: Confidence
    public let projects: [Project]
    public let totalProjectPoints: Int
    /// تقييم مئوي مبسط لقوة اليد يصلح للعرض والتدريب.
    public let strengthPercent: Int
    /// احتمال تقريبي أن تكون اليد صالحة للشراء حسب نفس سياسة المزايدة.
    public let bidConfidencePercent: Int
    /// احتمال تقريبي أن تكون اليد مناسبة للصن.
    public let sunConfidencePercent: Int
    /// احتمال تقريبي أن تكون اليد مناسبة لأفضل حكم متاح.
    public let hokumConfidencePercent: Int
    /// فرق تقييم الصن عن أفضل حكم متاح بعد تطبيق سياسة المزايدة.
    ///
    /// قيمة موجبة تعني أن الصن أقوى، وسالبة تعني أن الحكم أقوى.
    public let sunHokumScoreGap: Int
    /// عنوان قصير يقارن الصن بأفضل حكم.
    public let modeComparisonTitle: String
    /// تفسير عملي لسبب ترجيح الصن أو الحكم أو اعتبار القرار قريبًا.
    public let modeComparisonDetail: String
    /// ملخص تدريبي سريع يختصر قوة القرار قبل قراءة التفاصيل.
    public let decisionGrade: DecisionGrade
    /// عنوان قصير للخطوة التالية بعد قراءة التحليل.
    public let nextActionTitle: String
    /// شرح عملي للخطوة التالية، محسوب داخل المحرك.
    public let nextActionDetail: String
    /// أسباب إيجابية تدعم التوصية، محسوبة داخل المحرك لا داخل الواجهة.
    public let strengths: [String]
    /// مخاطر أو نواقص يجب الانتباه لها قبل الشراء.
    public let weaknesses: [String]
    /// نصيحة عملية قصيرة مبنية على نفس قرار الشراء.
    public let tacticalAdvice: String

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

/// نتيجة فحص مدخلات أداة «حلل يدي».
///
/// تفصل هذه البنية تحقق الإدخال عن واجهة SwiftUI، حتى يمكن استخدام نفس الفحص لاحقًا
/// مع إدخال يدوي آخر أو قراءة كاميرا/Vision دون أن يغيّر ذلك منطق التحليل نفسه.
public struct HandAnalysisInputValidation: Sendable, Equatable {
    public let requiredCardCount: Int
    public let cardCount: Int
    public let uniqueCardCount: Int
    public let duplicateCards: [PlayingCard]

    public var missingCardCount: Int {
        max(0, requiredCardCount - uniqueCardCount)
    }

    public var extraCardCount: Int {
        max(0, uniqueCardCount - requiredCardCount)
    }

    public var isValid: Bool {
        cardCount == requiredCardCount && uniqueCardCount == requiredCardCount && duplicateCards.isEmpty
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
        policy: BiddingPolicy = .standard,
        legalBids: [Bid]? = nil
    ) -> HandAnalysis {
        analyze(
            hand: hand,
            rules: rules,
            policy: policy,
            legalBids: legalBids,
            contextualRecommendedBid: nil
        )
    }

    /// يحلل يد لاعب في سياق مزايدة حقيقي.
    ///
    /// هذا المسار هو الأنسب لتحليل الجولة وReplay؛ لأنه يستخدم نفس ``BiddingPolicy``
    /// مع ``GameState`` بدل تحليل اليد بمعزل عن الدور. بذلك تدخل في القرار عوامل مثل
    /// الورقة المكشوفة التي سيأخذها المشتري، شراء الشريك الحالي، وخفض عتبة آخر فرصة
    /// في جولة الأشكال.
    public static func analyze(
        playerID: Player.ID,
        state: GameState,
        policy: BiddingPolicy = .standard
    ) -> HandAnalysis? {
        guard let hand = state.hands[playerID] else { return nil }
        let legal = GameEngine.legalBids(for: playerID, state: state)
        guard !legal.isEmpty else { return nil }
        let bidHand = BiddingPolicy.bidEvaluationHand(hand: hand, state: state)
        let recommended = policy.chooseBid(hand: hand, legalBids: legal, state: state)
        return analyze(
            hand: bidHand,
            rules: state.rules,
            policy: policy,
            legalBids: legal,
            contextualRecommendedBid: recommended
        )
    }

    private static func analyze(
        hand: [PlayingCard],
        rules: BalootRulesConfiguration,
        policy: BiddingPolicy,
        legalBids: [Bid]?,
        contextualRecommendedBid: Bid?
    ) -> HandAnalysis {
        let normalized = normalizedHand(hand)
        let evaluation = HandEvaluator.evaluate(hand: normalized)
        let options = normalizedBidOptions(legalBids)
        let recommended = contextualRecommendedBid ?? recommendation(
            for: normalized,
            evaluation: evaluation,
            policy: policy,
            legalBids: options
        )
        let bidOptions = rankedBidOptions(
            for: normalized,
            evaluation: evaluation,
            policy: policy,
            legalBids: options,
            recommendedBid: recommended
        )
        let projects = detectableProjects(for: normalized, recommendedBid: recommended, rules: rules)
        let projectPoints = projects.reduce(0) { $0 + $1.points }
        let metrics = probabilityMetrics(
            evaluation: evaluation,
            recommendedBid: recommended,
            policy: policy,
            projectPoints: projectPoints
        )
        let comparison = modeComparison(evaluation: evaluation, policy: policy)
        let confidence = confidence(for: recommended, evaluation: evaluation, policy: policy, projectPoints: projectPoints)
        let grade = decisionGrade(
            recommendedBid: recommended,
            confidence: confidence,
            bidConfidencePercent: metrics.bidConfidencePercent
        )
        let nextAction = nextAction(
            for: recommended,
            grade: grade,
            metrics: metrics,
            projects: projects
        )
        let rationale = rationale(
            for: normalized,
            recommendedBid: recommended,
            evaluation: evaluation,
            projects: projects,
            totalProjectPoints: projectPoints,
            policy: policy
        )

        return HandAnalysis(
            hand: normalized,
            evaluation: evaluation,
            recommendedBid: recommended,
            bidOptions: bidOptions,
            confidence: confidence,
            projects: projects,
            totalProjectPoints: projectPoints,
            strengthPercent: metrics.strengthPercent,
            bidConfidencePercent: metrics.bidConfidencePercent,
            sunConfidencePercent: metrics.sunConfidencePercent,
            hokumConfidencePercent: metrics.hokumConfidencePercent,
            sunHokumScoreGap: comparison.gap,
            modeComparisonTitle: comparison.title,
            modeComparisonDetail: comparison.detail,
            decisionGrade: grade,
            nextActionTitle: nextAction.title,
            nextActionDetail: nextAction.detail,
            strengths: rationale.strengths,
            weaknesses: rationale.weaknesses,
            tacticalAdvice: rationale.advice
        )
    }

    public static func inputValidation(
        for hand: [PlayingCard],
        requiredCardCount: Int = 8
    ) -> HandAnalysisInputValidation {
        var counts: [PlayingCard: Int] = [:]
        for card in hand {
            counts[card, default: 0] += 1
        }
        let duplicates = counts
            .filter { $0.value > 1 }
            .map(\.key)
            .sorted {
                if $0.suit.ordinal != $1.suit.ordinal { return $0.suit.ordinal < $1.suit.ordinal }
                return $0.rank.sequenceOrder < $1.rank.sequenceOrder
            }

        return HandAnalysisInputValidation(
            requiredCardCount: requiredCardCount,
            cardCount: hand.count,
            uniqueCardCount: counts.count,
            duplicateCards: duplicates
        )
    }

    private static func normalizedHand(_ hand: [PlayingCard]) -> [PlayingCard] {
        Array(Set(hand)).sorted { lhs, rhs in
            if lhs.suit.ordinal != rhs.suit.ordinal { return lhs.suit.ordinal < rhs.suit.ordinal }
            return lhs.rank.sequenceOrder < rhs.rank.sequenceOrder
        }
    }

    private static func recommendation(
        for hand: [PlayingCard],
        evaluation: HandEvaluation,
        policy: BiddingPolicy,
        legalBids: [Bid]?
    ) -> Bid {
        let options = normalizedBidOptions(legalBids)
        guard options.contains(where: \.isBid) else { return .pass }

        var best: (bid: Bid, margin: Int)?
        for bid in options where bid.isBid {
            guard let score = score(for: bid, hand: hand, evaluation: evaluation, policy: policy) else { continue }
            let margin = score - threshold(for: bid, policy: policy)
            guard margin >= 0 else { continue }
            if best == nil || margin > best!.margin {
                best = (bid, margin)
            }
        }

        return best?.bid ?? .pass
    }

    private static func rankedBidOptions(
        for hand: [PlayingCard],
        evaluation: HandEvaluation,
        policy: BiddingPolicy,
        legalBids: [Bid],
        recommendedBid: Bid
    ) -> [HandAnalysis.BidOption] {
        legalBids.compactMap { bid -> HandAnalysis.BidOption? in
            let threshold = threshold(for: bid, policy: policy)
            let optionScoreValue: Int
            let margin: Int
            let confidence: Int
            switch bid {
            case .pass:
                let bestBidScore = bestAvailableBidScore(
                    hand: hand,
                    evaluation: evaluation,
                    policy: policy,
                    legalBids: legalBids
                )
                let passThreshold = min(policy.sunThreshold, policy.hokumThreshold) - policy.riskTolerance
                optionScoreValue = bestBidScore == Int.min ? 100 : max(0, passThreshold - bestBidScore)
                margin = recommendedBid == .pass ? optionScoreValue : -max(1, bestBidScore - passThreshold)
                confidence = recommendedBid == .pass
                    ? clampPercent(55 + optionScoreValue * 4)
                    : clampPercent(45 - max(0, bestBidScore - passThreshold) * 4)
            case .sun, .hokum:
                guard let optionScore = score(for: bid, hand: hand, evaluation: evaluation, policy: policy) else {
                    return nil
                }
                optionScoreValue = optionScore
                margin = optionScore - threshold
                confidence = confidencePercent(score: optionScore, threshold: threshold)
            }

            return HandAnalysis.BidOption(
                id: bidStableID(bid),
                bid: bid,
                score: optionScoreValue,
                threshold: threshold == Int.max ? 0 : threshold,
                margin: margin,
                confidencePercent: confidence,
                isRecommended: bid == recommendedBid,
                title: bidTitle(bid),
                detail: bidOptionDetail(
                    bid: bid,
                    score: optionScoreValue,
                    threshold: threshold == Int.max ? 0 : threshold,
                    margin: margin,
                    confidencePercent: confidence,
                    recommendedBid: recommendedBid
                )
            )
        }
        .sorted(by: bidOptionSort)
    }

    private static func bestAvailableBidScore(
        hand: [PlayingCard],
        evaluation: HandEvaluation,
        policy: BiddingPolicy,
        legalBids: [Bid]
    ) -> Int {
        legalBids
            .filter(\.isBid)
            .compactMap { score(for: $0, hand: hand, evaluation: evaluation, policy: policy) }
            .max() ?? Int.min
    }

    private static func bidOptionSort(_ lhs: HandAnalysis.BidOption, _ rhs: HandAnalysis.BidOption) -> Bool {
        if lhs.isRecommended != rhs.isRecommended { return lhs.isRecommended }
        if lhs.margin != rhs.margin { return lhs.margin > rhs.margin }
        if lhs.confidencePercent != rhs.confidencePercent { return lhs.confidencePercent > rhs.confidencePercent }
        return bidOrder(lhs.bid) < bidOrder(rhs.bid)
    }

    private static func bidStableID(_ bid: Bid) -> String {
        switch bid {
        case .pass:
            return "pass"
        case .sun:
            return "sun"
        case .hokum(let suit):
            return "hokum-\(suit.ordinal)"
        }
    }

    private static func bidOrder(_ bid: Bid) -> Int {
        switch bid {
        case .pass:
            return 0
        case .sun:
            return 1
        case .hokum(let suit):
            return 10 + suit.ordinal
        }
    }

    private static func bidTitle(_ bid: Bid) -> String {
        switch bid {
        case .pass:
            return "بس"
        case .sun:
            return "صن"
        case .hokum(let suit):
            return "حكم \(suit.arabicName)"
        }
    }

    private static func bidOptionDetail(
        bid: Bid,
        score: Int,
        threshold: Int,
        margin: Int,
        confidencePercent: Int,
        recommendedBid: Bid
    ) -> String {
        let status = bid == recommendedBid ? "الخيار الموصى به" : (margin >= 0 ? "خيار قابل للشراء" : "أقل من عتبة الشراء")
        if bid == .pass {
            return "\(status): ثقة \(confidencePercent)%، هامش أمان \(margin)."
        }
        return "\(status): تقييم \(score)، العتبة \(threshold)، الهامش \(margin)، الثقة \(confidencePercent)%."
    }

    private static func normalizedBidOptions(_ legalBids: [Bid]?) -> [Bid] {
        guard let legalBids else {
            return [.pass, .sun] + Suit.allCases.map { Bid.hokum(suit: $0) }
        }

        var seen: Set<Bid> = []
        var result: [Bid] = []
        for bid in legalBids where !seen.contains(bid) {
            seen.insert(bid)
            result.append(bid)
        }
        return result.isEmpty ? [.pass] : result
    }

    private static func score(
        for bid: Bid,
        hand: [PlayingCard],
        evaluation: HandEvaluation,
        policy: BiddingPolicy
    ) -> Int? {
        switch bid {
        case .pass:
            return nil
        case .sun:
            return evaluation.sunScore + policy.sunBias
        case .hokum(let suit):
            let raw = HandEvaluator.hokumScore(hand: hand, trumpSuit: suit)
            guard raw != Int.min else { return nil }
            return raw + policy.hokumBias
        }
    }

    private static func threshold(for bid: Bid, policy: BiddingPolicy) -> Int {
        switch bid {
        case .pass:
            return Int.max
        case .sun:
            return policy.sunThreshold - policy.riskTolerance
        case .hokum:
            return policy.hokumThreshold - policy.riskTolerance
        }
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

    private static func probabilityMetrics(
        evaluation: HandEvaluation,
        recommendedBid: Bid,
        policy: BiddingPolicy,
        projectPoints: Int
    ) -> (strengthPercent: Int, bidConfidencePercent: Int, sunConfidencePercent: Int, hokumConfidencePercent: Int) {
        let bestHokumScore = evaluation.bestHokum?.score == Int.min ? 0 : (evaluation.bestHokum?.score ?? 0)
        let sunPercent = confidencePercent(
            score: evaluation.sunScore + projectPoints / 4,
            threshold: policy.sunThreshold
        )
        let hokumPercent = confidencePercent(
            score: bestHokumScore + projectPoints / 4,
            threshold: policy.hokumThreshold
        )
        let bidPercent = max(sunPercent, hokumPercent)
        let recommendedBonus: Int
        switch recommendedBid {
        case .pass:
            recommendedBonus = 0
        case .sun:
            recommendedBonus = 6
        case .hokum:
            recommendedBonus = 8
        }
        let strengthPercent = clampPercent(
            max(evaluation.sunScore, bestHokumScore)
                + projectPoints / 3
                + evaluation.sureWinners * 4
                + recommendedBonus
        )

        return (
            strengthPercent,
            bidPercent,
            sunPercent,
            hokumPercent
        )
    }

    private static func modeComparison(
        evaluation: HandEvaluation,
        policy: BiddingPolicy
    ) -> (gap: Int, title: String, detail: String) {
        let sunScore = evaluation.sunScore + policy.sunBias
        guard let bestHokum = evaluation.bestHokum, bestHokum.score != Int.min else {
            return (
                sunScore,
                "الصن هو الخيار الوحيد الواضح",
                "لا يوجد لون حكم كافٍ للمقارنة؛ ركّز على قوة الصن والأوراق العالية قبل الشراء."
            )
        }

        let hokumScore = bestHokum.score + policy.hokumBias
        let gap = sunScore - hokumScore
        if gap >= 8 {
            return (
                gap,
                "الصن أقوى بفارق \(gap)",
                "تقييم الصن أعلى بوضوح من أفضل حكم \(bestHokum.suit.arabicName)، فاليد تعتمد على أوراق عالية موزعة لا على لون حكم واحد."
            )
        }
        if gap <= -8 {
            return (
                gap,
                "الحكم أقوى بفارق \(abs(gap))",
                "أفضل حكم هو \(bestHokum.suit.arabicName) ويتفوق بوضوح على الصن؛ ابحث عن السيطرة في هذا اللون قبل التفكير بالصن."
            )
        }
        return (
            gap,
            "القرار قريب بين الصن والحكم",
            "الفارق \(abs(gap)) فقط بين الصن وأفضل حكم \(bestHokum.suit.arabicName)، لذلك سياق المزايدة والورقة المكشوفة قد يغيّران القرار."
        )
    }

    private static func confidencePercent(score: Int, threshold: Int) -> Int {
        clampPercent(50 + ((score - threshold) * 5))
    }

    private static func clampPercent(_ value: Int) -> Int {
        min(100, max(0, value))
    }

    private static func decisionGrade(
        recommendedBid: Bid,
        confidence: HandAnalysis.Confidence,
        bidConfidencePercent: Int
    ) -> HandAnalysis.DecisionGrade {
        switch recommendedBid {
        case .pass:
            return bidConfidencePercent >= 40 ? .closePass : .clearPass
        case .sun, .hokum:
            return confidence == .high || bidConfidencePercent >= 75 ? .strongBid : .cautiousBid
        }
    }

    private static func nextAction(
        for recommendedBid: Bid,
        grade: HandAnalysis.DecisionGrade,
        metrics: (strengthPercent: Int, bidConfidencePercent: Int, sunConfidencePercent: Int, hokumConfidencePercent: Int),
        projects: [Project]
    ) -> (title: String, detail: String) {
        let projectHint = projects.isEmpty ? "" : " وأعلن مشاريعك في توقيتها قبل أول أكلة."
        switch grade {
        case .strongBid:
            switch recommendedBid {
            case .hokum(let suit):
                return (
                    "ادخل شراء بثقة",
                    "أفضل مسار ظاهر هو حكم \(suit.arabicName) بنسبة \(metrics.hokumConfidencePercent)%. ركّز على سحب الحكم العالي مبكرًا\(projectHint)"
                )
            case .sun:
                return (
                    "ادخل صن بثقة",
                    "قوة الصن \(metrics.sunConfidencePercent)%؛ حافظ على الآسات والعشرات ولا تفتح لونًا يسهّل قطع الخصم\(projectHint)"
                )
            case .pass:
                return ("راقب المزايدة", "اليد قوية نسبيًا لكن خيار الشراء غير متاح في هذا السياق؛ انتظر قرار الشريك.")
            }
        case .cautiousBid:
            return (
                "اشترِ بحذر",
                "الشراء ممكن لكنه ليس مضمونًا؛ لا ترفع المخاطرة إلا إذا كان الشريك يدعمك أو كانت المزايدة تسمح بسعر منخفض\(projectHint)"
            )
        case .closePass:
            return (
                "مرّر وراقب الشريك",
                "اليد قريبة من الشراء لكنها لا تكفي وحدها. إذا اشترى الشريك فخطتك حماية أكلاته لا قيادة الجولة."
            )
        case .clearPass:
            return (
                "مرّر بوضوح",
                "اليد ضعيفة للشراء الآن؛ هدفك تقليل خسارة النقاط واصطياد فرصة قطع أو تلزيم لاحقًا."
            )
        }
    }

    private static func rationale(
        for hand: [PlayingCard],
        recommendedBid: Bid,
        evaluation: HandEvaluation,
        projects: [Project],
        totalProjectPoints: Int,
        policy: BiddingPolicy
    ) -> (strengths: [String], weaknesses: [String], advice: String) {
        var strengths: [String] = []
        var weaknesses: [String] = []

        let aces = hand.filter { $0.rank == .ace }
        let tens = hand.filter { $0.rank == .ten }
        if !aces.isEmpty {
            strengths.append("لديك \(aces.count) آس؛ الآسات تمنحك أكلات قوية خصوصًا في الصن.")
        }
        if tens.count >= 2 {
            strengths.append("وجود \(tens.count) عشرات يرفع قيمة اليد إذا استطعت حماية الأكلات.")
        }

        if let bestHokum = evaluation.bestHokum, bestHokum.score != Int.min {
            let trumpCards = hand.filter { $0.suit == bestHokum.suit }
            let hasJack = trumpCards.contains { $0.rank == .jack }
            let hasNine = trumpCards.contains { $0.rank == .nine }
            strengths.append("أفضل حكم ظاهر هو \(bestHokum.suit.arabicName) وفيه \(trumpCards.count) أوراق.")
            if hasJack || hasNine {
                let highTrump = [hasJack ? "الولد" : nil, hasNine ? "التسعة" : nil].compactMap { $0 }.joined(separator: " و")
                strengths.append("تمتلك \(highTrump) في الحكم المحتمل، وهذا يعطي سيطرة مباشرة على الأكلات.")
            }
        }

        if totalProjectPoints > 0 {
            let names = projects.map(\.kind.arabicName).joined(separator: "، ")
            strengths.append("المشاريع المكتشفة: \(names) بقيمة \(totalProjectPoints) نقطة.")
        }

        let shortSuits = Suit.allCases.filter { suit in hand.filter { $0.suit == suit }.count <= 1 }
        if !shortSuits.isEmpty {
            let names = shortSuits.map(\.arabicName).joined(separator: "، ")
            strengths.append("الألوان القصيرة عندك (\(names)) قد تفتح فرصة قطع مبكر إذا أصبحت الجولة حكم.")
        }

        if evaluation.sunScore < policy.sunThreshold {
            weaknesses.append("تقييم الصن \(evaluation.sunScore) أقل من عتبة الشراء الآمنة \(policy.sunThreshold).")
        }
        if (evaluation.bestHokum?.score ?? Int.min) < policy.hokumThreshold {
            weaknesses.append("لا يوجد حكم يتجاوز عتبة شراء الحكم الآمنة \(policy.hokumThreshold).")
        }
        if evaluation.sureWinners <= 1 {
            weaknesses.append("عدد الأكلات شبه المضمونة قليل، لذلك شراء اليد يحمل مخاطرة طياح.")
        }

        let advice: String
        switch recommendedBid {
        case .pass:
            advice = "الأفضل تمرير الدور: اليد لا تملك سيطرة كافية في الصن ولا حكمًا واضحًا. انتظر دعم الشريك أو فرصة شراء أقوى."
        case .sun:
            advice = "اشترِ صن إذا بقي الخيار متاحًا: قوة اليد موزعة على الآسات والعشرات، ولا تحتاج لون حكم محدد كي تنتج نقاطًا."
        case .hokum(let suit):
            let projectHint = totalProjectPoints > 0 ? " واستفد من المشاريع بدل الاعتماد عليها وحدها" : ""
            advice = "اشترِ حكم \(suit.arabicName): ركّز على سحب الحكم في الوقت المناسب\(projectHint)، واحذر صرف الحكم العالي في أكلة قليلة النقاط."
        }

        if strengths.isEmpty {
            strengths.append("لا توجد قوة بارزة تكفي وحدها لتبرير شراء مرتفع.")
        }
        if weaknesses.isEmpty {
            weaknesses.append("لا تظهر مخاطرة كبيرة في التقييم الأولي، لكن قرار الشريك والمزايدة قد يغيّران الأفضل.")
        }

        return (strengths, weaknesses, advice)
    }
}
