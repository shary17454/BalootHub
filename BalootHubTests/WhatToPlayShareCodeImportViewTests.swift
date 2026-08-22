import XCTest
import BalootEngine
@testable import BalootHub

@MainActor
final class WhatToPlayShareCodeImportViewTests: XCTestCase {
    func testShareCodeImportToneMapsToMessageStyle() {
        let view = WhatToPlayTrainerView()

        XCTAssertEqual(view.shareCodeMessageStyle(for: .prompt), .neutral)
        XCTAssertEqual(view.shareCodeMessageStyle(for: .savedReview), .success)
        XCTAssertEqual(view.shareCodeMessageStyle(for: .duplicateReview), .warning)
    }

    func testShareCodeImportFormatsSimulationAlternativeLine() async throws {
        let view = WhatToPlayTrainerView()
        let result = try await importedResultWithSimulationAlternative()

        let line = try XCTUnwrap(view.shareCodeSimulationAlternativeLine(for: result))

        XCTAssertTrue(line.contains("\("ثاني محاكاة".localized): \(try XCTUnwrap(result.secondBestSimulationCard).accessibilityName)"))
        XCTAssertTrue(line.contains("\("ثاني نتيجة محاكاة".localized): \(try XCTUnwrap(result.secondBestProjectedTeamPoints))"))
        XCTAssertTrue(line.contains("\("فاقد ثاني محاكاة".localized): \(result.lostProjectedAgainstSecondBestPoints)"))
    }

    func testShareCodeImportOmitsSimulationAlternativeLineForPrompt() async throws {
        let view = WhatToPlayTrainerView()
        let scenario = try await WhatToPlayScenarioLoader.generate(
            seed: 2026,
            difficulty: .easy,
            preferredFocus: .followSuit
        )
        let code = WhatToPlayShareCard.content(for: scenario).scenarioCode
        let result = try await WhatToPlayShareCodeImporter.import(code: code, existingScenarioCodes: [])

        XCTAssertNil(view.shareCodeSimulationAlternativeLine(for: result))
    }

    private func importedResultWithSimulationAlternative() async throws -> WhatToPlayShareCodeImportResult {
        for seed in 2026...2040 {
            let scenario = try await WhatToPlayScenarioLoader.generate(
                seed: UInt64(seed),
                difficulty: .medium,
                preferredFocus: .followSuit
            )
            for selected in scenario.options where !selected.isExpertChoice {
                let code = WhatToPlayShareCard.content(for: scenario, selectedOption: selected).scenarioCode
                let result = try await WhatToPlayShareCodeImporter.import(code: code, existingScenarioCodes: [])
                if result.secondBestSimulationCard != nil,
                   result.secondBestProjectedTeamPoints != nil,
                   result.lostProjectedAgainstSecondBestPoints > 0 {
                    return result
                }
            }
        }
        XCTFail("لم يتم العثور على موقف استيراد فيه ثاني محاكاة ضمن نطاق الاختبار")
        throw NSError(domain: "WhatToPlayShareCodeImportViewTests", code: 1)
    }
}
