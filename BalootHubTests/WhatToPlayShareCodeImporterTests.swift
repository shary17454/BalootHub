import XCTest
@testable import BalootHub

final class WhatToPlayShareCodeImporterTests: XCTestCase {
    func testImporterLoadsPromptCodeWithoutAttempt() async throws {
        let scenario = try await WhatToPlayScenarioLoader.generate(
            seed: 2026,
            difficulty: .easy,
            preferredFocus: .followSuit
        )
        let code = WhatToPlayShareCard.content(for: scenario).scenarioCode

        let result = try await WhatToPlayShareCodeImporter.import(code: code, existingScenarioCodes: [])

        XCTAssertEqual(result.kind, .prompt)
        XCTAssertEqual(result.parsed.seed, scenario.seed)
        XCTAssertEqual(result.scenario.seed, scenario.seed)
        XCTAssertNil(result.selectedOption)
        XCTAssertNil(result.attempt)
        XCTAssertEqual(result.statusMessage, "تم تحميل الموقف. اختر الورقة الأفضل.".localized)
    }

    func testImporterLoadsReviewedDecisionAndCreatesAttempt() async throws {
        let scenario = try await WhatToPlayScenarioLoader.generate(
            seed: 2026,
            difficulty: .easy,
            preferredFocus: .followSuit
        )
        let selected = try XCTUnwrap(scenario.options.last)
        let code = WhatToPlayShareCard.content(for: scenario, selectedOption: selected).scenarioCode

        let result = try await WhatToPlayShareCodeImporter.import(code: code, existingScenarioCodes: [])

        XCTAssertEqual(result.kind, .reviewedDecision(isDuplicate: false))
        XCTAssertEqual(result.selectedOption?.card, selected.card)
        XCTAssertEqual(result.attempt?.selectedCard, selected.card)
        XCTAssertEqual(result.attempt?.scenarioCode, code)
        XCTAssertEqual(result.statusMessage, "تم تحميل مراجعة القرار وإضافتها للإحصاءات.".localized)
    }

    func testImporterDoesNotCreateDuplicateAttempt() async throws {
        let scenario = try await WhatToPlayScenarioLoader.generate(
            seed: 2026,
            difficulty: .easy,
            preferredFocus: .followSuit
        )
        let selected = try XCTUnwrap(scenario.options.last)
        let code = WhatToPlayShareCard.content(for: scenario, selectedOption: selected).scenarioCode

        let result = try await WhatToPlayShareCodeImporter.import(code: code, existingScenarioCodes: [code])

        XCTAssertEqual(result.kind, .reviewedDecision(isDuplicate: true))
        XCTAssertEqual(result.selectedOption?.card, selected.card)
        XCTAssertNil(result.attempt)
        XCTAssertEqual(
            result.statusMessage,
            "تم تحميل مراجعة القرار. هذه المحاولة موجودة في الإحصاءات.".localized
        )
    }

    func testImporterRejectsMalformedCode() async {
        do {
            _ = try await WhatToPlayShareCodeImporter.import(code: "WTP-invalid", existingScenarioCodes: [])
            XCTFail("كان يجب رفض رمز المشاركة غير الصالح")
        } catch let error as WhatToPlayShareCodeImporter.ImportError {
            XCTAssertEqual(error, .invalidCode)
        } catch {
            XCTFail("خطأ غير متوقع: \(error)")
        }
    }
}
