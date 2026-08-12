import XCTest
import BalootEngine
@testable import BalootHub

final class PlayerStatsAnalyzerTests: XCTestCase {
    func testSummarizesFinishedSessions() {
        let win = ScoreSession(createdAt: Date(timeIntervalSince1970: 1), teamOneName: "فريقنا", teamTwoName: "الخصم", targetScore: 100, status: .finished)
        let winRound = ScoreRound(roundNumber: 1, mode: .hokum, teamOneBaseScore: 120, teamTwoBaseScore: 40, teamOneProjects: 20)
        win.rounds.append(winRound)

        let loss = ScoreSession(createdAt: Date(timeIntervalSince1970: 2), teamOneName: "فريقنا", teamTwoName: "الخصم", targetScore: 100, status: .finished)
        let lossRound = ScoreRound(roundNumber: 1, mode: .sun, teamOneBaseScore: 40, teamTwoBaseScore: 120)
        loss.rounds.append(lossRound)

        let summary = PlayerStatsAnalyzer.summarize(sessions: [win, loss], rules: .standard)

        XCTAssertEqual(summary.finishedMatches, 2)
        XCTAssertEqual(summary.wins, 1)
        XCTAssertEqual(summary.losses, 1)
        XCTAssertEqual(summary.projectPoints, 20)
        XCTAssertEqual(summary.sunRounds, 1)
        XCTAssertEqual(summary.hokumRounds, 1)
        XCTAssertEqual(summary.winRate, 0.5)
    }

    func testIgnoresUnfinishedSessionsWithoutWinner() {
        let active = ScoreSession(teamOneName: "فريقنا", teamTwoName: "الخصم", targetScore: 500, status: .active)
        active.rounds.append(ScoreRound(roundNumber: 1, mode: .hokum, teamOneBaseScore: 80, teamTwoBaseScore: 70))

        let summary = PlayerStatsAnalyzer.summarize(sessions: [active], rules: .standard)

        XCTAssertEqual(summary.finishedMatches, 0)
    }

    func testDetectsProjectFocusedStyle() {
        let session = ScoreSession(teamOneName: "فريقنا", teamTwoName: "الخصم", targetScore: 100, status: .finished)
        session.rounds.append(ScoreRound(roundNumber: 1, mode: .hokum, teamOneBaseScore: 80, teamTwoBaseScore: 20, teamOneProjects: 200))

        let summary = PlayerStatsAnalyzer.summarize(sessions: [session], rules: .standard)

        XCTAssertEqual(summary.styleTitle, "صياد مشاريع")
    }

    func testIncludesWhatToPlayTrainingDecisionStats() {
        let attempts = (0..<10).map { index in
            makeTrainingAttempt(seed: UInt64(index), isCorrect: index < 8)
        }

        let summary = PlayerStatsAnalyzer.summarize(
            sessions: [],
            whatToPlayAttempts: attempts,
            rules: .standard
        )

        XCTAssertEqual(summary.trainingAttempts, 10)
        XCTAssertEqual(summary.trainingCorrectDecisions, 8)
        XCTAssertEqual(summary.trainingWrongDecisions, 2)
        XCTAssertEqual(summary.trainingAccuracyPercent, 80)
        XCTAssertEqual(summary.costlyTrainingDecisions, 2)
        XCTAssertEqual(summary.averageTrainingLostPoints, 2)
        XCTAssertEqual(summary.trainingValueCapturePercent, 77)
        XCTAssertEqual(summary.trainingStyleTitle, "قريب من الخبير")
        XCTAssertEqual(summary.decisionPatternTitle, "تبتعد عن أفضل خيارين")
        XCTAssertEqual(summary.decisionPatternAffectedAttempts, 2)
        XCTAssertEqual(summary.decisionPatternInspectedAttempts, 8)
    }

