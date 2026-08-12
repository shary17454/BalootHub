import Foundation
import BalootEngine

struct WhatToPlayOptionComparisonRow: Identifiable, Equatable {
    let card: PlayingCard
    let rank: Int
    let expectedImpact: Int
    let projectedTeamPoints: Int
    let impactBreakdown: WhatToPlayOptionImpactBreakdown
    let impactDetail: String
    let lostExpectedPoints: Int
    let lostProjectedTeamPoints: Int
    let outcome: WhatToPlayOptionOutcome
    let outcomeReason: String
    let simulationSummary: String
    let simulationTeamResult: String?
    let simulationTrickPoints: Int?
    let tacticalTag: WhatToPlayOptionTacticalTag
    let tacticalSummary: String
    let rationale: String
    let isSelected: Bool
    let isExpertChoice: Bool

    var id: PlayingCard { card }
}

struct WhatToPlayOptionComparisonSummary: Equatable {
    let bestCard: PlayingCard?
    let bestExpectedImpact: Int?
    let bestProjectedTeamPoints: Int?
    let secondBestCard: PlayingCard?
    let secondBestExpectedImpact: Int?
    let secondBestProjectedTeamPoints: Int?
    let bestToSecondGap: Int?
    let selectedCard: PlayingCard?
    let selectedExpectedImpact: Int?
    let selectedProjectedTeamPoints: Int?
    let selectedLostExpectedPoints: Int?
    let selectedLostProjectedTeamPoints: Int?
    let decisionQuality: WhatToPlayDecisionQuality?
    let nextActionTitle: String?
    let nextActionDetail: String?

    var hasSecondBest: Bool {
        secondBestCard != nil
    }
}

enum WhatToPlayDecisionQuality: Equatable {
    case expertMatch
    case close
    case acceptable
    case costly

    static func classify(
        isExpertChoice: Bool,
        lostExpectedPoints: Int,
        lostProjectedTeamPoints: Int = 0
    ) -> WhatToPlayDecisionQuality {
        let decisiveLoss = max(lostExpectedPoints, lostProjectedTeamPoints)
        if isExpertChoice || decisiveLoss == 0 { return .expertMatch }
        if decisiveLoss <= 2 { return .close }
        if decisiveLoss <= 8 { return .acceptable }
        return .costly
    }

    var title: String {
        switch self {
        case .expertMatch:
            "مطابق للخبير".localized
        case .close:
            "قريب من الأفضل".localized
        case .acceptable:
            "قرار مقبول".localized
        case .costly:
            "قرار مكلف".localized
        }
    }

    var systemImage: String {
        switch self {
        case .expertMatch:
            "checkmark.seal.fill"
        case .close:
            "equal.circle.fill"
        case .acceptable:
            "hand.thumbsup.fill"
        case .costly:
            "exclamationmark.triangle.fill"
        }
    }
}

enum WhatToPlayOptionTacticalTag: Equatable {
    case expertPick
    case closeAlternative
    case winsNow
    case holdsPosition
    case opensRisk
    case costly

    var title: String {
        switch self {
        case .expertPick:
            "اختيار الخبير".localized
        case .closeAlternative:
            "بديل قريب".localized
        case .winsNow:
            "يحسم الأكلة".localized
        case .holdsPosition:
            "يحافظ على الوضع".localized
        case .opensRisk:
            "يفتح مخاطرة".localized
        case .costly:
            "مكلف".localized
        }
    }

    var systemImage: String {
        switch self {
        case .expertPick:
            "star.fill"
        case .closeAlternative:
            "equal.circle.fill"
        case .winsNow:
            "checkmark.seal.fill"
        case .holdsPosition:
            "shield.fill"
        case .opensRisk:
            "exclamationmark.triangle.fill"
        case .costly:
            "drop.fill"
        }
    }
}

enum WhatToPlayOptionComparison {
    static func summary(for scenario: WhatToPlayScenario) -> WhatToPlayOptionComparisonSummary {
        summary(for: scenario, selectedCard: nil)
    }

