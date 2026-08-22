import XCTest
import BalootEngine
@testable import BalootHub

@MainActor
final class WhatToPlayTrainerViewReviewItemTests: XCTestCase {
    func testHandAnalyzerInputStatusShowsRemainingCards() {
        let view = WhatToPlayTrainerView()
        let validation = HandAnalyzer.inputValidation(for: Array(Self.completeHand.prefix(6)))

        XCTAssertEqual(view.inputStatusTitle(for: validation), "\("باقي".localized) 2 \("من الأوراق".localized)")
        XCTAssertEqual(
            view.inputStatusMessage(for: validation),
            "\("اختر".localized) 2 \("ورقة إضافية لإظهار التحليل.".localized)"
        )
    }

    func testHandAnalyzerInputStatusRecognizesCompleteHand() {
        let view = WhatToPlayTrainerView()
        let validation = HandAnalyzer.inputValidation(for: Self.completeHand)

        XCTAssertEqual(view.inputStatusTitle(for: validation), "التحليل جاهز".localized)
        XCTAssertEqual(
            view.inputStatusMessage(for: validation),
            "بعد اكتمال اليد يعرض التطبيق تقييم القوة، أفضل شراء، المشاريع، ونصيحة تكتيكية.".localized
        )
    }

    func testHandAnalyzerInputStatusReportsDuplicates() {
        let view = WhatToPlayTrainerView()
        let duplicated = Self.completeHand + [Self.completeHand[0]]
        let validation = HandAnalyzer.inputValidation(for: duplicated)

        XCTAssertEqual(view.inputStatusTitle(for: validation), "أزل الأوراق المكررة".localized)
        XCTAssertEqual(
            view.inputStatusMessage(for: validation),
            "كل ورقة يجب أن تظهر مرة واحدة فقط في اليد.".localized
        )
    }

    func testHandAnalyzerSignedScoreTextKeepsPositiveSign() {
        let view = HandAnalyzerView()

        XCTAssertEqual(view.signedScoreText(12), "+12")
        XCTAssertEqual(view.signedScoreText(0), "0")
        XCTAssertEqual(view.signedScoreText(-7), "-7")
    }

    func testHandAnalyzerGapExplanationDescribesSignMeaning() {
        let view = HandAnalyzerView()

        XCTAssertEqual(
            view.sunHokumGapExplanation(for: 12),
            "الفارق الموجب يعني أن الصن أعلى من أفضل حكم في هذا التحليل.".localized
        )
        XCTAssertEqual(
            view.sunHokumGapExplanation(for: -7),
            "الفارق السالب يعني أن أفضل حكم أعلى من الصن في هذا التحليل.".localized
        )
        XCTAssertEqual(
            view.sunHokumGapExplanation(for: 0),
            "الفارق صفر، لذلك القرار قريب جدًا ويعتمد على سياق المزايدة.".localized
        )
    }

    func testReviewCardSourceTextExplainsWhyReviewCardWasChosen() throws {
        let selected = PlayingCard(suit: .spades, rank: .seven)
        let best = PlayingCard(suit: .hearts, rank: .ace)
        let attempt = WhatToPlayAttempt(
            difficulty: .medium,
            seed: 940,
            selectedCard: selected,
            bestCard: best,
            isCorrect: false,
            expectedImpact: 1,
            bestExpectedImpact: 7
        )
        let item = try XCTUnwrap(WhatToPlayStatsAnalyzer.reviewQueue(for: [attempt], limit: 1).first)
        let view = WhatToPlayTrainerView()

        let text = view.reviewCardSourceText(for: item)

        XCTAssertEqual(
            text,
            "\("سبب ورقة المراجعة".localized): \(try XCTUnwrap(WhatToPlayStatsAnalyzer.reviewCardSourceTitle(for: item)))"
        )
    }

    func testReviewCardSourceTextOmitsResolvedAttempt() throws {
        let selected = PlayingCard(suit: .spades, rank: .ace)
        let attempt = WhatToPlayAttempt(
            difficulty: .easy,
            seed: 941,
            selectedCard: selected,
            bestCard: selected,
            isCorrect: true,
            expectedImpact: 6,
            bestExpectedImpact: 6
        )
        let item = try XCTUnwrap(WhatToPlayStatsAnalyzer.reviewQueue(for: [attempt], limit: 1).first)
        let view = WhatToPlayTrainerView()

        XCTAssertNil(view.reviewCardSourceText(for: item))
    }

    private static let completeHand = [
        PlayingCard(suit: .spades, rank: .ace),
        PlayingCard(suit: .spades, rank: .king),
        PlayingCard(suit: .spades, rank: .queen),
        PlayingCard(suit: .spades, rank: .jack),
        PlayingCard(suit: .hearts, rank: .ten),
        PlayingCard(suit: .hearts, rank: .nine),
        PlayingCard(suit: .diamonds, rank: .eight),
        PlayingCard(suit: .clubs, rank: .seven)
    ]
}
