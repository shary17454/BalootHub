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
        #expect(analysis.bidConfidencePercent >= 70)
        #expect(analysis.hokumConfidencePercent >= 70)
        #expect(analysis.bidConfidencePercent == max(analysis.sunConfidencePercent, analysis.hokumConfidencePercent))
        #expect(analysis.decisionGrade == .strongBid)
        #expect(analysis.bidOptions.first?.bid == .hokum(suit: .spades))
        #expect(analysis.bidOptions.first?.isRecommended == true)
        #expect(analysis.bidOptions.first?.margin ?? -1 >= 0)
        #expect(analysis.nextActionTitle.contains("شراء"))
        #expect(analysis.nextActionDetail.contains("حكم سباتي"))
        #expect(analysis.sunHokumScoreGap < 0)
        #expect(analysis.modeComparisonTitle.contains("الحكم"))
        #expect(analysis.modeComparisonDetail.contains("سباتي"))
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
        #expect(firstRoundAnalysis.bidOptions.contains { $0.bid == .pass && $0.isRecommended })
        #expect(!firstRoundAnalysis.bidOptions.contains { $0.bid == .hokum(suit: .spades) })
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
        #expect(analysis.bidConfidencePercent < 50)
        #expect(analysis.decisionGrade == .clearPass)
        #expect(analysis.nextActionTitle.contains("مرّر"))
        #expect(analysis.nextActionDetail.contains("تقليل خسارة"))
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
        #expect(first.sunHokumScoreGap > 0)
        #expect(first.modeComparisonTitle.contains("الصن"))
        #expect(first.strengths == second.strengths)
        #expect(first.weaknesses == second.weaknesses)
        #expect(first.tacticalAdvice == second.tacticalAdvice)
        #expect(first.strengthPercent == second.strengthPercent)
        #expect(first.bidConfidencePercent == second.bidConfidencePercent)
        #expect(first.sunConfidencePercent == second.sunConfidencePercent)
        #expect(first.hokumConfidencePercent == second.hokumConfidencePercent)
        #expect(first.decisionGrade == second.decisionGrade)
        #expect(first.nextActionTitle == second.nextActionTitle)
        #expect(first.nextActionDetail == second.nextActionDetail)
        #expect(first.sunHokumScoreGap == second.sunHokumScoreGap)
        #expect(first.modeComparisonTitle == second.modeComparisonTitle)
        #expect(first.modeComparisonDetail == second.modeComparisonDetail)
        #expect(first.bidOptions == second.bidOptions)
        #expect(first.bidOptions.map(\.id) == second.bidOptions.map(\.id))
    }

    @Test("مقارنة الصن والحكم تشرح القرار القريب")
    func modeComparisonExplainsCloseDecision() {
        let hand = [
            PlayingCard(suit: .spades, rank: .ace),
            PlayingCard(suit: .spades, rank: .jack),
            PlayingCard(suit: .spades, rank: .nine),
            PlayingCard(suit: .hearts, rank: .ace),
            PlayingCard(suit: .hearts, rank: .king),
            PlayingCard(suit: .diamonds, rank: .ten),
            PlayingCard(suit: .clubs, rank: .ten),
            PlayingCard(suit: .clubs, rank: .seven)
        ]

        let analysis = HandAnalyzer.analyze(hand: hand)

        #expect(abs(analysis.sunHokumScoreGap) < 8)
        #expect(analysis.modeComparisonTitle.contains("قريب"))
        #expect(analysis.modeComparisonDetail.contains("سياق المزايدة"))
    }

    @Test("تحقق إدخال اليد يرفض النقص والتكرار دون تحليل صامت")
    func inputValidationReportsMissingAndDuplicateCards() {
        let duplicate = PlayingCard(suit: .spades, rank: .ace)
        let hand = [
            duplicate,
            duplicate,
            PlayingCard(suit: .hearts, rank: .ace),
            PlayingCard(suit: .diamonds, rank: .ace),
            PlayingCard(suit: .clubs, rank: .ace),
            PlayingCard(suit: .hearts, rank: .ten),
            PlayingCard(suit: .diamonds, rank: .ten),
            PlayingCard(suit: .clubs, rank: .king)
        ]

        let validation = HandAnalyzer.inputValidation(for: hand)

        #expect(!validation.isValid)
        #expect(validation.cardCount == 8)
        #expect(validation.uniqueCardCount == 7)
        #expect(validation.missingCardCount == 1)
        #expect(validation.extraCardCount == 0)
        #expect(validation.duplicateCards == [duplicate])
    }

    @Test("ترتيب بدائل المزايدة يثبت الخيار الموصى به أولًا ويعرض الصن والحكم والبس")
    func bidOptionsRankLegalChoicesDeterministically() {
        let hand = [
            PlayingCard(suit: .spades, rank: .ace),
            PlayingCard(suit: .spades, rank: .king),
            PlayingCard(suit: .spades, rank: .queen),
            PlayingCard(suit: .diamonds, rank: .ace),
            PlayingCard(suit: .hearts, rank: .ten),
            PlayingCard(suit: .hearts, rank: .ace),
            PlayingCard(suit: .diamonds, rank: .ten),
            PlayingCard(suit: .clubs, rank: .ace)
        ]

        let analysis = HandAnalyzer.analyze(hand: hand)

        #expect(analysis.recommendedBid == .sun)
        #expect(analysis.bidOptions.first?.bid == .sun)
        #expect(analysis.bidOptions.first?.isRecommended == true)
        #expect(analysis.bidOptions.contains { $0.bid == .pass })
        #expect(analysis.bidOptions.contains { $0.bid == .hokum(suit: .spades) })
        #expect(analysis.bidOptions == HandAnalyzer.analyze(hand: hand.reversed()).bidOptions)
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
            #expect((0...100).contains(analysis.bidConfidencePercent))
            #expect((0...100).contains(analysis.sunConfidencePercent))
            #expect((0...100).contains(analysis.hokumConfidencePercent))
        }
    }
}
