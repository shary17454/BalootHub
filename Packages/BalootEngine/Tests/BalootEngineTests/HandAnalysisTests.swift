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
    }
}
