import XCTest
import BalootEngine
@testable import BalootHub

final class WhatToPlayTrainingSessionReviewTests: XCTestCase {
    func testAchievedSessionReviewIncludesGradeReason() {
        let plan = WhatToPlayTrainingSessionPlan(
            difficulty: .easy,
            focusKind: nil,
            gameMode: nil,
            scenarioCount: 3,
            targetAccuracyPercent: 67,
            targetAverageExpectedImpact: 1,
            title: "خطة".localized,
            detail: "تفصيل".localized,
            successMetric: "هدف".localized,
            iconName: "target"
        )
        let attempts = [
            attempt(seed: 11, difficulty: .easy, selected: PlayingCard(suit: .clubs, rank: .ace), best: PlayingCard(suit: .clubs, rank: .ace), isCorrect: true, impact: 6),
            attempt(seed: 12, difficulty: .easy, selected: PlayingCard(suit: .hearts, rank: .ace), best: PlayingCard(suit: .hearts, rank: .ace), isCorrect: true, impact: 6),
            attempt(seed: 13, difficulty: .easy, selected: PlayingCard(suit: .spades, rank: .ace), best: PlayingCard(suit: .spades, rank: .ace), isCorrect: true, impact: 6)
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)
        let review = WhatToPlayStatsAnalyzer.trainingSessionReview(for: attempts, plan: plan)

        XCTAssertEqual(review.action, .nextChallenge)
        XCTAssertEqual(progress.state, .achieved)
        XCTAssertTrue(review.detail.contains("\("نتيجة الجلسة".localized): \(progress.gradePercent)/100"))
        XCTAssertTrue(review.detail.contains(progress.gradeTitle))
        XCTAssertTrue(review.detail.contains(progress.gradeDetail))
        XCTAssertTrue(review.detail.contains(progress.gradeReasonTitle))
        XCTAssertTrue(review.detail.contains(progress.gradeReasonDetail))
        XCTAssertNotNil(review.nextSeed)
        XCTAssertNotNil(review.difficulty)
    }

    func testReplayMistakeDetailIncludesSecondBestAndSimulationLoss() throws {
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
        let reviewItem = try XCTUnwrap(WhatToPlayStatsAnalyzer.reviewQueue(for: attempts).first)

        let review = WhatToPlayStatsAnalyzer.trainingSessionReview(for: attempts, plan: plan)

        XCTAssertEqual(reviewItem.scenarioContext, scenarioContext)
        XCTAssertEqual(review.action, .replayMistake)
        XCTAssertEqual(review.replaySeed, 10)
        XCTAssertEqual(review.replayScenarioCode, reviewItem.scenarioCode)
        XCTAssertEqual(review.secondBestCard, second)
        XCTAssertEqual(review.secondBestExpectedImpact, 5)
        XCTAssertTrue(review.detail.contains("\("رمز الموقف".localized): \(reviewItem.scenarioCode)"))
        XCTAssertTrue(review.detail.contains("\("الأكلة".localized): 4"))
        XCTAssertTrue(review.detail.contains("\("أنت ترد بعد".localized) 2 \("ورقة".localized)"))
        XCTAssertTrue(review.detail.contains("\("اللون المطلوب".localized): \(Suit.hearts.spokenName)"))
        XCTAssertTrue(review.detail.contains("\("حكم".localized): \(Suit.spades.spokenName)"))
        XCTAssertTrue(review.detail.contains("الحكم على الطاولة".localized))
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
        XCTAssertTrue(review.detail.contains("\("ثاني نتيجة محاكاة".localized): 58"))
        XCTAssertTrue(review.detail.contains("\("فاقد ثاني محاكاة".localized): 8"))
        XCTAssertTrue(review.detail.contains("تكتمل الأكلة وتنتقل للفائز.".localized))
        XCTAssertTrue(review.detail.contains("\("نتيجة المحاكاة".localized): \("للخصم".localized)"))
        XCTAssertTrue(review.detail.contains("\("نقاط الأكلة".localized): 18"))
        XCTAssertTrue(review.detail.contains(WhatToPlayStatsAnalyzer.valueLossTitle(for: .high)))
        XCTAssertTrue(review.detail.contains("\("نقاط محاكاة ضائعة".localized): 12"))
    }

