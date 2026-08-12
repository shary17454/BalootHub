import Foundation

enum ScoringQuizDifficulty: String, CaseIterable, Identifiable {
    case easy
    case medium
    case hard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .easy: "سهل".localized
        case .medium: "متوسط".localized
        case .hard: "صعب".localized
        }
    }

    var timeLimitSeconds: Int {
        switch self {
        case .easy: 45
        case .medium: 35
        case .hard: 25
        }
    }
}

enum ScoringQuizQuestionCategory: String, Equatable {
    case basics
    case projects
    case multipliers
    case coffee

    var title: String {
        switch self {
        case .basics: "أساسيات".localized
        case .projects: "المشاريع".localized
        case .multipliers: "مضاعفات".localized
        case .coffee: "قهوة".localized
        }
    }
}

struct ScoringQuizQuestion: Identifiable, Equatable {
    let id: UInt64
    let difficulty: ScoringQuizDifficulty
    let category: ScoringQuizQuestionCategory
    let mode: BalootMode
    let teamOneBase: Int
    let teamTwoBase: Int
    let teamOneProjects: Int
    let teamTwoProjects: Int
    let multiplier: ScoreMultiplier
    let targetTeam: TargetTeam
    let answer: Int
    let explanation: String

    enum TargetTeam: String, Equatable {
        case teamOne
        case teamTwo

        var title: String {
            switch self {
            case .teamOne: "فريقنا".localized
            case .teamTwo: "الخصم".localized
            }
        }
    }
}

struct ScoringQuizEvaluation: Equatable {
    let submittedAnswer: Int?
    let expectedAnswer: Int
    let isCorrect: Bool
}

struct ScoringQuizStatsSummary: Equatable {
    let attempts: Int
    let correctAnswers: Int
    let accuracyPercent: Int
    let currentStreak: Int
    let bestStreak: Int
    let averageRemainingSeconds: Int
    let hardestSolvedDifficulty: ScoringQuizDifficulty?
}

struct ScoringQuizDifficultySummary: Identifiable, Equatable {
    let difficulty: ScoringQuizDifficulty
    let attempts: Int
    let correctAnswers: Int
    let accuracyPercent: Int

    var id: ScoringQuizDifficulty { difficulty }
}

struct ScoringQuizCoachingInsight: Equatable {
    let title: String
    let detail: String
    let recommendedDifficulty: ScoringQuizDifficulty
    let iconName: String
}

enum ScoringQuizEvaluator {
    static func evaluate(answerText: String, question: ScoringQuizQuestion) -> ScoringQuizEvaluation {
        let cleaned = answerText.trimmingCharacters(in: .whitespacesAndNewlines)
        let submittedAnswer = Int(cleaned)
        return ScoringQuizEvaluation(
            submittedAnswer: submittedAnswer,
            expectedAnswer: question.answer,
            isCorrect: submittedAnswer == question.answer
        )
    }
}

enum ScoringQuizStatsAnalyzer {
    static func summarize(attempts: [ScoringQuizAttempt]) -> ScoringQuizStatsSummary {
        let sorted = attempts.sorted { $0.createdAt > $1.createdAt }
        let correct = sorted.filter(\.isCorrect).count
        let attemptsCount = sorted.count
        let averageRemainingSeconds = attemptsCount == 0
            ? 0
            : sorted.reduce(0) { $0 + $1.remainingSeconds } / attemptsCount

        return ScoringQuizStatsSummary(
            attempts: attemptsCount,
            correctAnswers: correct,
            accuracyPercent: percent(correct, of: attemptsCount),
            currentStreak: currentStreak(sorted),
            bestStreak: bestStreak(sorted),
            averageRemainingSeconds: averageRemainingSeconds,
            hardestSolvedDifficulty: hardestSolvedDifficulty(sorted)
        )
    }

