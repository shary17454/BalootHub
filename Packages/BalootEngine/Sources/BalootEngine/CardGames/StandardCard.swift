import Foundation

/// Physical identity distinguishes duplicate cards in double-deck games.
public struct StandardCard: Identifiable, Equatable, Hashable, Codable, Sendable {
    public let id: Int
    public let suit: Suit
    public let rank: Int
    public let joker: Int

    public init(id: Int, suit: Suit, rank: Int, joker: Int = 0) {
        self.id = id; self.suit = suit; self.rank = rank; self.joker = joker
    }

    public var isJoker: Bool { joker != 0 }
    public var highRank: Int { rank == 1 ? 14 : rank }
    public var label: String {
        if isJoker { return joker == 1 ? "JOKER ♠" : "JOKER ♥" }
        return "\([1: "A", 11: "J", 12: "Q", 13: "K"][rank] ?? String(rank)) \(suit.symbol)"
    }

    public static func deck(copies: Int = 1, jokers: Int = 0, seed: UInt64) -> [StandardCard] {
        var cards: [StandardCard] = []
        for _ in 0..<copies {
            for suit in Suit.allCases {
                for rank in 1...13 { cards.append(.init(id: cards.count, suit: suit, rank: rank)) }
            }
        }
        for index in 0..<jokers {
            cards.append(.init(id: cards.count, suit: index.isMultiple(of: 2) ? .spades : .hearts, rank: 0, joker: index + 1))
        }
        var generator = SeededGenerator(seed: seed)
        cards.shuffle(using: &generator)
        return cards
    }
}

public enum CardGameError: Error, Equatable, Sendable {
    case wrongPhase, wrongTurn, illegalMove, invalidSelection
}