    func testReplayMistakeRecommendsBestSimulationCardWhenProjectedLossDominates() throws {
        let selected = PlayingCard(suit: .clubs, rank: .seven)
        let best = PlayingCard(suit: .hearts, rank: .ace)
        let second = PlayingCard(suit: .spades, rank: .king)
        let bestSimulation = PlayingCard(suit: .diamonds, rank: .ace)
        let plan = WhatToPlayTrainingSessionPlan(
            difficulty: .medium,
            focusKind: .followSuit,
            gameMode: .hokum,
            scenarioCount: 1,
            targetAccuracyPercent: 100,
            targetAverageExpectedImpact: 5,
            title: "خطة".localized,
            detail: "تفصيل".localized,
            successMetric: "هدف".localized,
            iconName: "target"
        )
        let attempts = [
            attempt(seed: 30, selected: selected, best: best, second: second, impact: 7)
        ]

        let review = WhatToPlayStatsAnalyzer.trainingSessionReview(for: attempts, plan: plan)
        let drill = WhatToPlayStatsAnalyzer.microDrill(for: attempts)

        XCTAssertEqual(review.action, .replayMistake)
        XCTAssertEqual(review.recommendedCard, bestSimulation)
        XCTAssertEqual(review.expectedImprovement, 12)
        XCTAssertEqual(review.expectedImprovementSource, .projectedTeamPoints)
        XCTAssertEqual(drill.recommendedCard, bestSimulation)
        XCTAssertEqual(drill.expectedImprovement, 12)
    }

    func testInProgressSessionReviewsMistakeWhenAccuracyTargetCannotBeRecovered() {
        let plan = WhatToPlayTrainingSessionPlan(
            difficulty: .medium,
            focusKind: .followSuit,
            gameMode: .hokum,
            scenarioCount: 3,
            targetAccuracyPercent: 100,
            targetAverageExpectedImpact: 0,
            title: "خطة".localized,
            detail: "تفصيل".localized,
            successMetric: "هدف".localized,
            iconName: "target"
        )
        let attempts = [
            attempt(
                seed: 40,
                selected: PlayingCard(suit: .clubs, rank: .seven),
                best: PlayingCard(suit: .hearts, rank: .ace)
            ),
            attempt(
                seed: 41,
                selected: PlayingCard(suit: .diamonds, rank: .eight),
                best: PlayingCard(suit: .spades, rank: .ace)
            )
        ]

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)
        let review = WhatToPlayStatsAnalyzer.trainingSessionReview(for: progress, attempts: attempts, plan: plan)