    static func summariesByDifficulty(_ attempts: [ScoringQuizAttempt]) -> [ScoringQuizDifficultySummary] {
        ScoringQuizDifficulty.allCases.map { difficulty in
            let matching = attempts.filter { $0.difficulty == difficulty }
            let correct = matching.filter(\.isCorrect).count
            return ScoringQuizDifficultySummary(
                difficulty: difficulty,
                attempts: matching.count,
                correctAnswers: correct,
                accuracyPercent: percent(correct, of: matching.count)
            )
        }
    }

    static func recentAttempts(_ attempts: [ScoringQuizAttempt], limit: Int = 5) -> [ScoringQuizAttempt] {
        Array(attempts.sorted { $0.createdAt > $1.createdAt }.prefix(limit))
    }

    static func coachingInsight(for attempts: [ScoringQuizAttempt]) -> ScoringQuizCoachingInsight {
        let summary = summarize(attempts: attempts)
        guard summary.attempts > 0 else {
            return ScoringQuizCoachingInsight(
                title: "ابدأ من السهل".localized,
                detail: "حل أول أسئلة بدون مشاريع أو مضاعفات حتى تثبت طريقة جمع النقاط الأساسية.".localized,
                recommendedDifficulty: .easy,
                iconName: "flag.fill"
            )
        }

        if summary.accuracyPercent >= 85, summary.currentStreak >= 3 {
            if summary.hardestSolvedDifficulty == .hard {
                return ScoringQuizCoachingInsight(
                    title: "ثبّت مستوى الصعب".localized,
                    detail: "دقتك وسلسلتك قوية حتى في أعلى مستوى؛ ركز على السرعة ومراجعة القهوة والمضاعفات.".localized,
                    recommendedDifficulty: .hard,
                    iconName: "checkmark.seal.fill"
                )
            }

            return ScoringQuizCoachingInsight(
                title: "ارفع مستوى التحدي".localized,
                detail: "الدقة والسلسلة تسمحان بالانتقال لمستوى أعلى مع مشاريع ومضاعفات أكثر.".localized,
                recommendedDifficulty: nextDifficulty(after: summary.hardestSolvedDifficulty ?? .easy),
                iconName: "arrow.up.circle.fill"
            )
        }

        if summary.accuracyPercent < 50 {
            return ScoringQuizCoachingInsight(
                title: "راجع أساس الحساب".localized,
                detail: "الدقة الحالية منخفضة؛ عد إلى السهل وركّز على جمع نقاط الفريق قبل تطبيق المضاعف.".localized,
                recommendedDifficulty: .easy,
                iconName: "exclamationmark.triangle.fill"
            )
        }

        if summary.averageRemainingSeconds <= 5 {
            return ScoringQuizCoachingInsight(
                title: "خفف ضغط الوقت".localized,
                detail: "إجاباتك تصل قرب نهاية المؤقت؛ ابق على نفس المستوى حتى تزيد سرعة الجمع.".localized,
                recommendedDifficulty: summary.hardestSolvedDifficulty ?? .medium,
                iconName: "timer"
            )
        }

        return ScoringQuizCoachingInsight(
            title: "استمر على نفس المستوى".localized,
            detail: "أداؤك متوسط ومستقر؛ أكمل عدة أسئلة بنفس المستوى حتى تبني سلسلة صحيحة قبل التصعيد.".localized,
            recommendedDifficulty: summary.hardestSolvedDifficulty ?? .medium,
            iconName: "target"
        )
    }

    private static func currentStreak(_ attempts: [ScoringQuizAttempt]) -> Int {
        var streak = 0
        for attempt in attempts {
            guard attempt.isCorrect else { break }
            streak += 1
        }
        return streak
    }

