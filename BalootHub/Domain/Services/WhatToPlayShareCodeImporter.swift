import BalootEngine
import Foundation

enum WhatToPlayShareCodeImportKind: Equatable {
    case prompt
    case reviewedDecision(isDuplicate: Bool)
}

enum WhatToPlayShareCodeImportStatusTone: Equatable {
    case prompt
    case savedReview
    case duplicateReview
}

struct WhatToPlayShareCodeImportResult {
    let parsed: WhatToPlayScenarioCode.Parsed
    let scenario: WhatToPlayScenario
    let selectedOption: WhatToPlayOption?
    let attempt: WhatToPlayAttempt?
    let kind: WhatToPlayShareCodeImportKind
    let canonicalScenarioCode: String
    let expectedImprovement: Int
    let expectedImprovementSource: WhatToPlayExpectedImprovementSource?

    var bestSimulationCard: PlayingCard? {
        comparisonSummary?.bestSimulationCard
    }

    var bestProjectedTeamPoints: Int? {
        comparisonSummary?.bestSimulationProjectedTeamPoints
    }

    var secondBestSimulationCard: PlayingCard? {
        comparisonSummary?.secondBestSimulationCard
    }

    var secondBestProjectedTeamPoints: Int? {
        comparisonSummary?.secondBestSimulationProjectedTeamPoints
    }

    var lostProjectedAgainstSecondBestPoints: Int {
        max(0, comparisonSummary?.selectedLostProjectedAgainstSecondBestPoints ?? 0)
    }

    var valueLossTitle: String? {
        guard selectedOption != nil else { return nil }
        let severity = WhatToPlayStatsAnalyzer.valueLossSeverity(
            lostExpectedPoints: comparisonSummary?.selectedLostExpectedPoints ?? 0,
            lostProjectedTeamPoints: comparisonSummary?.selectedLostProjectedTeamPoints ?? 0,
            lostProjectedAgainstSecondBestPoints: lostProjectedAgainstSecondBestPoints
        )
        guard severity != .none else { return nil }
        return WhatToPlayStatsAnalyzer.valueLossTitle(for: severity)
    }

    var reviewCardSourceTitle: String? {
        guard selectedOption != nil,
              expectedImprovement > 0,
              let expectedImprovementSource
        else { return nil }

        return WhatToPlayStatsAnalyzer.expectedImprovementSourceTitle(for: expectedImprovementSource)
    }

    private var comparisonSummary: WhatToPlayOptionComparisonSummary? {
        guard let selectedOption else { return nil }
        return WhatToPlayOptionComparison.summary(for: scenario, selectedCard: selectedOption.card)
    }

    var statusMessage: String {
        var lines = [
            statusTitle,
            "\("رمز الموقف".localized): \(canonicalScenarioCode)"
        ]
        lines.append(contentsOf: scenarioContextLines())
        if let selectedOption {
            lines.append(contentsOf: reviewedDecisionLines(for: selectedOption))
        }
        if let valueLossTitle {
            lines.append("\("شدة خسارة القيمة".localized): \(valueLossTitle)")
        }
        lines.append(contentsOf: expectedImprovementLines(points: expectedImprovement, source: expectedImprovementSource))
        if let reviewCardSourceTitle {
            lines.append("\("سبب ورقة المراجعة".localized): \(reviewCardSourceTitle)")
        }
        return lines.joined(separator: "\n")
    }

    private var statusTitle: String {
        switch kind {
        case .prompt:
            return "تم تحميل الموقف. اختر الورقة الأفضل.".localized
        case .reviewedDecision(let isDuplicate):
            if isDuplicate {
                return "تم تحميل مراجعة القرار. هذه المحاولة موجودة في الإحصاءات.".localized
            }
            return "تم تحميل مراجعة القرار وإضافتها للإحصاءات.".localized
        }
    }

    private func scenarioContextLines() -> [String] {
        let contextContent = WhatToPlayShareCard.content(for: scenario)
        var lines = [
            "\("النمط".localized): \(contextContent.mode)",
            "\("الصعوبة".localized): \(contextContent.difficulty)",
            "\("نوع الموقف".localized): \(contextContent.focus)",
            "\("الدور".localized): \(contextContent.turnPlayerName)",
            "\("خيارات".localized): \(contextContent.legalOptionCount) · \("على الطاولة".localized): \(contextContent.playedCardCount)",
            "\("الأوراق القانونية".localized): \(contextContent.legalCardNames.joined(separator: "، "))"
        ]
        if contextContent.isOpeningTrick {
            lines.append("أنت تفتتح الأكلة.".localized)
        } else {
            lines.append("\("الأوراق على الطاولة".localized):")
            for playedCard in contextContent.tableCards {
                lines.append("- \(playedCard.playerName): \(playedCard.cardName)")
            }
        }
        return lines
    }

