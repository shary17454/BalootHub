import Foundation
import SwiftData

/// جولة واحدة (صكّة) داخل جلسة تسجيل بلوت.
@Model
final class ScoreRound {
    var id: UUID
    var roundNumber: Int
    var createdAt: Date
    var modeRaw: String
    var teamOneBaseScore: Int
    var teamTwoBaseScore: Int
    var teamOneProjects: Int
    var teamTwoProjects: Int
    var multiplierRaw: String
    var notes: String?
    var session: ScoreSession?

    init(
        id: UUID = UUID(),
        roundNumber: Int,
        createdAt: Date = .now,
        mode: BalootMode,
        teamOneBaseScore: Int,
        teamTwoBaseScore: Int,
        teamOneProjects: Int = 0,
        teamTwoProjects: Int = 0,
        multiplier: ScoreMultiplier = .none,
        notes: String? = nil
    ) {
        self.id = id
        self.roundNumber = roundNumber
        self.createdAt = createdAt
        self.modeRaw = mode.rawValue
        self.teamOneBaseScore = max(0, teamOneBaseScore)
        self.teamTwoBaseScore = max(0, teamTwoBaseScore)
        self.teamOneProjects = max(0, teamOneProjects)
        self.teamTwoProjects = max(0, teamTwoProjects)
        self.multiplierRaw = multiplier.rawValue
        self.notes = notes
    }

    var mode: BalootMode {
        get { BalootMode(rawValue: modeRaw) ?? .hokum }
        set { modeRaw = newValue.rawValue }
    }

    var multiplier: ScoreMultiplier {
        get { ScoreMultiplier(rawValue: multiplierRaw) ?? .none }
        set { multiplierRaw = newValue.rawValue }
    }

    /// إجمالي نقاط الفريق الأول بعد تطبيق المضاعف، وفق ``ScoreRules``.
    func teamOneFinalScore(rules: ScoreRules) -> Int {
        rules.finalScore(baseScore: teamOneBaseScore, projects: teamOneProjects, multiplier: multiplier)
    }

    /// إجمالي نقاط الفريق الثاني بعد تطبيق المضاعف، وفق ``ScoreRules``.
    func teamTwoFinalScore(rules: ScoreRules) -> Int {
        rules.finalScore(baseScore: teamTwoBaseScore, projects: teamTwoProjects, multiplier: multiplier)
    }
}
