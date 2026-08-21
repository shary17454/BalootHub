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
        let content = WhatToPlayShareCard.content(for: scenario)

        XCTAssertTrue(text.contains("وش تلعب؟".localized))
        XCTAssertTrue(text.contains("\("أنت تلعب".localized) \(contentMode(for: scenario))"))
        XCTAssertTrue(text.contains("\("رمز الموقف".localized): \(content.scenarioCode)"))
        XCTAssertTrue(text.contains("\("النمط".localized):"))
        XCTAssertTrue(text.contains("\("الصعوبة".localized):"))
        XCTAssertTrue(text.contains("\("تركيز التدريب".localized):"))
        XCTAssertTrue(text.contains("\("الأكلة".localized):"))
        XCTAssertTrue(text.contains("\("النقاط".localized): \(shareScoreText(for: scenario))"))
        XCTAssertTrue(text.contains(turnContextText(for: scenario)))
        XCTAssertTrue(text.contains("\("خيارات".localized): \(scenario.context.legalOptionCount) · \("على الطاولة".localized): \(scenario.context.playedCardCount)"))
        XCTAssertTrue(text.contains("\("الأوراق القانونية".localized):"))
        for option in scenario.options {
            XCTAssertTrue(text.contains(option.card.accessibilityName))
        }
    }

    func testShareCardScenarioCodeIsStableAndSelectionAware() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let selected = try XCTUnwrap(scenario.options.last)

        let promptContent = WhatToPlayShareCard.content(for: scenario)
        let repeatedPromptContent = WhatToPlayShareCard.content(for: scenario)
        let reviewedContent = WhatToPlayShareCard.content(for: scenario, selectedOption: selected)
        let modeToken = scenarioModeToken(for: scenario)

        XCTAssertEqual(promptContent.scenarioCode, repeatedPromptContent.scenarioCode)
        XCTAssertEqual(
            promptContent.scenarioCode,
            "WTP-\(scenario.seed)-\(scenario.difficulty.rawValue)-\(scenario.context.focusKind.rawValue)-\(modeToken)-P"
        )
        XCTAssertEqual(
            reviewedContent.scenarioCode,
            "WTP-\(scenario.seed)-\(scenario.difficulty.rawValue)-\(scenario.context.focusKind.rawValue)-\(modeToken)-C\(selected.card.suit.ordinal)\(selected.card.rank.ordinal)"
        )
        XCTAssertNotEqual(promptContent.scenarioCode, reviewedContent.scenarioCode)
        XCTAssertTrue(WhatToPlayShareCard.text(for: scenario).contains(promptContent.scenarioCode))
        XCTAssertTrue(WhatToPlayShareCard.text(for: scenario, selectedOption: selected).contains(reviewedContent.scenarioCode))
    }

    func testShareCardContentSeparatesVisualSections() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let content = WhatToPlayShareCard.content(for: scenario)

        XCTAssertEqual(content.title, "وش تلعب؟".localized)
        XCTAssertEqual(content.contextLine, "\("أنت تلعب".localized) \(content.mode)")
        XCTAssertFalse(content.scenarioCode.isEmpty)
        XCTAssertEqual(content.mode.isEmpty, false)
        XCTAssertEqual(content.difficulty.isEmpty, false)
        XCTAssertEqual(content.focus.isEmpty, false)
        XCTAssertEqual(content.trickProgress, "\(scenario.state.completedTricks.count + 1) \("من".localized) 8")
        XCTAssertEqual(content.scoreLine, shareScoreText(for: scenario))
        XCTAssertEqual(content.turnContextLine, turnContextText(for: scenario))
        XCTAssertEqual(content.legalOptionCount, scenario.context.legalOptionCount)
        XCTAssertEqual(content.playedCardCount, scenario.context.playedCardCount)
        XCTAssertEqual(content.legalCardNames, scenario.options.sorted {
            if $0.card.suit.ordinal != $1.card.suit.ordinal {
                return $0.card.suit.ordinal < $1.card.suit.ordinal
            }
            return $0.card.rank.ordinal < $1.card.rank.ordinal
        }.map { $0.card.accessibilityName })
        let checklist = WhatToPlayStatsAnalyzer.preDecisionChecklist(for: scenario)
        XCTAssertEqual(content.checklistTitle, checklist.title)
        XCTAssertEqual(content.checklistItems, checklist.items)
    }

    func testShareCardScenarioCodeCarriesHokumTrumpSuit() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(
            seed: 2026,
            difficulty: .easy,
            preferredFocus: .trumpPressure,
            preferredMode: .hokum,
            preferredTrumpSuit: .spades
        )

        let content = WhatToPlayShareCard.content(for: scenario)
        let parsed = WhatToPlayScenarioCode.parse(content.scenarioCode)

        XCTAssertEqual(parsed?.gameMode, .hokum)
        XCTAssertEqual(parsed?.trumpSuit, .spades)
        XCTAssertTrue(content.scenarioCode.contains("-hokum.\(Suit.spades.ordinal)-"))
    }

    func testShareTextIncludesPreDecisionChecklistWithoutRevealingAnswer() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let checklist = WhatToPlayStatsAnalyzer.preDecisionChecklist(for: scenario)
        let best = try XCTUnwrap(scenario.bestOption)
        let text = WhatToPlayShareCard.text(for: scenario)

        XCTAssertTrue(text.contains(checklist.title))
        for item in checklist.items {
            XCTAssertTrue(text.contains(item))
        }
        XCTAssertFalse(text.contains("\("أفضل ورقة".localized): \(best.card.accessibilityName)"))
    }

    func testShareTextIncludesBlockedCardsWithValidatorReasons() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(
            seed: 2026,
            difficulty: .easy,
            preferredFocus: .followSuit
        )
        let blocked = try XCTUnwrap(scenario.blockedCards.first)
        let text = WhatToPlayShareCard.text(for: scenario)
        let reason = RuleExplanationFormatter.illegalMoveExplanation(
            for: blocked.reason,
            trumpSuit: scenario.state.trumpSuit
        )

        XCTAssertTrue(text.contains("\("الأوراق الممنوعة".localized):"))
        XCTAssertTrue(text.contains("- \(blocked.card.accessibilityName): \(reason)"))
        XCTAssertFalse(text.contains("\("أفضل ورقة".localized):"))
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
        XCTAssertFalse(text.contains("ثقة أفضل ورقة".localized))
    }

    func testShareTextIncludesAnswerReviewAfterSelection() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let selected = try XCTUnwrap(scenario.options.last)
        let best = try XCTUnwrap(scenario.bestOption)
        let secondBest = try XCTUnwrap(scenario.secondBestOption)
        let bestSimulation = try XCTUnwrap(WhatToPlayOptionComparison.bestSimulationOption(scenario.options))
        let text = WhatToPlayShareCard.text(for: scenario, selectedOption: selected)

        XCTAssertTrue(text.contains("مراجعة القرار".localized))
        XCTAssertTrue(text.contains("\("اختياري".localized): \(selected.card.accessibilityName)"))
        XCTAssertTrue(text.contains("\("أفضل ورقة".localized): \(best.card.accessibilityName)"))
        XCTAssertTrue(text.contains("\("أثر الأفضل".localized): \(best.expectedImpact >= 0 ? "+\(best.expectedImpact)" : "\(best.expectedImpact)")"))
        XCTAssertTrue(text.contains("\("ثاني أفضل".localized): \(secondBest.card.accessibilityName)"))
        XCTAssertTrue(text.contains("\("أثر ثاني أفضل".localized): \(secondBest.expectedImpact >= 0 ? "+\(secondBest.expectedImpact)" : "\(secondBest.expectedImpact)")"))
        XCTAssertTrue(text.contains("\("ترتيب اختياري".localized): \(selected.rank)"))
        XCTAssertTrue(text.contains("\("نقاط متوقعة ضائعة".localized): \(max(0, best.expectedImpact - selected.expectedImpact))"))
        XCTAssertTrue(text.contains("\("نقاط محاكاة ضائعة".localized): \(max(0, bestSimulation.projectedTeamPoints - selected.projectedTeamPoints))"))
        let severity = WhatToPlayStatsAnalyzer.valueLossSeverity(
            for: max(
                max(0, best.expectedImpact - selected.expectedImpact),
                max(0, bestSimulation.projectedTeamPoints - selected.projectedTeamPoints)
            )
        )
        XCTAssertTrue(text.contains("\("شدة خسارة القيمة".localized): \(WhatToPlayStatsAnalyzer.valueLossTitle(for: severity))"))
        let confidence = try XCTUnwrap(
            WhatToPlayOptionComparison.summary(for: scenario, selectedCard: selected.card).bestMoveConfidence
        )
        XCTAssertTrue(text.contains("\("ثقة أفضل ورقة".localized): \(confidence.title)"))
        XCTAssertTrue(text.contains(confidence.detail))
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
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).decisionQualityDetail)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).bestMoveConfidenceTitle)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).bestMoveConfidenceDetail)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).nextActionTitle)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).nextActionDetail)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).selectedSimulationSummary)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).selectedSimulationTeamResult)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).selectedSimulationTrickPoints)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).selectedProjectedTeamPoints)
        XCTAssertFalse(WhatToPlayShareCard.content(for: scenario).checklistItems.isEmpty)
        XCTAssertEqual(
            WhatToPlayShareCard.content(for: scenario).blockedCards.count,
            scenario.blockedCards.count
        )

        let reviewed = WhatToPlayShareCard.content(for: scenario, selectedOption: selected)
        let secondBest = try XCTUnwrap(scenario.secondBestOption)
        let bestSimulation = try XCTUnwrap(WhatToPlayOptionComparison.bestSimulationOption(scenario.options))
        let lostProjectedTeamPoints = max(0, bestSimulation.projectedTeamPoints - selected.projectedTeamPoints)

        XCTAssertTrue(reviewed.includesAnswerReview)
        XCTAssertEqual(reviewed.subtitle, "مراجعة قرار من Baloot Hub".localized)
        XCTAssertEqual(reviewed.selectedCardName, selected.card.accessibilityName)
        XCTAssertEqual(reviewed.bestCardName, selected.card.accessibilityName)
        XCTAssertEqual(reviewed.bestExpectedImpact, selected.expectedImpact)
        XCTAssertEqual(reviewed.secondBestCardName, secondBest.card.accessibilityName)
        XCTAssertEqual(reviewed.secondBestExpectedImpact, secondBest.expectedImpact)
        XCTAssertEqual(reviewed.lostExpectedPoints, 0)
        XCTAssertEqual(reviewed.lostProjectedTeamPoints, lostProjectedTeamPoints)
        XCTAssertEqual(reviewed.lostAgainstSecondBestPoints, max(0, secondBest.expectedImpact - selected.expectedImpact))
        XCTAssertEqual(
            reviewed.valueLossTitle,
            WhatToPlayStatsAnalyzer.valueLossTitle(
                for: WhatToPlayStatsAnalyzer.valueLossSeverity(for: lostProjectedTeamPoints)
            )
        )
        XCTAssertEqual(reviewed.decisionQualityTitle, "مطابق للخبير".localized)
        XCTAssertEqual(reviewed.decisionQualityDetail, WhatToPlayDecisionQuality.expertMatch.detail)
        let confidence = try XCTUnwrap(
            WhatToPlayOptionComparison.summary(for: scenario, selectedCard: selected.card).bestMoveConfidence
        )
        XCTAssertEqual(reviewed.bestMoveConfidenceTitle, confidence.title)
        XCTAssertEqual(reviewed.bestMoveConfidenceDetail, confidence.detail)
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
        XCTAssertNotNil(content.decisionQualityDetail)
        XCTAssertNotNil(content.nextActionTitle)
        XCTAssertNotNil(content.nextActionDetail)
        XCTAssertTrue(text.contains("\("تقييم القرار".localized): \(try XCTUnwrap(content.decisionQualityTitle))"))
        XCTAssertTrue(text.contains(try XCTUnwrap(content.decisionQualityDetail)))
        XCTAssertTrue(text.contains("\("الإجراء التالي".localized): \(try XCTUnwrap(content.nextActionTitle))"))
        XCTAssertTrue(text.contains(try XCTUnwrap(content.nextActionDetail)))
    }

    func testShareDecisionQualityUsesProjectedLossWhenLarger() throws {
        let (scenario, selected) = try simulationLossShareSelection()
        let best = try XCTUnwrap(scenario.bestOption)
        let bestSimulation = try XCTUnwrap(WhatToPlayOptionComparison.bestSimulationOption(scenario.options))

        let content = WhatToPlayShareCard.content(for: scenario, selectedOption: selected)
        let text = WhatToPlayShareCard.text(for: scenario, selectedOption: selected)

        XCTAssertLessThanOrEqual(max(0, best.expectedImpact - selected.expectedImpact), 2)
        XCTAssertGreaterThanOrEqual(max(0, bestSimulation.projectedTeamPoints - selected.projectedTeamPoints), 9)
        XCTAssertEqual(content.lostProjectedTeamPoints, max(0, bestSimulation.projectedTeamPoints - selected.projectedTeamPoints))
        XCTAssertEqual(content.decisionQualityTitle, "قرار مكلف".localized)
        XCTAssertEqual(content.decisionQualityDetail, WhatToPlayDecisionQuality.costly.detail)
        XCTAssertEqual(content.valueLossTitle, "خسارة قيمة عالية".localized)
        XCTAssertTrue(text.contains("\("نقاط محاكاة ضائعة".localized): \(try XCTUnwrap(content.lostProjectedTeamPoints))"))
        XCTAssertTrue(text.contains("\("تقييم القرار".localized): \("قرار مكلف".localized)"))
        XCTAssertTrue(text.contains(WhatToPlayDecisionQuality.costly.detail))
        XCTAssertTrue(text.contains("\("شدة خسارة القيمة".localized): \("خسارة قيمة عالية".localized)"))
    }

    func testShareCardImageFileNameUsesFullScenarioCode() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(
            seed: 2026,
            difficulty: .easy,
            preferredFocus: .trumpPressure,
            preferredMode: .hokum,
            preferredTrumpSuit: .spades
        )
        let selected = try XCTUnwrap(scenario.options.last)

        let promptFileName = WhatToPlayShareCardImageRenderer.fileName(for: scenario, selectedOption: nil)
        let reviewedFileName = WhatToPlayShareCardImageRenderer.fileName(for: scenario, selectedOption: selected)
        let promptCode = WhatToPlayShareCard.content(for: scenario).scenarioCode
        let reviewedCode = WhatToPlayShareCard.content(for: scenario, selectedOption: selected).scenarioCode

        XCTAssertEqual(promptFileName, "baloothub-what-to-play-\(promptCode).png")
        XCTAssertEqual(reviewedFileName, "baloothub-what-to-play-\(reviewedCode).png")
        XCTAssertTrue(promptFileName.contains("-hokum.\(Suit.spades.ordinal)-P"))
        XCTAssertTrue(reviewedFileName.contains("-hokum.\(Suit.spades.ordinal)-C\(selected.card.suit.ordinal)\(selected.card.rank.ordinal)"))
        XCTAssertNotEqual(promptFileName, reviewedFileName)
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

    @MainActor
    func testShareCardImageRendererWritesReviewedDecisionPNGFile() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)
        let selected = try XCTUnwrap(scenario.options.last)
        let content = WhatToPlayShareCard.content(for: scenario, selectedOption: selected)

        XCTAssertTrue(content.includesAnswerReview)
        XCTAssertNotNil(content.selectedCardName)
        XCTAssertNotNil(content.bestCardName)

        let url = try WhatToPlayShareCardImageRenderer.render(
            content: content,
            fileName: "baloothub-share-card-review-test.png",
            scale: 2
        )
        defer { try? FileManager.default.removeItem(at: url) }

        let data = try Data(contentsOf: url)
        let pngSignature = Data([0x89, 0x50, 0x4E, 0x47])

        XCTAssertGreaterThan(data.count, 1024)
        XCTAssertEqual(data.prefix(4), pngSignature)
    }

    func testHandAnalysisShareSummaryIsDeterministic() {
        let analysis = HandAnalyzer.analyze(hand: strongHokumHand())

        XCTAssertEqual(
            HandAnalysisShareSummary.text(for: analysis),
            HandAnalysisShareSummary.text(for: analysis)
        )
    }

    func testHandAnalysisShareSummaryIncludesRecommendationProjectsAndAdvice() {
        let analysis = HandAnalyzer.analyze(hand: strongHokumHand())
        let text = HandAnalysisShareSummary.text(for: analysis)

        XCTAssertTrue(text.contains("ملخص حلّل يدي".localized))
        XCTAssertTrue(text.contains("\("اليد".localized):"))
        XCTAssertTrue(text.contains("\("التوصية".localized):"))
        XCTAssertTrue(text.contains("\("قوة اليد".localized): \(analysis.strengthPercent)%"))
        XCTAssertTrue(text.contains("\("احتمال الشراء".localized): \(analysis.bidConfidencePercent)%"))
        XCTAssertTrue(text.contains("\("مقارنة الصن والحكم".localized): \(analysis.modeComparisonTitle)"))
        XCTAssertTrue(text.contains(analysis.modeComparisonDetail))
        XCTAssertTrue(text.contains("\("ترتيب خيارات المزايدة".localized):"))
        XCTAssertTrue(text.contains("\("موصى به".localized)"))
        XCTAssertTrue(text.contains("\("الهامش".localized)"))
        XCTAssertTrue(text.contains("\("نقاط القوة".localized):"))
        XCTAssertTrue(text.contains("\("نقاط الضعف".localized):"))
        XCTAssertTrue(text.contains("\("النصيحة التكتيكية".localized):"))
        XCTAssertTrue(text.contains(analysis.tacticalAdvice))
        for card in analysis.hand {
            XCTAssertTrue(text.contains(card.accessibilityName))
        }
        if !analysis.projects.isEmpty {
            XCTAssertTrue(text.contains("\("المشاريع".localized): \(analysis.totalProjectPoints)"))
        }
    }

    private func contentMode(for scenario: WhatToPlayScenario) -> String {
        WhatToPlayShareCard.content(for: scenario).mode
    }

    private func scenarioModeToken(for scenario: WhatToPlayScenario) -> String {
        guard let mode = scenario.state.mode else { return "auto" }
        switch mode {
        case .sun:
            return "sun"
        case .hokum:
            if let trumpSuit = scenario.state.trumpSuit {
                return "hokum.\(trumpSuit.ordinal)"
            } else {
                return "hokum"
            }
        }
    }

    private func shareScoreText(for scenario: WhatToPlayScenario) -> String {
        let margin = scenario.context.playerTeamPointMargin
        let marginPrefix = margin > 0 ? "+" : ""
        return "\("فريقنا".localized) \(scenario.context.playerTeamTrickPoints) · \("الخصم".localized) \(scenario.context.opponentTeamTrickPoints) · \(marginPrefix)\(margin)"
    }

    private func turnContextText(for scenario: WhatToPlayScenario) -> String {
        if scenario.context.isLeading {
            return "أنت تفتتح الأكلة".localized
        }
        if let requiredSuit = scenario.context.requiredSuit {
            return "\("اللون المطلوب".localized): \(requiredSuit.arabicName)"
        }
        return "الأوراق على الطاولة".localized
    }

    private func strongHokumHand() -> [PlayingCard] {
        [
            PlayingCard(suit: .spades, rank: .jack),
            PlayingCard(suit: .spades, rank: .nine),
            PlayingCard(suit: .spades, rank: .ace),
            PlayingCard(suit: .spades, rank: .ten),
            PlayingCard(suit: .spades, rank: .king),
            PlayingCard(suit: .hearts, rank: .ace),
            PlayingCard(suit: .hearts, rank: .ten),
            PlayingCard(suit: .clubs, rank: .ace)
        ]
    }

    private func costlyShareSelection() throws -> (WhatToPlayScenario, WhatToPlayOption) {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 3, difficulty: .hard)
        let option = try XCTUnwrap(scenario.options.first { option in
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
        })
        return (scenario, option)
    }

    private func simulationLossShareSelection() throws -> (WhatToPlayScenario, WhatToPlayOption) {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 1, difficulty: .hard)
        let best = try XCTUnwrap(scenario.bestOption)
        let bestSimulation = try XCTUnwrap(WhatToPlayOptionComparison.bestSimulationOption(scenario.options))
        let option = try XCTUnwrap(scenario.options.first {
            $0.card != best.card
                && max(0, best.expectedImpact - $0.expectedImpact) <= 2
                && max(0, bestSimulation.projectedTeamPoints - $0.projectedTeamPoints) >= 9
        })
        return (scenario, option)
    }
}
