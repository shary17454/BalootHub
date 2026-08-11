import Foundation
import BalootEngine

struct WhatToPlayShareCardContent: Equatable {
    struct PlayedCardLine: Equatable {
        let playerName: String
        let cardName: String
    }

    let title: String
    let subtitle: String
    let contextLine: String
    let mode: String
    let difficulty: String
    let focus: String
    let trickProgress: String
    let turnPlayerName: String
    let tableCards: [PlayedCardLine]
    let legalCardNames: [String]
    let selectedCardName: String?
    let bestCardName: String?
    let lostExpectedPoints: Int?
    let selectedRank: Int?
    let prompt: String

    var isOpeningTrick: Bool {
        tableCards.isEmpty
    }

    var includesAnswerReview: Bool {
        selectedCardName != nil || bestCardName != nil
    }
}

enum WhatToPlayShareCard {
    static func content(
        for scenario: WhatToPlayScenario,
        selectedOption: WhatToPlayOption? = nil
    ) -> WhatToPlayShareCardContent {
        let state = scenario.state
        let played = state.currentTrick?.playedCards ?? []
        let mode = modeText(state)
        let best = selectedOption == nil ? nil : scenario.bestOption
        let lost = selectedOption.flatMap { selected in
            best.map { max(0, $0.expectedImpact - selected.expectedImpact) }
        }
        return WhatToPlayShareCardContent(
            title: "وش تلعب؟".localized,
            subtitle: selectedOption == nil
                ? "موقف تدريبي من Baloot Hub".localized
                : "مراجعة قرار من Baloot Hub".localized,
            contextLine: "\("أنت تلعب".localized) \(mode)",
            mode: mode,
            difficulty: difficultyText(scenario.difficulty),
            focus: focusText(scenario.context.focusKind),
            trickProgress: "\(state.completedTricks.count + 1) \("من".localized) 8",
            turnPlayerName: state.player(id: scenario.playerID)?.name ?? "أنت".localized,
            tableCards: played.map { playedCard in
                WhatToPlayShareCardContent.PlayedCardLine(
                    playerName: state.player(id: playedCard.playerID)?.name ?? "لاعب".localized,
                    cardName: playedCard.card.accessibilityName
                )
            },
            legalCardNames: sortedOptions(scenario.options).map { $0.card.accessibilityName },
            selectedCardName: selectedOption?.card.accessibilityName,
            bestCardName: best?.card.accessibilityName,
            lostExpectedPoints: lost,
            selectedRank: selectedOption?.rank,
            prompt: selectedOption == nil ? "ما أفضل ورقة؟".localized : "راجع القرار وتدرّب على قراءة الموقف.".localized
        )
    }

    static func text(
        for scenario: WhatToPlayScenario,
        selectedOption: WhatToPlayOption? = nil
    ) -> String {
        let content = content(for: scenario, selectedOption: selectedOption)
        var lines = [
            content.title,
            content.subtitle,
            content.contextLine,
            "\("النمط".localized): \(content.mode)",
            "\("الصعوبة".localized): \(content.difficulty)",
            "\("تركيز التدريب".localized): \(content.focus)",
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

        if content.includesAnswerReview {
            lines.append("\("مراجعة القرار".localized):")
            if let selectedCardName = content.selectedCardName {
                lines.append("\("اختياري".localized): \(selectedCardName)")
            }
            if let bestCardName = content.bestCardName {
                lines.append("\("أفضل ورقة".localized): \(bestCardName)")
            }
            if let selectedRank = content.selectedRank {
                lines.append("\("ترتيب اختياري".localized): \(selectedRank)")
            }
            if let lostExpectedPoints = content.lostExpectedPoints {
                lines.append("\("نقاط متوقعة ضائعة".localized): \(lostExpectedPoints)")
            }
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

    private static func difficultyText(_ difficulty: WhatToPlayDifficulty) -> String {
        switch difficulty {
        case .easy:
            return "سهل".localized
        case .medium:
            return "متوسط".localized
        case .hard:
            return "صعب".localized
        }
    }

    private static func focusText(_ focusKind: WhatToPlayScenarioFocusKind) -> String {
        switch focusKind {
        case .openingLead:
            return "افتتاح الأكلة".localized
        case .followSuit:
            return "اتباع اللون".localized
        case .trumpPressure:
            return "ضغط الحكم".localized
        case .narrowChoice:
            return "خيارات محدودة".localized
        }
    }
}
