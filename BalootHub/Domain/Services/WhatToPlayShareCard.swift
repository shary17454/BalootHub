import Foundation
import BalootEngine

struct WhatToPlayShareCardContent: Equatable {
    struct PlayedCardLine: Equatable {
        let playerName: String
        let cardName: String
    }

    struct BlockedCardLine: Equatable {
        let cardName: String
        let reason: String
    }

    let title: String
    let subtitle: String
    let scenarioCode: String
    let contextLine: String
    let mode: String
    let difficulty: String
    let focus: String
    let trickProgress: String
    let scoreLine: String
    let turnPlayerName: String
    let turnContextLine: String
    let legalOptionCount: Int
    let playedCardCount: Int
    let tableCards: [PlayedCardLine]
    let legalCardNames: [String]
    let blockedCards: [BlockedCardLine]
    let checklistTitle: String
    let checklistItems: [String]
    let selectedCardName: String?
    let bestCardName: String?
    let bestExpectedImpact: Int?
    let secondBestCardName: String?
    let secondBestExpectedImpact: Int?
    let bestSimulationCardName: String?
    let bestProjectedTeamPoints: Int?
    let secondBestSimulationCardName: String?
    let secondBestProjectedTeamPoints: Int?
    let lostProjectedAgainstSecondBestPoints: Int?
    let lostExpectedPoints: Int?
    let lostProjectedTeamPoints: Int?
    let lostAgainstSecondBestPoints: Int?
    let valueLossTitle: String?
    let decisionQualityTitle: String?
    let decisionQualityDetail: String?
    let bestMoveConfidenceTitle: String?
    let bestMoveConfidenceDetail: String?
    let nextActionTitle: String?
    let nextActionDetail: String?
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
        let review = selectedOption.map {
            WhatToPlayTrainer.choiceReview(in: scenario, selectedCard: $0.card)
        }
        let best = review?.bestOption
        let secondBest = review?.secondBestOption
        let bestProjected = review?.bestProjectedOption
        let lost = review?.selectedLostExpectedPoints
        let projectedLost = review?.selectedLostProjectedTeamPoints
        let lostProjectedAgainstSecondBest = selectedOption.flatMap { selected in
            review?.secondBestProjectedOption.map { max(0, $0.projectedTeamPoints - selected.projectedTeamPoints) }
        }
        let lostAgainstSecondBest = selectedOption.flatMap { selected in
            review?.secondBestOption.map { max(0, $0.expectedImpact - selected.expectedImpact) }
        }
        let valueLossTitle = lost.map { lostExpectedPoints in
            let decisiveLoss = max(lostExpectedPoints, projectedLost ?? 0)
            return WhatToPlayStatsAnalyzer.valueLossTitle(for: WhatToPlayStatsAnalyzer.valueLossSeverity(for: decisiveLoss))
        }
        let decisionQualityTitle = review?.decisionQuality?.title
        let comparisonSummary = selectedOption.map {
            WhatToPlayOptionComparison.summary(for: scenario, selectedCard: $0.card)
        }
        let checklist = WhatToPlayStatsAnalyzer.preDecisionChecklist(for: scenario)
        let tacticalReason = selectedOption.flatMap(tacticalReason(for:))
        let selectedSimulationDisplay = selectedOption.map { WhatToPlaySimulationFormatter.display(for: $0.simulation) }
        return WhatToPlayShareCardContent(
            title: "وش تلعب؟".localized,
            subtitle: selectedOption == nil
                ? "موقف تدريبي من Baloot Hub".localized
                : "مراجعة قرار من Baloot Hub".localized,
            scenarioCode: WhatToPlayScenarioCode.make(for: scenario, selectedOption: selectedOption),
            contextLine: "\("أنت تلعب".localized) \(mode)",
            mode: mode,
            difficulty: difficultyText(scenario.difficulty),
            focus: focusText(scenario.context.focusKind),
            trickProgress: "\(state.completedTricks.count + 1) \("من".localized) 8",
            scoreLine: scoreText(scenario.context),
            turnPlayerName: state.player(id: scenario.playerID)?.name ?? "أنت".localized,
            turnContextLine: turnContextText(scenario.context),
            legalOptionCount: scenario.context.legalOptionCount,
            playedCardCount: scenario.context.playedCardCount,
            tableCards: played.map { playedCard in
                WhatToPlayShareCardContent.PlayedCardLine(
                    playerName: state.player(id: playedCard.playerID)?.name ?? "لاعب".localized,
                    cardName: playedCard.card.accessibilityName
                )
            },
            legalCardNames: sortedOptions(scenario.options).map { $0.card.accessibilityName },
            blockedCards: scenario.blockedCards.map { blocked in
                WhatToPlayShareCardContent.BlockedCardLine(
                    cardName: blocked.card.accessibilityName,
                    reason: RuleExplanationFormatter.illegalMoveExplanation(
                        for: blocked.reason,
                        trumpSuit: state.trumpSuit
                    )
                )
            },
            checklistTitle: checklist.title,
            checklistItems: checklist.items,
            selectedCardName: selectedOption?.card.accessibilityName,
            bestCardName: best?.card.accessibilityName,
            bestExpectedImpact: best?.expectedImpact,
            secondBestCardName: secondBest?.card.accessibilityName,
            secondBestExpectedImpact: secondBest?.expectedImpact,
            bestSimulationCardName: bestProjected?.card.accessibilityName,
            bestProjectedTeamPoints: bestProjected?.projectedTeamPoints,
            secondBestSimulationCardName: review?.secondBestProjectedOption?.card.accessibilityName,
            secondBestProjectedTeamPoints: review?.secondBestProjectedOption?.projectedTeamPoints,
            lostProjectedAgainstSecondBestPoints: lostProjectedAgainstSecondBest,
            lostExpectedPoints: lost,
            lostProjectedTeamPoints: projectedLost,
            lostAgainstSecondBestPoints: lostAgainstSecondBest,
            valueLossTitle: valueLossTitle,
            decisionQualityTitle: decisionQualityTitle,
            decisionQualityDetail: comparisonSummary?.decisionQualityDetail,
            bestMoveConfidenceTitle: comparisonSummary?.bestMoveConfidence?.title,
            bestMoveConfidenceDetail: comparisonSummary?.bestMoveConfidence?.detail,
            nextActionTitle: comparisonSummary?.nextActionTitle,
            nextActionDetail: comparisonSummary?.nextActionDetail,
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
            "\("رمز الموقف".localized): \(content.scenarioCode)",
            "\("النمط".localized): \(content.mode)",
            "\("الصعوبة".localized): \(content.difficulty)",
            "\("تركيز التدريب".localized): \(content.focus)",
            "\("الأكلة".localized): \(content.trickProgress)",
            "\("النقاط".localized): \(content.scoreLine)",
            "\("الدور".localized): \(content.turnPlayerName)",
            content.turnContextLine,
            "\("خيارات".localized): \(content.legalOptionCount) · \("على الطاولة".localized): \(content.playedCardCount)"
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

        if !content.blockedCards.isEmpty {
            lines.append("\("الأوراق الممنوعة".localized):")
            for blockedCard in content.blockedCards {
                lines.append("- \(blockedCard.cardName): \(blockedCard.reason)")
            }
        }

        lines.append(content.checklistTitle)
        for item in content.checklistItems {
            lines.append("- \(item)")
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
            if let bestSimulationCardName = content.bestSimulationCardName {
                lines.append("\("أفضل محاكاة".localized): \(bestSimulationCardName)")
            }
            if let bestProjectedTeamPoints = content.bestProjectedTeamPoints {
                lines.append("\("أفضل نتيجة محاكاة".localized): \(bestProjectedTeamPoints)")
            }
            if let secondBestSimulationCardName = content.secondBestSimulationCardName {
                lines.append("\("ثاني محاكاة".localized): \(secondBestSimulationCardName)")
            }
            if let secondBestProjectedTeamPoints = content.secondBestProjectedTeamPoints {
                lines.append("\("ثاني نتيجة محاكاة".localized): \(secondBestProjectedTeamPoints)")
            }
            if let lostProjectedAgainstSecondBestPoints = content.lostProjectedAgainstSecondBestPoints {
                lines.append("\("فاقد ثاني محاكاة".localized): \(lostProjectedAgainstSecondBestPoints)")
            }
            if let selectedRank = content.selectedRank {
                lines.append("\("ترتيب اختياري".localized): \(selectedRank)")
            }
            if let lostExpectedPoints = content.lostExpectedPoints {
                lines.append("\("نقاط متوقعة ضائعة".localized): \(lostExpectedPoints)")
            }
            if let lostProjectedTeamPoints = content.lostProjectedTeamPoints {
                lines.append("\("نقاط محاكاة ضائعة".localized): \(lostProjectedTeamPoints)")
            }
            if let valueLossTitle = content.valueLossTitle {
                lines.append("\("شدة خسارة القيمة".localized): \(valueLossTitle)")
            }
            appendDecisionQualityLines(to: &lines, content: content)
            if let bestMoveConfidenceTitle = content.bestMoveConfidenceTitle {
                lines.append("\("ثقة أفضل ورقة".localized): \(bestMoveConfidenceTitle)")
            }
            if let bestMoveConfidenceDetail = content.bestMoveConfidenceDetail {
                lines.append(bestMoveConfidenceDetail)
            }
            if let nextActionTitle = content.nextActionTitle {
                lines.append("\("الإجراء التالي".localized): \(nextActionTitle)")
            }
            if let nextActionDetail = content.nextActionDetail {
                lines.append(nextActionDetail)
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

    private static func appendDecisionQualityLines(
        to lines: inout [String],
        content: WhatToPlayShareCardContent
    ) {
        if let decisionQualityTitle = content.decisionQualityTitle {
            lines.append("\("تقييم القرار".localized): \(decisionQualityTitle)")
        }
        if let decisionQualityDetail = content.decisionQualityDetail {
            lines.append(decisionQualityDetail)
        }
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
        let metrics = WhatToPlayTacticalReviewReasonMetrics.classify(
            expectedImpact: option.expectedImpact,
            impactBreakdown: option.impactBreakdown
        )

        switch metrics.category {
        case .opponentTrickClosure:
            return WhatToPlayShareTacticalReason(
                title: "تغلق الأكلة للخصم".localized,
                detail: "اختيارك أضاف نقاطًا لأكلة انتهت للفريق الخصم. راجع هل كان يمكن تقليل الخسارة بدل تغذية الأكلة.".localized,
                iconName: "flag.slash.fill"
            )
        case .unprotectedPointDump:
            return WhatToPlayShareTacticalReason(
                title: "ترمي نقاطًا بلا حماية".localized,
                detail: "الورقة تحمل نقاطًا والأكلة لم تُحسم بعد. اسأل هل شريكك يحميها أو هل الأفضل التخلص من ورقة أرخص.".localized,
                iconName: "drop.triangle.fill"
            )
        case .costlyOpeningLead:
            return WhatToPlayShareTacticalReason(
                title: "افتتاح مكلف".localized,
                detail: "بدأت الأكلة بورقة تخفض الأثر المتوقع. جرّب افتتاحًا يحفظ القوة أو يسحب الحكم بسبب واضح.".localized,
                iconName: "arrow.up.forward.circle.fill"
            )
        case nil:
            return nil
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
        case .expert:
            return "خبير".localized
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

    private static func scoreText(_ context: WhatToPlayScenarioContext) -> String {
        let margin = context.playerTeamPointMargin
        let marginPrefix = margin > 0 ? "+" : ""
        return "\("فريقنا".localized) \(context.playerTeamTrickPoints) · \("الخصم".localized) \(context.opponentTeamTrickPoints) · \(marginPrefix)\(margin)"
    }

    private static func turnContextText(_ context: WhatToPlayScenarioContext) -> String {
        if context.isLeading {
            return "أنت تفتتح الأكلة".localized
        }
        if let requiredSuit = context.requiredSuit {
            return "\("اللون المطلوب".localized): \(requiredSuit.arabicName)"
        }
        return "الأوراق على الطاولة".localized
    }

}

private struct WhatToPlayShareTacticalReason: Equatable {
    let title: String
    let detail: String
    let iconName: String
}

enum HandAnalysisShareSummary {
    static func text(for analysis: HandAnalysis) -> String {
        var lines = [
            "ملخص حلّل يدي".localized,
            "\("اليد".localized): \(analysis.hand.map(\.accessibilityName).joined(separator: "، "))",
            "\("التوصية".localized): \(recommendationText(analysis.recommendedBid))",
            "\("خلاصة القرار".localized): \(decisionGradeText(analysis.decisionGrade))",
            "\("قوة اليد".localized): \(analysis.strengthPercent)%",
            "\("احتمال الشراء".localized): \(analysis.bidConfidencePercent)%",
            "\("الثقة".localized): \(confidenceText(analysis.confidence))",
            "\("احتمال الصن".localized): \(analysis.sunConfidencePercent)% · \(analysis.evaluation.sunScore)",
            "\("احتمال الحكم".localized): \(analysis.hokumConfidencePercent)%",
            "\("مقارنة الصن والحكم".localized): \(analysis.modeComparisonTitle)"
        ]

        if let best = analysis.evaluation.bestHokum {
            lines.append("\("أفضل حكم".localized): \(best.suit.spokenName) · \(best.score)")
        }

        if !analysis.bidOptions.isEmpty {
            lines.append("\("ترتيب خيارات المزايدة".localized):")
            for option in analysis.bidOptions.prefix(4) {
                lines.append("- \(bidOptionText(option))")
            }
        }

        lines.append(analysis.modeComparisonDetail)

        if analysis.projects.isEmpty {
            lines.append("\("المشاريع".localized): \("لا يوجد".localized)")
        } else {
            lines.append("\("المشاريع".localized): \(analysis.totalProjectPoints)")
            for project in analysis.projects.sorted(by: projectSort) {
                let cards = project.cards.map(\.accessibilityName).joined(separator: "، ")
                lines.append("- \(project.kind.arabicName) +\(project.points): \(cards)")
            }
        }

        lines.append("\("نقاط القوة".localized):")
        appendItems(analysis.strengths, to: &lines)

        lines.append("\("نقاط الضعف".localized):")
        appendItems(analysis.weaknesses, to: &lines)

        lines.append("\("الخطوة التالية".localized): \(analysis.nextActionTitle)")
        lines.append(analysis.nextActionDetail)
        lines.append("\("النصيحة التكتيكية".localized): \(analysis.tacticalAdvice)")
        lines.append("Baloot Hub")

        return lines.joined(separator: "\n")
    }

    private static func appendItems(_ items: [String], to lines: inout [String]) {
        if items.isEmpty {
            lines.append("- \("لا يوجد".localized)")
        } else {
            for item in items {
                lines.append("- \(item)")
            }
        }
    }

    private static func bidOptionText(_ option: HandAnalysis.BidOption) -> String {
        let recommended = option.isRecommended ? " · \("موصى به".localized)" : ""
        return "\(option.title): \(option.confidencePercent)% · \("الهامش".localized) \(option.margin)\(recommended)"
    }

    private static func recommendationText(_ bid: Bid) -> String {
        switch bid {
        case .pass:
            return "بس".localized
        case .sun:
            return "اشترِ صن".localized
        case .hokum(let suit):
            return "\("اشترِ حكم".localized) \(suit.spokenName)"
        }
    }

    private static func confidenceText(_ confidence: HandAnalysis.Confidence) -> String {
        switch confidence {
        case .low:
            return "منخفضة".localized
        case .medium:
            return "متوسطة".localized
        case .high:
            return "عالية".localized
        }
    }

    private static func decisionGradeText(_ grade: HandAnalysis.DecisionGrade) -> String {
        switch grade {
        case .strongBid:
            return "شراء قوي".localized
        case .cautiousBid:
            return "شراء حذر".localized
        case .closePass:
            return "تمرير قريب".localized
        case .clearPass:
            return "تمرير واضح".localized
        }
    }

    private static func projectSort(_ lhs: Project, _ rhs: Project) -> Bool {
        if lhs.points != rhs.points { return lhs.points > rhs.points }
        if lhs.kind.rawValue != rhs.kind.rawValue { return lhs.kind.rawValue < rhs.kind.rawValue }
        return lhs.id < rhs.id
    }
}
