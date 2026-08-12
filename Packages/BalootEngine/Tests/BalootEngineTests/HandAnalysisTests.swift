import Testing
@testable import BalootEngine

@Suite("تحليل اليد")
struct HandAnalysisTests {
    @Test("اليد القوية في الحكم تقترح شراء حكم بلونها")
    func strongHokumHandRecommendsTrumpSuit() {
        let hand = [
            PlayingCard(suit: .spades, rank: .jack),
            PlayingCard(suit: .spades, rank: .nine),
            PlayingCard(suit: .spades, rank: .ace),
            PlayingCard(suit: .spades, rank: .king),
            PlayingCard(suit: .spades, rank: .queen),
            PlayingCard(suit: .hearts, rank: .ace),
            PlayingCard(suit: .diamonds, rank: .ten),
            PlayingCard(suit: .clubs, rank: .seven)
        ]

        let analysis = HandAnalyzer.analyze(hand: hand)

        #expect(analysis.recommendedBid == .hokum(suit: .spades))
        #expect(analysis.bestTrumpSuit == .spades)
        #expect(analysis.projects.contains { $0.kind == .belot })
        #expect(analysis.confidence != .low)
        #expect(analysis.strengthPercent >= 70)
        #expect(analysis.buyConfidencePercent >= 70)
        #expect(analysis.hokumConfidencePercent >= 70)
        #expect(analysis.buyConfidencePercent == max(analysis.sunConfidencePercent, analysis.hokumConfidencePercent))
        #expect(analysis.decisionGrade == .strongBuy)
        #expect(analysis.strengths.contains { $0.contains("سباتي") })
        #expect(analysis.strengths.contains { $0.contains("الولد") })
        #expect(analysis.tacticalAdvice.contains("حكم سباتي"))
    }

    @Test("تحليل موقف مزايدة فعلي لا يقترح حكمًا غير قانوني")
    func constrainedBiddingAnalysisDoesNotRecommendUnavailableTrumpSuit() {
        let hand = [
            PlayingCard(suit: .spades, rank: .jack),
            PlayingCard(suit: .spades, rank: .nine),
            PlayingCard(suit: .spades, rank: .ace),
            PlayingCard(suit: .spades, rank: .king),
            PlayingCard(suit: .spades, rank: .queen),
            PlayingCard(suit: .hearts, rank: .seven),
            PlayingCard(suit: .diamonds, rank: .seven),
            PlayingCard(suit: .clubs, rank: .eight)
        ]

        let freeAnalysis = HandAnalyzer.analyze(hand: hand)
        let firstRoundAnalysis = HandAnalyzer.analyze(
            hand: hand,
            legalBids: [.pass, .sun, .hokum(suit: .hearts)]
        )

        #expect(freeAnalysis.recommendedBid == .hokum(suit: .spades))
        #expect(firstRoundAnalysis.recommendedBid == .pass)
        #expect(firstRoundAnalysis.tacticalAdvice.contains("تمرير"))
    }

    @Test("اليد الضعيفة تقترح بس")
    func weakHandRecommendsPass() {
        let hand = [
            PlayingCard(suit: .spades, rank: .seven),
            PlayingCard(suit: .spades, rank: .eight),
            PlayingCard(suit: .hearts, rank: .seven),
            PlayingCard(suit: .hearts, rank: .eight),
            PlayingCard(suit: .diamonds, rank: .seven),
            PlayingCard(suit: .diamonds, rank: .eight),
            PlayingCard(suit: .clubs, rank: .seven),
            PlayingCard(suit: .clubs, rank: .eight)
        ]

        let analysis = HandAnalyzer.analyze(hand: hand)

        #expect(analysis.recommendedBid == .pass)
        #expect(analysis.projects.isEmpty)
        #expect(analysis.strengthPercent < 50)
        #expect(analysis.buyConfidencePercent < 50)
        #expect(analysis.decisionGrade == .clearPass)
        #expect(analysis.weaknesses.contains { $0.contains("تقييم الصن") })
        #expect(analysis.tacticalAdvice.contains("تمرير"))
    }

    @Test("التحليل حتمي ولا يتأثر بترتيب إدخال الأوراق")
    func analysisIsDeterministicAcrossHandOrder() {
        let hand = [
            PlayingCard(suit: .hearts, rank: .ace),
            PlayingCard(suit: .diamonds, rank: .ace),
            PlayingCard(suit: .clubs, rank: .ace),
            PlayingCard(suit: .spades, rank: .ace),
            PlayingCard(suit: .hearts, rank: .ten),
            PlayingCard(suit: .diamonds, rank: .ten),
            PlayingCard(suit: .clubs, rank: .king),
            PlayingCard(suit: .spades, rank: .queen)
        ]

        let first = HandAnalyzer.analyze(hand: hand)
        let second = HandAnalyzer.analyze(hand: hand.reversed())

        #expect(first == second)
        #expect(first.recommendedBid == .sun)
        #expect(first.projects.contains { $0.kind == .fourHundred })
        #expect(first.strengths == second.strengths)
        #expect(first.weaknesses == second.weaknesses)
        #expect(first.tacticalAdvice == second.tacticalAdvice)
        #expect(first.strengthPercent == second.strengthPercent)
        #expect(first.buyConfidencePercent == second.buyConfidencePercent)
        #expect(first.sunConfidencePercent == second.sunConfidencePercent)
        #expect(first.hokumConfidencePercent == second.hokumConfidencePercent)
        #expect(first.decisionGrade == second.decisionGrade)
    }

    @Test("احتمالات تحليل اليد تبقى ضمن النطاق المئوي")
    func probabilityMetricsStayWithinPercentRange() {
        let hands = [
            [
                PlayingCard(suit: .spades, rank: .jack),
                PlayingCard(suit: .spades, rank: .nine),
                PlayingCard(suit: .spades, rank: .ace),
                PlayingCard(suit: .spades, rank: .king),
                PlayingCard(suit: .hearts, rank: .ace),
                PlayingCard(suit: .diamonds, rank: .ten),
                PlayingCard(suit: .clubs, rank: .seven),
                PlayingCard(suit: .clubs, rank: .eight)
            ],
            [
                PlayingCard(suit: .spades, rank: .seven),
                PlayingCard(suit: .spades, rank: .eight),
                PlayingCard(suit: .hearts, rank: .seven),
                PlayingCard(suit: .hearts, rank: .eight),
                PlayingCard(suit: .diamonds, rank: .seven),
                PlayingCard(suit: .diamonds, rank: .eight),
                PlayingCard(suit: .clubs, rank: .seven),
                PlayingCard(suit: .clubs, rank: .eight)
            ]
        ]

        for hand in hands {
            let analysis = HandAnalyzer.analyze(hand: hand)
            #expect((0...100).contains(analysis.strengthPercent))
            #expect((0...100).contains(analysis.buyConfidencePercent))
            #expect((0...100).contains(analysis.sunConfidencePercent))
            #expect((0...100).contains(analysis.hokumConfidencePercent))
        }
    }
}
