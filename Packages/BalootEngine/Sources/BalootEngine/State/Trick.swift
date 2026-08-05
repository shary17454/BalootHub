import Foundation

/// ورقة لُعبت ضمن أكلة (Trick) من لاعب محدد.
public struct PlayedCard: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public let playerID: Player.ID
    public let card: PlayingCard

    public init(id: UUID = UUID(), playerID: Player.ID, card: PlayingCard) {
        self.id = id
        self.playerID = playerID
        self.card = card
    }
}

/// أكلة واحدة: أربع أوراق يلعبها اللاعبون بالترتيب.
public struct Trick: Identifiable, Codable, Sendable {
    public let id: UUID
    public var playedCards: [PlayedCard]
    public var leaderSeat: SeatPosition
    public var winnerPlayerID: Player.ID?

    public init(id: UUID = UUID(), playedCards: [PlayedCard] = [], leaderSeat: SeatPosition, winnerPlayerID: Player.ID? = nil) {
        self.id = id
        self.playedCards = playedCards
        self.leaderSeat = leaderSeat
        self.winnerPlayerID = winnerPlayerID
    }

    public var isComplete: Bool { playedCards.count == 4 }

    /// نوع الورقة المطلوب اتّباعه، وهو نوع أول ورقة لُعبت في الأكلة.
    public var requiredSuit: Suit? { playedCards.first?.card.suit }
}
