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
        lastRoundResult: RoundScoreResult? = nil
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
    }

    /// ينشئ حالة إعداد جاهزة بأربعة لاعبين (لاعب واحد إنسان والباقي آليون) وفريقين.
    public static func newLocalMatch(humanName: String = "أنت", rules: BalootRulesConfiguration = .standard, dealerSeat: SeatPosition = .east) -> GameState {
        let teamA = Team(name: "فريقنا")
        let teamB = Team(name: "الخصم")
        let players = [
            Player(name: humanName, kind: .human, seat: .south, teamID: teamA.id),
            Player(name: "آلي غرب", kind: .ai, seat: .west, teamID: teamB.id),
            Player(name: "آلي شمال", kind: .ai, seat: .north, teamID: teamA.id),
            Player(name: "آلي شرق", kind: .ai, seat: .east, teamID: teamB.id)
        ]
        return GameState(players: players, teams: [teamA, teamB], rules: rules, dealerSeat: dealerSeat)
    }

    public func player(at seat: SeatPosition) -> Player? {
        players.first { $0.seat == seat }
    }

    public func player(id: Player.ID) -> Player? {
        players.first { $0.id == id }
    }
}
