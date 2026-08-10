import Foundation

/// نتيجة احتساب جولة بلوت مكتملة، مفصّلة بما يكفي لشاشة التحليل بعد الجولة.
///
/// التفصيل هنا ليس ترفًا: تقرير «أين ضاعت النقاط» يحتاج تفكيك النتيجة إلى مصادرها،
/// وإعادة حسابها في طبقة الواجهة كانت ستنتج مصدر حقيقة ثانيًا يتعارض مع المحرك.
public struct RoundScoreResult: Sendable, Equatable, Codable {
    /// النقاط النهائية لكل فريق بعد كل القواعد والمضاعفات.
    public var teamPoints: [Team.ID: Int]
    public var winningTeamID: Team.ID?
    /// نقاط الأوراق والأكلات وحدها (قبل المشاريع والكبوت والمضاعفات).
    public var trickPoints: [Team.ID: Int]
    /// نقاط المشاريع المحتسَبة لكل فريق.
    public var projectPoints: [Team.ID: Int]
    /// المشاريع التي احتُسبت فعلًا بعد المفاضلة.
    public var awardedProjects: [Project]
    /// المشاريع التي أُلغيت لأن الخصم ملك مشروعًا أقوى.
    public var overruledProjects: [Project]
    /// الفريق الذي حقق كبوتًا (أخذ الأكلات الثماني)، إن وُجد.
    public var kabootTeamID: Team.ID?
    /// هل «طاح» المشتري (لم يتجاوز الخصم فذهبت كل النقاط للخصم)؟
    public var didDeclarerFail: Bool
    /// المضاعف المطبَّق على الجولة.
    public var multiplier: Multiplier

    public init(
        teamPoints: [Team.ID: Int],
        winningTeamID: Team.ID?,
        trickPoints: [Team.ID: Int] = [:],
        projectPoints: [Team.ID: Int] = [:],
        awardedProjects: [Project] = [],
        overruledProjects: [Project] = [],
        kabootTeamID: Team.ID? = nil,
        didDeclarerFail: Bool = false,
        multiplier: Multiplier = .none
    ) {
        self.teamPoints = teamPoints
        self.winningTeamID = winningTeamID
        self.trickPoints = trickPoints
        self.projectPoints = projectPoints
        self.awardedProjects = awardedProjects
        self.overruledProjects = overruledProjects
        self.kabootTeamID = kabootTeamID
        self.didDeclarerFail = didDeclarerFail
        self.multiplier = multiplier
    }

    /// فك ترميز متسامح حتى تبقى النتائج المحفوظة سابقًا قابلة للقراءة.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        teamPoints = try container.decode([Team.ID: Int].self, forKey: .teamPoints)
        winningTeamID = try container.decodeIfPresent(Team.ID.self, forKey: .winningTeamID)
        trickPoints = try container.decodeIfPresent([Team.ID: Int].self, forKey: .trickPoints) ?? [:]
        projectPoints = try container.decodeIfPresent([Team.ID: Int].self, forKey: .projectPoints) ?? [:]
        awardedProjects = try container.decodeIfPresent([Project].self, forKey: .awardedProjects) ?? []
        overruledProjects = try container.decodeIfPresent([Project].self, forKey: .overruledProjects) ?? []
        kabootTeamID = try container.decodeIfPresent(Team.ID.self, forKey: .kabootTeamID)
        didDeclarerFail = try container.decodeIfPresent(Bool.self, forKey: .didDeclarerFail) ?? false
        multiplier = try container.decodeIfPresent(Multiplier.self, forKey: .multiplier) ?? .none
    }
}

/// يحسب الفائز بكل أكلة، ويحسب النتيجة الإجمالية للجولة.
public enum ScoreCalculator {
    /// عدد الأكلات في جولة بلوت مكتملة (32 ورقة ÷ 4 لاعبين).
    public static let tricksPerRound = 8

    // MARK: - الأكلات

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

    // MARK: - الكبوت

    /// الفريق الذي أخذ **كل** الأكلات الثماني، أو `nil` إن لم يحدث كبوت.
    public static func detectKaboot(completedTricks: [Trick], players: [Player]) -> Team.ID? {
        guard completedTricks.count == Self.tricksPerRound else { return nil }

        var teamIDs: Set<Team.ID> = []
        for trick in completedTricks {
            guard let winnerID = trick.winnerPlayerID,
                  let winner = players.first(where: { $0.id == winnerID }) else { return nil }
            teamIDs.insert(winner.teamID)
        }
        return teamIDs.count == 1 ? teamIDs.first : nil
    }

    // MARK: - المشاريع

    /// يكتشف مشروع «البلوت» (شايب وبنت الحكم معًا في يد لاعب واحد) في وضع حكم فقط.
    ///
    /// أُبقيت كواجهة مستقلة لأن الكتالوج التعليمي وشاشات القواعد تستدعيها لعرض
    /// المشروع الأشهر وحده دون بقية المشاريع.
    public static func detectBelotProjects(originalHands: [Player.ID: [PlayingCard]], players: [Player], mode: GameMode, trumpSuit: Suit?) -> [Project] {
        var rules = BalootRulesConfiguration.standard
        rules.sequenceProjectsEnabled = false
        rules.sameRankProjectsEnabled = false
        return players.flatMap { player in
            ProjectDetector.detect(
                hand: originalHands[player.id] ?? [],
                player: player,
                mode: mode,
                trumpSuit: trumpSuit,
                rules: rules
            )
        }
    }

