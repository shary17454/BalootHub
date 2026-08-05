import Foundation
import SwiftData

/// جلسة تسجيل بلوت كاملة بين فريقين.
@Model
final class ScoreSession {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?
    var teamOneName: String
    var teamTwoName: String
    var targetScore: Int
    var winnerTeamNumberRaw: Int?
    var statusRaw: String

    @Relationship(deleteRule: .cascade, inverse: \ScoreRound.session)
    var rounds: [ScoreRound] = []

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date = .now,
        completedAt: Date? = nil,
        teamOneName: String,
        teamTwoName: String,
        targetScore: Int,
        status: SessionStatus = .active
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
        self.teamOneName = teamOneName
        self.teamTwoName = teamTwoName
        self.targetScore = targetScore
        self.statusRaw = status.rawValue
    }

    var status: SessionStatus {
        get { SessionStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    var sortedRounds: [ScoreRound] {
        rounds.sorted { $0.roundNumber < $1.roundNumber }
    }

    func teamOneTotal(rules: ScoreRules) -> Int {
        rounds.reduce(0) { $0 + $1.teamOneFinalScore(rules: rules) }
    }

    func teamTwoTotal(rules: ScoreRules) -> Int {
        rounds.reduce(0) { $0 + $1.teamTwoFinalScore(rules: rules) }
    }

    /// الفريق المتقدم حاليًا، أو `nil` عند التعادل.
    func leadingTeamName(rules: ScoreRules) -> String? {
        let one = teamOneTotal(rules: rules)
        let two = teamTwoTotal(rules: rules)
        if one == two { return nil }
        return one > two ? teamOneName : teamTwoName
    }

    /// اسم الفريق الفائز إن بلغ أحدهما الهدف، وإلا `nil`.
    func winnerName(rules: ScoreRules) -> String? {
        let one = teamOneTotal(rules: rules)
        let two = teamTwoTotal(rules: rules)
        guard one >= targetScore || two >= targetScore else { return nil }
        if one == two { return nil }
        return one > two ? teamOneName : teamTwoName
    }

    /// ملخص نصي للجلسة قابل للمشاركة عبر ShareLink.
    func textSummary(rules: ScoreRules) -> String {
        var lines: [String] = []
        lines.append("ملخص جلسة تسجيل البلوت")
        lines.append("\(teamOneName) مقابل \(teamTwoName)")
        lines.append("الهدف: \(targetScore) نقطة")
        lines.append("")
        for round in sortedRounds {
            let scoreLine = "\(teamOneName) \(round.teamOneFinalScore(rules: rules)) - \(round.teamTwoFinalScore(rules: rules)) \(teamTwoName)"
            lines.append("الصكة \(round.roundNumber) — \(round.mode.title) — \(round.multiplier.title): \(scoreLine)")
        }
        lines.append("")
        lines.append("الإجمالي: \(teamOneName) \(teamOneTotal(rules: rules)) - \(teamTwoTotal(rules: rules)) \(teamTwoName)")
        if let winner = winnerName(rules: rules) {
            lines.append("الفائز: \(winner) 🏆")
        }
        return lines.joined(separator: "\n")
    }
}