    private func reviewedDecisionLines(for selectedOption: WhatToPlayOption) -> [String] {
        let comparisonSummary = WhatToPlayOptionComparison.summary(
            for: scenario,
            selectedCard: selectedOption.card
        )
        let selectedComparisonRow = WhatToPlayOptionComparison
            .rows(for: scenario, selectedCard: selectedOption.card)
            .first { $0.card == selectedOption.card }
        var lines = [
            "\("اختيارك".localized): \(selectedOption.card.accessibilityName)"
        ]
        if let bestOption = scenario.bestOption {
            lines.append("\("أفضل ورقة".localized): \(bestOption.card.accessibilityName)")
            lines.append("\("سبب أفضل ورقة".localized): \(bestOption.explanation)")
        }
        if let secondBestOption = scenario.secondBestOption,
           secondBestOption.card != scenario.bestOption?.card {
            lines.append("\("ثاني أفضل".localized): \(secondBestOption.card.accessibilityName)")
            lines.append("\("سبب ثاني أفضل".localized): \(secondBestOption.explanation)")
        }
        lines.append(contentsOf: decisionSummaryLines(comparisonSummary))
        if let selectedComparisonRow {
            lines.append(contentsOf: selectedComparisonLines(row: selectedComparisonRow, summary: comparisonSummary))
        }
        lines.append(contentsOf: simulationLines(for: selectedOption))
        lines.append(contentsOf: nextActionLines(comparisonSummary))
        if let retryPrompt = WhatToPlayStatsAnalyzer.retryPrompt(for: selectedOption, in: scenario) {
            lines.append(contentsOf: retryPromptLines(retryPrompt))
        }
        return lines
    }

    private func decisionSummaryLines(_ summary: WhatToPlayOptionComparisonSummary) -> [String] {
        var lines: [String] = []
        if let decisionQuality = summary.decisionQuality {
            lines.append("\("تقييم القرار".localized): \(decisionQuality.title)")
        }
        if let decisionQualityDetail = summary.decisionQualityDetail {
            lines.append(decisionQualityDetail)
        }
        if let bestMoveConfidence = summary.bestMoveConfidence {
            lines.append("\("ثقة أفضل ورقة".localized): \(bestMoveConfidence.title)")
            lines.append(bestMoveConfidence.detail)
        }
        return lines
    }

    private func selectedComparisonLines(
        row: WhatToPlayOptionComparisonRow,
        summary: WhatToPlayOptionComparisonSummary
    ) -> [String] {
        var lines = [
            "\("الترتيب".localized): \(row.rank) \("من".localized) \(scenario.options.count)",
            "\("الأثر المتوقع".localized): \(impactText(row.expectedImpact))",
            "\("أثر القرار".localized): \(row.impactDetail)"
        ]
        if let selectedLostExpectedPoints = summary.selectedLostExpectedPoints,
           selectedLostExpectedPoints > 0 {
            lines.append("\("النقاط الضائعة".localized): \(selectedLostExpectedPoints)")
        }
        lines.append("\("نقاط فريقك بعد المحاكاة".localized): \(row.projectedTeamPoints)")
        if let bestSimulationCard = summary.bestSimulationCard {
            lines.append("\("أفضل محاكاة".localized): \(bestSimulationCard.accessibilityName)")
        }
        if let bestSimulationProjectedTeamPoints = summary.bestSimulationProjectedTeamPoints {
            lines.append("\("أفضل نتيجة محاكاة".localized): \(bestSimulationProjectedTeamPoints)")
        }
        if let selectedLostProjectedTeamPoints = summary.selectedLostProjectedTeamPoints,
           selectedLostProjectedTeamPoints > 0 {
            lines.append("\("نقاط محاكاة ضائعة".localized): \(selectedLostProjectedTeamPoints)")
        }
        if let secondBestSimulationCard = summary.secondBestSimulationCard,
           secondBestSimulationCard != summary.bestSimulationCard {
            lines.append("\("ثاني محاكاة".localized): \(secondBestSimulationCard.accessibilityName)")
        }
        if let secondBestSimulationProjectedTeamPoints = summary.secondBestSimulationProjectedTeamPoints,
           summary.secondBestSimulationCard != summary.bestSimulationCard {
            lines.append("\("ثاني نتيجة محاكاة".localized): \(secondBestSimulationProjectedTeamPoints)")
        }
        if let selectedLostProjectedAgainstSecondBestPoints = summary.selectedLostProjectedAgainstSecondBestPoints,
           selectedLostProjectedAgainstSecondBestPoints > 0 {
            lines.append("\("فاقد ثاني محاكاة".localized): \(selectedLostProjectedAgainstSecondBestPoints)")
        }
        lines.append("\("سبب تكتيكي".localized): \(row.tacticalSummary)")
        return lines
    }

