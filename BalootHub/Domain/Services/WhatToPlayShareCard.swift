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
    let bestExpectedImpact: Int?
    let secondBestCardName: String?
    let secondBestExpectedImpact: Int?
    let lostExpectedPoints: Int?
    let lostAgainstSecondBestPoints: Int?
    let valueLossTitle: String?
    let decisionQualityTitle: String?
    let selectedRank: Int?
    let selectedImpact: Int?
    let selectedImpactDetail: String?
    let selectedProjectedTeamPoints: Int?
    let selectedSimulationSummary: String?
    let selectedSimulationTeamResult: String?
    let selectedSimulationTrickPoints: Int?
    let tacticalReasonTitle: String?
    let tacticalReasonDetail: String?
    let tacticalReasonIconName: String?
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
        let secondBest = selectedOption == nil ? nil : scenario.secondBestOption
        let lost = selectedOption.flatMap { selected in
            best.map { max(0, $0.expectedImpact - selected.expectedImpact) }
        }
        let lostAgainstSecondBest = selectedOption.flatMap { selected in
            secondBest.map { max(0, $0.expectedImpact - selected.expectedImpact) }
        }
        let valueLossTitle = lost.map { WhatToPlayStatsAnalyzer.valueLossTitle(for: WhatToPlayStatsAnalyzer.valueLossSeverity(for: $0)) }
        let decisionQualityTitle = selectedOption.flatMap { selected in
            lost.map {
                WhatToPlayDecisionQuality.classify(
                    isExpertChoice: selected.isExpertChoice,
                    lostExpectedPoints: $0
                ).title
            }
        }
        let tacticalReason = selectedOption.flatMap(tacticalReason(for:))
        let selectedSimulationDisplay = selectedOption.map { WhatToPlaySimulationFormatter.display(for: $0.simulation) }
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
            bestExpectedImpact: best?.expectedImpact,
            secondBestCardName: secondBest?.card.accessibilityName,
            secondBestExpectedImpact: secondBest?.expectedImpact,
            lostExpectedPoints: lost,
            lostAgainstSecondBestPoints: lostAgainstSecondBest,
            valueLossTitle: valueLossTitle,
            decisionQualityTitle: decisionQualityTitle,
            selectedRank: selectedOption?.rank,
            selectedImpact: selectedOption?.expectedImpact,
            selectedImpactDetail: selectedOption.map { WhatToPlayImpactFormatter.detail(for: $0.impactBreakdown) },
            selectedProjectedTeamPoints: selectedOption?.projectedTeamPoints,
            selectedSimulationSummary: selectedSimulationDisplay?.summary,
            selectedSimulationTeamResult: selectedSimulationDisplay?.teamResult,
            selectedSimulationTrickPoints: selectedSimulationDisplay?.trickPoints,
            tacticalReasonTitle: tacticalReason?.title,
            tacticalReasonDetail: tacticalReason?.detail,
            tacticalReasonIconName: tacticalReason?.iconName,
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
            if let bestExpectedImpact = content.bestExpectedImpact {
                lines.append("\("أثر الأفضل".localized): \(impactText(bestExpectedImpact))")
            }
            if let secondBestCardName = content.secondBestCardName {
                lines.append("\("ثاني أفضل".localized): \(secondBestCardName)")
            }
            if let secondBestExpectedImpact = content.secondBestExpectedImpact {
                lines.append("\("أثر ثاني أفضل".localized): \(impactText(secondBestExpectedImpact))")
            }
            if let selectedRank = content.selectedRank {
                lines.append("\("ترتيب اختياري".localized): \(selectedRank)")
            }
            if let lostExpectedPoints = content.lostExpectedPoints {
                lines.append("\("نقاط متوقعة ضائعة".localized): \(lostExpectedPoints)")
            }
            if let valueLossTitle = content.valueLossTitle {
                lines.append("\("شدة خسارة القيمة".localized): \(valueLossTitle)")
            }
            if let decisionQualityTitle = content.decisionQualityTitle {
                lines.append("\("تقييم القرار".localized): \(decisionQualityTitle)")
            }
            if let lostAgainstSecondBestPoints = content.lostAgainstSecondBestPoints {
                lines.append("\("فارق عن ثاني أفضل".localized): \(lostAgainstSecondBestPoints)")
            }
            if let selectedImpact = content.selectedImpact {
                lines.append("\("الأثر المتوقع".localized): \(impactText(selectedImpact))")
            }
            if let selectedImpactDetail = content.selectedImpactDetail {
                lines.append("\("تفصيل الأثر".localized): \(selectedImpactDetail)")
            }
            if let selectedProjectedTeamPoints = content.selectedProjectedTeamPoints {
                lines.append("\("نقاط فريقك بعد المحاكاة".localized): \(selectedProjectedTeamPoints)")
            }
            if let selectedSimulationSummary = content.selectedSimulationSummary {
                lines.append("\("نتيجة المحاكاة".localized): \(selectedSimulationSummary)")
            }
            if let selectedSimulationTeamResult = content.selectedSimulationTeamResult {
                lines.append("\("اتجاه الأكلة".localized): \(selectedSimulationTeamResult)")
            }
            if let selectedSimulationTrickPoints = content.selectedSimulationTrickPoints {
                lines.append("\("نقاط الأكلة".localized): \(selectedSimulationTrickPoints)")
            }
            if let tacticalReasonTitle = content.tacticalReasonTitle {
                lines.append("\("سبب تكتيكي".localized): \(tacticalReasonTitle)")
            }
            if let tacticalReasonDetail = content.tacticalReasonDetail {
                lines.append(tacticalReasonDetail)
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

    private static func tacticalReason(for option: WhatToPlayOption) -> WhatToPlayShareTacticalReason? {
        guard option.expectedImpact < 0 else { return nil }
        let breakdown = option.impactBreakdown

        if breakdown.completesTrick,
           breakdown.winsForPlayerTeam == false,
           breakdown.trickPointsSwing < 0 {
            return WhatToPlayShareTacticalReason(
                title: "تغلق الأكلة للخصم".localized,
                detail: "اختيارك أضاف نقاطًا لأكلة انتهت للفريق الخصم. راجع هل كان يمكن تقليل الخسارة بدل تغذية الأكلة.".localized,
                iconName: "flag.slash.fill"
            )
        }

        if !breakdown.completesTrick,
           !breakdown.preservesLead,
           breakdown.playedCardPoints > 0,
           breakdown.immediateImpact < 0 {
            return WhatToPlayShareTacticalReason(
                title: "ترمي نقاطًا بلا حماية".localized,
                detail: "الورقة تحمل نقاطًا والأكلة لم تُحسم بعد. اسأل هل شريكك يحميها أو هل الأفضل التخلص من ورقة أرخص.".localized,
                iconName: "drop.triangle.fill"
            )
        }

        if breakdown.preservesLead, breakdown.immediateImpact < 0 {
            return WhatToPlayShareTacticalReason(
                title: "افتتاح مكلف".localized,
                detail: "بدأت الأكلة بورقة تخفض الأثر المتوقع. جرّب افتتاحًا يحفظ القوة أو يسحب الحكم بسبب واضح.".localized,
                iconName: "arrow.up.forward.circle.fill"
            )
        }

        return nil
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

    private static func impactText(_ value: Int) -> String {
        value >= 0 ? "+\(value)" : "\(value)"
    }

}

private struct WhatToPlayShareTacticalReason: Equatable {
    let title: String
    let detail: String
    let iconName: String
}
