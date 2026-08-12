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

struct ScoringQuizQuestion: Identifiable, Equatable {
    let id: UInt64
    let difficulty: ScoringQuizDifficulty
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
