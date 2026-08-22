import XCTest
import BalootEngine
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
        XCTAssertEqual(result.canonicalScenarioCode, code)
        XCTAssertEqual(result.statusTone, .prompt)
        XCTAssertTrue(result.statusMessage.contains("تم تحميل الموقف. اختر الورقة الأفضل.".localized))
        XCTAssertTrue(result.statusMessage.contains("\("رمز الموقف".localized): \(code)"))
        XCTAssertFalse(result.statusMessage.contains("اختيارك".localized))
        XCTAssertFalse(result.statusMessage.contains("أفضل ورقة".localized))
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
        XCTAssertEqual(result.canonicalScenarioCode, code)
        XCTAssertEqual(result.statusTone, .savedReview)
        XCTAssertTrue(result.statusMessage.contains("تم تحميل مراجعة القرار وإضافتها للإحصاءات.".localized))
        XCTAssertTrue(result.statusMessage.contains("\("رمز الموقف".localized): \(code)"))
        XCTAssertTrue(result.statusMessage.contains("\("اختيارك".localized): \(selected.card.accessibilityName)"))
        XCTAssertTrue(result.statusMessage.contains("\("أفضل ورقة".localized): \(try XCTUnwrap(scenario.bestOption?.card.accessibilityName))"))
        if let secondBest = scenario.secondBestOption,
           secondBest.card != scenario.bestOption?.card {
            XCTAssertTrue(result.statusMessage.contains("\("ثاني أفضل".localized): \(secondBest.card.accessibilityName)"))
        }
    }

    func testImporterOmitsImprovementContextForExpertReviewedDecision() async throws {
        let scenario = try await WhatToPlayScenarioLoader.generate(
            seed: 2026,
            difficulty: .easy,
            preferredFocus: .followSuit
        )
        let selected = try XCTUnwrap(scenario.options.first { $0.isExpertChoice })
        let code = WhatToPlayShareCard.content(for: scenario, selectedOption: selected).scenarioCode

        let result = try await WhatToPlayShareCodeImporter.import(code: code, existingScenarioCodes: [])

        XCTAssertEqual(result.kind, .reviewedDecision(isDuplicate: false))
        XCTAssertEqual(result.selectedOption?.card, selected.card)
        XCTAssertEqual(result.expectedImprovement, 0)
        XCTAssertNil(result.expectedImprovementSource)
        XCTAssertFalse(result.statusMessage.contains("تحسن متوقع".localized))
        XCTAssertFalse(result.statusMessage.contains("مصدر التحسن".localized))
    }

    func testImporterCanRunOffMainActor() async throws {
        let scenario = try await WhatToPlayScenarioLoader.generate(
            seed: 2026,
            difficulty: .easy,
            preferredFocus: .followSuit
        )
        let selected = try XCTUnwrap(scenario.options.last)
        let code = WhatToPlayShareCard.content(for: scenario, selectedOption: selected).scenarioCode

        let imported = try await Task.detached(priority: .userInitiated) {
            let result = try await WhatToPlayShareCodeImporter.import(code: code, existingScenarioCodes: [])
            return (
                kind: result.kind,
                selectedCardName: result.selectedOption?.card.accessibilityName,
                scenarioCode: result.attempt?.scenarioCode
            )
        }.value

        XCTAssertEqual(imported.kind, .reviewedDecision(isDuplicate: false))
        XCTAssertEqual(imported.selectedCardName, selected.card.accessibilityName)
        XCTAssertEqual(imported.scenarioCode, code)
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
        let expectedCode = WhatToPlayShareCard.content(for: scenario, selectedOption: selected).scenarioCode
        XCTAssertEqual(result.attempt?.scenarioCode, expectedCode)
        XCTAssertEqual(result.canonicalScenarioCode, expectedCode)
    }

    func testImporterLoadsReviewQueueShareText() async throws {
        let scenario = try await WhatToPlayScenarioLoader.generate(
            seed: 45,
            difficulty: .hard,
            preferredFocus: .trumpPressure,
            preferredMode: .hokum,
            preferredTrumpSuit: .spades
        )
        let selected = try XCTUnwrap(scenario.options.first { !$0.isExpertChoice })
        let attempt = try XCTUnwrap(
            WhatToPlayAttemptFactory.makeAttempt(scenario: scenario, evaluated: selected)
        )
        let reviewItem = try XCTUnwrap(
            WhatToPlayStatsAnalyzer.reviewQueue(for: [attempt], limit: 1).first
        )
        let sharedText = WhatToPlayShareCard.reviewText(for: reviewItem)

        let result = try await WhatToPlayShareCodeImporter.import(code: sharedText, existingScenarioCodes: [])

        XCTAssertEqual(result.kind, .reviewedDecision(isDuplicate: false))
        XCTAssertEqual(result.selectedOption?.card, selected.card)
        XCTAssertEqual(result.attempt?.selectedCard, selected.card)
        XCTAssertEqual(result.attempt?.scenarioCode, reviewItem.scenarioCode)
        XCTAssertEqual(result.canonicalScenarioCode, reviewItem.scenarioCode)
    }

    func testImporterDoesNotDuplicateReviewQueueShareText() async throws {
        let scenario = try await WhatToPlayScenarioLoader.generate(
            seed: 45,
            difficulty: .hard,
            preferredFocus: .trumpPressure,
            preferredMode: .hokum,
            preferredTrumpSuit: .spades
        )
        let selected = try XCTUnwrap(scenario.options.first { !$0.isExpertChoice })
        let attempt = try XCTUnwrap(
            WhatToPlayAttemptFactory.makeAttempt(scenario: scenario, evaluated: selected)
        )
        let reviewItem = try XCTUnwrap(
            WhatToPlayStatsAnalyzer.reviewQueue(for: [attempt], limit: 1).first
        )
        let sharedText = WhatToPlayShareCard.reviewText(for: reviewItem)

        let result = try await WhatToPlayShareCodeImporter.import(
            code: sharedText,
            existingScenarioCodes: [reviewItem.scenarioCode]
        )

        XCTAssertEqual(result.kind, .reviewedDecision(isDuplicate: true))
        XCTAssertEqual(result.selectedOption?.card, selected.card)
        XCTAssertNil(result.attempt)
        XCTAssertEqual(result.canonicalScenarioCode, reviewItem.scenarioCode)
    }

    func testImporterLoadsTrainingSessionReviewShareTextReplayCode() async throws {
        let fixture = try await makeTrainingReviewImportFixture()

        let result = try await WhatToPlayShareCodeImporter.import(code: fixture.sharedText, existingScenarioCodes: [])

        XCTAssertEqual(fixture.review.action, .replayMistake)
        XCTAssertTrue(fixture.sharedText.contains("\("رمز الموقف".localized): \(fixture.replayScenarioCode)"))
        XCTAssertTrue(fixture.sharedText.contains("\("مصدر التحسن".localized):"))
        XCTAssertEqual(result.kind, .reviewedDecision(isDuplicate: false))
        XCTAssertEqual(result.selectedOption?.card, fixture.selected.card)
        XCTAssertEqual(result.attempt?.selectedCard, fixture.selected.card)
        XCTAssertEqual(result.attempt?.scenarioCode, fixture.replayScenarioCode)
        XCTAssertEqual(result.canonicalScenarioCode, fixture.replayScenarioCode)
        XCTAssertEqual(result.expectedImprovement, fixture.review.expectedImprovement)
        XCTAssertEqual(result.expectedImprovementSource, fixture.review.expectedImprovementSource)
        XCTAssertTrue(result.statusMessage.contains("\("تحسن متوقع".localized): +\(fixture.review.expectedImprovement)"))
        XCTAssertTrue(result.statusMessage.contains("\("مصدر التحسن".localized):"))
    }

    func testImporterKeepsExpectedImprovementContextForDuplicateTrainingReview() async throws {
        let fixture = try await makeTrainingReviewImportFixture()

        let result = try await WhatToPlayShareCodeImporter.import(
            code: fixture.sharedText,
            existingScenarioCodes: [fixture.replayScenarioCode]
        )

        XCTAssertEqual(result.kind, .reviewedDecision(isDuplicate: true))
        XCTAssertNil(result.attempt)
        XCTAssertEqual(result.canonicalScenarioCode, fixture.replayScenarioCode)
        XCTAssertEqual(result.expectedImprovement, fixture.review.expectedImprovement)
        XCTAssertEqual(result.expectedImprovementSource, fixture.review.expectedImprovementSource)
        XCTAssertTrue(result.statusMessage.contains("تم تحميل مراجعة القرار. هذه المحاولة موجودة في الإحصاءات.".localized))
        XCTAssertTrue(result.statusMessage.contains("\("تحسن متوقع".localized): +\(fixture.review.expectedImprovement)"))
        XCTAssertTrue(result.statusMessage.contains("\("مصدر التحسن".localized):"))
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
        XCTAssertEqual(result.canonicalScenarioCode, code)
    }

    func testImporterCanonicalizesPercentEncodedPromptURL() async throws {
        let scenario = try await WhatToPlayScenarioLoader.generate(
            seed: 2026,
            difficulty: .medium,
            preferredFocus: .followSuit,
            preferredMode: .sun
        )
        let code = WhatToPlayShareCard.content(for: scenario).scenarioCode
        let urlText = "https://baloothub.local/share/\(code)/open"
        let encodedURL = try XCTUnwrap(
            urlText.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics)
        )

        let result = try await WhatToPlayShareCodeImporter.import(code: encodedURL, existingScenarioCodes: [])

        XCTAssertEqual(result.kind, .prompt)
        XCTAssertNil(result.selectedOption)
        XCTAssertNil(result.attempt)
        XCTAssertEqual(result.canonicalScenarioCode, code)
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
        XCTAssertEqual(result.statusTone, .duplicateReview)
        XCTAssertTrue(result.statusMessage.contains("تم تحميل مراجعة القرار. هذه المحاولة موجودة في الإحصاءات.".localized))
        XCTAssertTrue(result.statusMessage.contains("\("رمز الموقف".localized): \(code)"))
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

    private func makeTrainingReviewImportFixture() async throws -> (
        selected: WhatToPlayOption,
        review: WhatToPlayTrainingSessionReview,
        replayScenarioCode: String,
        sharedText: String
    ) {
        let plan = WhatToPlayTrainingSessionPlan(
            difficulty: .hard,
            focusKind: .trumpPressure,
            gameMode: .hokum,
            trumpSuit: .spades,
            scenarioCount: 1,
            targetAccuracyPercent: 100,
            targetAverageExpectedImpact: 5,
            title: "خطة مراجعة".localized,
            detail: "تفصيل".localized,
            successMetric: "هدف".localized,
            iconName: "target"
        )

        for seed in 40...90 {
            let scenario = try await WhatToPlayScenarioLoader.generate(
                seed: UInt64(seed),
                difficulty: .hard,
                preferredFocus: .trumpPressure,
                preferredMode: .hokum,
                preferredTrumpSuit: .spades
            )
            for selected in scenario.options where !selected.isExpertChoice {
                guard let attempt = WhatToPlayAttemptFactory.makeAttempt(scenario: scenario, evaluated: selected)
                else { continue }
                let review = WhatToPlayStatsAnalyzer.trainingSessionReview(for: [attempt], plan: plan)
                guard review.action == .replayMistake,
                      review.expectedImprovement > 0,
                      review.expectedImprovementSource != nil,
                      let replayScenarioCode = review.replayScenarioCode
                else { continue }
                return (
                    selected,
                    review,
                    replayScenarioCode,
                    WhatToPlayShareCard.trainingSessionReviewText(for: review)
                )
            }
        }

        XCTFail("لم يتم العثور على مراجعة تدريب قابلة للاستيراد وفيها مصدر تحسن")
        throw NSError(domain: "WhatToPlayShareCodeImporterTests", code: 1)
    }
}
