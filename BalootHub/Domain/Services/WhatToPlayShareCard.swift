import Foundation
import BalootEngine

struct WhatToPlayShareCardContent: Equatable {
    struct PlayedCardLine: Equatable {
        let playerName: String
        let cardName: String
    }

    let title: String
    let subtitle: String
    let mode: String
    let trickProgress: String
    let turnPlayerName: String
    let tableCards: [PlayedCardLine]
    let legalCardNames: [String]
    let prompt: String

    var isOpeningTrick: Bool {
        tableCards.isEmpty
    }
}

enum WhatToPlayShareCard {
    static func content(for scenario: WhatToPlayScenario) -> WhatToPlayShareCardContent {
        let state = scenario.state
        let played = state.currentTrick?.playedCards ?? []
        return WhatToPlayShareCardContent(
            title: "وش تلعب؟".localized,
            subtitle: "موقف تدريبي من Baloot Hub".localized,
            mode: modeText(state),
            trickProgress: "\(state.completedTricks.count + 1) \("من".localized) 8",
            turnPlayerName: state.player(id: scenario.playerID)?.name ?? "أنت".localized,
            tableCards: played.map { playedCard in
                WhatToPlayShareCardContent.PlayedCardLine(
                    playerName: state.player(id: playedCard.playerID)?.name ?? "لاعب".localized,
                    cardName: playedCard.card.accessibilityName
                )
            },
            legalCardNames: sortedOptions(scenario.options).map { $0.card.accessibilityName },
            prompt: "ما أفضل ورقة؟".localized
        )
    }

    static func text(for scenario: WhatToPlayScenario) -> String {
        let content = content(for: scenario)
        var lines = [
            content.title,
            content.subtitle,
            "\("النمط".localized): \(content.mode)",
            "\("الأكلة".localized): \(content.trickProgress)",
            "\("الدور".localized): \(content.turnPlayerName)"
        ]

        if content.isOpeningTrick {
            lines.append("أنت تفتتح الأكلة.".localized)
        } else {
            lines.append("\("الأوراق على الطاولة".localized):")
            for playedCard in content.tableCards {
                lines.append("- \(playedCard.playerName): \(playedCard.cardName)")
            }
        }

        lines.append("\("الأوراق القانونية".localized):")
        for cardName in content.legalCardNames {
            lines.append("- \(cardName)")
        }
        lines.append(content.prompt)

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
