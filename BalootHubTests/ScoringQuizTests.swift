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
}
