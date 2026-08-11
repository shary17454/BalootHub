import Foundation
import BalootEngine

struct WhatToPlayOptionComparisonRow: Identifiable, Equatable {
    let card: PlayingCard
    let rank: Int
    let expectedImpact: Int
    let rationale: String
    let isSelected: Bool
    let isExpertChoice: Bool

    var id: PlayingCard { card }
}

enum WhatToPlayOptionComparison {
    static func rows(for scenario: WhatToPlayScenario, selectedCard: PlayingCard) -> [WhatToPlayOptionComparisonRow] {
        scenario.options
            .sorted { lhs, rhs in
                if lhs.rank != rhs.rank { return lhs.rank < rhs.rank }
                if lhs.card.suit.ordinal != rhs.card.suit.ordinal { return lhs.card.suit.ordinal < rhs.card.suit.ordinal }
                return lhs.card.rank.ordinal < rhs.card.rank.ordinal
            }
            .map { option in
                WhatToPlayOptionComparisonRow(
                    card: option.card,
                    rank: option.rank,
                    expectedImpact: option.expectedImpact,
                    rationale: option.explanation,
                    isSelected: option.card == selectedCard,
                    isExpertChoice: option.isExpertChoice
                )
            }
    }
}
