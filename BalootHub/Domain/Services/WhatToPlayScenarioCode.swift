import Foundation
import BalootEngine

enum WhatToPlayScenarioCode {
    static func make(
        seed: UInt64,
        difficulty: WhatToPlayDifficulty,
        focusKindRaw: String?,
        selectedCard: PlayingCard?
    ) -> String {
        let focus = focusKindRaw ?? "auto"
        let selected = selectedCard.map { "-C\($0.suit.ordinal)\($0.rank.ordinal)" } ?? "-P"
        return "WTP-\(seed)-\(difficulty.rawValue)-\(focus)\(selected)"
    }

    static func make(
        for scenario: WhatToPlayScenario,
        selectedOption: WhatToPlayOption?
    ) -> String {
        make(
            seed: scenario.seed,
            difficulty: scenario.difficulty,
            focusKindRaw: scenario.context.focusKind.rawValue,
            selectedCard: selectedOption?.card
        )
    }
}