        XCTAssertEqual(progress.state, .inProgress)
        XCTAssertFalse(progress.accuracyTargetReachable)
        XCTAssertEqual(review.action, .replayMistake)
        XCTAssertEqual(review.replaySeed, 41)
        XCTAssertEqual(review.title, "راجع الخطأ الأعلى أثرًا".localized)
        XCTAssertTrue(review.detail.contains("قبل تكرار الجلسة؛ هذا يربط التدريب بسبب الخسارة لا بعدد المحاولات فقط.".localized))
    }

    func testReviewScenarioTargetReplaysPreviousSelection() throws {
        let selected = PlayingCard(suit: .hearts, rank: .ace)
        let stored = attempt(
            seed: 20,
            selected: selected,
            best: PlayingCard(suit: .clubs, rank: .ace)
        )
        let item = try XCTUnwrap(WhatToPlayStatsAnalyzer.reviewQueue(for: [stored]).first)

        let target = WhatToPlayReviewScenarioTarget.replaying(item)

        XCTAssertEqual(target.seed, item.seed)
        XCTAssertEqual(target.difficulty, .medium)
        XCTAssertEqual(target.focusKind, .followSuit)
        XCTAssertEqual(target.preferredFocusRaw, WhatToPlayScenarioFocusKind.followSuit.rawValue)
        XCTAssertEqual(target.gameMode, .hokum)
        XCTAssertEqual(target.preferredModeRaw, GameMode.hokum.rawValue)
        XCTAssertEqual(target.trumpSuit, .spades)
        XCTAssertEqual(target.pendingReviewSelection, selected)
    }

    func testReviewScenarioTargetPracticesBlindWithoutPreviousSelection() throws {
        let selected = PlayingCard(suit: .hearts, rank: .ace)
        let stored = attempt(
            seed: 21,
            selected: selected,
            best: PlayingCard(suit: .clubs, rank: .ace)
        )
        let item = try XCTUnwrap(WhatToPlayStatsAnalyzer.reviewQueue(for: [stored]).first)

        let target = WhatToPlayReviewScenarioTarget.practicingBlind(item)

        XCTAssertEqual(target.seed, item.seed)
        XCTAssertEqual(target.difficulty, .medium)
        XCTAssertEqual(target.focusKind, .followSuit)
        XCTAssertEqual(target.preferredFocusRaw, WhatToPlayScenarioFocusKind.followSuit.rawValue)
        XCTAssertEqual(target.gameMode, .hokum)
        XCTAssertEqual(target.preferredModeRaw, GameMode.hokum.rawValue)
        XCTAssertEqual(target.trumpSuit, .spades)
        XCTAssertNil(target.pendingReviewSelection)
    }

    func testTrainingSessionReviewItemCanStartBlindPractice() throws {
        let selected = PlayingCard(suit: .clubs, rank: .seven)
        let stored = attempt(
            seed: 31,
            selected: selected,
            best: PlayingCard(suit: .hearts, rank: .ace),
            second: PlayingCard(suit: .spades, rank: .king)
        )
        let plan = WhatToPlayTrainingSessionPlan(
            difficulty: .medium,
            focusKind: .followSuit,
            gameMode: .hokum,
            scenarioCount: 3,
            targetAccuracyPercent: 100,
            targetAverageExpectedImpact: 5,
            title: "خطة".localized,
            detail: "تفصيل".localized,
            successMetric: "هدف".localized,
            iconName: "target"
        )

        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: [stored], plan: plan)
        let reviewItem = try XCTUnwrap(progress.reviewItem)
        let target = WhatToPlayReviewScenarioTarget.practicingBlind(reviewItem)

        XCTAssertEqual(reviewItem.seed, stored.replaySeed)
        XCTAssertEqual(reviewItem.selectedCard, selected)
        XCTAssertEqual(target.seed, stored.replaySeed)
        XCTAssertEqual(target.difficulty, stored.difficulty)
        XCTAssertEqual(target.focusKind, stored.focusKind)
        XCTAssertEqual(target.preferredFocusRaw, WhatToPlayScenarioFocusKind.followSuit.rawValue)
        XCTAssertEqual(target.gameMode, stored.gameMode)
        XCTAssertEqual(target.preferredModeRaw, GameMode.hokum.rawValue)
        XCTAssertEqual(target.trumpSuit, stored.contextTrumpSuit)
        XCTAssertNil(target.pendingReviewSelection)
    }

    private func attempt(
        seed: UInt64,
        difficulty: WhatToPlayDifficulty = .medium,
        selected: PlayingCard,
        best: PlayingCard,
        second: PlayingCard? = nil,
        isCorrect: Bool = false,
        impact: Int = -4
    ) -> WhatToPlayAttempt {
        WhatToPlayAttempt(
            createdAt: Date(timeIntervalSince1970: Double(seed)),
            difficulty: difficulty,
            seed: seed,
            selectedCard: selected,
            bestCard: best,
            secondBestCard: second,
            bestSimulationCard: second == nil ? nil : PlayingCard(suit: .diamonds, rank: .ace),
            isCorrect: isCorrect,
            selectedRank: second == nil ? 3 : 4,
            expectedImpact: impact,
            bestExpectedImpact: 8,
            secondBestExpectedImpact: second == nil ? nil : 5,
            projectedTeamPoints: 50,
            bestProjectedTeamPoints: second == nil ? 55 : 62,
            secondBestProjectedTeamPoints: second == nil ? nil : 58,
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
