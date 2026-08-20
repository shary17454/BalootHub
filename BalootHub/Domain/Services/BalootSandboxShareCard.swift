import Foundation
import BalootEngine

enum BalootSandboxShareCard {
    static func text(
        configuration: BalootSandboxConfiguration,
        difficulty: WhatToPlayDifficulty = .medium,
        preview: BalootSandboxPlayPreview? = nil
    ) -> String {
        var lines = [
            "مختبر البلوت".localized,
            "موقف من مختبر Baloot Hub".localized,
            "\("أنت تلعب".localized) \(modeText(configuration))",
            "\("النمط".localized): \(modeText(configuration))",
            "\("الصعوبة".localized): \(difficultyText(difficulty))",
            "\("المضاعف".localized): \(configuration.multiplier.arabicName.localized)",
            "\("الدور".localized): \(seatTitle(configuration.currentTurnSeat))",
            "\("نقاط فريقك".localized): \(teamScore(for: .south, configuration: configuration))",
            "\("نقاط الخصم".localized): \(teamScore(for: .west, configuration: configuration))"
        ]

        if configuration.currentTrickCards.isEmpty {
            lines.append("أنت تفتتح الأكلة.".localized)
        } else {
            lines.append("\("الأوراق على الطاولة".localized):")
            for played in configuration.currentTrickCards {
                lines.append("- \(seatTitle(played.seat)): \(played.card.accessibilityName)")
            }
        }

        if !configuration.declaredProjects.isEmpty {
            lines.append("\("المشاريع المعلنة".localized):")
            for project in configuration.declaredProjects {
                lines.append("- \(seatTitle(project.seat)): \(project.kind.arabicName.localized) +\(project.points)")
            }
        }

        lines.append("\("الأوراق القانونية".localized):")
        for card in legalCards(configuration: configuration) {
            lines.append("- \(card.accessibilityName)")
        }

        if let preview {
            lines.append("\("مراجعة القرار".localized):")
            lines.append("\("اختيارك".localized): \(preview.selectedCard.accessibilityName)")
            if let expertCard = preview.expertCard {
                lines.append("\("اختيار الخبير".localized): \(expertCard.accessibilityName)")
            }
            if let reason = preview.invalidReason {
                lines.append("\("ورقة ممنوعة".localized): \(RuleExplanationFormatter.illegalMoveExplanation(for: preview.selectedCard, reason: reason, trumpSuit: configuration.trumpSuit))")
            }
            if let points = preview.completedTrickPoints {
                lines.append("\("نقاط الأكلة".localized): \(points)")
            }
        }

        lines.append("وش تلعب؟".localized)
        return lines.joined(separator: "\n")
    }

    private static func legalCards(configuration: BalootSandboxConfiguration) -> [PlayingCard] {
        let cards: [PlayingCard] = (try? BalootSandbox.legalMoves(configuration: configuration).compactMap { action in
            guard case .playCard(_, let card) = action else { return nil }
            return card
        }) ?? []
        return cards.sorted {
            if $0.suit.ordinal != $1.suit.ordinal {
                return $0.suit.ordinal < $1.suit.ordinal
            }
            return $0.rank.ordinal < $1.rank.ordinal
        }
    }

    private static func teamScore(
        for representativeSeat: SeatPosition,
        configuration: BalootSandboxConfiguration
    ) -> Int {
        teamSeats(for: representativeSeat).reduce(0) {
            $0 + (configuration.teamTrickPointsBySeat[$1] ?? 0)
        }
    }

    private static func teamSeats(for representativeSeat: SeatPosition) -> [SeatPosition] {
        switch representativeSeat {
        case .south, .north: [.south, .north]
        case .west, .east: [.west, .east]
        }
    }

    private static func modeText(_ configuration: BalootSandboxConfiguration) -> String {
        switch configuration.mode {
        case .sun:
            return "صن".localized
        case .hokum:
            return "\("حكم".localized) \(configuration.trumpSuit?.spokenName ?? "")"
        }
    }

    private static func difficultyText(_ difficulty: WhatToPlayDifficulty) -> String {
        switch difficulty {
        case .easy: "سهل".localized
        case .medium: "متوسط".localized
        case .hard: "صعب".localized
        case .expert: "خبير".localized
        }
    }

    private static func seatTitle(_ seat: SeatPosition) -> String {
        switch seat {
        case .south: "جنوب".localized
        case .west: "غرب".localized
        case .north: "شمال".localized
        case .east: "شرق".localized
        }
    }
}
