import Foundation

/// اللقطة الكاملة لحالة جولة بلوت محلية واحدة. لا تعتمد على SwiftUI إطلاقًا.
public struct GameState: Codable, Sendable {
    public var phase: GamePhase
    public var players: [Player]
    public var teams: [Team]
    public var rules: BalootRulesConfiguration
    public var mode: GameMode?
    public var trumpSuit: Suit?
    public var dealerSeat: SeatPosition
    public var hands: [Player.ID: [PlayingCard]]
    /// نسخة من الأوراق كما وُزّعت أول مرة، تُستخدم لاحقًا لاكتشاف المشاريع (مثل البلوت).
    public var originalHands: [Player.ID: [PlayingCard]]
    public var currentTrick: Trick?
    public var completedTricks: [Trick]
    public var currentTurnPlayerID: Player.ID?
    public var teamTrickPoints: [Team.ID: Int]
    public var roundNumber: Int
    /// سجل كل الأفعال المطبَّقة على هذه الحالة، يُستخدم لإعادة تشغيل الجولة من الصفر.
    public var actionHistory: [GameAction]
    public var lastRoundResult: RoundScoreResult?

    /// حالة دورة المزايدة الكاملة (الورقة المكشوفة، المزايدات، المشتري، المضاعف).
    public var bidding: BiddingState
    /// الأوراق التي لم تُوزَّع بعد في النمط الكامل (تُسلَّم بعد استقرار المزايدة).
    ///
    /// جزء من الحالة لا متغيّر خارجي، حتى تبقى إعادة التشغيل من سجل الأفعال منتجةً
    /// نفس التوزيع تمامًا بنفس البذرة.
    public var undealtCards: [PlayingCard]
    /// المشاريع التي أعلنها اللاعبون فعلًا في مرحلة الإعلان.
    public var declaredProjects: [Project]
    /// المشاريع المحتسَبة بعد المفاضلة بين الفريقين، تُملأ عند إنهاء الجولة.
    public var awardedProjects: [Project]
    /// الفريق الذي أخذ الأكلات الثماني كلها (كبوت)، إن وُجد.
    public var kabootTeamID: Team.ID?

    public init(
        phase: GamePhase = .setup,
        players: [Player] = [],
        teams: [Team] = [],
        rules: BalootRulesConfiguration = .standard,
        mode: GameMode? = nil,
        trumpSuit: Suit? = nil,
        dealerSeat: SeatPosition = .south,
        hands: [Player.ID: [PlayingCard]] = [:],
        originalHands: [Player.ID: [PlayingCard]] = [:],
        currentTrick: Trick? = nil,
        completedTricks: [Trick] = [],
        currentTurnPlayerID: Player.ID? = nil,
        teamTrickPoints: [Team.ID: Int] = [:],
        roundNumber: Int = 1,
        actionHistory: [GameAction] = [],
        lastRoundResult: RoundScoreResult? = nil,
        bidding: BiddingState = BiddingState(),
        undealtCards: [PlayingCard] = [],
        declaredProjects: [Project] = [],
        awardedProjects: [Project] = [],
        kabootTeamID: Team.ID? = nil
    ) {
        self.phase = phase
        self.players = players
        self.teams = teams
        self.rules = rules
        self.mode = mode
        self.trumpSuit = trumpSuit
        self.dealerSeat = dealerSeat
        self.hands = hands
        self.originalHands = originalHands
        self.currentTrick = currentTrick
        self.completedTricks = completedTricks
        self.currentTurnPlayerID = currentTurnPlayerID
        self.teamTrickPoints = teamTrickPoints
        self.roundNumber = roundNumber
        self.actionHistory = actionHistory
        self.lastRoundResult = lastRoundResult
        self.bidding = bidding
        self.undealtCards = undealtCards
        self.declaredProjects = declaredProjects
        self.awardedProjects = awardedProjects
        self.kabootTeamID = kabootTeamID
    }

    // MARK: - فك ترميز متسامح

