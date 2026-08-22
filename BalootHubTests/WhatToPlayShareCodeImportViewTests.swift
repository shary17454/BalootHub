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

    func testClearShareCodeImportFeedbackRemovesStaleImportState() {
        var view = WhatToPlayTrainerView()
        view.shareCodeMessage = "تم تحميل مراجعة القرار".localized
        view.shareCodeMessageStyle = .success
        view.shareCodeSimulationAlternativeMessage = "ثاني محاكاة: إكة سباتي"

        view.clearShareCodeImportFeedback()

        XCTAssertNil(view.shareCodeMessage)
        XCTAssertEqual(view.shareCodeMessageStyle, .neutral)
        XCTAssertNil(view.shareCodeSimulationAlternativeMessage)
    }

    func testShareCodeStatusAccessibilityLabelReadsMultilineMessageClearly() {
        let view = WhatToPlayTrainerView()
        let message = [
            "تم تحميل مراجعة القرار".localized,
            "\("رمز الموقف".localized): WTP-2026-medium-followSuit-auto-C37",
            "\("ثاني نتيجة محاكاة".localized): 58 · \("فاقد ثاني محاكاة".localized): 8"
        ].joined(separator: "\n")

        let label = view.shareCodeStatusAccessibilityLabel(for: message)

        XCTAssertEqual(
            label,
            "\("تم تحميل مراجعة القرار".localized)، \("رمز الموقف".localized): WTP-2026-medium-followSuit-auto-C37، \("ثاني نتيجة محاكاة".localized): 58، \("فاقد ثاني محاكاة".localized): 8"
        )
    }

    func testShareCodeStatusDisplayTextKeepsShortMessageWhole() {
        let view = WhatToPlayTrainerView()
        let message = [
            "تم تحميل مراجعة القرار".localized,
            "\("رمز الموقف".localized): WTP-2026-medium-followSuit-auto-C37"
        ].joined(separator: "\n")

        XCTAssertEqual(view.shareCodeStatusDisplayText(for: message), message)
    }

    func testShareCodeStatusDisplayTextCondensesLongImportedReview() {
        let view = WhatToPlayTrainerView()
        let message = (1...11).map { "سطر \($0)" }.joined(separator: "\n")

        let display = view.shareCodeStatusDisplayText(for: message, maxLines: 8)

        XCTAssertTrue(display.contains("سطر 1"))
        XCTAssertTrue(display.contains("سطر 8"))
        XCTAssertFalse(display.contains("سطر 9"))
        XCTAssertTrue(display.contains("+3 \("سطر إضافي في المراجعة".localized)"))
        XCTAssertEqual(view.shareCodeStatusAccessibilityLabel(for: message), (1...11).map { "سطر \($0)" }.joined(separator: "، "))
    }

    func testShareCodeStatusDisplayTextPreservesImportedTrumpSuitLine() {
        let view = WhatToPlayTrainerView()
        let trumpSuitLine = "\("لون الحكم".localized): \(Suit.spades.spokenName)"
        let message = [
            "تم تحميل مراجعة القرار".localized,
            "\("رمز الموقف".localized): WTP-2026-medium-trumpPressure-hokum-spades-C37",
            "السياق: حكم",
            "الدور: اللاعب 1",
            "الأفضل: إكة سباتي",
            "اختيارك: عشرة هاص",
            "الأثر المتوقع: -8",
            "تفسير: قطع الحكم هنا يحمي الأكلة",
            trumpSuitLine,
            "نهاية المراجعة"
        ].joined(separator: "\n")

        let display = view.shareCodeStatusDisplayText(for: message, maxLines: 8)

        XCTAssertTrue(display.contains(trumpSuitLine))
        XCTAssertFalse(display.contains("تفسير: قطع الحكم هنا يحمي الأكلة"))
        XCTAssertTrue(display.contains("+2 \("سطر إضافي في المراجعة".localized)"))
        XCTAssertTrue(view.shareCodeStatusAccessibilityLabel(for: message).contains(trumpSuitLine))
    }

    func testShareCodeStatusDisplayTextPreservesBlockedAndChecklistSections() {
        let view = WhatToPlayTrainerView()
        let blockedTitle = "\("الأوراق الممنوعة".localized):"
        let checklistTitle = "افحص قبل اللعب".localized
        let message = [
            "تم تحميل الموقف. اختر الورقة الأفضل.".localized,
            "\("رمز الموقف".localized): WTP-2026-medium-followSuit-auto-P",
            "\("النمط".localized): صن",
            "\("الصعوبة".localized): متوسط",
            "\("نوع الموقف".localized): اتباع اللون",
            "\("الأكلة".localized): 3 من 8",
            "\("النقاط".localized): فريقنا 18 · الخصم 20 · -2",
            "\("الدور".localized): أنت",
            blockedTitle,
            "- إكة هاص: يجب التلزيم.",
            checklistTitle
        ].joined(separator: "\n")

        let display = view.shareCodeStatusDisplayText(for: message, maxLines: 8)

        XCTAssertTrue(display.contains(blockedTitle))
        XCTAssertTrue(display.contains(checklistTitle))
        XCTAssertFalse(display.contains("\("الدور".localized): أنت"))
        XCTAssertTrue(display.contains("+3 \("سطر إضافي في المراجعة".localized)"))
        XCTAssertTrue(view.shareCodeStatusAccessibilityLabel(for: message).contains(checklistTitle))
    }

    func testShareCodeImportFormatsSimulationAlternativeLine() async throws {
        let view = WhatToPlayTrainerView()
        let result = try await importedResultWithSimulationAlternative()

        let line = try XCTUnwrap(view.shareCodeSimulationAlternativeLine(for: result))

        XCTAssertTrue(line.contains("\("أفضل محاكاة".localized): \(try XCTUnwrap(result.bestSimulationCard).accessibilityName)"))
        XCTAssertTrue(line.contains("\("أفضل نتيجة محاكاة".localized): \(try XCTUnwrap(result.bestProjectedTeamPoints))"))
        XCTAssertTrue(line.contains("\("ثاني محاكاة".localized): \(try XCTUnwrap(result.secondBestSimulationCard).accessibilityName)"))
        XCTAssertTrue(line.contains("\("ثاني نتيجة محاكاة".localized): \(try XCTUnwrap(result.secondBestProjectedTeamPoints))"))
        XCTAssertTrue(line.contains("\("فاقد ثاني محاكاة".localized): \(result.lostProjectedAgainstSecondBestPoints)"))
    }

    func testShareCodeImportSimulationAlternativeAccessibilityLabelIsSpokenClearly() {
        let view = WhatToPlayTrainerView()
        let line = [
            "\("أفضل محاكاة".localized): عشرة هاص",
            "\("أفضل نتيجة محاكاة".localized): 66",
            "\("ثاني محاكاة".localized): إكة سباتي",
            "\("ثاني نتيجة محاكاة".localized): 58",
            "\("فاقد ثاني محاكاة".localized): 8"
        ].joined(separator: " · ")

        let label = view.shareCodeSimulationAlternativeAccessibilityLabel(for: line)

        XCTAssertEqual(
            label,
            "\("بديل المحاكاة المستورد".localized): \("أفضل محاكاة".localized): عشرة هاص، \("أفضل نتيجة محاكاة".localized): 66، \("ثاني محاكاة".localized): إكة سباتي، \("ثاني نتيجة محاكاة".localized): 58، \("فاقد ثاني محاكاة".localized): 8"
        )
    }

    func testOptionSummaryCardTextNamesProjectedSimulationPoints() {
        let view = WhatToPlayTrainerView()
        let card = PlayingCard(suit: .spades, rank: .ace)

        let text = view.optionSummaryCardText(card: card, impact: 7, projectedTeamPoints: 58)

        XCTAssertEqual(text, "\(card.accessibilityName) · +7 · \("نقاط المحاكاة".localized): 58")
    }

    func testOptionSummaryCardTextFallsBackWhenCardOrImpactIsMissing() {
        let view = WhatToPlayTrainerView()
        let card = PlayingCard(suit: .spades, rank: .ace)

        XCTAssertEqual(
            view.optionSummaryCardText(card: nil, impact: 7, projectedTeamPoints: 58),
            "لا يوجد بديل".localized
        )
        XCTAssertEqual(
            view.optionSummaryCardText(card: card, impact: nil, projectedTeamPoints: 58),
            "لا يوجد بديل".localized
        )
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
                if result.bestSimulationCard != nil,
                   result.bestProjectedTeamPoints != nil,
                   result.secondBestSimulationCard != nil,
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