    func testTrainingPerformanceCanShapePlayerStyleWithoutFinishedMatches() {
        let attempts = (0..<8).map { index in
            makeTrainingAttempt(seed: UInt64(index), isCorrect: true)
        }

        let summary = PlayerStatsAnalyzer.summarize(
            sessions: [],
            whatToPlayAttempts: attempts,
            rules: .standard
        )

        XCTAssertEqual(summary.finishedMatches, 0)
        XCTAssertEqual(summary.styleTitle, "قارئ طاولة")
        XCTAssertEqual(summary.trainingStyleTitle, "قريب من الخبير")
        XCTAssertEqual(summary.decisionPatternTitle, "قراراتك الأخيرة نظيفة")
    }

    func testPlayerStatsReportsFoundationalTrainingStyleForWeakTrainingRecord() {
        let attempts = (0..<5).map { index in
            makeTrainingAttempt(seed: UInt64(index), isCorrect: false)
        }

        let summary = PlayerStatsAnalyzer.summarize(
            sessions: [],
            whatToPlayAttempts: attempts,
            rules: .standard
        )

        XCTAssertEqual(summary.trainingStyleTitle, "تحتاج تأسيس")
        XCTAssertEqual(summary.decisionPatternTitle, "تبتعد عن أفضل خيارين")
        XCTAssertEqual(summary.decisionPatternAffectedAttempts, 5)
        XCTAssertEqual(summary.decisionPatternInspectedAttempts, 5)
    }

    func testIncludesScoringQuizCategoryStrengthAndWeakness() throws {
        let scoringAttempts = [
            try makeScoringQuizAttempt(category: .coffee, seedOffset: 0, isCorrect: true),
            try makeScoringQuizAttempt(category: .coffee, seedOffset: 1, isCorrect: true),
            try makeScoringQuizAttempt(category: .multipliers, seedOffset: 0, isCorrect: false),
            try makeScoringQuizAttempt(category: .multipliers, seedOffset: 1, isCorrect: false)
        ]

        let summary = PlayerStatsAnalyzer.summarize(
            sessions: [],
            scoringQuizAttempts: scoringAttempts,
            rules: .standard
        )

        XCTAssertEqual(summary.scoringQuizAttempts, 4)
        XCTAssertEqual(summary.scoringQuizCorrectAnswers, 2)
        XCTAssertEqual(summary.scoringQuizAccuracyPercent, 50)
        XCTAssertEqual(summary.scoringStrongestCategoryTitle, ScoringQuizQuestionCategory.coffee.title)
        XCTAssertEqual(summary.scoringWeakestCategoryTitle, ScoringQuizQuestionCategory.multipliers.title)
    }

    private func makeTrainingAttempt(seed: UInt64, isCorrect: Bool) -> WhatToPlayAttempt {
        let selected = isCorrect
            ? PlayingCard(suit: .spades, rank: .ace)
            : PlayingCard(suit: .clubs, rank: .seven)
        let best = PlayingCard(suit: .spades, rank: .ace)
        return WhatToPlayAttempt(
            difficulty: .medium,
            seed: seed,
            selectedCard: selected,
            bestCard: best,
            isCorrect: isCorrect,
            selectedRank: isCorrect ? 1 : 4,
            expectedImpact: isCorrect ? 10 : 0,
            bestExpectedImpact: isCorrect ? 10 : 12
        )
    }

    private func makeScoringQuizAttempt(
        category: ScoringQuizQuestionCategory,
        seedOffset: UInt64,
        isCorrect: Bool
    ) throws -> ScoringQuizAttempt {
        var matchedOffset: UInt64 = 0
        for seed in 1...1_200 {
            let question = ScoringQuizGenerator.generate(seed: UInt64(seed), difficulty: .hard)
            guard question.category == category else { continue }
            if matchedOffset < seedOffset {
                matchedOffset += 1
                continue
            }
            let submitted = isCorrect ? question.answer : question.answer + 1
            return ScoringQuizAttempt(
                question: question,
                evaluation: ScoringQuizEvaluator.evaluate(answerText: "\(submitted)", question: question),
                remainingSeconds: isCorrect ? 10 : 0
            )
        }
        XCTFail("لم يتم العثور على سؤال من نوع \(category.rawValue)")
        throw NSError(domain: "PlayerStatsAnalyzerTests", code: 1)
    }
}
