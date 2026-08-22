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

    var statusMessage: String {
        let message: String
        switch kind {
        case .prompt:
            message = "تم تحميل الموقف. اختر الورقة الأفضل.".localized
        case .reviewedDecision(let isDuplicate):
            if isDuplicate {
                message = "تم تحميل مراجعة القرار. هذه المحاولة موجودة في الإحصاءات.".localized
            } else {
                message = "تم تحميل مراجعة القرار وإضافتها للإحصاءات.".localized
            }
        }
        var lines = [
            message,
            "\("رمز الموقف".localized): \(canonicalScenarioCode)"
        ]
        if let selectedOption {
            let comparisonSummary = WhatToPlayOptionComparison.summary(
                for: scenario,
                selectedCard: selectedOption.card
            )
            let retryPrompt = WhatToPlayStatsAnalyzer.retryPrompt(for: selectedOption, in: scenario)
            let selectedComparisonRow = WhatToPlayOptionComparison
                .rows(for: scenario, selectedCard: selectedOption.card)
                .first { $0.card == selectedOption.card }
            lines.append("\("اختيارك".localized): \(selectedOption.card.accessibilityName)")
            if let bestOption = scenario.bestOption {
                lines.append("\("أفضل ورقة".localized): \(bestOption.card.accessibilityName)")
            }
            if let secondBestOption = scenario.secondBestOption,
               secondBestOption.card != scenario.bestOption?.card {
                lines.append("\("ثاني أفضل".localized): \(secondBestOption.card.accessibilityName)")
            }
            if let decisionQuality = comparisonSummary.decisionQuality {
                lines.append("\("تقييم القرار".localized): \(decisionQuality.title)")
            }
            if let decisionQualityDetail = comparisonSummary.decisionQualityDetail {
                lines.append(decisionQualityDetail)
            }
            if let bestMoveConfidence = comparisonSummary.bestMoveConfidence {
                lines.append("\("ثقة أفضل ورقة".localized): \(bestMoveConfidence.title)")
                lines.append(bestMoveConfidence.detail)
            }
            if let selectedComparisonRow {
                lines.append("\("الترتيب".localized): \(selectedComparisonRow.rank) \("من".localized) \(scenario.options.count)")
                lines.append("\("الأثر المتوقع".localized): \(impactText(selectedComparisonRow.expectedImpact))")
                lines.append("\("أثر القرار".localized): \(selectedComparisonRow.impactDetail)")
                if let selectedLostExpectedPoints = comparisonSummary.selectedLostExpectedPoints,
                   selectedLostExpectedPoints > 0 {
                    lines.append("\("النقاط الضائعة".localized): \(selectedLostExpectedPoints)")
                }
                lines.append("\("نقاط فريقك بعد المحاكاة".localized): \(selectedComparisonRow.projectedTeamPoints)")
                if let bestSimulationCard = comparisonSummary.bestSimulationCard {
                    lines.append("\("أفضل محاكاة".localized): \(bestSimulationCard.accessibilityName)")
                }
                if let bestSimulationProjectedTeamPoints = comparisonSummary.bestSimulationProjectedTeamPoints {
                    lines.append("\("أفضل نتيجة محاكاة".localized): \(bestSimulationProjectedTeamPoints)")
                }
                if let selectedLostProjectedTeamPoints = comparisonSummary.selectedLostProjectedTeamPoints,
                   selectedLostProjectedTeamPoints > 0 {
                    lines.append("\("نقاط محاكاة ضائعة".localized): \(selectedLostProjectedTeamPoints)")
                }
                if let secondBestSimulationCard = comparisonSummary.secondBestSimulationCard,
                   secondBestSimulationCard != comparisonSummary.bestSimulationCard {
                    lines.append("\("ثاني محاكاة".localized): \(secondBestSimulationCard.accessibilityName)")
                }
                if let secondBestSimulationProjectedTeamPoints = comparisonSummary.secondBestSimulationProjectedTeamPoints,
                   comparisonSummary.secondBestSimulationCard != comparisonSummary.bestSimulationCard {
                    lines.append("\("ثاني نتيجة محاكاة".localized): \(secondBestSimulationProjectedTeamPoints)")
                }
                if let selectedLostProjectedAgainstSecondBestPoints = comparisonSummary.selectedLostProjectedAgainstSecondBestPoints,
                   selectedLostProjectedAgainstSecondBestPoints > 0 {
                    lines.append("\("فاقد ثاني محاكاة".localized): \(selectedLostProjectedAgainstSecondBestPoints)")
                }
                lines.append("\("سبب تكتيكي".localized): \(selectedComparisonRow.tacticalSummary)")
            }
            let simulationDisplay = WhatToPlaySimulationFormatter.display(for: selectedOption.simulation)
            lines.append("\("نتيجة المحاكاة".localized): \(simulationDisplay.summary)")
            if let teamResult = simulationDisplay.teamResult {
                lines.append("\("اتجاه الأكلة".localized): \(teamResult)")
            }
            if let trickPoints = simulationDisplay.trickPoints {
                lines.append("\("نقاط الأكلة".localized): \(trickPoints)")
            }
            if let nextActionTitle = comparisonSummary.nextActionTitle,
               let nextActionDetail = comparisonSummary.nextActionDetail {
                lines.append("\("الخطوة التالية".localized): \(nextActionTitle)")
                lines.append(nextActionDetail)
            }
            if let retryPrompt {
                lines.append("\("تدريب الإعادة".localized): \(retryPrompt.title)")
                lines.append(retryPrompt.detail)
                if let recommendedCard = retryPrompt.recommendedCard {
                    lines.append("\("جرّب الورقة".localized): \(recommendedCard.accessibilityName)")
                }
                if retryPrompt.expectedImprovement > 0 {
                    lines.append("\("تحسن متوقع".localized): +\(retryPrompt.expectedImprovement)")
                }
                if let expectedImprovementSource = retryPrompt.expectedImprovementSource {
                    lines.append("\("مصدر التحسن".localized): \(WhatToPlayStatsAnalyzer.expectedImprovementSourceTitle(for: expectedImprovementSource))")
                }
            }
        }
        if expectedImprovement > 0, let expectedImprovementSource {
            lines.append("\("تحسن متوقع".localized): +\(expectedImprovement)")
            lines.append("\("مصدر التحسن".localized): \(WhatToPlayStatsAnalyzer.expectedImprovementSourceTitle(for: expectedImprovementSource))")
        }
        return lines.joined(separator: "\n")
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
