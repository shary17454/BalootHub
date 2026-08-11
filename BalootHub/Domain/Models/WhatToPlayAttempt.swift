import Foundation
import SwiftData
import BalootEngine

@Model
final class WhatToPlayAttempt {
    var id: UUID
    var createdAt: Date
    var difficultyRaw: String
    var seedValue: Int64
    var selectedSuitRaw: String
    var selectedRankRaw: String
    var bestSuitRaw: String
    var bestRankRaw: String
    var isCorrect: Bool
    var expectedImpact: Int

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        difficulty: WhatToPlayDifficulty,
        seed: UInt64,
        selectedCard: PlayingCard,
        bestCard: PlayingCard,
        isCorrect: Bool,
        expectedImpact: Int
    ) {
        self.id = id
        self.createdAt = createdAt
        self.difficultyRaw = difficulty.rawValue
        self.seedValue = Int64(clamping: seed)
        self.selectedSuitRaw = selectedCard.suit.rawValue
        self.selectedRankRaw = selectedCard.rank.rawValue
        self.bestSuitRaw = bestCard.suit.rawValue
        self.bestRankRaw = bestCard.rank.rawValue
        self.isCorrect = isCorrect
        self.expectedImpact = expectedImpact
    }

    var difficulty: WhatToPlayDifficulty {
        WhatToPlayDifficulty(rawValue: difficultyRaw) ?? .medium
    }

    var selectedCard: PlayingCard? {
        guard let suit = Suit(rawValue: selectedSuitRaw),
              let rank = Rank(rawValue: selectedRankRaw)
        else { return nil }
        return PlayingCard(suit: suit, rank: rank)
    }

    var bestCard: PlayingCard? {
        guard let suit = Suit(rawValue: bestSuitRaw),
              let rank = Rank(rawValue: bestRankRaw)
        else { return nil }
        return PlayingCard(suit: suit, rank: rank)
    }
}