    /// أي حقل أُضيف بعد حفظ الحالة يأخذ قيمته الافتراضية بدل إفشال فك الترميز كله.
    /// حالات محفوظة (Replay، مباراة متوقفة) يجب أن تبقى قابلة للفتح بعد أي توسعة.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        phase = try container.decode(GamePhase.self, forKey: .phase)
        players = try container.decode([Player].self, forKey: .players)
        teams = try container.decode([Team].self, forKey: .teams)
        rules = try container.decodeIfPresent(BalootRulesConfiguration.self, forKey: .rules) ?? .standard
        mode = try container.decodeIfPresent(GameMode.self, forKey: .mode)
        trumpSuit = try container.decodeIfPresent(Suit.self, forKey: .trumpSuit)
        dealerSeat = try container.decode(SeatPosition.self, forKey: .dealerSeat)
        hands = try container.decode([Player.ID: [PlayingCard]].self, forKey: .hands)
        originalHands = try container.decode([Player.ID: [PlayingCard]].self, forKey: .originalHands)
        currentTrick = try container.decodeIfPresent(Trick.self, forKey: .currentTrick)
        completedTricks = try container.decode([Trick].self, forKey: .completedTricks)
        currentTurnPlayerID = try container.decodeIfPresent(Player.ID.self, forKey: .currentTurnPlayerID)
        teamTrickPoints = try container.decode([Team.ID: Int].self, forKey: .teamTrickPoints)
        roundNumber = try container.decode(Int.self, forKey: .roundNumber)
        actionHistory = try container.decode([GameAction].self, forKey: .actionHistory)
        lastRoundResult = try container.decodeIfPresent(RoundScoreResult.self, forKey: .lastRoundResult)
        bidding = try container.decodeIfPresent(BiddingState.self, forKey: .bidding) ?? BiddingState()
        undealtCards = try container.decodeIfPresent([PlayingCard].self, forKey: .undealtCards) ?? []
        declaredProjects = try container.decodeIfPresent([Project].self, forKey: .declaredProjects) ?? []
        awardedProjects = try container.decodeIfPresent([Project].self, forKey: .awardedProjects) ?? []
        kabootTeamID = try container.decodeIfPresent(Team.ID.self, forKey: .kabootTeamID)
    }

    /// الأسماء المعروضة للاعبين والفريقين في جولة محلية.
    ///
    /// المحرك لا يعرف شيئًا عن الترجمة، فكانت هذه الأسماء مثبّتة بالعربية داخله وتظهر
    /// كما هي حتى عند تشغيل التطبيق بالإنجليزية. صارت تُحقن من طبقة الواجهة بدلًا من
    /// ذلك، مع إبقاء القيم العربية افتراضًا حتى لا يتغيّر أي مستدعٍ قائم.
    public struct LocalMatchNames: Sendable {
        public var human: String
        public var teamOurs: String
        public var teamOpponent: String
        public var aiWest: String
        public var aiNorth: String
        public var aiEast: String

        public init(
            human: String = "أنت",
            teamOurs: String = "فريقنا",
            teamOpponent: String = "الخصم",
            aiWest: String = "آلي غرب",
            aiNorth: String = "آلي شمال",
            aiEast: String = "آلي شرق"
        ) {
            self.human = human
            self.teamOurs = teamOurs
            self.teamOpponent = teamOpponent
            self.aiWest = aiWest
            self.aiNorth = aiNorth
            self.aiEast = aiEast
        }

        public static let arabicDefault = LocalMatchNames()
    }

    /// ينشئ حالة إعداد جاهزة بأربعة لاعبين (لاعب واحد إنسان والباقي آليون) وفريقين.
    public static func newLocalMatch(
        names: LocalMatchNames = .arabicDefault,
        rules: BalootRulesConfiguration = .standard,
        dealerSeat: SeatPosition = .east
    ) -> GameState {
        newMatch(names: names, rules: rules, dealerSeat: dealerSeat, playerKinds: [.human, .ai, .ai, .ai])
    }

    /// ينشئ جولة تمرير محلية: كل المقاعد بشر، وتُستخدم عند لعب أربعة أشخاص على نفس الجهاز.
    public static func newLocalHumanMatch(
        names: LocalMatchNames = .arabicDefault,
        rules: BalootRulesConfiguration = .standard,
        dealerSeat: SeatPosition = .east
    ) -> GameState {
        newMatch(names: names, rules: rules, dealerSeat: dealerSeat, playerKinds: [.human, .human, .human, .human])
    }

    private static func newMatch(
        names: LocalMatchNames,
        rules: BalootRulesConfiguration,
        dealerSeat: SeatPosition,
        playerKinds: [PlayerKind]
    ) -> GameState {
        let teamA = Team(name: names.teamOurs)
        let teamB = Team(name: names.teamOpponent)
        let players = [
            Player(name: names.human, kind: playerKinds[safe: 0] ?? .human, seat: .south, teamID: teamA.id),
            Player(name: names.aiWest, kind: playerKinds[safe: 1] ?? .ai, seat: .west, teamID: teamB.id),
            Player(name: names.aiNorth, kind: playerKinds[safe: 2] ?? .ai, seat: .north, teamID: teamA.id),
            Player(name: names.aiEast, kind: playerKinds[safe: 3] ?? .ai, seat: .east, teamID: teamB.id)
        ]
        return GameState(players: players, teams: [teamA, teamB], rules: rules, dealerSeat: dealerSeat)
    }

    public func player(at seat: SeatPosition) -> Player? {
        players.first { $0.seat == seat }
    }

    public func player(id: Player.ID) -> Player? {
        players.first { $0.id == id }
    }

    /// اللاعب المشتري في الجولة الحالية.
    public var declarer: Player? {
        bidding.declarerID.flatMap { player(id: $0) }
    }

    /// معرّف فريق المشتري.
    public var declaringTeamID: Team.ID? { declarer?.teamID }

    /// الفريق المقابل لفريق معيّن.
    public func opposingTeamID(of teamID: Team.ID) -> Team.ID? {
        teams.first { $0.id != teamID }?.id
    }

    /// شريك لاعب معيّن (اللاعب الآخر في نفس الفريق).
    public func partner(of playerID: Player.ID) -> Player? {
        guard let me = player(id: playerID) else { return nil }
        return players.first { $0.id != me.id && $0.teamID == me.teamID }
    }

    /// اللاعبون بترتيب الأدوار ابتداءً من مقعد معيّن.
    public func playersInTurnOrder(startingAt seat: SeatPosition) -> [Player] {
        var result: [Player] = []
        var current = seat
        for _ in 0..<players.count {
            if let match = player(at: current) { result.append(match) }
            current = current.next
        }
        return result
    }

    /// اللاعب الذي يبدأ المزايدة وأول أكلة: صاحب الدور بعد الموزّع.
    public var firstToActPlayerID: Player.ID? {
        player(at: dealerSeat.next)?.id
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
