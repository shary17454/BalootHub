import BalootEngine
import Foundation

enum WhatToPlayShareCodeImportKind: Equatable {
    case prompt
    case reviewedDecision(isDuplicate: Bool)
}

struct WhatToPlayShareCodeImportResult {
    let parsed: WhatToPlayScenarioCode.Parsed
    let scenario: WhatToPlayScenario
    let selectedOption: WhatToPlayOption?
    let attempt: WhatToPlayAttempt?
    let kind: WhatToPlayShareCodeImportKind

    var statusMessage: String {
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
}

@MainActor
enum WhatToPlayShareCodeImporter {
    enum ImportError: Error, Equatable {
        case invalidCode
        case selectedCardUnavailable
    }

    static func `import`(
        code: String,
        existingScenarioCodes: Set<String>
    ) async throws -> WhatToPlayShareCodeImportResult {
        guard let parsed = WhatToPlayScenarioCode.parse(code) else {
            throw ImportError.invalidCode
        }

        let scenario = try await WhatToPlayScenarioLoader.generate(code: code)
        guard let selectedCard = parsed.selectedCard else {
            return WhatToPlayShareCodeImportResult(
                parsed: parsed,
                scenario: scenario,
                selectedOption: nil,
                attempt: nil,
                kind: .prompt
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

        return WhatToPlayShareCodeImportResult(
            parsed: parsed,
            scenario: scenario,
            selectedOption: selectedOption,
            attempt: isDuplicate ? nil : attempt,
            kind: .reviewedDecision(isDuplicate: isDuplicate)
        )
    }
}
