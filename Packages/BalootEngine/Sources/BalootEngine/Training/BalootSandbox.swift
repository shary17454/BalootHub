import Foundation

/// ورقة موضوعة يدويًا في أكلة Sandbox.
public struct BalootSandboxPlayedCard: Sendable, Codable, Equatable {
    public let seat: SeatPosition
    public let card: PlayingCard

    public init(seat: SeatPosition, card: PlayingCard) {
        self.seat = seat
        self.card = card
    }
}

/// مشروع معلن يدويًا داخل Sandbox.
public struct BalootSandboxProjectDeclaration: Sendable, Codable, Equatable {
    public let seat: SeatPosition
    public let kind: Project.Kind
    public let cards: [PlayingCard]
    public let points: Int

    public init(seat: SeatPosition, kind: Project.Kind, cards: [PlayingCard], points: Int) {
        self.seat = seat
        self.kind = kind
        self.cards = cards
        self.points = points
    }
}

/// إعداد موقف بلوت يدوي يمكن تشغيله بالمحرك نفسه.
public struct BalootSandboxConfiguration: Sendable, Codable, Equatable {
    public var rules: BalootRulesConfiguration
    public var mode: GameMode
    public var trumpSuit: Suit?
    public var multiplier: Multiplier
    public var dealerSeat: SeatPosition
    public var currentTurnSeat: SeatPosition
    public var handsBySeat: [SeatPosition: [PlayingCard]]
    public var currentTrickCards: [BalootSandboxPlayedCard]
    public var declaredProjects: [BalootSandboxProjectDeclaration]
    public var teamTrickPointsBySeat: [SeatPosition: Int]

    public init(
        rules: BalootRulesConfiguration = .standard,
        mode: GameMode,
        trumpSuit: Suit? = nil,
        multiplier: Multiplier = .none,
        dealerSeat: SeatPosition = .east,
        currentTurnSeat: SeatPosition = .south,
        handsBySeat: [SeatPosition: [PlayingCard]],
        currentTrickCards: [BalootSandboxPlayedCard] = [],
        declaredProjects: [BalootSandboxProjectDeclaration] = [],
        teamTrickPointsBySeat: [SeatPosition: Int] = [:]
    ) {
        self.rules = rules
        self.mode = mode
        self.trumpSuit = trumpSuit
        self.multiplier = multiplier
        self.dealerSeat = dealerSeat
        self.currentTurnSeat = currentTurnSeat
        self.handsBySeat = handsBySeat
        self.currentTrickCards = currentTrickCards
        self.declaredProjects = declaredProjects
        self.teamTrickPointsBySeat = teamTrickPointsBySeat
    }
}

/// نتيجة تجربة ورقة داخل Sandbox.
public struct BalootSandboxPlayPreview: Sendable {
    public let beforeState: GameState
    public let afterState: GameState?
    public let legalCards: [PlayingCard]
    public let selectedCard: PlayingCard
    public let invalidReason: IllegalMoveReason?
    public let expertCard: PlayingCard?
    public let completedTrickWinnerID: Player.ID?
    public let completedTrickPoints: Int?

    public var isLegal: Bool { invalidReason == nil && afterState != nil }
}

public enum BalootSandboxError: Error, Sendable, Equatable {
    case missingHand(SeatPosition)
    case duplicateCard(PlayingCard)
    case invalidTrumpConfiguration
    case currentTrickTooLong
    case currentTrickOrderMismatch(expected: SeatPosition, actual: SeatPosition)
    case currentTurnMismatch(expected: SeatPosition, actual: SeatPosition)
    case unknownProjectSeat(SeatPosition)
}

/// مختبر بلوت يدوي مبني فوق GameState وGameEngine بدل منطق جانبي.
public enum BalootSandbox {
    private static let teamAID = UUID(uuidString: "00000000-0000-0000-0000-00000000BA01")!
    private static let teamBID = UUID(uuidString: "00000000-0000-0000-0000-00000000BA02")!
    private static let playerIDs: [SeatPosition: Player.ID] = [
        .south: UUID(uuidString: "00000000-0000-0000-0000-00000000B301")!,
        .west: UUID(uuidString: "00000000-0000-0000-0000-00000000B302")!,
        .north: UUID(uuidString: "00000000-0000-0000-0000-00000000B303")!,
        .east: UUID(uuidString: "00000000-0000-0000-0000-00000000B304")!
    ]

