import Foundation
import SwiftData

@Model
final class ScoringQuizAttempt {
    var id: UUID
    var createdAt: Date
    var difficultyRaw: String
    var seedRaw: String
    var modeRaw: String
    var targetTeamRaw: String
    var teamOneBase: Int
    var teamTwoBase: Int
    var teamOneProjects: Int
    var teamTwoProjects: Int
    var multiplierRaw: String
    var submittedAnswer: Int?
    var expectedAnswer: Int
    var isCorrect: Bool
    var remainingSeconds: Int

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        question: ScoringQuizQuestion,
        evaluation: ScoringQuizEvaluation,
        remainingSeconds: Int
    ) {
        self.id = id
        self.createdAt = createdAt
        self.difficultyRaw = question.difficulty.rawValue
        self.seedRaw = String(question.id)
        self.modeRaw = question.mode.rawValue
        self.targetTeamRaw = question.targetTeam.rawValue
        self.teamOneBase = question.teamOneBase
        self.teamTwoBase = question.teamTwoBase
        self.teamOneProjects = question.teamOneProjects
        self.teamTwoProjects = question.teamTwoProjects
        self.multiplierRaw = question.multiplier.rawValue
        self.submittedAnswer = evaluation.submittedAnswer
        self.expectedAnswer = evaluation.expectedAnswer
        self.isCorrect = evaluation.isCorrect
        self.remainingSeconds = max(0, remainingSeconds)
    }

    var difficulty: ScoringQuizDifficulty {
        ScoringQuizDifficulty(rawValue: difficultyRaw) ?? .medium
    }

    var replaySeed: UInt64 {
        UInt64(seedRaw) ?? 0
    }

    var mode: BalootMode {
        BalootMode(rawValue: modeRaw) ?? .hokum
    }

    var targetTeam: ScoringQuizQuestion.TargetTeam {
        ScoringQuizQuestion.TargetTeam(rawValue: targetTeamRaw) ?? .teamOne
    }

    var multiplier: ScoreMultiplier {
        ScoreMultiplier(rawValue: multiplierRaw) ?? .none
    }
}
