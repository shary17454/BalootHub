import Foundation

/// ورقة لعب واحدة من حزمة الـ32 ورقة.
public struct PlayingCard: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public let suit: Suit
    public let rank: Rank

    public init(id: UUID = UUID(), suit: Suit, rank: Rank) {
        self.id = id
        self.suit = suit
        self.rank = rank
    }

    /// نص العرض المختصر، مثل "A♠".
    public var displayLabel: String {
        "\(rank.shortLabel)\(suit.symbol)"
    }

    public static func == (lhs: PlayingCard, rhs: PlayingCard) -> Bool {
        lhs.suit == rhs.suit && lhs.rank == rhs.rank
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(suit)
        hasher.combine(rank)
    }

    /// قوة الورقة النسبية ضمن نوعها حسب وضع اللعب، تُستخدم لمقارنة ورقتين من نفس النوع.
    /// - Parameters:
    ///   - mode: نمط الجولة (صن أو حكم).
    ///   - trumpSuit: نوع الحكم إن كان النمط حكم.
    public func strength(mode: GameMode, trumpSuit: Suit?) -> Int {
        switch mode {
        case .sun:
            return Rank.sunOrder.firstIndex(of: rank) ?? 0
        case .hokum:
            if let trumpSuit, suit == trumpSuit {
                return Rank.hokumTrumpOrder.firstIndex(of: rank) ?? 0
            }
            return Rank.hokumNonTrumpOrder.firstIndex(of: rank) ?? 0
        }
    }

    /// نقاط الورقة حسب النمط الحالي.
    public func points(mode: GameMode, trumpSuit: Suit?) -> Int {
        switch mode {
        case .sun:
            return rank.sunPoints
        case .hokum:
            if let trumpSuit, suit == trumpSuit {
                return rank.hokumTrumpPoints
            }
            return rank.hokumNonTrumpPoints
        }
    }
}