    /// موقف تدريبي جاهز يصلح كنقطة بداية للواجهة والاختبارات.
    public static let defaultConfiguration = BalootSandboxConfiguration(
        mode: .hokum,
        trumpSuit: .hearts,
        multiplier: .double,
        currentTurnSeat: .south,
        handsBySeat: [
            .south: [
                PlayingCard(suit: .hearts, rank: .jack),
                PlayingCard(suit: .clubs, rank: .ace)
            ],
            .west: [
                PlayingCard(suit: .clubs, rank: .seven),
                PlayingCard(suit: .diamonds, rank: .seven)
            ],
            .north: [
                PlayingCard(suit: .clubs, rank: .eight),
                PlayingCard(suit: .diamonds, rank: .eight)
            ],
            .east: [
                PlayingCard(suit: .clubs, rank: .nine),
                PlayingCard(suit: .diamonds, rank: .nine)
            ]
        ],
        currentTrickCards: [
            BalootSandboxPlayedCard(seat: .west, card: PlayingCard(suit: .spades, rank: .ace)),
            BalootSandboxPlayedCard(seat: .north, card: PlayingCard(suit: .spades, rank: .king)),
            BalootSandboxPlayedCard(seat: .east, card: PlayingCard(suit: .diamonds, rank: .ten))
        ]
    )

    public static func makeState(configuration: BalootSandboxConfiguration) throws -> GameState {
        try validateTrump(mode: configuration.mode, trumpSuit: configuration.trumpSuit)
        try validateCardOwnership(configuration)
        try validateTrickOrder(configuration.currentTrickCards, currentTurnSeat: configuration.currentTurnSeat)

        let teams = [
            Team(id: teamAID, name: "الفريق الأول"),
            Team(id: teamBID, name: "الفريق الثاني")
        ]
        let players = SeatPosition.allCases.map { seat in
            Player(
                id: playerID(for: seat),
                name: playerName(for: seat),
                kind: .human,
                seat: seat,
                teamID: teamID(for: seat)
            )
        }
        let hands = Dictionary(uniqueKeysWithValues: SeatPosition.allCases.map { seat in
            (playerID(for: seat), sorted(configuration.handsBySeat[seat] ?? []))
        })
        let trick = Trick(
            playedCards: configuration.currentTrickCards.map {
                PlayedCard(playerID: playerID(for: $0.seat), card: $0.card)
            },
            leaderSeat: configuration.currentTrickCards.first?.seat ?? configuration.currentTurnSeat
        )
        let teamTrickPoints = Dictionary(uniqueKeysWithValues: teams.map { team -> (Team.ID, Int) in
            let seats = SeatPosition.allCases.filter { teamID(for: $0) == team.id }
            let total = seats.reduce(0) { $0 + (configuration.teamTrickPointsBySeat[$1] ?? 0) }
            return (team.id, total)
        })
        let declaredProjects = try configuration.declaredProjects.map { declaration in
            guard configuration.handsBySeat[declaration.seat] != nil else {
                throw BalootSandboxError.unknownProjectSeat(declaration.seat)
            }
            return Project(
                kind: declaration.kind,
                teamID: teamID(for: declaration.seat),
                playerID: playerID(for: declaration.seat),
                cards: declaration.cards,
                points: declaration.points
            )
        }
        var bidding = BiddingState(
            stage: .completed,
            declarerID: playerID(for: configuration.currentTurnSeat),
            mode: configuration.mode,
            trumpSuit: configuration.mode == .hokum ? configuration.trumpSuit : nil,
            multiplier: configuration.multiplier
        )
        bidding.isLocked = configuration.multiplier != .none

        return GameState(
            phase: .playing,
            players: players,
            teams: teams,
            rules: configuration.rules,
            mode: configuration.mode,
            trumpSuit: configuration.mode == .hokum ? configuration.trumpSuit : nil,
            dealerSeat: configuration.dealerSeat,
            hands: hands,
            originalHands: hands,
            currentTrick: trick,
            completedTricks: [],
            currentTurnPlayerID: playerID(for: configuration.currentTurnSeat),
            teamTrickPoints: teamTrickPoints,
            bidding: bidding,
            declaredProjects: declaredProjects
        )
    }

    public static func legalCards(configuration: BalootSandboxConfiguration) throws -> [PlayingCard] {
        try legalMoves(configuration: configuration).compactMap { action in
            guard case .playCard(_, let card) = action else { return nil }
            return card
        }
    }

    public static func legalMoves(configuration: BalootSandboxConfiguration) throws -> [GameAction] {
        let state = try makeState(configuration: configuration)
        return GameEngine.legalMoves(for: playerID(for: configuration.currentTurnSeat), state: state)
    }

