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
        if expectedImprovement > 0, let expectedImprovementSource {
            lines.append("\("تحسن متوقع".localized): +\(expectedImprovement)")
            lines.append("\("مصدر التحسن".localized): \(WhatToPlayStatsAnalyzer.expectedImprovementSourceTitle(for: expectedImprovementSource))")
        }
        return lines.joined(separator: "\n")
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