    private func simulationLines(for selectedOption: WhatToPlayOption) -> [String] {
        let simulationDisplay = WhatToPlaySimulationFormatter.display(for: selectedOption.simulation)
        var lines = [
            "\("نتيجة المحاكاة".localized): \(simulationDisplay.summary)"
        ]
        if let teamResult = simulationDisplay.teamResult {
            lines.append("\("اتجاه الأكلة".localized): \(teamResult)")
        }
        if let trickPoints = simulationDisplay.trickPoints {
            lines.append("\("نقاط الأكلة".localized): \(trickPoints)")
        }
        return lines
    }

    private func nextActionLines(_ summary: WhatToPlayOptionComparisonSummary) -> [String] {
        guard let nextActionTitle = summary.nextActionTitle,
              let nextActionDetail = summary.nextActionDetail
        else { return [] }
        return [
            "\("الخطوة التالية".localized): \(nextActionTitle)",
            nextActionDetail
        ]
    }

    private func retryPromptLines(_ retryPrompt: WhatToPlayRetryPrompt) -> [String] {
        var lines = [
            "\("تدريب الإعادة".localized): \(retryPrompt.title)",
            retryPrompt.detail
        ]
        if let recommendedCard = retryPrompt.recommendedCard {
            lines.append("\("جرّب الورقة".localized): \(recommendedCard.accessibilityName)")
        }
        lines.append(
            contentsOf: expectedImprovementLines(
                points: retryPrompt.expectedImprovement,
                source: retryPrompt.expectedImprovementSource
            )
        )
        return lines
    }

    private func expectedImprovementLines(
        points: Int,
        source: WhatToPlayExpectedImprovementSource?
    ) -> [String] {
        guard points > 0 else { return [] }
        var lines = [
            "\("تحسن متوقع".localized): +\(points)"
        ]
        if let source {
            lines.append("\("مصدر التحسن".localized): \(WhatToPlayStatsAnalyzer.expectedImprovementSourceTitle(for: source))")
        }
        return lines
    }

    private func impactText(_ value: Int) -> String {
        if value > 0 { return "+\(value)" }
        return "\(value)"
    }

    var statusTone: WhatToPlayShareCodeImportStatusTone {
        switch kind {
        case .prompt:
            return .prompt
        case .reviewedDecision(let isDuplicate):
            return isDuplicate ? .duplicateReview : .savedReview
        }
    }
}

enum WhatToPlayShareCodeImporter {
    enum ImportError: Error, Equatable {
        case invalidCode
        case selectedCardUnavailable
    }

    static func `import`(
        code: String,
        existingScenarioCodes: Set<String>
    ) async throws -> WhatToPlayShareCodeImportResult {
        guard let extractedCode = WhatToPlayScenarioCode.extractCode(from: code),
              let parsed = WhatToPlayScenarioCode.parse(extractedCode)
        else {
            throw ImportError.invalidCode
        }

        let scenario = try await WhatToPlayScenarioLoader.generate(code: extractedCode)
        guard let selectedCard = parsed.selectedCard else {
            return WhatToPlayShareCodeImportResult(
                parsed: parsed,
                scenario: scenario,
                selectedOption: nil,
                attempt: nil,
                kind: .prompt,
                canonicalScenarioCode: WhatToPlayScenarioCode.make(
                    for: scenario,
                    selectedOption: nil
                ),
                expectedImprovement: 0,
                expectedImprovementSource: nil
            )
        }

        guard let selectedOption = WhatToPlayTrainer.evaluateChoice(card: selectedCard, in: scenario) else {
            throw ImportError.selectedCardUnavailable
        }

        guard let attempt = WhatToPlayAttemptFactory.makeAttempt(scenario: scenario, evaluated: selectedOption) else {
            throw ImportError.selectedCardUnavailable
        }
        let scenarioCode = attempt.scenarioCode
        let isDuplicate = existingScenarioCodes.contains(scenarioCode)
        let improvement = expectedImprovement(for: attempt)

        return WhatToPlayShareCodeImportResult(
            parsed: parsed,
            scenario: scenario,
            selectedOption: selectedOption,
            attempt: isDuplicate ? nil : attempt,
            kind: .reviewedDecision(isDuplicate: isDuplicate),
            canonicalScenarioCode: scenarioCode,
            expectedImprovement: improvement.points,
            expectedImprovementSource: improvement.points > 0 ? improvement.source : nil
        )
    }

    private static func expectedImprovement(for attempt: WhatToPlayAttempt) -> WhatToPlayExpectedImprovementMetrics {
        WhatToPlayExpectedImprovementMetrics.calculate(
            lostExpectedPoints: attempt.lostExpectedPoints,
            lostProjectedTeamPoints: attempt.lostProjectedTeamPoints,
            lostProjectedAgainstSecondBestPoints: attempt.lostProjectedAgainstSecondBestPoints
        )
    }
}
