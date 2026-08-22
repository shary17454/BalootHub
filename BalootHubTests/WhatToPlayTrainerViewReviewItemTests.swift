import XCTest
import BalootEngine
@testable import BalootHub

@MainActor
final class WhatToPlayTrainerViewReviewItemTests: XCTestCase {
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
}
