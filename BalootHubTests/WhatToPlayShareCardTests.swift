import XCTest
import BalootEngine
@testable import BalootHub

final class WhatToPlayShareCardTests: XCTestCase {
    func testShareTextIsDeterministicForSameScenario() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)

        XCTAssertEqual(
            WhatToPlayShareCard.text(for: scenario),
            WhatToPlayShareCard.text(for: scenario)
        )
    }

    func testShareTextContainsScenarioContextAndLegalOptions() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let text = WhatToPlayShareCard.text(for: scenario)

        XCTAssertTrue(text.contains("وش تلعب؟".localized))
        XCTAssertTrue(text.contains("\("أنت تلعب".localized) \(contentMode(for: scenario))"))
        XCTAssertTrue(text.contains("\("النمط".localized):"))
        XCTAssertTrue(text.contains("\("الصعوبة".localized):"))
        XCTAssertTrue(text.contains("\("تركيز التدريب".localized):"))
        XCTAssertTrue(text.contains("\("الأكلة".localized):"))
        XCTAssertTrue(text.contains("\("الأوراق القانونية".localized):"))
        for option in scenario.options {
            XCTAssertTrue(text.contains(option.card.accessibilityName))
        }
    }

    func testShareCardContentSeparatesVisualSections() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let content = WhatToPlayShareCard.content(for: scenario)

        XCTAssertEqual(content.title, "وش تلعب؟".localized)
        XCTAssertEqual(content.contextLine, "\("أنت تلعب".localized) \(content.mode)")
        XCTAssertEqual(content.mode.isEmpty, false)
        XCTAssertEqual(content.difficulty.isEmpty, false)
        XCTAssertEqual(content.focus.isEmpty, false)
        XCTAssertEqual(content.trickProgress, "\(scenario.state.completedTricks.count + 1) \("من".localized) 8")
        XCTAssertEqual(content.legalCardNames, scenario.options.sorted {
            if $0.card.suit.ordinal != $1.card.suit.ordinal {
                return $0.card.suit.ordinal < $1.card.suit.ordinal
            }
            return $0.card.rank.ordinal < $1.card.rank.ordinal
        }.map { $0.card.accessibilityName })
    }

    func testShareTextIncludesFocusedScenarioMetadata() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(
            seed: 2026,
            difficulty: .easy,
            preferredFocus: .followSuit
        )
        let text = WhatToPlayShareCard.text(for: scenario)
        let content = WhatToPlayShareCard.content(for: scenario)

        XCTAssertEqual(content.difficulty, "سهل".localized)
        XCTAssertEqual(content.focus, "اتباع اللون".localized)
        XCTAssertTrue(text.contains("\("الصعوبة".localized): \("سهل".localized)"))
        XCTAssertTrue(text.contains("\("تركيز التدريب".localized): \("اتباع اللون".localized)"))
        XCTAssertTrue(text.contains(content.contextLine))
    }

    func testShareCardContentKeepsTableCardsSeparateFromLegalOptions() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)
        let content = WhatToPlayShareCard.content(for: scenario)
        let tableCards = scenario.state.currentTrick?.playedCards ?? []

        XCTAssertEqual(content.tableCards.count, tableCards.count)
        XCTAssertEqual(content.isOpeningTrick, tableCards.isEmpty)
        for line in content.tableCards {
            XCTAssertFalse(line.playerName.isEmpty)
            XCTAssertFalse(line.cardName.isEmpty)
            XCTAssertFalse(content.legalCardNames.contains("\(line.playerName): \(line.cardName)"))
        }
    }

    func testShareTextDoesNotRevealExpertAnswer() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let text = WhatToPlayShareCard.text(for: scenario)

        XCTAssertFalse(text.contains("أفضل ورقة:".localized))
        XCTAssertFalse(text.contains("الأفضل".localized))
        XCTAssertFalse(text.contains("ثاني أفضل:".localized))
        XCTAssertFalse(text.contains("أثر الأفضل:".localized))
        XCTAssertFalse(text.contains("أثر ثاني أفضل:".localized))
        XCTAssertFalse(text.contains("اختيار الخبير".localized))
        XCTAssertFalse(text.contains("نتيجة المحاكاة".localized))
        XCTAssertFalse(text.contains("اتجاه الأكلة".localized))
        XCTAssertFalse(text.contains("نقاط فريقك بعد المحاكاة".localized))
    }

    func testShareTextIncludesAnswerReviewAfterSelection() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let selected = try XCTUnwrap(scenario.options.last)
        let best = try XCTUnwrap(scenario.bestOption)
        let secondBest = try XCTUnwrap(scenario.secondBestOption)
        let text = WhatToPlayShareCard.text(for: scenario, selectedOption: selected)

        XCTAssertTrue(text.contains("مراجعة القرار".localized))
        XCTAssertTrue(text.contains("\("اختياري".localized): \(selected.card.accessibilityName)"))
        XCTAssertTrue(text.contains("\("أفضل ورقة".localized): \(best.card.accessibilityName)"))
        XCTAssertTrue(text.contains("\("أثر الأفضل".localized): \(best.expectedImpact >= 0 ? "+\(best.expectedImpact)" : "\(best.expectedImpact)")"))
        XCTAssertTrue(text.contains("\("ثاني أفضل".localized): \(secondBest.card.accessibilityName)"))
        XCTAssertTrue(text.contains("\("أثر ثاني أفضل".localized): \(secondBest.expectedImpact >= 0 ? "+\(secondBest.expectedImpact)" : "\(secondBest.expectedImpact)")"))
        XCTAssertTrue(text.contains("\("ترتيب اختياري".localized): \(selected.rank)"))
        XCTAssertTrue(text.contains("\("نقاط متوقعة ضائعة".localized): \(max(0, best.expectedImpact - selected.expectedImpact))"))
        XCTAssertTrue(text.contains("\("نقاط محاكاة ضائعة".localized): \(max(0, best.projectedTeamPoints - selected.projectedTeamPoints))"))
        let severity = WhatToPlayStatsAnalyzer.valueLossSeverity(
            for: max(
                max(0, best.expectedImpact - selected.expectedImpact),
                max(0, best.projectedTeamPoints - selected.projectedTeamPoints)
            )
        )
        XCTAssertTrue(text.contains("\("شدة خسارة القيمة".localized): \(WhatToPlayStatsAnalyzer.valueLossTitle(for: severity))"))
        XCTAssertTrue(text.contains("\("فارق عن ثاني أفضل".localized): \(max(0, secondBest.expectedImpact - selected.expectedImpact))"))
        XCTAssertTrue(text.contains("\("الأثر المتوقع".localized): \(selected.expectedImpact >= 0 ? "+\(selected.expectedImpact)" : "\(selected.expectedImpact)")"))
        XCTAssertTrue(text.contains("\("تفصيل الأثر".localized): \(WhatToPlayImpactFormatter.detail(for: selected.impactBreakdown))"))
        XCTAssertTrue(text.contains("\("نقاط فريقك بعد المحاكاة".localized): \(selected.projectedTeamPoints)"))
        XCTAssertTrue(text.contains("\("نتيجة المحاكاة".localized):"))
        if let wonByPlayerTeam = selected.simulation.completedTrickWonByPlayerTeam {
            XCTAssertTrue(text.contains("\("اتجاه الأكلة".localized): \(wonByPlayerTeam ? "لفريقك".localized : "للخصم".localized)"))
            XCTAssertTrue(text.contains("\("نقاط الأكلة".localized): \(selected.simulation.completedTrickPoints)"))
        }
    }

    func testShareCardContentMarksAnswerReviewOnlyAfterSelection() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let selected = try XCTUnwrap(scenario.bestOption)

        XCTAssertFalse(WhatToPlayShareCard.content(for: scenario).includesAnswerReview)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).tacticalReasonTitle)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).secondBestCardName)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).bestExpectedImpact)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).secondBestExpectedImpact)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).lostAgainstSecondBestPoints)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).lostProjectedTeamPoints)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).valueLossTitle)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).decisionQualityTitle)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).nextActionTitle)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).nextActionDetail)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).selectedSimulationSummary)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).selectedSimulationTeamResult)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).selectedSimulationTrickPoints)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).selectedProjectedTeamPoints)

        let reviewed = WhatToPlayShareCard.content(for: scenario, selectedOption: selected)
        let secondBest = try XCTUnwrap(scenario.secondBestOption)

        XCTAssertTrue(reviewed.includesAnswerReview)
        XCTAssertEqual(reviewed.subtitle, "مراجعة قرار من Baloot Hub".localized)
        XCTAssertEqual(reviewed.selectedCardName, selected.card.accessibilityName)
        XCTAssertEqual(reviewed.bestCardName, selected.card.accessibilityName)
        XCTAssertEqual(reviewed.bestExpectedImpact, selected.expectedImpact)
        XCTAssertEqual(reviewed.secondBestCardName, secondBest.card.accessibilityName)
        XCTAssertEqual(reviewed.secondBestExpectedImpact, secondBest.expectedImpact)
        XCTAssertEqual(reviewed.lostExpectedPoints, 0)
        XCTAssertEqual(reviewed.lostProjectedTeamPoints, 0)
        XCTAssertEqual(reviewed.lostAgainstSecondBestPoints, max(0, secondBest.expectedImpact - selected.expectedImpact))
        XCTAssertEqual(reviewed.valueLossTitle, "لا توجد خسارة قيمة".localized)
        XCTAssertEqual(reviewed.decisionQualityTitle, "مطابق للخبير".localized)
        XCTAssertEqual(reviewed.nextActionTitle, "ثبّت القراءة".localized)
        XCTAssertTrue(reviewed.nextActionDetail?.contains(selected.card.accessibilityName) ?? false)
        XCTAssertEqual(reviewed.selectedImpact, selected.expectedImpact)
        XCTAssertEqual(reviewed.selectedImpactDetail, WhatToPlayImpactFormatter.detail(for: selected.impactBreakdown))
        XCTAssertEqual(reviewed.selectedProjectedTeamPoints, selected.projectedTeamPoints)
        XCTAssertNotNil(reviewed.selectedSimulationSummary)
        XCTAssertEqual(
            reviewed.selectedSimulationTeamResult,
            selected.simulation.completedTrickWonByPlayerTeam.map { $0 ? "لفريقك".localized : "للخصم".localized }
        )
        XCTAssertEqual(
            reviewed.selectedSimulationTrickPoints,
            selected.simulation.completedTrickWinnerID == nil ? nil : selected.simulation.completedTrickPoints
        )
        XCTAssertEqual(reviewed.prompt, "راجع القرار وتدرّب على قراءة الموقف.".localized)
    }

    func testShareCardIncludesTacticalReasonAfterCostlySelection() throws {
        let (scenario, selected) = try costlyShareSelection()

        let content = WhatToPlayShareCard.content(for: scenario, selectedOption: selected)
        let text = WhatToPlayShareCard.text(for: scenario, selectedOption: selected)

        XCTAssertNotNil(content.tacticalReasonTitle)
        XCTAssertNotNil(content.tacticalReasonDetail)
        XCTAssertNotNil(content.tacticalReasonIconName)
        XCTAssertTrue(text.contains("سبب تكتيكي".localized))
        XCTAssertTrue(text.contains(try XCTUnwrap(content.tacticalReasonTitle)))
        XCTAssertTrue(text.contains(try XCTUnwrap(content.tacticalReasonDetail)))
    }

    func testShareTextIncludesDecisionQualityAfterSelection() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)
        let selected = try XCTUnwrap(scenario.options.last)
        let content = WhatToPlayShareCard.content(for: scenario, selectedOption: selected)
        let text = WhatToPlayShareCard.text(for: scenario, selectedOption: selected)

        XCTAssertNotNil(content.decisionQualityTitle)
        XCTAssertNotNil(content.nextActionTitle)
        XCTAssertNotNil(content.nextActionDetail)
        XCTAssertTrue(text.contains("\("تقييم القرار".localized): \(try XCTUnwrap(content.decisionQualityTitle))"))
        XCTAssertTrue(text.contains("\("الإجراء التالي".localized): \(try XCTUnwrap(content.nextActionTitle))"))
        XCTAssertTrue(text.contains(try XCTUnwrap(content.nextActionDetail)))
    }

    func testShareDecisionQualityUsesProjectedLossWhenLarger() throws {
        let (scenario, selected) = try simulationLossShareSelection()
        let best = try XCTUnwrap(scenario.bestOption)

        let content = WhatToPlayShareCard.content(for: scenario, selectedOption: selected)
        let text = WhatToPlayShareCard.text(for: scenario, selectedOption: selected)

        XCTAssertLessThanOrEqual(max(0, best.expectedImpact - selected.expectedImpact), 2)
        XCTAssertGreaterThanOrEqual(max(0, best.projectedTeamPoints - selected.projectedTeamPoints), 9)
        XCTAssertEqual(content.lostProjectedTeamPoints, max(0, best.projectedTeamPoints - selected.projectedTeamPoints))
        XCTAssertEqual(content.decisionQualityTitle, "قرار مكلف".localized)
        XCTAssertEqual(content.valueLossTitle, "خسارة عالية".localized)
        XCTAssertTrue(text.contains("\("نقاط محاكاة ضائعة".localized): \(try XCTUnwrap(content.lostProjectedTeamPoints))"))
        XCTAssertTrue(text.contains("\("تقييم القرار".localized): \("قرار مكلف".localized)"))
        XCTAssertTrue(text.contains("\("شدة خسارة القيمة".localized): \("خسارة عالية".localized)"))
    }

    @MainActor
    func testShareCardImageRendererWritesPNGFile() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let content = WhatToPlayShareCard.content(for: scenario)

        let url = try WhatToPlayShareCardImageRenderer.render(
            content: content,
            fileName: "baloothub-share-card-test.png",
            scale: 2
        )
        defer { try? FileManager.default.removeItem(at: url) }

        let data = try Data(contentsOf: url)
        let pngSignature = Data([0x89, 0x50, 0x4E, 0x47])

        XCTAssertGreaterThan(data.count, 1024)
        XCTAssertEqual(data.prefix(4), pngSignature)
    }

    private func contentMode(for scenario: WhatToPlayScenario) -> String {
        WhatToPlayShareCard.content(for: scenario).mode
    }

    private func costlyShareSelection() throws -> (WhatToPlayScenario, WhatToPlayOption) {
        for seed in 1..<500 {
            let scenario = try WhatToPlayTrainer.generateScenario(seed: UInt64(seed), difficulty: .hard)
            if let option = scenario.options.first(where: { option in
                option.expectedImpact < 0
                    && (
                        option.impactBreakdown.preservesLead
                        || (
                            option.impactBreakdown.completesTrick
                                && option.impactBreakdown.winsForPlayerTeam == false
                                && option.impactBreakdown.trickPointsSwing < 0
                        )
                        || (
                            !option.impactBreakdown.completesTrick
                                && !option.impactBreakdown.preservesLead
                                && option.impactBreakdown.playedCardPoints > 0
                                && option.impactBreakdown.immediateImpact < 0
                        )
                    )
            }) {
                return (scenario, option)
            }
        }
        XCTFail("لم يتم العثور على موقف مشاركة بخطأ تكتيكي ضمن نطاق البذور المحدد")
        throw NSError(domain: "WhatToPlayShareCardTests", code: 1)
    }

    private func simulationLossShareSelection() throws -> (WhatToPlayScenario, WhatToPlayOption) {
        for seed in 1...300 {
            let scenario = try WhatToPlayTrainer.generateScenario(seed: UInt64(seed), difficulty: .hard)
            guard let best = scenario.bestOption else { continue }
            if let option = scenario.options.first(where: {
                $0.card != best.card
                    && max(0, best.expectedImpact - $0.expectedImpact) <= 2
                    && max(0, best.projectedTeamPoints - $0.projectedTeamPoints) >= 9
            }) {
                return (scenario, option)
            }
        }
        XCTFail("لم يتم العثور على موقف مشاركة بخسارة محاكاة عالية ضمن نطاق البذور المحدد")
        throw NSError(domain: "WhatToPlayShareCardTests", code: 2)
    }
}
