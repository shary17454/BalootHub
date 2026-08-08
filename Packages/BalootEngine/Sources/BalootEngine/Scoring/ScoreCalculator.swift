import Foundation

/// نتيجة احتساب جولة بلوت مكتملة.
public struct RoundScoreResult: Sendable, Equatable, Codable {
    public var teamPoints: [Team.ID: Int]
    public var winningTeamID: Team.ID?

    public init(teamPoints: [Team.ID: Int], winningTeamID: Team.ID?) {
        self.teamPoints = teamPoints
        self.winningTeamID = winningTeamID
    }
}

/// يحسب الفائز بكل أكلة، ويحسب النتيجة الإجمالية للجولة.
public enum ScoreCalculator {
    /// عدد الأكلات في جولة بلوت مكتملة (32 ورقة ÷ 4 لاعبين).
    public static let tricksPerRound = 8

    /// يحدد الفائز بأكلة مكتملة (4 أوراق) حسب نوع الورقة المطلوب ونوع الحكم إن وُجد.
    public static func resolveTrickWinner(_ trick: Trick, mode: GameMode, trumpSuit: Suit?) -> Player.ID? {
        guard trick.isComplete, let requiredSuit = trick.requiredSuit else { return nil }

        func isEligible(_ played: PlayedCard) -> Bool {
            played.card.suit == requiredSuit || (mode == .hokum && played.card.suit == trumpSuit)
        }

        let eligibleCards = trick.playedCards.filter(isEligible)
        let winner = eligibleCards.max { lhs, rhs in
            rank(of: lhs.card, mode: mode, trumpSuit: trumpSuit, requiredSuit: requiredSuit)
                < rank(of: rhs.card, mode: mode, trumpSuit: trumpSuit, requiredSuit: requiredSuit)
        }
        return winner?.playerID
    }

    /// قوة مقارنة تراعي أفضلية الحكم على النوع المطلوب.
    private static func rank(of card: PlayingCard, mode: GameMode, trumpSuit: Suit?, requiredSuit: Suit) -> Int {
        let isTrump = mode == .hokum && card.suit == trumpSuit
        let base = card.strength(mode: mode, trumpSuit: trumpSuit)
        return isTrump ? base + 100 : base
    }

    /// مجموع نقاط الأوراق التي فازت بها كل أكلة، مضافًا إليها مكافأة آخر أكلة.
    public static func trickPoints(completedTricks: [Trick], players: [Player], mode: GameMode, trumpSuit: Suit?, rules: BalootRulesConfiguration) -> [Team.ID: Int] {
        var totals: [Team.ID: Int] = [:]

        for (index, trick) in completedTricks.enumerated() {
            guard let winnerID = trick.winnerPlayerID ?? resolveTrickWinner(trick, mode: mode, trumpSuit: trumpSuit),
                  let winner = players.first(where: { $0.id == winnerID }) else { continue }

            let cardPoints = trick.playedCards.reduce(0) { $0 + $1.card.points(mode: mode, trumpSuit: trumpSuit) }
            // مكافأة آخر أكلة (10) تُطبَّق في النمطين معًا، وهي القاعدة المتفق عليها في البلوت:
            // حكم = 152 نقطة أوراق + 10 آخر أكلة = 162، وصن = 120 + 10 = 130 (تُضاعف ⇒ 260).
            // كانت تُطبَّق في صن فقط، فكان مجموع جولة الحكم 152 بدل 162.
            // تُحتسب على الأكلة الثامنة تحديدًا لا على آخر عنصر في المصفوفة، حتى لا تُمنح
            // المكافأة لجولة غير مكتملة.
            var bonus = 0
            if index == completedTricks.count - 1, completedTricks.count == Self.tricksPerRound {
                bonus = rules.lastTrickBonus
            }
            totals[winner.teamID, default: 0] += cardPoints + bonus
        }

        return totals
    }

    /// يكتشف مشروع "البلوت" (شايب وبنت الحكم معًا في يد لاعب واحد) في وضع حكم فقط.
    public static func detectBelotProjects(originalHands: [Player.ID: [PlayingCard]], players: [Player], mode: GameMode, trumpSuit: Suit?) -> [Project] {
        guard mode == .hokum, let trumpSuit else { return [] }

        var projects: [Project] = []
        for player in players {
            guard let hand = originalHands[player.id] else { continue }
            let hasKing = hand.contains { $0.suit == trumpSuit && $0.rank == .king }
            let hasQueen = hand.contains { $0.suit == trumpSuit && $0.rank == .queen }
            if hasKing, hasQueen {
                projects.append(Project(kind: .belot, teamID: player.teamID, playerID: player.id, points: 20))
            }
        }
        return projects
    }

    /// يحسب النتيجة الكاملة لجولة مكتملة: نقاط الأكلات + المشاريع، مضروبة بالمضاعف، مع تطبيق مضاعف الصن الافتراضي.
    public static func finalRoundScore(
        completedTricks: [Trick],
        originalHands: [Player.ID: [PlayingCard]],
        players: [Player],
        teams: [Team],
        mode: GameMode,
        trumpSuit: Suit?,
        rules: BalootRulesConfiguration,
        multiplier: Multiplier = .none
    ) -> RoundScoreResult {
        var totals = trickPoints(completedTricks: completedTricks, players: players, mode: mode, trumpSuit: trumpSuit, rules: rules)

        for project in detectBelotProjects(originalHands: originalHands, players: players, mode: mode, trumpSuit: trumpSuit) {
            totals[project.teamID, default: 0] += project.points
        }

        for team in teams where totals[team.id] == nil {
            totals[team.id] = 0
        }

        let modeMultiplier = mode == .sun ? rules.sunScoreMultiplier : 1
        for (key, value) in totals {
            totals[key] = value * modeMultiplier * multiplier.rawValue
        }

        // الترتيب داخل القاموس غير مضمون في Swift، فأخذ `max` منه مباشرة كان يعطي
        // فائزًا مختلفًا بين تشغيل وآخر عند تساوي الفريقين. نمرّ على `teams` بترتيبها
        // الثابت، ونُعيد `nil` صراحةً عند التعادل بدل ترجيح أحدهما عشوائيًا.
        var winningTeamID: Team.ID?
        var bestPoints = Int.min
        var isTied = false
        for team in teams {
            let points = totals[team.id] ?? 0
            if points > bestPoints {
                bestPoints = points
                winningTeamID = team.id
                isTied = false
            } else if points == bestPoints {
                isTied = true
            }
        }
        return RoundScoreResult(teamPoints: totals, winningTeamID: isTied ? nil : winningTeamID)
    }
}