    private static func bestStreak(_ attempts: [ScoringQuizAttempt]) -> Int {
        var best = 0
        var current = 0
        for attempt in attempts.sorted(by: { $0.createdAt < $1.createdAt }) {
            if attempt.isCorrect {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
        }
        return best
    }

    private static func hardestSolvedDifficulty(_ attempts: [ScoringQuizAttempt]) -> ScoringQuizDifficulty? {
        attempts
            .filter(\.isCorrect)
            .map(\.difficulty)
            .max { lhs, rhs in
                difficultyWeight(lhs) < difficultyWeight(rhs)
            }
    }

    private static func difficultyWeight(_ difficulty: ScoringQuizDifficulty) -> Int {
        switch difficulty {
        case .easy: 1
        case .medium: 2
        case .hard: 3
        }
    }

    private static func nextDifficulty(after difficulty: ScoringQuizDifficulty) -> ScoringQuizDifficulty {
        switch difficulty {
        case .easy: .medium
        case .medium, .hard: .hard
        }
    }

    private static func percent(_ numerator: Int, of denominator: Int) -> Int {
        guard denominator > 0 else { return 0 }
        return Int((Double(numerator) / Double(denominator) * 100).rounded())
    }
}

enum ScoringQuizGenerator {
    static func generate(
        seed: UInt64,
        difficulty: ScoringQuizDifficulty,
        rules: ScoreRules = .standard
    ) -> ScoringQuizQuestion {
        var generator = QuizSeededGenerator(seed: seed)
        let mode: BalootMode = generator.nextInt(upperBound: 2) == 0 ? .sun : .hokum
        let roundTotal = mode == .sun ? 130 : 162
        let minimumBase = difficulty == .easy ? 30 : 0
        let teamOneBase = generator.nextInt(in: minimumBase...roundTotal)
        let teamTwoBase = max(0, roundTotal - teamOneBase)

        let projectChoices: [Int]
        switch difficulty {
        case .easy:
            projectChoices = [0]
        case .medium:
            projectChoices = [0, 20, 50]
        case .hard:
            projectChoices = [0, 20, 50, 100, 400]
        }

        let teamOneProjects = projectChoices[generator.nextInt(upperBound: projectChoices.count)]
        let teamTwoProjects = projectChoices[generator.nextInt(upperBound: projectChoices.count)]

        let multipliers: [ScoreMultiplier]
        switch difficulty {
        case .easy:
            multipliers = [.none]
        case .medium:
            multipliers = [.none, .double, .triple]
        case .hard:
            multipliers = [.none, .double, .triple, .quadruple, .coffee]
        }
        let multiplier = multipliers[generator.nextInt(upperBound: multipliers.count)]
        let targetTeam: ScoringQuizQuestion.TargetTeam = generator.nextInt(upperBound: 2) == 0 ? .teamOne : .teamTwo

        let targetBase = targetTeam == .teamOne ? teamOneBase : teamTwoBase
        let targetProjects = targetTeam == .teamOne ? teamOneProjects : teamTwoProjects
        let answer = rules.finalScore(baseScore: targetBase, projects: targetProjects, multiplier: multiplier)
        let subtotal = max(0, targetBase) + max(0, targetProjects)
        let factor = max(1, answer / max(1, subtotal))

        return ScoringQuizQuestion(
            id: seed,
            difficulty: difficulty,
            category: category(projects: teamOneProjects + teamTwoProjects, multiplier: multiplier),
            mode: mode,
            teamOneBase: teamOneBase,
            teamTwoBase: teamTwoBase,
            teamOneProjects: teamOneProjects,
            teamTwoProjects: teamTwoProjects,
            multiplier: multiplier,
            targetTeam: targetTeam,
            answer: answer,
            explanation: "\("نجمع نقاط الفريق".localized): \(targetBase) + \(targetProjects) = \(subtotal)، \("ثم نطبق المضاعف".localized) ×\(factor) = \(answer)."
        )
    }

    private static func category(projects: Int, multiplier: ScoreMultiplier) -> ScoringQuizQuestionCategory {
        if multiplier == .coffee {
            return .coffee
        }
        if multiplier != .none {
            return .multipliers
        }
        if projects > 0 {
            return .projects
        }
        return .basics
    }
}

private struct QuizSeededGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }

    mutating func nextInt(upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        return Int(next() % UInt64(upperBound))
    }

    mutating func nextInt(in range: ClosedRange<Int>) -> Int {
        range.lowerBound + nextInt(upperBound: range.upperBound - range.lowerBound + 1)
    }
}
