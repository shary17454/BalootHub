import XCTest
import BalootEngine
@testable import BalootHub

final class WhatToPlaySimulationFormatterTests: XCTestCase {
    func testCompletedSimulationDisplaysWinnerDirectionAndPoints() {
        let winnerID = UUID()
        let simulation = WhatToPlayOptionSimulation(
            phaseAfterPlay: .playing,
            currentTrickCardCount: 0,
            completedTrickWinnerID: winnerID,
            completedTrickWinnerTeamID: UUID(),
            completedTrickWonByPlayerTeam: true,
            completedTrickPoints: 18,
            nextTurnPlayerID: winnerID,
            playerRemainingCards: 4,
            actionHistoryCount: 12
        )

        let display = WhatToPlaySimulationFormatter.display(for: simulation)

        XCTAssertEqual(display.summary, "تكتمل الأكلة وتنتقل للفائز.".localized)
        XCTAssertEqual(display.teamResult, "لفريقك".localized)
        XCTAssertEqual(display.trickPoints, 18)
    }

    func testOpenSimulationDisplaysCardCountOnly() {
        let simulation = WhatToPlayOptionSimulation(
            phaseAfterPlay: .playing,
            currentTrickCardCount: 2,
            completedTrickWinnerID: nil,
            completedTrickWinnerTeamID: nil,
            completedTrickWonByPlayerTeam: nil,
            completedTrickPoints: 0,
            nextTurnPlayerID: UUID(),
            playerRemainingCards: 5,
            actionHistoryCount: 10
        )

        let display = WhatToPlaySimulationFormatter.display(for: simulation)

        XCTAssertEqual(display.summary, "\("تبقى الأكلة مفتوحة".localized) · 2 \("أوراق على الطاولة".localized)")
        XCTAssertNil(display.teamResult)
        XCTAssertNil(display.trickPoints)
    }

    func testAttemptWithoutSimulationHasNoDisplay() {
        let attempt = WhatToPlayAttempt(
            difficulty: .medium,
            seed: 1,
            selectedCard: PlayingCard(suit: .clubs, rank: .seven),
            bestCard: PlayingCard(suit: .clubs, rank: .eight),
            isCorrect: false,
            expectedImpact: -2
        )

        XCTAssertNil(WhatToPlaySimulationFormatter.display(for: attempt))
    }
}
