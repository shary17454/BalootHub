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
    let coachingSummary: String
    let rationale: String
    let isSelected: Bool
    let isExpertChoice: Bool
    let isBestSimulationResult: Bool

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
    let bestSimulationCard: PlayingCard?
    let bestSimulationExpectedImpact: Int?
    let bestSimulationProjectedTeamPoints: Int?
    let expertToBestSimulationGap: Int?
    let selectedCard: PlayingCard?
    let selectedExpectedImpact: Int?
    let selectedProjectedTeamPoints: Int?
    let selectedLostExpectedPoints: Int?
    let selectedLostProjectedTeamPoints: Int?
    let decisionQuality: WhatToPlayDecisionQuality?
    let decisionQualityDetail: String?
    let bestMoveConfidence: WhatToPlayBestMoveConfidence?
    let nextActionTitle: String?
    let nextActionDetail: String?

    var hasSecondBest: Bool {
        secondBestCard != nil
    }
}

extension WhatToPlayBestMoveConfidence {
    var title: String {
        switch self {
        case .tied:
            "أفضلية متعادلة".localized
        case .narrow:
            "أفضلية ضيقة".localized
        case .clear:
            "أفضلية واضحة".localized
        case .decisive:
            "أفضلية حاسمة".localized
        }
    }

    var detail: String {
        switch self {
        case .tied:
            "الخياران الأول والثاني متقاربان جدًا؛ راجع السبب التكتيكي قبل اعتبار أحدهما خطأ.".localized
        case .narrow:
            "ثاني أفضل قريب من اختيار الخبير؛ ركز على الفارق الصغير في الأثر المتوقع.".localized
        case .clear:
            "أفضل ورقة تتقدم بفارق واضح، والبديل يحتاج سببًا تكتيكيًا قويًا.".localized
        case .decisive:
            "اختيار الخبير يتقدم بفارق كبير؛ أعد قراءة الموقف قبل اختيار بديل.".localized
        }
    }

    var systemImage: String {
        switch self {
        case .tied:
            "equal.circle.fill"
        case .narrow:
            "arrow.left.and.right.circle.fill"
        case .clear:
            "checkmark.seal.fill"
        case .decisive:
            "exclamationmark.triangle.fill"
        }
    }
}

extension WhatToPlayDecisionQuality {
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

