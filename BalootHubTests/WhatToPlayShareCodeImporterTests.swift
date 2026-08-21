import XCTest
@testable import BalootHub

@MainActor
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

    func testImporterLoadsReviewedHokumDecisionWithTrumpSuit() async throws {
        let scenario = try await WhatToPlayScenarioLoader.generate(
            seed: 2026,
            difficulty: .easy,
            preferredFocus: .trumpPressure,
            preferredMode: .hokum,
            preferredTrumpSuit: .spades
        )
        let selected = try XCTUnwrap(scenario.options.last)
        let code = WhatToPlayShareCard.content(for: scenario, selectedOption: selected).scenarioCode

        let result = try await WhatToPlayShareCodeImporter.import(code: code, existingScenarioCodes: [])

        XCTAssertEqual(result.kind, .reviewedDecision(isDuplicate: false))
        XCTAssertEqual(result.parsed.gameMode, .hokum)
        XCTAssertEqual(result.parsed.trumpSuit, .spades)
        XCTAssertEqual(result.scenario.state.mode, .hokum)
        XCTAssertEqual(result.scenario.state.trumpSuit, .spades)
        XCTAssertEqual(result.selectedOption?.card, selected.card)
        XCTAssertEqual(result.attempt?.gameMode, .hokum)
        XCTAssertEqual(result.attempt?.contextTrumpSuit, .spades)
        XCTAssertEqual(result.attempt?.scenarioCode, code)
    }

    func testImporterLoadsFullSharedText() async throws {
        let scenario = try await WhatToPlayScenarioLoader.generate(
            seed: 2026,
            difficulty: .easy,
            preferredFocus: .followSuit
        )
        let selected = try XCTUnwrap(scenario.options.last)
        let sharedText = WhatToPlayShareCard.text(for: scenario, selectedOption: selected)

        let result = try await WhatToPlayShareCodeImporter.import(code: sharedText, existingScenarioCodes: [])

        XCTAssertEqual(result.kind, .reviewedDecision(isDuplicate: false))
        XCTAssertEqual(result.selectedOption?.card, selected.card)
        XCTAssertEqual(result.attempt?.scenarioCode, WhatToPlayShareCard.content(for: scenario, selectedOption: selected).scenarioCode)
    }

    func testImporterLoadsCodeEmbeddedInURLPath() async throws {
        let scenario = try await WhatToPlayScenarioLoader.generate(
            seed: 2026,
            difficulty: .easy,
            preferredFocus: .trumpPressure,
            preferredMode: .hokum,
            preferredTrumpSuit: .spades
        )
        let selected = try XCTUnwrap(scenario.options.last)
        let code = WhatToPlayShareCard.content(for: scenario, selectedOption: selected).scenarioCode
        let urlText = "https://baloothub.local/share/\(code)/open"

        let result = try await WhatToPlayShareCodeImporter.import(code: urlText, existingScenarioCodes: [])

        XCTAssertEqual(result.kind, .reviewedDecision(isDuplicate: false))
        XCTAssertEqual(result.parsed.trumpSuit, .spades)
        XCTAssertEqual(result.selectedOption?.card, selected.card)
        XCTAssertEqual(result.attempt?.scenarioCode, code)
    }

    func testImporterLoadsPercentEncodedSharedURL() async throws {
        let scenario = try await WhatToPlayScenarioLoader.generate(
            seed: 2026,
            difficulty: .medium,
            preferredFocus: .followSuit,
            preferredMode: .sun
        )
        let selected = try XCTUnwrap(scenario.options.last)
        let code = WhatToPlayShareCard.content(for: scenario, selectedOption: selected).scenarioCode
        let urlText = "https://baloothub.local/share/\(code)/open"
        let encodedURL = try XCTUnwrap(
            urlText.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics)
        )

        let result = try await WhatToPlayShareCodeImporter.import(code: encodedURL, existingScenarioCodes: [])

        XCTAssertEqual(result.kind, .reviewedDecision(isDuplicate: false))
        XCTAssertEqual(result.parsed.gameMode, .sun)
        XCTAssertEqual(result.selectedOption?.card, selected.card)
        XCTAssertEqual(result.attempt?.scenarioCode, code)
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

    func testImporterDoesNotCreateDuplicateAttemptFromPercentEncodedSharedURL() async throws {
        let scenario = try await WhatToPlayScenarioLoader.generate(
            seed: 2026,
            difficulty: .medium,
            preferredFocus: .trumpPressure,
            preferredMode: .hokum,
            preferredTrumpSuit: .spades
        )
        let selected = try XCTUnwrap(scenario.options.last)
        let code = WhatToPlayShareCard.content(for: scenario, selectedOption: selected).scenarioCode
        let urlText = "https://baloothub.local/share/\(code)/open"
        let encodedURL = try XCTUnwrap(
            urlText.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics)
        )

        let result = try await WhatToPlayShareCodeImporter.import(code: encodedURL, existingScenarioCodes: [code])

        XCTAssertEqual(result.kind, .reviewedDecision(isDuplicate: true))
        XCTAssertEqual(result.selectedOption?.card, selected.card)
        XCTAssertNil(result.attempt)
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
