import Foundation
import BalootEngine

enum WhatToPlayShareCard {
    static func text(for scenario: WhatToPlayScenario) -> String {
        var lines = [
            "وش تلعب؟".localized,
            "\("النمط".localized): \(modeText(scenario.state))",
            "\("الأكلة".localized): \(scenario.state.completedTricks.count + 1) \("من".localized) 8",
            "\("الدور".localized): \(scenario.state.player(id: scenario.playerID)?.name ?? "أنت".localized)"
        ]

        let played = scenario.state.currentTrick?.playedCards ?? []
        if played.isEmpty {
            lines.append("أنت تفتتح الأكلة.".localized)
        } else {
            lines.append("\("الأوراق على الطاولة".localized):")
            for playedCard in played {
                let playerName = scenario.state.player(id: playedCard.playerID)?.name ?? "لاعب".localized
                lines.append("- \(playerName): \(playedCard.card.accessibilityName)")
            }
        }

        lines.append("\("الأوراق القانونية".localized):")
        for option in sortedOptions(scenario.options) {
            lines.append("- \(option.card.accessibilityName)")
        }
        lines.append("ما أفضل ورقة؟".localized)

        return lines.joined(separator: "\n")
    }

    private static func sortedOptions(_ options: [WhatToPlayOption]) -> [WhatToPlayOption] {
        options.sorted { lhs, rhs in
            if lhs.card.suit.ordinal != rhs.card.suit.ordinal {
                return lhs.card.suit.ordinal < rhs.card.suit.ordinal
            }
            return lhs.card.rank.ordinal < rhs.card.rank.ordinal
        }
    }

    private static func modeText(_ state: GameState) -> String {
        guard let mode = state.mode else { return "غير محدد".localized }
        if mode == .hokum, let suit = state.trumpSuit {
            return "\(mode.arabicName) \(suit.spokenName)"
        }
        return mode.arabicName
    }
}
