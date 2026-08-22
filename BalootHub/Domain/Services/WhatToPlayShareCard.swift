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

    struct LegalCardLine: Equatable {
        let cardName: String
        let expectedImpact: Int?
        let projectedTeamPoints: Int?
        let expectedImprovement: Int?
        let expectedImprovementSourceTitle: String?
        let rationale: String?
        let isExpertChoice: Bool
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
    let legalCards: [LegalCardLine]
    let legalCardNames: [String]
    let blockedCards: [BlockedCardLine]
    let checklistTitle: String
    let checklistItems: [String]
    let selectedCardName: String?
    let bestCardName: String?
    let bestExpectedImpact: Int?
    let bestMoveRationale: String?
    let secondBestCardName: String?
    let secondBestExpectedImpact: Int?
    let secondBestMoveRationale: String?
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
    let nextActionExpectedImprovement: Int?
    let nextActionExpectedImprovementSourceTitle: String?
    let retryPromptTitle: String?
    let retryPromptDetail: String?
    let retryPromptRecommendedCardName: String?
    let retryPromptExpectedImprovement: Int?
    let retryPromptExpectedImprovementSourceTitle: String?
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
            let severity = WhatToPlayStatsAnalyzer.valueLossSeverity(
                lostExpectedPoints: lostExpectedPoints,
                lostProjectedTeamPoints: projectedLost ?? 0,
                lostProjectedAgainstSecondBestPoints: lostProjectedAgainstSecondBest ?? 0
            )
            return WhatToPlayStatsAnalyzer.valueLossTitle(for: severity)
        }
        let decisionQualityTitle = review?.decisionQuality?.title
        let comparisonSummary = selectedOption.map {
            WhatToPlayOptionComparison.summary(for: scenario, selectedCard: $0.card)
        }
        let nextAction = selectedOption.flatMap {
            WhatToPlayStatsAnalyzer.nextDecisionAction(for: $0, in: scenario)
        }
        let retryPrompt = selectedOption.flatMap {
            WhatToPlayStatsAnalyzer.retryPrompt(for: $0, in: scenario)
        }
        let checklist = WhatToPlayStatsAnalyzer.preDecisionChecklist(for: scenario)
        let tacticalReason = selectedOption.flatMap(tacticalReason(for:))
        let selectedSimulationDisplay = selectedOption.map { WhatToPlaySimulationFormatter.display(for: $0.simulation) }
        let sortedLegalOptions = sortedOptions(scenario.options)
        let shouldRevealOptionImpact = selectedOption != nil
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
            legalCards: sortedLegalOptions.map { option in
                let improvement = WhatToPlayOptionComparison.expectedImprovement(for: option, in: scenario)
                return WhatToPlayShareCardContent.LegalCardLine(
                    cardName: option.card.accessibilityName,
                    expectedImpact: shouldRevealOptionImpact ? option.expectedImpact : nil,
                    projectedTeamPoints: shouldRevealOptionImpact ? option.projectedTeamPoints : nil,
                    expectedImprovement: shouldRevealOptionImpact ? positiveImprovement(improvement.points) : nil,
                    expectedImprovementSourceTitle: shouldRevealOptionImpact
                        ? improvementSourceTitle(improvement: improvement.points, source: improvement.source)
                        : nil,
                    rationale: shouldRevealOptionImpact ? option.explanation : nil,
                    isExpertChoice: shouldRevealOptionImpact && option.isExpertChoice
                )
            },
            legalCardNames: sortedLegalOptions.map { $0.card.accessibilityName },
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
            bestMoveRationale: selectedOption == nil ? nil : best?.explanation,
            secondBestCardName: secondBest?.card.accessibilityName,
            secondBestExpectedImpact: secondBest?.expectedImpact,
            secondBestMoveRationale: selectedOption == nil ? nil : secondBest?.explanation,
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
            nextActionExpectedImprovement: positiveImprovement(nextAction?.expectedImprovement),
            nextActionExpectedImprovementSourceTitle: improvementSourceTitle(
                improvement: nextAction?.expectedImprovement,
                source: nextAction?.expectedImprovementSource
            ),
            retryPromptTitle: retryPrompt?.title,
            retryPromptDetail: retryPrompt?.detail,
            retryPromptRecommendedCardName: retryPrompt?.recommendedCard?.accessibilityName,
            retryPromptExpectedImprovement: positiveImprovement(retryPrompt?.expectedImprovement),
            retryPromptExpectedImprovementSourceTitle: improvementSourceTitle(
                improvement: retryPrompt?.expectedImprovement,
                source: retryPrompt?.expectedImprovementSource
            ),
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
        for legalCard in content.legalCards {
            lines.append("- \(legalCardText(legalCard))")
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
            if let bestMoveRationale = content.bestMoveRationale {
                lines.append("\("سبب أفضل ورقة".localized): \(bestMoveRationale)")
            }
            if let secondBestCardName = content.secondBestCardName {
                lines.append("\("ثاني أفضل".localized): \(secondBestCardName)")
            }
            if let secondBestExpectedImpact = content.secondBestExpectedImpact {
                lines.append("\("أثر ثاني أفضل".localized): \(impactText(secondBestExpectedImpact))")
            }
            if let secondBestMoveRationale = content.secondBestMoveRationale {
                lines.append("\("سبب ثاني أفضل".localized): \(secondBestMoveRationale)")
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
            if let nextActionExpectedImprovement = content.nextActionExpectedImprovement {
                lines.append("\("تحسن متوقع".localized): +\(nextActionExpectedImprovement)")
            }
            if let nextActionExpectedImprovementSourceTitle = content.nextActionExpectedImprovementSourceTitle {
                lines.append("\("مصدر التحسن".localized): \(nextActionExpectedImprovementSourceTitle)")
            }
            if let retryPromptTitle = content.retryPromptTitle {
                lines.append("\("تدريب الإعادة".localized): \(retryPromptTitle)")
            }
            if let retryPromptDetail = content.retryPromptDetail {
                lines.append(retryPromptDetail)
            }
            if let retryPromptRecommendedCardName = content.retryPromptRecommendedCardName {
                lines.append("\("جرّب الورقة".localized): \(retryPromptRecommendedCardName)")
            }
            if let retryPromptExpectedImprovement = content.retryPromptExpectedImprovement {
                lines.append("\("تحسن متوقع".localized): +\(retryPromptExpectedImprovement)")
            }
            if let retryPromptExpectedImprovementSourceTitle = content.retryPromptExpectedImprovementSourceTitle {
                lines.append("\("مصدر التحسن".localized): \(retryPromptExpectedImprovementSourceTitle)")
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

    static func reviewText(for item: WhatToPlayReviewItem) -> String {
        let improvement = WhatToPlayExpectedImprovementMetrics.calculate(
            lostExpectedPoints: item.lostExpectedPoints,
            lostProjectedTeamPoints: item.lostProjectedTeamPoints,
            lostProjectedAgainstSecondBestPoints: item.lostProjectedAgainstSecondBestPoints
        )
        var lines = [
            "موقف للمراجعة في وش تلعب؟".localized,
            "\("رمز الموقف".localized): \(item.scenarioCode)",
            "\("الصعوبة".localized): \(difficultyText(item.difficulty))",
            "\("اختيارك".localized): \(cardName(item.selectedCard))",
            "\("أفضل ورقة".localized): \(cardName(item.bestCard))",
            "\("نقاط متوقعة ضائعة".localized): \(item.lostExpectedPoints)",
            "\("شدة خسارة القيمة".localized): \(item.valueLossTitle)"
        ]

        if let focusKind = item.focusKind {
            lines.append("\("تركيز التدريب".localized): \(focusText(focusKind))")
        }
        lines.append(
            "\("النمط".localized): \(modeText(mode: item.gameMode, trumpSuit: item.contextTrumpSuit))"
        )
        if let secondBestCard = item.secondBestCard {
            lines.append("\("ثاني أفضل".localized): \(secondBestCard.accessibilityName)")
        }
        if item.lostProjectedTeamPoints > item.lostExpectedPoints {
            lines.append("\("نقاط محاكاة ضائعة".localized): \(item.lostProjectedTeamPoints)")
        }
        if let bestSimulationCard = item.bestSimulationCard {
            lines.append("\("أفضل محاكاة".localized): \(bestSimulationCard.accessibilityName)")
        }
        if let projectedTeamPoints = item.projectedTeamPoints,
           item.lostProjectedTeamPoints > 0 {
            lines.append("\("أفضل نتيجة محاكاة".localized): \(projectedTeamPoints + item.lostProjectedTeamPoints)")
        }
        if let secondBestSimulationCard = item.secondBestSimulationCard {
            lines.append("\("ثاني محاكاة".localized): \(secondBestSimulationCard.accessibilityName)")
        }
        if let secondBestProjectedTeamPoints = item.secondBestProjectedTeamPoints {
            lines.append("\("ثاني نتيجة محاكاة".localized): \(secondBestProjectedTeamPoints)")
        }
        if item.lostProjectedAgainstSecondBestPoints > 0 {
            lines.append("\("فاقد ثاني محاكاة".localized): \(item.lostProjectedAgainstSecondBestPoints)")
        }
        if improvement.points > 0 {
            lines.append("\("تحسن متوقع".localized): +\(improvement.points)")
            lines.append("\("مصدر التحسن".localized): \(WhatToPlayStatsAnalyzer.expectedImprovementSourceTitle(for: improvement.source))")
            if let reviewCardSourceTitle = WhatToPlayStatsAnalyzer.reviewCardSourceTitle(for: item) {
                lines.append("\("سبب ورقة المراجعة".localized): \(reviewCardSourceTitle)")
            }
        }
        if let simulationSummary = item.simulationSummary {
            lines.append("\("نتيجة المحاكاة".localized): \(simulationSummary)")
        }
        if let simulationTeamResult = item.simulationTeamResult {
            lines.append("\("اتجاه الأكلة".localized): \(simulationTeamResult)")
        }
        if let tacticalReasonTitle = item.tacticalReasonTitle {
            lines.append("\("سبب المراجعة".localized): \(tacticalReasonTitle)")
        }
        if let tacticalReasonDetail = item.tacticalReasonDetail {
            lines.append(tacticalReasonDetail)
        }

        lines.append("افتح مدرب وش تلعب واستورد رمز الموقف.".localized)
        lines.append("أعد الموقف وحاول اختيار ورقة أفضل.".localized)
        return lines.joined(separator: "\n")
    }

    static func trainingSessionReviewText(for review: WhatToPlayTrainingSessionReview) -> String {
        var lines = [
            "مراجعة جلسة وش تلعب؟".localized,
            review.title
        ]

        if let statusLine = review.statusLine {
            lines.append(statusLine)
        }

        lines.append(review.detail)
        lines.append(review.contextLine)

        if let difficulty = review.difficulty {
            lines.append("\("الصعوبة".localized): \(difficultyText(difficulty))")
        }
        if let focusKind = review.focusKind {
            lines.append("\("تركيز التدريب".localized): \(focusText(focusKind))")
        }
        if review.gameMode != nil || review.trumpSuit != nil {
            lines.append(
                "\("النمط".localized): \(modeText(mode: review.gameMode, trumpSuit: review.trumpSuit))"
            )
        }
        if let scenarioCode = review.replayScenarioCode {
            lines.append("\("رمز الموقف".localized): \(scenarioCode)")
        }
        if let seed = review.replaySeed ?? review.nextSeed {
            lines.append("\("Seed".localized): \(seed)")
        }
        if let recommendedCard = review.recommendedCard {
            lines.append("\("ورقة المراجعة".localized): \(recommendedCard.accessibilityName)")
            if let reviewCardSourceTitle = review.reviewCardSourceTitle {
                lines.append("\("سبب ورقة المراجعة".localized): \(reviewCardSourceTitle)")
            }
        }
        if let secondBestCard = review.secondBestCard {
            lines.append("\("ثاني أفضل".localized): \(secondBestCard.accessibilityName)")
        }
        if let secondBestExpectedImpact = review.secondBestExpectedImpact {
            lines.append("\("أثر ثاني أفضل".localized): \(impactText(secondBestExpectedImpact))")
        }
        if let bestSimulationCard = review.bestSimulationCard {
            lines.append("\("أفضل محاكاة".localized): \(bestSimulationCard.accessibilityName)")
        }
        if let bestProjectedTeamPoints = review.bestProjectedTeamPoints {
            lines.append("\("أفضل نتيجة محاكاة".localized): \(bestProjectedTeamPoints)")
        }
        if let secondBestSimulationCard = review.secondBestSimulationCard {
            lines.append("\("ثاني محاكاة".localized): \(secondBestSimulationCard.accessibilityName)")
        }
        if let secondBestProjectedTeamPoints = review.secondBestProjectedTeamPoints {
            lines.append("\("ثاني نتيجة محاكاة".localized): \(secondBestProjectedTeamPoints)")
        }
        if review.lostProjectedAgainstSecondBestPoints > 0 {
            lines.append("\("فاقد ثاني محاكاة".localized): \(review.lostProjectedAgainstSecondBestPoints)")
        }
        if review.expectedImprovement > 0 {
            lines.append("\("تحسن متوقع".localized): +\(review.expectedImprovement)")
            if let source = review.expectedImprovementSource {
                lines.append("\("مصدر التحسن".localized): \(WhatToPlayStatsAnalyzer.expectedImprovementSourceTitle(for: source))")
            }
        }

        lines.append("افتح مدرب وش تلعب وأكمل جلسة التدريب.".localized)
        return lines.joined(separator: "\n")
    }

    static func trainingSessionProgressText(for progress: WhatToPlayTrainingSessionProgress) -> String {
        var lines = [
            "تقدم جلسة وش تلعب؟".localized,
            progress.title,
            progress.detail
        ]

        if let nextSeedGuidance = progress.nextSeedGuidance {
            lines.append(nextSeedGuidance)
        }

        lines.append("\("المكتمل".localized): \(progress.completedAttempts) \("من".localized) \(progress.targetAttempts)")
        lines.append("\("الدقة الحالية".localized): \(progress.accuracyPercent)%")
        lines.append("\("أفضل دقة ممكنة".localized): \(progress.bestPossibleAccuracyPercent)%")
        lines.append(trainingSessionTargetText(
            title: "هدف الدقة".localized,
            isMet: progress.accuracyTargetMet
        ))
        if progress.correctAttemptsNeededForTarget > 0 {
            lines.append("\("إجابات صحيحة مطلوبة".localized): \(progress.correctAttemptsNeededForTarget)")
        }
        lines.append(trainingSessionTargetText(
            title: "إمكانية هدف الدقة".localized,
            isMet: progress.accuracyTargetReachable
        ))
        if let nextSeed = progress.nextSeed {
            lines.append("\(trainingSessionNextSeedTitle(progress.nextSeedState)): \(nextSeed)")
        }
        lines.append("\("متوسط الأثر".localized): \(impactText(progress.averageExpectedImpact))")
        lines.append("\("أثر الجلسة".localized): \(impactText(progress.totalExpectedImpact))")
        lines.append(trainingSessionTargetText(
            title: "هدف الأثر".localized,
            isMet: progress.impactTargetMet
        ))
        if progress.expectedImpactNeededForTarget > 0 {
            lines.append("\("أثر مطلوب للوصول للهدف".localized): \(impactText(progress.expectedImpactNeededForTarget))")
            if progress.expectedImpactNeededPerRemainingAttempt > 0 {
                lines.append("\("أثر مطلوب لكل موقف متبقٍ".localized): \(impactText(progress.expectedImpactNeededPerRemainingAttempt))")
            }
        }
        if progress.expectedImpactNeededForTarget > 0 {
            lines.append(trainingSessionTargetText(
                title: "ضغط الأثر".localized,
                isMet: !progress.impactRecoveryHighPressure
            ))
        }
        if let maxCostlyDecisions = progress.maxCostlyDecisions {
            lines.append("\("قرارات مكلفة".localized): \(progress.costlyDecisions)/\(maxCostlyDecisions)")
            lines.append(trainingSessionTargetText(
                title: "هدف القرارات المكلفة".localized,
                isMet: progress.costlyDecisionTargetMet
            ))
        }
        lines.append("\("تقييم الجلسة".localized): \(progress.gradeTitle) · \(progress.gradePercent)/100")
        lines.append("\("مكون الدقة".localized): \(progress.gradeAccuracyComponent)/100")
        lines.append("\("مكون الأثر".localized): \(progress.gradeImpactComponent)/100")
        lines.append(progress.gradeDetail)
        lines.append("\(progress.gradeReasonTitle): \(progress.gradeReasonDetail)")
        if let bestDecisionHighlight = progress.bestDecisionHighlight {
            lines.append("\("أفضل قرار في الجلسة".localized): \(decisionHighlightText(bestDecisionHighlight))")
        }
        if let worstDecisionHighlight = progress.worstDecisionHighlight, worstDecisionHighlight.totalLoss > 0 {
            lines.append("\("أسوأ قرار في الجلسة".localized): \(decisionHighlightText(worstDecisionHighlight))")
        }
        if let reviewItem = progress.reviewItem {
            lines.append(contentsOf: trainingSessionReviewItemLines(reviewItem))
        }
        lines.append("\("الخطوة التالية".localized): \(progress.nextStepTitle)")
        lines.append(progress.nextStepDetail)

        if progress.lostExpectedPoints > 0 {
            lines.append("\("نقاط ضائعة".localized): \(progress.lostExpectedPoints)")
        }
        if progress.lostProjectedTeamPoints > 0 {
            lines.append("\("نقاط محاكاة ضائعة".localized): \(progress.lostProjectedTeamPoints)")
        }
        if progress.lostProjectedAgainstSecondBestPoints > 0 {
            lines.append("\("فاقد ثاني محاكاة".localized): \(progress.lostProjectedAgainstSecondBestPoints)")
        }
        if progress.expectedImprovement > 0, let source = progress.expectedImprovementSource {
            lines.append("\("تحسن متوقع".localized): +\(progress.expectedImprovement)")
            lines.append("\("مصدر التحسن".localized): \(WhatToPlayStatsAnalyzer.expectedImprovementSourceTitle(for: source))")
        }

        lines.append("افتح مدرب وش تلعب وأكمل جلسة التدريب.".localized)
        return lines.joined(separator: "\n")
    }

    static func coachingTipText(for tip: WhatToPlayCoachingTip) -> String {
        var lines = [
            "نصيحة مدرب وش تلعب؟".localized,
            tip.title,
            tip.detail
        ]

        if let targetLine = tip.targetLine {
            lines.append("\("الهدف المقترح".localized): \(targetLine)")
        }

        lines.append("افتح مدرب وش تلعب وابدأ التدريب المقترح.".localized)
        return lines.joined(separator: "\n")
    }

    static func decisionPatternText(for pattern: WhatToPlayDecisionPattern) -> String {
        var lines = [
            "نمط قرارات وش تلعب؟".localized,
            pattern.title,
            pattern.detail,
            "\("محاولات مفحوصة".localized): \(pattern.inspectedAttempts)",
            "\("محاولات متأثرة".localized): \(pattern.affectedAttempts)",
            "\("نسبة التأثر".localized): \(pattern.affectedPercent)%"
        ]

        if let targetLine = pattern.targetLine {
            lines.append("\("التدريب المقترح".localized): \(targetLine)")
        }

        lines.append("افتح مدرب وش تلعب وراجع نمط قراراتك.".localized)
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

    static func legalCardText(_ legalCard: WhatToPlayShareCardContent.LegalCardLine) -> String {
        legalCardText(legalCard, includesRationale: true)
    }

    static func legalCardSummaryText(_ legalCard: WhatToPlayShareCardContent.LegalCardLine) -> String {
        legalCardText(legalCard, includesRationale: false)
    }

    private static func legalCardText(
        _ legalCard: WhatToPlayShareCardContent.LegalCardLine,
        includesRationale: Bool
    ) -> String {
        var parts = [legalCard.cardName]
        if let expectedImpact = legalCard.expectedImpact {
            parts.append("\("الأثر المتوقع".localized): \(impactText(expectedImpact))")
        }
        if let projectedTeamPoints = legalCard.projectedTeamPoints {
            parts.append("\("نقاط فريقك بعد المحاكاة".localized): \(projectedTeamPoints)")
        }
        if let expectedImprovement = legalCard.expectedImprovement {
            parts.append("\("تحسن متوقع".localized): +\(expectedImprovement)")
        }
        if let expectedImprovementSourceTitle = legalCard.expectedImprovementSourceTitle {
            parts.append("\("مصدر التحسن".localized): \(expectedImprovementSourceTitle)")
        }
        if includesRationale, let rationale = legalCard.rationale, !rationale.isEmpty {
            parts.append("\("سبب الخيار".localized): \(rationale)")
        }
        if legalCard.isExpertChoice {
            parts.append("اختيار الخبير".localized)
        }
        return parts.joined(separator: " · ")
    }

    private static func positiveImprovement(_ value: Int?) -> Int? {
        guard let value, value > 0 else { return nil }
        return value
    }

    private static func improvementSourceTitle(
        improvement: Int?,
        source: WhatToPlayExpectedImprovementSource?
    ) -> String? {
        guard positiveImprovement(improvement) != nil, let source else { return nil }
        return WhatToPlayStatsAnalyzer.expectedImprovementSourceTitle(for: source)
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
        modeText(mode: state.mode, trumpSuit: state.trumpSuit)
    }

    private static func modeText(mode: GameMode?, trumpSuit: Suit?) -> String {
        guard let mode else { return "غير محدد".localized }
        if mode == .hokum, let suit = trumpSuit {
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

    private static func cardName(_ card: PlayingCard?) -> String {
        card?.accessibilityName ?? "غير محدد".localized
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

    private static func trainingSessionNextSeedTitle(_ state: WhatToPlayTrainingSessionNextSeedState) -> String {
        switch state {
        case .retry:
            return "إعادة الموقف".localized
        case .fresh:
            return "الموقف القادم".localized
        case .complete:
            return "الجلسة مكتملة".localized
        }
    }

    private static func trainingSessionTargetText(title: String, isMet: Bool) -> String {
        "\(title): \(isMet ? "متحقق".localized : "غير متحقق".localized)"
    }

    private static func trainingSessionReviewItemLines(_ item: WhatToPlayReviewItem) -> [String] {
        var lines = [
            "\("أهم موقف للمراجعة".localized): \(item.title)",
            "\("رمز الموقف".localized): \(item.scenarioCode)",
            "\("اختيارك".localized): \(cardName(item.selectedCard))",
            "\("أفضل ورقة".localized): \(cardName(item.bestCard))",
            "\("سبب المراجعة".localized): \(item.detail)"
        ]
        if let reviewCardSourceTitle = WhatToPlayStatsAnalyzer.reviewCardSourceTitle(for: item) {
            lines.append("\("سبب ورقة المراجعة".localized): \(reviewCardSourceTitle)")
        }
        if let secondBestCard = item.secondBestCard {
            lines.append("\("ثاني أفضل".localized): \(secondBestCard.accessibilityName)")
        }
        if item.lostProjectedTeamPoints > 0 {
            lines.append("\("نقاط محاكاة ضائعة".localized): \(item.lostProjectedTeamPoints)")
        }
        if item.lostProjectedAgainstSecondBestPoints > 0 {
            lines.append("\("فاقد ثاني محاكاة".localized): \(item.lostProjectedAgainstSecondBestPoints)")
        }
        return lines
    }

    private static func decisionHighlightText(_ highlight: WhatToPlayDecisionHighlight) -> String {
        let cardName = highlight.selectedCard?.accessibilityName ?? "غير محدد".localized
        if highlight.totalLoss > 0 {
            return "\(cardName) · \("فاقد القرار".localized): \(highlight.totalLoss) · \(decisionHighlightLossSource(highlight)) · \("رمز الموقف".localized): \(highlight.scenarioCode) · \("Seed".localized): \(highlight.seed)"
        }
        return "\(cardName) · \("أثر القرار".localized): \(impactText(highlight.expectedImpact)) · \("رمز الموقف".localized): \(highlight.scenarioCode) · \("Seed".localized): \(highlight.seed)"
    }

    private static func decisionHighlightLossSource(_ highlight: WhatToPlayDecisionHighlight) -> String {
        if highlight.lostProjectedTeamPoints == highlight.totalLoss {
            return "محاكاة الجولة".localized
        }
        if highlight.lostProjectedAgainstSecondBestPoints == highlight.totalLoss {
            return "ثاني محاكاة".localized
        }
        return "القيمة المتوقعة".localized
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
            "\("مقارنة الصن والحكم".localized): \(analysis.modeComparisonTitle)",
            "\("فارق الصن والحكم".localized): \(signedScoreText(analysis.sunHokumScoreGap))",
            "\("تفسير الفارق".localized): \(sunHokumGapExplanation(for: analysis.sunHokumScoreGap))"
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
        return "\(option.title): \(option.confidencePercent)% · \("الهامش".localized) \(option.margin)\(recommended) · \(option.rationale)"
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

    private static func signedScoreText(_ value: Int) -> String {
        value > 0 ? "+\(value)" : "\(value)"
    }

    private static func sunHokumGapExplanation(for value: Int) -> String {
        if value > 0 {
            return "الفارق الموجب يعني أن الصن أعلى من أفضل حكم في هذا التحليل.".localized
        }
        if value < 0 {
            return "الفارق السالب يعني أن أفضل حكم أعلى من الصن في هذا التحليل.".localized
        }
        return "الفارق صفر، لذلك القرار قريب جدًا ويعتمد على سياق المزايدة.".localized
    }

    private static func projectSort(_ lhs: Project, _ rhs: Project) -> Bool {
        if lhs.points != rhs.points { return lhs.points > rhs.points }
        if lhs.kind.rawValue != rhs.kind.rawValue { return lhs.kind.rawValue < rhs.kind.rawValue }
        return lhs.id < rhs.id
    }
}
