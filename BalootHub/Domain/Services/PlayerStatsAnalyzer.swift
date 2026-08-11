import Foundation

struct PlayerStatsSummary: Equatable {
    let finishedMatches: Int
    let wins: Int
    let losses: Int
    let ties: Int
    let winRate: Double
    let averagePoints: Double
    let sunRounds: Int
    let hokumRounds: Int
    let projectPoints: Int
    let kabootCount: Int
    let highestWinMargin: Int
    let biggestLossMargin: Int
    let longestWinStreak: Int
    let styleTitle: String
    let advice: String
}

enum PlayerStatsAnalyzer {
    static func summarize(sessions: [ScoreSession], rules: ScoreRules) -> PlayerStatsSummary {
        let finished = sessions
            .filter { $0.status == .finished || $0.winnerName(rules: rules) != nil }
            .sorted { $0.createdAt < $1.createdAt }

        var wins = 0
        var losses = 0
        var ties = 0
        var totalPoints = 0
        var sunRounds = 0
        var hokumRounds = 0
        var projectPoints = 0
        var kabootCount = 0
        var highestWinMargin = 0
        var biggestLossMargin = 0
        var currentWinStreak = 0
        var longestWinStreak = 0

        for session in finished {
            let ours = session.teamOneTotal(rules: rules)
            let opponent = session.teamTwoTotal(rules: rules)
            totalPoints += ours

            let margin = ours - opponent
            if margin > 0 {
                wins += 1
                highestWinMargin = max(highestWinMargin, margin)
                currentWinStreak += 1
                longestWinStreak = max(longestWinStreak, currentWinStreak)
            } else if margin < 0 {
                losses += 1
                biggestLossMargin = max(biggestLossMargin, abs(margin))
                currentWinStreak = 0
            } else {
                ties += 1
                currentWinStreak = 0
            }

            for round in session.rounds {
                switch round.mode {
                case .sun:
                    sunRounds += 1
                case .hokum:
                    hokumRounds += 1
                }
                projectPoints += round.teamOneProjects
                let oursRound = round.teamOneFinalScore(rules: rules)
                let opponentRound = round.teamTwoFinalScore(rules: rules)
                if oursRound > 0, opponentRound == 0 {
                    kabootCount += 1
                }
            }
        }

        let finishedMatches = finished.count
        let winRate = finishedMatches == 0 ? 0 : Double(wins) / Double(finishedMatches)
        let averagePoints = finishedMatches == 0 ? 0 : Double(totalPoints) / Double(finishedMatches)
        let style = style(
            winRate: winRate,
            sunRounds: sunRounds,
            hokumRounds: hokumRounds,
            projectPoints: projectPoints,
            kabootCount: kabootCount
        )

        return PlayerStatsSummary(
            finishedMatches: finishedMatches,
            wins: wins,
            losses: losses,
            ties: ties,
            winRate: winRate,
            averagePoints: averagePoints,
            sunRounds: sunRounds,
            hokumRounds: hokumRounds,
            projectPoints: projectPoints,
            kabootCount: kabootCount,
            highestWinMargin: highestWinMargin,
            biggestLossMargin: biggestLossMargin,
            longestWinStreak: longestWinStreak,
            styleTitle: style.title,
            advice: style.advice
        )
    }

    private static func style(
        winRate: Double,
        sunRounds: Int,
        hokumRounds: Int,
        projectPoints: Int,
        kabootCount: Int
    ) -> (title: String, advice: String) {
        if kabootCount > 0 {
            return ("لاعب ضاغط", "استثمر قدرتك على السيطرة، لكن لا تصرف أوراق الحكم القوية في أكلات قليلة النقاط.")
        }
        if projectPoints >= 150 {
            return ("صياد مشاريع", "مشاريعك مؤثرة؛ راجع توقيت الإعلان والشراء حتى لا تعتمد على المشروع وحده.")
        }
        if hokumRounds > sunRounds * 2 {
            return ("متخصص حكم", "أداؤك يميل للحكم. درّب قراءة الصن حتى لا تصبح قراراتك متوقعة.")
        }
        if sunRounds > hokumRounds * 2 {
            return ("متخصص صن", "أداؤك يميل للصن. راجع القطع وسحب الحكم لتقوية لعب الحكم.")
        }
        if winRate >= 0.65 {
            return ("لاعب متوازن", "نسبة الفوز جيدة. ركز الآن على تقليل أسوأ خسارة وتحسين قرارات الشراء.")
        }
        return ("قيد التطور", "ابدأ بتحدي الحساب ومدرب وش تلعب؟ ثم راقب ارتفاع نسبة الفوز ومتوسط النقاط.")
    }
}
