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
        XCTAssertEqual(question.category, .basics)
    }

    func testQuestionCategoryMatchesProjectsAndMultipliers() {
        let rules = ScoreRules.from(preset: .standard, coffeeEnabled: true)
        let questions = (1...120).map {
            ScoringQuizGenerator.generate(seed: UInt64($0), difficulty: .hard, rules: rules)
        }

        XCTAssertTrue(questions.contains { $0.category == .projects })
        XCTAssertTrue(questions.contains { $0.category == .multipliers })
        XCTAssertTrue(questions.contains { $0.category == .coffee })

        for question in questions {
            XCTAssertEqual(question.category, expectedCategory(for: question))
        }
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

    func testAppSettingsScoreRulesDriveScoringQuizFormula() {
        let settings = AppSettings(
            enableCoffeeMultiplier: true,
            selectedScoreRulePreset: .highStakes
        )
        let question = ScoringQuizGenerator.generate(
            seed: 2_026,
            difficulty: .hard,
            rules: settings.scoreRules
        )
        let base = question.targetTeam == .teamOne ? question.teamOneBase : question.teamTwoBase
        let projects = question.targetTeam == .teamOne ? question.teamOneProjects : question.teamTwoProjects

        XCTAssertEqual(
            question.answer,
            settings.scoreRules.finalScore(
                baseScore: base,
                projects: projects,
                multiplier: question.multiplier
            )
        )
        XCTAssertEqual(settings.scoreRules.coffeeFactor, 8)
    }

    func testAppSettingsScoreRulesCanDisableCoffeeForScoringQuiz() {
        let settings = AppSettings(
            enableCoffeeMultiplier: false,
            selectedScoreRulePreset: .highStakes
        )

        XCTAssertEqual(
            settings.scoreRules.finalScore(baseScore: 50, projects: 0, multiplier: .coffee),
            50
        )
    }

    func testGeneratorDoesNotAskCoffeeWhenRulesDisableCoffee() {
        let rules = ScoreRules.from(preset: .highStakes, coffeeEnabled: false)
        let questions = (1...200).map {
            ScoringQuizGenerator.generate(seed: UInt64($0), difficulty: .hard, rules: rules)
        }

        XCTAssertFalse(questions.contains { $0.multiplier == .coffee })
        XCTAssertFalse(questions.contains { $0.category == .coffee })
    }

    func testGeneratorCanAskCoffeeWhenRulesEnableCoffee() {
        let rules = ScoreRules.from(preset: .highStakes, coffeeEnabled: true)
        let questions = (1...200).map {
            ScoringQuizGenerator.generate(seed: UInt64($0), difficulty: .hard, rules: rules)
        }

        XCTAssertTrue(questions.contains { $0.multiplier == .coffee })
        XCTAssertTrue(questions.contains { $0.category == .coffee })
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
        XCTAssertEqual(attempt.category, question.category)
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

    func testCategorySummariesGroupAttemptsByQuestionType() throws {
        let attempts = [
            makeAttempt(seed: 7, difficulty: .easy, isCorrect: true),
            try makeAttempt(category: .projects, isCorrect: false),
            try makeAttempt(category: .multipliers, isCorrect: true),
            try makeAttempt(category: .coffee, isCorrect: true)
        ]

        let summaries = ScoringQuizStatsAnalyzer.summariesByCategory(attempts)

        XCTAssertEqual(summaries.first { $0.category == .basics }?.accuracyPercent, 100)
        XCTAssertEqual(summaries.first { $0.category == .projects }?.attempts, 1)
        XCTAssertEqual(summaries.first { $0.category == .projects }?.accuracyPercent, 0)
        XCTAssertEqual(summaries.first { $0.category == .multipliers }?.correctAnswers, 1)
        XCTAssertEqual(summaries.first { $0.category == .coffee }?.accuracyPercent, 100)
    }

    func testCoachingInsightStartsAtEasyWithoutAttempts() {
        let insight = ScoringQuizStatsAnalyzer.coachingInsight(for: [])

        XCTAssertEqual(insight.title, "ابدأ من السهل".localized)
        XCTAssertEqual(insight.recommendedDifficulty, .easy)
    }

    func testCoachingInsightRaisesDifficultyAfterStrongStreak() {
        let attempts = [
            makeAttempt(seed: 1, difficulty: .easy, isCorrect: true, remainingSeconds: 20, createdAt: Date(timeIntervalSince1970: 1)),
            makeAttempt(seed: 2, difficulty: .easy, isCorrect: true, remainingSeconds: 18, createdAt: Date(timeIntervalSince1970: 2)),
            makeAttempt(seed: 3, difficulty: .easy, isCorrect: true, remainingSeconds: 16, createdAt: Date(timeIntervalSince1970: 3))
        ]

        let insight = ScoringQuizStatsAnalyzer.coachingInsight(for: attempts)

        XCTAssertEqual(insight.title, "ارفع مستوى التحدي".localized)
        XCTAssertEqual(insight.recommendedDifficulty, .medium)
    }

    func testCoachingInsightRecommendsEasyWhenAccuracyIsLow() {
        let attempts = [
            makeAttempt(seed: 1, difficulty: .hard, isCorrect: false),
            makeAttempt(seed: 2, difficulty: .medium, isCorrect: false),
            makeAttempt(seed: 3, difficulty: .easy, isCorrect: true),
            makeAttempt(seed: 4, difficulty: .hard, isCorrect: false)
        ]

        let insight = ScoringQuizStatsAnalyzer.coachingInsight(for: attempts)

        XCTAssertEqual(insight.title, "راجع أساس الحساب".localized)
        XCTAssertEqual(insight.recommendedDifficulty, .easy)
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

    private func makeAttempt(
        category: ScoringQuizQuestionCategory,
        isCorrect: Bool
    ) throws -> ScoringQuizAttempt {
        let rules = ScoreRules.from(preset: .standard, coffeeEnabled: true)
        for seed in 1...500 {
            let question = ScoringQuizGenerator.generate(seed: UInt64(seed), difficulty: .hard, rules: rules)
            guard question.category == category else { continue }
            let answer = isCorrect ? question.answer : question.answer + 1
            let evaluation = ScoringQuizEvaluator.evaluate(answerText: "\(answer)", question: question)
            return ScoringQuizAttempt(
                question: question,
                evaluation: evaluation,
                remainingSeconds: 10
            )
        }
        XCTFail("لم يتم العثور على سؤال من النوع \(category.rawValue)")
        throw NSError(domain: "ScoringQuizTests", code: 1)
    }

    private func expectedCategory(for question: ScoringQuizQuestion) -> ScoringQuizQuestionCategory {
        if question.multiplier == .coffee {
            return .coffee
        }
        if question.multiplier != .none {
            return .multipliers
        }
        if question.teamOneProjects + question.teamTwoProjects > 0 {
            return .projects
        }
        return .basics
    }
}