    static func summary(for scenario: WhatToPlayScenario, selectedCard: PlayingCard?) -> WhatToPlayOptionComparisonSummary {
        let sorted = sortedOptions(scenario.options)
        let best = sorted.first
        let second = sorted.dropFirst().first
        let gap = best.flatMap { bestOption in
            second.map { max(0, bestOption.expectedImpact - $0.expectedImpact) }
        }
        let selected = selectedCard.flatMap { card in
            sorted.first { $0.card == card }
        }
        let lost = selected.flatMap { selectedOption in
            best.map { max(0, $0.expectedImpact - selectedOption.expectedImpact) }
        }
        let projectedLost = selected.flatMap { selectedOption in
            best.map { max(0, $0.projectedTeamPoints - selectedOption.projectedTeamPoints) }
        }
        let action = nextAction(
            selected: selected,
            best: best,
            second: second,
            lostExpectedPoints: lost,
            lostProjectedTeamPoints: projectedLost
        )

        return WhatToPlayOptionComparisonSummary(
            bestCard: best?.card,
            bestExpectedImpact: best?.expectedImpact,
            bestProjectedTeamPoints: best?.projectedTeamPoints,
            secondBestCard: second?.card,
            secondBestExpectedImpact: second?.expectedImpact,
            secondBestProjectedTeamPoints: second?.projectedTeamPoints,
            bestToSecondGap: gap,
            selectedCard: selected?.card,
            selectedExpectedImpact: selected?.expectedImpact,
            selectedProjectedTeamPoints: selected?.projectedTeamPoints,
            selectedLostExpectedPoints: lost,
            selectedLostProjectedTeamPoints: projectedLost,
            decisionQuality: decisionQuality(
                selected: selected,
                lostExpectedPoints: lost,
                lostProjectedTeamPoints: projectedLost
            ),
            nextActionTitle: action.title,
            nextActionDetail: action.detail
        )
    }

    static func rows(for scenario: WhatToPlayScenario, selectedCard: PlayingCard) -> [WhatToPlayOptionComparisonRow] {
        let bestImpact = scenario.bestOption?.expectedImpact ?? scenario.options.map(\.expectedImpact).max() ?? 0
        let bestProjectedTeamPoints = scenario.bestOption?.projectedTeamPoints ?? scenario.options.map(\.projectedTeamPoints).max() ?? 0
        return sortedOptions(scenario.options)
            .map { option in
                let simulationDisplay = WhatToPlaySimulationFormatter.display(for: option.simulation)
                return WhatToPlayOptionComparisonRow(
                    card: option.card,
                    rank: option.rank,
                    expectedImpact: option.expectedImpact,
                    projectedTeamPoints: option.projectedTeamPoints,
                    impactBreakdown: option.impactBreakdown,
                    impactDetail: WhatToPlayImpactFormatter.detail(for: option.impactBreakdown),
                    lostExpectedPoints: max(0, bestImpact - option.expectedImpact),
                    lostProjectedTeamPoints: max(0, bestProjectedTeamPoints - option.projectedTeamPoints),
                    outcome: option.outcome,
                    outcomeReason: option.outcomeReason,
                    simulationSummary: simulationDisplay.summary,
                    simulationTeamResult: simulationDisplay.teamResult,
                    simulationTrickPoints: simulationDisplay.trickPoints,
                    tacticalTag: tacticalTag(
                        for: option,
                        bestImpact: bestImpact,
                        bestProjectedTeamPoints: bestProjectedTeamPoints
                    ),
                    tacticalSummary: tacticalSummary(
                        for: option,
                        bestImpact: bestImpact,
                        bestProjectedTeamPoints: bestProjectedTeamPoints
                    ),
                    rationale: option.explanation,
                    isSelected: option.card == selectedCard,
                    isExpertChoice: option.isExpertChoice
                )
            }
    }

    private static func sortedOptions(_ options: [WhatToPlayOption]) -> [WhatToPlayOption] {
        options.sorted { lhs, rhs in
            if lhs.rank != rhs.rank { return lhs.rank < rhs.rank }
            if lhs.card.suit.ordinal != rhs.card.suit.ordinal { return lhs.card.suit.ordinal < rhs.card.suit.ordinal }
            return lhs.card.rank.ordinal < rhs.card.rank.ordinal
        }
    }

    private static func decisionQuality(
        selected: WhatToPlayOption?,
        lostExpectedPoints: Int?,
        lostProjectedTeamPoints: Int?
    ) -> WhatToPlayDecisionQuality? {
        guard let selected, let lostExpectedPoints else { return nil }
        return WhatToPlayDecisionQuality.classify(
            isExpertChoice: selected.isExpertChoice,
            lostExpectedPoints: lostExpectedPoints,
            lostProjectedTeamPoints: lostProjectedTeamPoints ?? 0
        )
    }

