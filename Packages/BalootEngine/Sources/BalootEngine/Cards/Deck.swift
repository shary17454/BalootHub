import Foundation

/// حزمة أوراق البلوت المكوّنة من 32 ورقة (لا توجد قيم 2 حتى 6).
public struct Deck: Sendable {
    public private(set) var cards: [PlayingCard]

    /// ينشئ حزمة كاملة مرتبة (غير مخلوطة) من 32 ورقة.
    public init() {
        cards = Suit.allCases.flatMap { suit in
            Rank.allCases.map { rank in PlayingCard(suit: suit, rank: rank) }
        }
    }

    /// عدد الأوراق في الحزمة الكاملة.
    public static let fullCount = 32

    /// يخلط ترتيب الأوراق باستخدام مولّد عشوائي مُمرَّر (لتمكين الاختبار الحتمي).
    public mutating func shuffle(using generator: inout some RandomNumberGenerator) {
        cards.shuffle(using: &generator)
    }

    public mutating func shuffle() {
        cards.shuffle()
    }

    /// يوزّع الأوراق على أربعة لاعبين بالتساوي (8 أوراق لكل لاعب).
    /// - Returns: مصفوفة من 4 مصفوفات أوراق بترتيب اللاعبين.
    public func dealEqually(playerCount: Int = 4) -> [[PlayingCard]] {
        guard playerCount > 0, cards.count % playerCount == 0 else {
            return []
        }
        let handSize = cards.count / playerCount
        return (0..<playerCount).map { index in
            Array(cards[(index * handSize)..<((index + 1) * handSize)])
        }
    }
}
