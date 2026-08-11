import Foundation
import BalootEngine

struct WhatToPlayOptionComparisonRow: Identifiable, Equatable {
    let card: PlayingCard
    let rank: Int
    let expectedImpact: Int
    let impactBreakdown: WhatToPlayOptionImpactBreakdown
    let impactDetail: String
    let lostExpectedPoints: Int
    let outcome: WhatToPlayOptionOutcome
    let outcomeReason: String
    let tacticalTag: WhatToPlayOptionTacticalTag
    let tacticalSummary: String
    let rationale: String
    let isSelected: Bool
    let isExpertChoice: Bool

    var id: PlayingCard { card }
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
                    impactBreakdown: option.impactBreakdown,
                    impactDetail: WhatToPlayImpactFormatter.detail(for: option.impactBreakdown),
                    lostExpectedPoints: max(0, bestImpact - option.expectedImpact),
                    outcome: option.outcome,
                    outcomeReason: option.outcomeReason,
                    tacticalTag: tacticalTag(for: option, bestImpact: bestImpact),
                    tacticalSummary: tacticalSummary(for: option, bestImpact: bestImpact),
                    rationale: option.explanation,
                    isSelected: option.card == selectedCard,
                    isExpertChoice: option.isExpertChoice
                )
            }
    }

    private static func tacticalTag(for option: WhatToPlayOption, bestImpact: Int) -> WhatToPlayOptionTacticalTag {
        let lost = max(0, bestImpact - option.expectedImpact)
        if option.isExpertChoice { return .expertPick }
        if lost <= 2 { return .closeAlternative }
        if option.outcome == .winsTrick && option.expectedImpact > 0 { return .winsNow }
        if option.expectedImpact < 0 { return .costly }
        if option.outcome == .leadsTrick || option.outcome == .developsTrick { return .opensRisk }
        return .holdsPosition
    }

    private static func tacticalSummary(for option: WhatToPlayOption, bestImpact: Int) -> String {
        let lost = max(0, bestImpact - option.expectedImpact)
        if option.isExpertChoice {
            return "هذه أعلى ورقة حسب تحليل الخبير لهذا الموقف.".localized
        }
        if lost == 0 {
            return "قريب جدًا من اختيار الخبير ولا يخسر أثرًا متوقعًا.".localized
        }
        if lost <= 2 {
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
