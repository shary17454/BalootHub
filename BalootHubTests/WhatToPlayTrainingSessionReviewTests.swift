import XCTest
import BalootEngine
@testable import BalootHub

final class WhatToPlayTrainingSessionReviewTests: XCTestCase {
    func testReplayMistakeDetailIncludesSecondBestAndSimulationLoss() {
        let selected = PlayingCard(suit: .clubs, rank: .seven)
        let best = PlayingCard(suit: .hearts, rank: .ace)
        let second = PlayingCard(suit: .spades, rank: .king)
        let bestSimulation = PlayingCard(suit: .diamonds, rank: .ace)
        let plan = WhatToPlayTrainingSessionPlan(
            difficulty: .medium,
            focusKind: .followSuit,
            gameMode: .hokum,
            scenarioCount: 2,
            targetAccuracyPercent: 100,
            targetAverageExpectedImpact: 5,
            title: "خطة".localized,
            detail: "تفصيل".localized,
            successMetric: "هدف".localized,
            iconName: "target"
        )
        let attempts = [
            attempt(seed: 10, selected: selected, best: best, second: second),
            attempt(seed: 11, selected: PlayingCard(suit: .diamonds, rank: .eight), best: best)
        ]

        let review = WhatToPlayStatsAnalyzer.trainingSessionReview(for: attempts, plan: plan)

        XCTAssertEqual(review.action, .replayMistake)
        XCTAssertEqual(review.replaySeed, 10)
        XCTAssertTrue(review.detail.contains("\("الأكلة".localized): 4"))
        XCTAssertTrue(review.detail.contains("\("اللون المطلوب".localized): \(Suit.hearts.spokenName)"))
        XCTAssertTrue(review.detail.contains("\("حكم".localized): \(Suit.spades.spokenName)"))
        XCTAssertTrue(review.detail.contains("\("نقاط فريقك".localized): 36 · \("للخصم".localized): 42"))
        XCTAssertTrue(review.detail.contains("\("الفارق".localized): -6"))
        XCTAssertTrue(review.detail.contains("\("الأوراق القانونية".localized): 3"))
        XCTAssertTrue(review.detail.contains("\("أوراق".localized): 2/4"))
        XCTAssertTrue(review.detail.contains("\("السبب التكتيكي".localized): \("تغلق الأكلة للخصم".localized)"))
        XCTAssertTrue(review.detail.contains("اختيارك أضاف نقاطًا لأكلة انتهت للفريق الخصم".localized))
        XCTAssertTrue(review.detail.contains("\("اختيارك".localized): \(selected.accessibilityName)"))
        XCTAssertTrue(review.detail.contains("\("أثر القرار".localized): -4"))
        XCTAssertTrue(review.detail.contains("\("الترتيب".localized): 4"))
        XCTAssertTrue(review.detail.contains("\("أفضل ورقة".localized): \(best.accessibilityName)"))
        XCTAssertTrue(review.detail.contains("\("الأثر المتوقع".localized): +8"))
        XCTAssertTrue(review.detail.contains("\("ثاني أفضل".localized): \(second.accessibilityName)"))
        XCTAssertTrue(review.detail.contains("\("أثر ثاني أفضل".localized): +5"))
        XCTAssertTrue(review.detail.contains("\("نقاط فريقك بعد المحاكاة".localized): 50"))
        XCTAssertTrue(review.detail.contains("\("أفضل نتيجة محاكاة".localized): 62"))
        XCTAssertTrue(review.detail.contains("\("أفضل محاكاة".localized): \(bestSimulation.accessibilityName)"))
        XCTAssertTrue(review.detail.contains("تكتمل الأكلة وتنتقل للفائز.".localized))
        XCTAssertTrue(review.detail.contains("\("نتيجة المحاكاة".localized): \("للخصم".localized)"))
        XCTAssertTrue(review.detail.contains("\("نقاط الأكلة".localized): 18"))
        XCTAssertTrue(review.detail.contains(WhatToPlayStatsAnalyzer.valueLossTitle(for: .high)))
        XCTAssertTrue(review.detail.contains("\("نقاط محاكاة ضائعة".localized): 12"))
    }

    private func attempt(
        seed: UInt64,
        selected: PlayingCard,
        best: PlayingCard,
        second: PlayingCard? = nil
    ) -> WhatToPlayAttempt {
        WhatToPlayAttempt(
            createdAt: Date(timeIntervalSince1970: Double(seed)),
            difficulty: .medium,
            seed: seed,
            selectedCard: selected,
            bestCard: best,
            secondBestCard: second,
            bestSimulationCard: second == nil ? nil : PlayingCard(suit: .diamonds, rank: .ace),
            isCorrect: false,
            selectedRank: second == nil ? 3 : 4,
            expectedImpact: -4,
            bestExpectedImpact: 8,
            secondBestExpectedImpact: second == nil ? nil : 5,
            projectedTeamPoints: 50,
            bestProjectedTeamPoints: second == nil ? 55 : 62,
            focusKind: .followSuit,
            gameMode: .hokum,
            impactBreakdown: second == nil ? nil : opponentTrickClosureBreakdown,
            simulation: second == nil ? nil : completedOpponentSimulation,
            scenarioContext: scenarioContext
        )
    }

    private var opponentTrickClosureBreakdown: WhatToPlayOptionImpactBreakdown {
        WhatToPlayOptionImpactBreakdown(
            playedCardPoints: 10,
            immediateImpact: -4,
            trickPointsSwing: -18,
            completesTrick: true,
            winsForPlayerTeam: false,
            preservesLead: false
        )
    }

    private var completedOpponentSimulation: WhatToPlayOptionSimulation {
        let winnerID = UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID()
        return WhatToPlayOptionSimulation(
            phaseAfterPlay: .playing,
            currentTrickCardCount: 0,
            completedTrickWinnerID: winnerID,
            completedTrickWinnerTeamID: UUID(uuidString: "22222222-2222-2222-2222-222222222222") ?? UUID(),
            completedTrickWonByPlayerTeam: false,
            completedTrickPoints: 18,
            nextTurnPlayerID: winnerID,
            playerRemainingCards: 4,
            actionHistoryCount: 12
        )
    }

    private var scenarioContext: WhatToPlayScenarioContext {
        WhatToPlayScenarioContext(
            trickNumber: 4,
            isLeading: false,
            requiredSuit: .hearts,
            playedCardCount: 2,
            legalOptionCount: 3,
            mode: .hokum,
            trumpSuit: .spades,
            hasTrumpInCurrentTrick: true,
            playerTeamTrickPoints: 36,
            opponentTeamTrickPoints: 42,
            playerTeamPointMargin: -6,
            focusKind: .followSuit
        )
    }
}
