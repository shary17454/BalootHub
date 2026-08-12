import XCTest
@testable import BalootHub

final class ScoringQuizTests: XCTestCase {
    func testGenerationIsDeterministicForSameSeedAndDifficulty() {
        let first = ScoringQuizGenerator.generate(seed: 42, difficulty: .hard)
        let second = ScoringQuizGenerator.generate(seed: 42, difficulty: .hard)

        XCTAssertEqual(first, second)
    }

    func testEasyQuestionsAvoidProjectsAndMultipliers() {
        let question = ScoringQuizGenerator.generate(seed: 7, difficulty: .easy)

        XCTAssertEqual(question.teamOneProjects, 0)
        XCTAssertEqual(question.teamTwoProjects, 0)
        XCTAssertEqual(question.multiplier, .none)
    }

    func testQuestionAnswerMatchesConfiguredScoreRules() {
        let rules = ScoreRules.from(preset: .highStakes, coffeeEnabled: true)
        let question = ScoringQuizGenerator.generate(seed: 2_026, difficulty: .hard, rules: rules)
        let base = question.targetTeam == .teamOne ? question.teamOneBase : question.teamTwoBase
        let projects = question.targetTeam == .teamOne ? question.teamOneProjects : question.teamTwoProjects

        XCTAssertEqual(
            question.answer,
            rules.finalScore(baseScore: base, projects: projects, multiplier: question.multiplier)
        )
    }

    func testDifficultyTimeLimitsTightenAsDifficultyIncreases() {
        XCTAssertGreaterThan(ScoringQuizDifficulty.easy.timeLimitSeconds, ScoringQuizDifficulty.medium.timeLimitSeconds)
        XCTAssertGreaterThan(ScoringQuizDifficulty.medium.timeLimitSeconds, ScoringQuizDifficulty.hard.timeLimitSeconds)
    }

    func testEvaluatorAcceptsTrimmedCorrectAnswer() {
        let question = ScoringQuizGenerator.generate(seed: 99, difficulty: .medium)

        let evaluation = ScoringQuizEvaluator.evaluate(answerText: "  \(question.answer)\n", question: question)

        XCTAssertEqual(evaluation.submittedAnswer, question.answer)
        XCTAssertEqual(evaluation.expectedAnswer, question.answer)
        XCTAssertTrue(evaluation.isCorrect)
    }

    func testEvaluatorRejectsWrongAnswer() {
        let question = ScoringQuizGenerator.generate(seed: 99, difficulty: .medium)

        let evaluation = ScoringQuizEvaluator.evaluate(answerText: "\(question.answer + 1)", question: question)

        XCTAssertEqual(evaluation.submittedAnswer, question.answer + 1)
        XCTAssertEqual(evaluation.expectedAnswer, question.answer)
        XCTAssertFalse(evaluation.isCorrect)
    }

    func testEvaluatorRejectsNonNumericAnswer() {
        let question = ScoringQuizGenerator.generate(seed: 99, difficulty: .medium)

        let evaluation = ScoringQuizEvaluator.evaluate(answerText: "abc", question: question)

        XCTAssertNil(evaluation.submittedAnswer)
        XCTAssertEqual(evaluation.expectedAnswer, question.answer)
        XCTAssertFalse(evaluation.isCorrect)
    }

    func testAttemptPersistsQuestionAndEvaluationFields() {
        let question = ScoringQuizGenerator.generate(seed: 123, difficulty: .hard)
        let evaluation = ScoringQuizEvaluator.evaluate(answerText: "\(question.answer)", question: question)

        let attempt = ScoringQuizAttempt(question: question, evaluation: evaluation, remainingSeconds: 11)

        XCTAssertEqual(attempt.difficulty, .hard)
        XCTAssertEqual(attempt.replaySeed, 123)
        XCTAssertEqual(attempt.mode, question.mode)
        XCTAssertEqual(attempt.targetTeam, question.targetTeam)
        XCTAssertEqual(attempt.multiplier, question.multiplier)
        XCTAssertEqual(attempt.submittedAnswer, question.answer)
        XCTAssertEqual(attempt.expectedAnswer, question.answer)
        XCTAssertTrue(attempt.isCorrect)
        XCTAssertEqual(attempt.remainingSeconds, 11)
    }

    func testStatsSummaryTracksAccuracyAndStreaks() {
        let attempts = [
            makeAttempt(seed: 1, difficulty: .easy, isCorrect: true, remainingSeconds: 20, createdAt: Date(timeIntervalSince1970: 1)),
            makeAttempt(seed: 2, difficulty: .medium, isCorrect: false, remainingSeconds: 0, createdAt: Date(timeIntervalSince1970: 2)),
            makeAttempt(seed: 3, difficulty: .hard, isCorrect: true, remainingSeconds: 8, createdAt: Date(timeIntervalSince1970: 3)),
            makeAttempt(seed: 4, difficulty: .hard, isCorrect: true, remainingSeconds: 10, createdAt: Date(timeIntervalSince1970: 4))
        ]

        let summary = ScoringQuizStatsAnalyzer.summarize(attempts: attempts)

        XCTAssertEqual(summary.attempts, 4)
        XCTAssertEqual(summary.correctAnswers, 3)
        XCTAssertEqual(summary.accuracyPercent, 75)
        XCTAssertEqual(summary.currentStreak, 2)
        XCTAssertEqual(summary.bestStreak, 2)
        XCTAssertEqual(summary.averageRemainingSeconds, 9)
        XCTAssertEqual(summary.hardestSolvedDifficulty, .hard)
    }

    func testDifficultySummariesGroupAttemptsByLevel() {
        let attempts = [
            makeAttempt(seed: 1, difficulty: .easy, isCorrect: true),
            makeAttempt(seed: 2, difficulty: .hard, isCorrect: false),
            makeAttempt(seed: 3, difficulty: .hard, isCorrect: true)
        ]

        let summaries = ScoringQuizStatsAnalyzer.summariesByDifficulty(attempts)

        XCTAssertEqual(summaries.first { $0.difficulty == .easy }?.accuracyPercent, 100)
        XCTAssertEqual(summaries.first { $0.difficulty == .medium }?.attempts, 0)
        XCTAssertEqual(summaries.first { $0.difficulty == .hard }?.correctAnswers, 1)
        XCTAssertEqual(summaries.first { $0.difficulty == .hard }?.accuracyPercent, 50)
    }

    private func makeAttempt(
        seed: UInt64,
        difficulty: ScoringQuizDifficulty,
        isCorrect: Bool,
        remainingSeconds: Int = 0,
        createdAt: Date = .now
    ) -> ScoringQuizAttempt {
        let question = ScoringQuizGenerator.generate(seed: seed, difficulty: difficulty)
        let answer = isCorrect ? question.answer : question.answer + 1
        let evaluation = ScoringQuizEvaluator.evaluate(answerText: "\(answer)", question: question)
        return ScoringQuizAttempt(
            createdAt: createdAt,
            question: question,
            evaluation: evaluation,
            remainingSeconds: remainingSeconds
        )
    }
}