    private static func nextAction(
        selected: WhatToPlayOption?,
        best: WhatToPlayOption?,
        second: WhatToPlayOption?,
        lostExpectedPoints: Int?,
        lostProjectedTeamPoints: Int?
    ) -> (title: String?, detail: String?) {
        guard let selected, let best, let lostExpectedPoints else { return (nil, nil) }
        let lostProjectedTeamPoints = lostProjectedTeamPoints ?? 0
        let decisiveLoss = max(lostExpectedPoints, lostProjectedTeamPoints)
        if selected.isExpertChoice || decisiveLoss == 0 {
            return (
                "ثبّت القراءة".localized,
                "اختيارك مطابق لتحليل الخبير. قبل الموقف التالي، سمِّ سبب قوة \(selected.card.accessibilityName) حتى تتكرر القراءة."
            )
        }
        if lostProjectedTeamPoints > lostExpectedPoints {
            return (
                "راجع المحاكاة".localized,
                "\("قرارك يخسر بعد استكمال الجولة؛ راجع Replay كامل قبل لعب موقف جديد.".localized) \("نقاط محاكاة ضائعة".localized): \(lostProjectedTeamPoints). \("أفضل ورقة".localized): \(best.card.accessibilityName)."
            )
        }
        if decisiveLoss <= 2 {
            let secondText = second.map { " وثاني أفضل كان \($0.card.accessibilityName)" } ?? ""
            return (
                "راجع الفرق الصغير".localized,
                "قرارك قريب جدًا؛ الفارق عن الأفضل \(lostExpectedPoints)\(secondText). ركز على سبب تقدّم \(best.card.accessibilityName)."
            )
        }
        if decisiveLoss <= 8 {
            return (
                "قارن قبل اللعب".localized,
                "القرار مقبول لكنه يخسر \(lostExpectedPoints) نقاط أثر متوقعة. في المرة القادمة احذف خيارين ضعيفين ثم قارن \(best.card.accessibilityName) باختيارك."
            )
        }
        return (
            "أعد الموقف".localized,
            "هذا اختيار مكلف بفارق \(lostExpectedPoints). أعد نفس الموقف وشاهد إعادة أفضل قرار قبل الانتقال لموقف جديد."
        )
    }

    private static func tacticalTag(
        for option: WhatToPlayOption,
        bestImpact: Int,
        bestProjectedTeamPoints: Int
    ) -> WhatToPlayOptionTacticalTag {
        let lost = max(0, bestImpact - option.expectedImpact)
        let projectedLost = max(0, bestProjectedTeamPoints - option.projectedTeamPoints)
        let decisiveLoss = max(lost, projectedLost)
        if option.isExpertChoice { return .expertPick }
        if decisiveLoss <= 2 { return .closeAlternative }
        if decisiveLoss >= 9 || option.expectedImpact < 0 { return .costly }
        if option.outcome == .winsTrick && option.expectedImpact > 0 { return .winsNow }
        if option.outcome == .leadsTrick || option.outcome == .developsTrick { return .opensRisk }
        return .holdsPosition
    }

    private static func tacticalSummary(
        for option: WhatToPlayOption,
        bestImpact: Int,
        bestProjectedTeamPoints: Int
    ) -> String {
        let lost = max(0, bestImpact - option.expectedImpact)
        let projectedLost = max(0, bestProjectedTeamPoints - option.projectedTeamPoints)
        let decisiveLoss = max(lost, projectedLost)
        if option.isExpertChoice {
            return "هذه أعلى ورقة حسب تحليل الخبير لهذا الموقف.".localized
        }
        if projectedLost > lost {
            return "\("هذا الخيار يخسر بعد استكمال الجولة".localized): \(projectedLost). \("راجع Replay قبل اعتباره بديلًا قريبًا.".localized)"
        }
        if decisiveLoss == 0 {
            return "قريب جدًا من اختيار الخبير ولا يخسر أثرًا متوقعًا.".localized
        }
        if decisiveLoss <= 2 {
            return "\("فرق بسيط عن الأفضل".localized): \(lost). \("مقبول إذا كان هدفك تقليل المخاطرة.".localized)"
        }
        if option.expectedImpact < 0 {
            return "\("هذا الخيار قد يكلّف فريقك نقاطًا متوقعة".localized): \(abs(option.expectedImpact))."
        }
        if option.outcome == .winsTrick {
            return "\("يربح الأكلة غالبًا، لكنه أقل من أفضل خيار بفارق".localized) \(lost)."
        }
        return "\("يبقي الأكلة مفتوحة ويخسر عن الأفضل".localized): \(lost)."
    }
}

enum WhatToPlayImpactFormatter {
    static func detail(for breakdown: WhatToPlayOptionImpactBreakdown) -> String {
        if breakdown.completesTrick {
            let owner = (breakdown.winsForPlayerTeam ?? false) ? "لفريقك".localized : "للخصم".localized
            return "\("نقاط الأكلة".localized): \(abs(breakdown.trickPointsSwing)) · \(owner)"
        }
        if breakdown.preservesLead {
            return "\("نقاط الورقة".localized): \(breakdown.playedCardPoints) · \("أثر افتتاحي".localized): \(breakdown.immediateImpact)"
        }
        return "\("نقاط الورقة".localized): \(breakdown.playedCardPoints) · \("لا تحسم الأكلة الآن".localized)"
    }
}