    // MARK: - النتيجة النهائية

    /// يحسب النتيجة الكاملة لجولة مكتملة.
    ///
    /// ترتيب التطبيق مقصود ولا يجوز تبديله:
    /// 1. نقاط الأكلات + مكافأة آخر أكلة.
    /// 2. مكافأة الكبوت.
    /// 3. المشاريع بعد حسم المفاضلة بين الفريقين.
    /// 4. قاعدة «طياح المشتري»: تُطبَّق على المجموع الأساسي **قبل** المضاعفات، لأن
    ///    المقارنة بين الفريقين على نقاط الجولة الحقيقية لا على قيمة مضاعَفة.
    /// 5. مضاعف الصن، ثم مضاعف الدبل/القهوة.
    ///
    /// - Parameters:
    ///   - declaredProjects: المشاريع المُعلنة فعلًا. تمرير `nil` يعني الاكتشاف
    ///     التلقائي من الأيدي (يُستخدم عند تعطيل شرط الإعلان وفي الدروس).
    ///   - declaringTeamID: فريق المشتري، ولا تُطبَّق قاعدة الطياح بدونه.
    public static func finalRoundScore(
        completedTricks: [Trick],
        originalHands: [Player.ID: [PlayingCard]],
        players: [Player],
        teams: [Team],
        mode: GameMode,
        trumpSuit: Suit?,
        rules: BalootRulesConfiguration,
        multiplier: Multiplier = .none,
        declaredProjects: [Project]? = nil,
        declaringTeamID: Team.ID? = nil
    ) -> RoundScoreResult {
        let tricks = trickPoints(completedTricks: completedTricks, players: players, mode: mode, trumpSuit: trumpSuit, rules: rules)

        var totals: [Team.ID: Int] = [:]
        for team in teams { totals[team.id] = tricks[team.id] ?? 0 }

        // 2) الكبوت
        var kabootTeamID: Team.ID?
        if rules.kabootEnabled, let sweeper = detectKaboot(completedTricks: completedTricks, players: players) {
            kabootTeamID = sweeper
            totals[sweeper, default: 0] += mode == .hokum ? rules.kabootBonusHokum : rules.kabootBonusSun
        }

        // 3) المشاريع
        let candidates = declaredProjects ?? autoDetectedProjects(
            originalHands: originalHands, players: players, mode: mode, trumpSuit: trumpSuit, rules: rules
        )
        let resolution = ProjectDetector.resolve(projects: candidates, teams: teams)
        var projectPoints: [Team.ID: Int] = [:]
        for team in teams {
            let points = resolution.points(for: team.id)
            projectPoints[team.id] = points
            totals[team.id, default: 0] += points
        }

        // 4) طياح المشتري
        var didDeclarerFail = false
        if rules.declarerMustWinMajority,
           let declaringTeamID,
           let opponentID = teams.first(where: { $0.id != declaringTeamID })?.id {
            let declaring = totals[declaringTeamID] ?? 0
            let opponent = totals[opponentID] ?? 0
            if declaring <= opponent {
                didDeclarerFail = true
                totals[opponentID] = declaring + opponent
                totals[declaringTeamID] = 0
            }
        }

        // 5) المضاعفات
        let modeMultiplier = mode == .sun ? rules.sunScoreMultiplier : 1
        let raiseFactor = multiplier.factor(rules: rules)
        for team in teams {
            totals[team.id] = (totals[team.id] ?? 0) * modeMultiplier * raiseFactor
        }

        return RoundScoreResult(
            teamPoints: totals,
            winningTeamID: resolveWinner(totals: totals, teams: teams),
            trickPoints: tricks,
            projectPoints: projectPoints,
            awardedProjects: resolution.awarded,
            overruledProjects: resolution.overruled,
            kabootTeamID: kabootTeamID,
            didDeclarerFail: didDeclarerFail,
            multiplier: multiplier
        )
    }

    private static func autoDetectedProjects(
        originalHands: [Player.ID: [PlayingCard]],
        players: [Player],
        mode: GameMode,
        trumpSuit: Suit?,
        rules: BalootRulesConfiguration
    ) -> [Project] {
        players.flatMap { player in
            ProjectDetector.detect(
                hand: originalHands[player.id] ?? [],
                player: player,
                mode: mode,
                trumpSuit: trumpSuit,
                rules: rules
            )
        }
    }

    /// الفائز بالجولة، أو `nil` عند التعادل.
    ///
    /// المرور على `teams` بترتيبها الثابت لا على القاموس: ترتيب القاموس في Swift غير
    /// مضمون، فأخذ `max` منه مباشرة كان يعطي فائزًا مختلفًا بين تشغيل وآخر عند التساوي.
    private static func resolveWinner(totals: [Team.ID: Int], teams: [Team]) -> Team.ID? {
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
        return isTied ? nil : winningTeamID
    }
}