    var detail: String {
        switch self {
        case .expertMatch:
            "اختيارك يطابق أعلى تحليل؛ ركز على تثبيت سبب القرار قبل الموقف التالي.".localized
        case .close:
            "اختيارك قريب من الأفضل، لكن الفارق البسيط يتراكم مع تكرار المواقف.".localized
        case .acceptable:
            "القرار قابل للدفاع عنه، لكنه يترك قيمة واضحة مقارنة بخيار الخبير.".localized
        case .costly:
            "هذا القرار يكلّف نقاطًا متوقعة أو نتيجة محاكاة مهمة؛ أعد الموقف قبل المتابعة.".localized
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

extension WhatToPlayOptionTacticalTag {
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
            "يرفع المخاطرة".localized
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
        let review = WhatToPlayTrainer.choiceReview(in: scenario, selectedCard: selectedCard)
        let action = WhatToPlayTrainer.nextActionRecommendation(from: review).map(nextAction)

        return WhatToPlayOptionComparisonSummary(
            bestCard: review.bestOption?.card,
            bestExpectedImpact: review.bestOption?.expectedImpact,
            bestProjectedTeamPoints: review.bestOption?.projectedTeamPoints,
            secondBestCard: review.secondBestOption?.card,
            secondBestExpectedImpact: review.secondBestOption?.expectedImpact,
            secondBestProjectedTeamPoints: review.secondBestOption?.projectedTeamPoints,
            bestToSecondGap: review.bestToSecondExpectedImpactGap,
            bestSimulationCard: review.bestProjectedOption?.card,
            bestSimulationExpectedImpact: review.bestProjectedOption?.expectedImpact,
            bestSimulationProjectedTeamPoints: review.bestProjectedOption?.projectedTeamPoints,
            expertToBestSimulationGap: review.expertToBestProjectedTeamPointsGap,
            selectedCard: review.selectedOption?.card,
            selectedExpectedImpact: review.selectedOption?.expectedImpact,
            selectedProjectedTeamPoints: review.selectedOption?.projectedTeamPoints,
            selectedLostExpectedPoints: review.selectedLostExpectedPoints,
            selectedLostProjectedTeamPoints: review.selectedLostProjectedTeamPoints,
            decisionQuality: review.decisionQuality,
            decisionQualityDetail: review.decisionQuality?.detail,
            bestMoveConfidence: review.bestMoveConfidence,
            nextActionTitle: action?.title,
            nextActionDetail: action?.detail
        )
    }

    static func rows(for scenario: WhatToPlayScenario, selectedCard: PlayingCard) -> [WhatToPlayOptionComparisonRow] {
        WhatToPlayTrainer.optionReviews(in: scenario)
            .map { review in
                let option = review.option
                let simulationDisplay = WhatToPlaySimulationFormatter.display(for: option.simulation)
                return WhatToPlayOptionComparisonRow(
                    card: option.card,
                    rank: option.rank,
                    expectedImpact: option.expectedImpact,
                    projectedTeamPoints: option.projectedTeamPoints,
                    impactBreakdown: option.impactBreakdown,
                    impactDetail: WhatToPlayImpactFormatter.detail(for: option.impactBreakdown),
                    lostExpectedPoints: review.lostExpectedPoints,
                    lostProjectedTeamPoints: review.lostProjectedTeamPoints,
                    outcome: option.outcome,
                    outcomeReason: option.outcomeReason,
                    simulationSummary: simulationDisplay.summary,
                    simulationTeamResult: simulationDisplay.teamResult,
                    simulationTrickPoints: simulationDisplay.trickPoints,
                    tacticalTag: review.tacticalTag,
                    tacticalSummary: tacticalSummary(
                        for: option,
                        metrics: review.tacticalSummaryMetrics
                    ),
                    coachingSummary: coachingSummary(
                        for: option,
                        impactDetail: WhatToPlayImpactFormatter.detail(for: option.impactBreakdown),
                        simulationDisplay: simulationDisplay
                    ),
                    rationale: option.explanation,
                    isSelected: option.card == selectedCard,
                    isExpertChoice: option.isExpertChoice,
                    isBestSimulationResult: review.isBestProjectedResult
                )
            }
    }

    static func bestSimulationOption(_ options: [WhatToPlayOption]) -> WhatToPlayOption? {
        WhatToPlayTrainer.projectedOptions(in: options).first
    }

    private static func nextAction(
        recommendation: WhatToPlayNextActionRecommendation
    ) -> (title: String, detail: String) {
        switch recommendation.kind {
        case .reviewExpertSimulation:
            return (
                "راجع المحاكاة".localized,
                "\("اختيارك يطابق الخبير في الأكلة الحالية، لكن المحاكاة الكاملة تفضّل مراجعة مسار الجولة.".localized) \("نقاط محاكاة ضائعة".localized): \(recommendation.lostProjectedTeamPoints). \("أفضل نتيجة محاكاة".localized): \(recommendation.bestProjectedOption.card.accessibilityName)."
            )
        case .reinforceRead:
            return (
                "ثبّت القراءة".localized,
                "\("اختيارك يطابق أعلى تحليل؛ ركز على تثبيت سبب القرار قبل الموقف التالي.".localized) \("أفضل ورقة".localized): \(recommendation.selectedOption.card.accessibilityName)."
            )
        case .reviewSimulation:
            return (
                "راجع المحاكاة".localized,
                "\("قرارك يخسر بعد استكمال الجولة؛ راجع Replay كامل قبل لعب موقف جديد.".localized) \("نقاط محاكاة ضائعة".localized): \(recommendation.lostProjectedTeamPoints). \("أفضل نتيجة محاكاة".localized): \(recommendation.bestProjectedOption.card.accessibilityName)."
            )
        case .reviewSmallGap:
            let secondText = recommendation.secondBestOption.map { " \("ثاني أفضل".localized): \($0.card.accessibilityName)." } ?? ""
            return (
                "راجع الفرق الصغير".localized,
                "\("قارن الفرق بين اختيارك وأفضل ورقة؛ هذا النوع من الفوارق الصغيرة يتراكم.".localized) \("الفارق عن اختيار الخبير".localized): \(recommendation.lostExpectedPoints). \("أفضل ورقة".localized): \(recommendation.bestOption.card.accessibilityName).\(secondText)"
            )
        case .compareBeforePlay:
            return (
                "قارن قبل اللعب".localized,
                "\("قبل الموقف التالي، احذف الخيارات الضعيفة ثم قارن اختيارك بأفضل ورقة وثاني أفضل ورقة.".localized) \("النقاط الضائعة".localized): \(recommendation.lostExpectedPoints). \("أفضل ورقة".localized): \(recommendation.bestOption.card.accessibilityName)."
            )
        case .replayScenario:
            return (
                "أعد الموقف".localized,
                "\(WhatToPlayDecisionQuality.costly.detail) \("النقاط الضائعة".localized): \(recommendation.lostExpectedPoints). \("أفضل ورقة".localized): \(recommendation.bestOption.card.accessibilityName)."
            )
        }
    }

    private static func tacticalSummary(
        for option: WhatToPlayOption,
        metrics: WhatToPlayOptionTacticalSummaryMetrics
    ) -> String {
        switch metrics.category {
        case .expertPick:
            return "هذه أعلى ورقة حسب تحليل الخبير لهذا الموقف.".localized
        case .projectedLoss:
            return "\("هذا الخيار يخسر بعد استكمال الجولة".localized): \(metrics.decisiveLoss). \("راجع Replay قبل اعتباره بديلًا قريبًا.".localized)"
        case .noLossCloseAlternative:
            return "قريب جدًا من اختيار الخبير ولا يخسر أثرًا متوقعًا.".localized
        case .smallLossAlternative:
            return "\("فرق بسيط عن الأفضل".localized): \(metrics.decisiveLoss). \("مقبول إذا كان هدفك تقليل المخاطرة.".localized)"
        case .negativeExpectedImpact:
            return "\("هذا الخيار قد يكلّف فريقك نقاطًا متوقعة".localized): \(abs(option.expectedImpact))."
        case .winsNowWithLowerValue:
            return "\("يربح الأكلة غالبًا، لكنه أقل من أفضل خيار بفارق".localized) \(metrics.decisiveLoss)."
        case .openTrickLoss:
            return "\("يبقي الأكلة مفتوحة ويخسر عن الأفضل".localized): \(metrics.decisiveLoss)."
        }
    }

    private static func coachingSummary(
        for option: WhatToPlayOption,
        impactDetail: String,
        simulationDisplay: WhatToPlaySimulationDisplay
    ) -> String {
        var parts = [
            "\("السبب التكتيكي".localized): \(option.outcomeReason.localized)",
            "\("أثر القرار".localized): \(impactDetail)",
            "\("نتيجة المحاكاة".localized): \(simulationDisplay.summary)"
        ]
        if let teamResult = simulationDisplay.teamResult {
            parts.append("\("اتجاه الأكلة".localized): \(teamResult)")
        }
        if let trickPoints = simulationDisplay.trickPoints {
            parts.append("\("نقاط الأكلة".localized): \(trickPoints)")
        }
        return parts.joined(separator: " · ")
    }
}

enum WhatToPlayImpactFormatter {
    static func accessibilityValue(_ value: Int) -> String {
        if value > 0 { return "+\(value)" }
        return "\(value)"
    }

    static func detail(for breakdown: WhatToPlayOptionImpactBreakdown) -> String {
        let metrics = WhatToPlayOptionImpactDetailMetrics.classify(breakdown: breakdown)

        switch metrics.category {
        case .completedTrick:
            let owner = (breakdown.winsForPlayerTeam ?? false) ? "لفريقك".localized : "للخصم".localized
            return "\("نقاط الأكلة".localized): \(abs(breakdown.trickPointsSwing)) · \(owner)"
        case .preservedLead:
            return "\("نقاط الورقة".localized): \(breakdown.playedCardPoints) · \("أثر افتتاحي".localized): \(breakdown.immediateImpact)"
        case .openTrick:
            return "\("نقاط الورقة".localized): \(breakdown.playedCardPoints) · \("لا تحسم الأكلة الآن".localized)"
        }
    }
}