    public static func suggestedProjectDeclaration(
        seat: SeatPosition,
        kind: Project.Kind,
        configuration: BalootSandboxConfiguration
    ) -> BalootSandboxProjectDeclaration? {
        guard let hand = configuration.handsBySeat[seat] else { return nil }
        let player = Player(
            id: playerID(for: seat),
            name: playerName(for: seat),
            kind: .human,
            seat: seat,
            teamID: teamID(for: seat)
        )
        let projects = ProjectDetector.detect(
            hand: hand,
            player: player,
            mode: configuration.mode,
            trumpSuit: configuration.mode == .hokum ? configuration.trumpSuit : nil,
            rules: configuration.rules
        )
        guard let project = projects
            .filter({ $0.kind == kind })
            .max(by: { $1.isStronger(than: $0) })
        else {
            return nil
        }
        return BalootSandboxProjectDeclaration(
            seat: seat,
            kind: kind,
            cards: project.cards,
            points: project.points
        )
    }

    public static func preview(
        playing card: PlayingCard,
        configuration: BalootSandboxConfiguration,
        difficulty: WhatToPlayDifficulty = .medium
    ) throws -> BalootSandboxPlayPreview {
        let state = try makeState(configuration: configuration)
        let playerID = playerID(for: configuration.currentTurnSeat)
        let legal = GameEngine.legalCards(for: playerID, state: state)
        let expert = (try? WhatToPlayTrainer.analyzeOptions(state: state, playerID: playerID, difficulty: difficulty))
            .flatMap { $0.first(where: { $0.rank == 1 })?.card }

        if let reason = GameEngine.invalidMoveReason(playerID: playerID, card: card, state: state) {
            return BalootSandboxPlayPreview(
                beforeState: state,
                afterState: nil,
                legalCards: legal,
                selectedCard: card,
                invalidReason: reason,
                expertCard: expert,
                completedTrickWinnerID: nil,
                completedTrickPoints: nil
            )
        }

        let after = try GameEngine.apply(.playCard(playerID: playerID, card: card), to: state)
        let completed = after.completedTricks.last
        return BalootSandboxPlayPreview(
            beforeState: state,
            afterState: after,
            legalCards: legal,
            selectedCard: card,
            invalidReason: nil,
            expertCard: expert,
            completedTrickWinnerID: completed?.winnerPlayerID,
            completedTrickPoints: completed?.playedCards.reduce(0) {
                $0 + $1.card.points(mode: configuration.mode, trumpSuit: configuration.trumpSuit)
            }
        )
    }

    public static func playerID(for seat: SeatPosition) -> Player.ID {
        playerIDs[seat]!
    }

    public static func teamID(for seat: SeatPosition) -> Team.ID {
        switch seat {
        case .south, .north: teamAID
        case .west, .east: teamBID
        }
    }

    private static func validateTrump(mode: GameMode, trumpSuit: Suit?) throws {
        if mode == .hokum, trumpSuit == nil { throw BalootSandboxError.invalidTrumpConfiguration }
        if mode == .sun, trumpSuit != nil { throw BalootSandboxError.invalidTrumpConfiguration }
    }

    private static func validateCardOwnership(_ configuration: BalootSandboxConfiguration) throws {
        for seat in SeatPosition.allCases where configuration.handsBySeat[seat] == nil {
            throw BalootSandboxError.missingHand(seat)
        }

        var seen: Set<PlayingCard> = []
        for card in configuration.handsBySeat.values.flatMap({ $0 }) + configuration.currentTrickCards.map(\.card) {
            guard seen.insert(card).inserted else {
                throw BalootSandboxError.duplicateCard(card)
            }
        }
    }

    private static func validateTrickOrder(
        _ playedCards: [BalootSandboxPlayedCard],
        currentTurnSeat: SeatPosition
    ) throws {
        guard playedCards.count <= 3 else { throw BalootSandboxError.currentTrickTooLong }
        guard let first = playedCards.first else { return }

        var expected = first.seat
        for played in playedCards {
            guard played.seat == expected else {
                throw BalootSandboxError.currentTrickOrderMismatch(expected: expected, actual: played.seat)
            }
            expected = expected.next
        }
        guard currentTurnSeat == expected else {
            throw BalootSandboxError.currentTurnMismatch(expected: expected, actual: currentTurnSeat)
        }
    }

    private static func sorted(_ cards: [PlayingCard]) -> [PlayingCard] {
        cards.sorted {
            if $0.suit.ordinal != $1.suit.ordinal { return $0.suit.ordinal < $1.suit.ordinal }
            return $0.rank.sequenceOrder < $1.rank.sequenceOrder
        }
    }

    private static func playerName(for seat: SeatPosition) -> String {
        switch seat {
        case .south: "جنوب"
        case .west: "غرب"
        case .north: "شمال"
        case .east: "شرق"
        }
    }
}
