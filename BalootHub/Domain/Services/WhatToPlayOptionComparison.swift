import Foundation
import BalootEngine

struct WhatToPlayOptionComparisonRow: Identifiable, Equatable {
    let card: PlayingCard
    let rank: Int
    let expectedImpact: Int
    let lostExpectedPoints: Int
    let outcome: WhatToPlayOptionOutcome
    let outcomeReason: String
    let rationale: String
    let isSelected: Bool
    let isExpertChoice: Bool

    var id: PlayingCard { card }
}

enum WhatToPlayOptionComparison {
    static func rows(for scenario: WhatToPlayScenario, selectedCard: PlayingCard) -> [WhatToPlayOptionComparisonRow] {
        let bestImpact = scenario.bestOption?.expectedImpact ?? scenario.options.map(\.expectedImpact).max() ?? 0
        return scenario.options
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
                    lostExpectedPoints: max(0, bestImpact - option.expectedImpact),
                    outcome: option.outcome,
                    outcomeReason: option.outcomeReason,
                    rationale: option.explanation,
                    isSelected: option.card == selectedCard,
                    isExpertChoice: option.isExpertChoice
                )
            }
    }
}
