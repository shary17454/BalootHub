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
        XCTAssertEqual(content.legalCards.map(\.cardName), content.legalCardNames)
        XCTAssertTrue(content.legalCards.allSatisfy { $0.expectedImpact == nil })
        XCTAssertTrue(content.legalCards.allSatisfy { $0.projectedTeamPoints == nil })
        XCTAssertTrue(content.legalCards.allSatisfy { $0.expectedImprovement == nil })
        XCTAssertTrue(content.legalCards.allSatisfy { $0.expectedImprovementSourceTitle == nil })
        XCTAssertFalse(content.legalCards.contains { $0.isExpertChoice })
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
        XCTAssertFalse(text.contains("أفضل محاكاة".localized))
        XCTAssertFalse(text.contains("أفضل نتيجة محاكاة".localized))
        XCTAssertFalse(text.contains("ثاني محاكاة".localized))
        XCTAssertFalse(text.contains("ثاني نتيجة محاكاة".localized))
        XCTAssertFalse(text.contains("فاقد ثاني محاكاة".localized))
        XCTAssertFalse(text.contains("ثقة أفضل ورقة".localized))
        XCTAssertFalse(text.contains("سبب أفضل ورقة".localized))
        XCTAssertFalse(text.contains("سبب ثاني أفضل".localized))
    }

    func testShareTextIncludesAnswerReviewAfterSelection() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let selected = try XCTUnwrap(scenario.options.last)
        let best = try XCTUnwrap(scenario.bestOption)
        let secondBest = try XCTUnwrap(scenario.secondBestOption)
        let bestSimulation = try XCTUnwrap(WhatToPlayTrainer.bestProjectedOption(in: scenario.options))
        let secondBestSimulation = try XCTUnwrap(WhatToPlayTrainer.secondBestProjectedOption(in: scenario.options))
        let text = WhatToPlayShareCard.text(for: scenario, selectedOption: selected)

        XCTAssertTrue(text.contains("مراجعة القرار".localized))
        XCTAssertTrue(text.contains("\("اختياري".localized): \(selected.card.accessibilityName)"))
        XCTAssertTrue(text.contains("\("أفضل ورقة".localized): \(best.card.accessibilityName)"))
        XCTAssertTrue(text.contains("\("أثر الأفضل".localized): \(best.expectedImpact >= 0 ? "+\(best.expectedImpact)" : "\(best.expectedImpact)")"))
        XCTAssertTrue(text.contains("\("سبب أفضل ورقة".localized): \(best.explanation)"))
        XCTAssertTrue(text.contains("\("ثاني أفضل".localized): \(secondBest.card.accessibilityName)"))
        XCTAssertTrue(text.contains("\("أثر ثاني أفضل".localized): \(secondBest.expectedImpact >= 0 ? "+\(secondBest.expectedImpact)" : "\(secondBest.expectedImpact)")"))
        XCTAssertTrue(text.contains("\("سبب ثاني أفضل".localized): \(secondBest.explanation)"))
        XCTAssertTrue(text.contains("\("أفضل محاكاة".localized): \(bestSimulation.card.accessibilityName)"))
        XCTAssertTrue(text.contains("\("أفضل نتيجة محاكاة".localized): \(bestSimulation.projectedTeamPoints)"))
        XCTAssertTrue(text.contains("\("ثاني محاكاة".localized): \(secondBestSimulation.card.accessibilityName)"))
        XCTAssertTrue(text.contains("\("ثاني نتيجة محاكاة".localized): \(secondBestSimulation.projectedTeamPoints)"))
        XCTAssertTrue(text.contains("\("فاقد ثاني محاكاة".localized): \(max(0, secondBestSimulation.projectedTeamPoints - selected.projectedTeamPoints))"))
        for option in scenario.options {
            let improvement = WhatToPlayOptionComparison.expectedImprovement(for: option, in: scenario)
            let line = WhatToPlayShareCard.legalCardText(
                .init(
                    cardName: option.card.accessibilityName,
                    expectedImpact: option.expectedImpact,
                    projectedTeamPoints: option.projectedTeamPoints,
                    expectedImprovement: improvement.points > 0
                        ? improvement.points
                        : nil,
                    expectedImprovementSourceTitle: improvement.points > 0
                        ? WhatToPlayStatsAnalyzer.expectedImprovementSourceTitle(
                            for: improvement.source
                        )
                        : nil,
                    isExpertChoice: option.isExpertChoice
                )
            )
            XCTAssertTrue(text.contains("- \(line)"))
        }
        XCTAssertTrue(text.contains("\("ترتيب اختياري".localized): \(selected.rank)"))
        XCTAssertTrue(text.contains("\("نقاط متوقعة ضائعة".localized): \(max(0, best.expectedImpact - selected.expectedImpact))"))
        XCTAssertTrue(text.contains("\("نقاط محاكاة ضائعة".localized): \(max(0, bestSimulation.projectedTeamPoints - selected.projectedTeamPoints))"))
        let severity = WhatToPlayStatsAnalyzer.valueLossSeverity(
            lostExpectedPoints: max(0, best.expectedImpact - selected.expectedImpact),
            lostProjectedTeamPoints: max(0, bestSimulation.projectedTeamPoints - selected.projectedTeamPoints),
            lostProjectedAgainstSecondBestPoints: max(0, secondBestSimulation.projectedTeamPoints - selected.projectedTeamPoints)
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
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).bestMoveRationale)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).secondBestExpectedImpact)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).secondBestMoveRationale)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).bestSimulationCardName)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).bestProjectedTeamPoints)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).secondBestSimulationCardName)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).secondBestProjectedTeamPoints)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).lostProjectedAgainstSecondBestPoints)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).lostAgainstSecondBestPoints)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).lostProjectedTeamPoints)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).valueLossTitle)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).decisionQualityTitle)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).decisionQualityDetail)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).bestMoveConfidenceTitle)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).bestMoveConfidenceDetail)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).nextActionTitle)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).nextActionDetail)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).nextActionExpectedImprovement)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).nextActionExpectedImprovementSourceTitle)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).retryPromptTitle)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).retryPromptDetail)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).retryPromptRecommendedCardName)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).retryPromptExpectedImprovement)
        XCTAssertNil(WhatToPlayShareCard.content(for: scenario).retryPromptExpectedImprovementSourceTitle)
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
        let review = WhatToPlayTrainer.choiceReview(in: scenario, selectedCard: selected.card)
        let secondBest = try XCTUnwrap(review.secondBestOption)
        let lostExpectedPoints = try XCTUnwrap(review.selectedLostExpectedPoints)
        let lostProjectedTeamPoints = try XCTUnwrap(review.selectedLostProjectedTeamPoints)

        XCTAssertTrue(reviewed.includesAnswerReview)
        XCTAssertEqual(reviewed.subtitle, "مراجعة قرار من Baloot Hub".localized)
        XCTAssertEqual(reviewed.selectedCardName, selected.card.accessibilityName)
        XCTAssertEqual(reviewed.bestCardName, review.bestOption?.card.accessibilityName)
        XCTAssertEqual(reviewed.bestExpectedImpact, review.bestOption?.expectedImpact)
        XCTAssertEqual(reviewed.bestMoveRationale, review.bestOption?.explanation)
        XCTAssertEqual(reviewed.secondBestCardName, secondBest.card.accessibilityName)
        XCTAssertEqual(reviewed.secondBestExpectedImpact, secondBest.expectedImpact)
        XCTAssertEqual(reviewed.secondBestMoveRationale, secondBest.explanation)
        XCTAssertEqual(reviewed.bestSimulationCardName, review.bestProjectedOption?.card.accessibilityName)
        XCTAssertEqual(reviewed.bestProjectedTeamPoints, review.bestProjectedOption?.projectedTeamPoints)
        XCTAssertEqual(reviewed.secondBestSimulationCardName, review.secondBestProjectedOption?.card.accessibilityName)
        XCTAssertEqual(reviewed.secondBestProjectedTeamPoints, review.secondBestProjectedOption?.projectedTeamPoints)
        XCTAssertEqual(
            reviewed.lostProjectedAgainstSecondBestPoints,
            review.secondBestProjectedOption.map { max(0, $0.projectedTeamPoints - selected.projectedTeamPoints) }
        )
        XCTAssertEqual(reviewed.lostExpectedPoints, lostExpectedPoints)
        XCTAssertEqual(reviewed.lostProjectedTeamPoints, lostProjectedTeamPoints)
        XCTAssertEqual(reviewed.lostAgainstSecondBestPoints, max(0, secondBest.expectedImpact - selected.expectedImpact))
        XCTAssertEqual(
            reviewed.valueLossTitle,
            WhatToPlayStatsAnalyzer.valueLossTitle(
                for: WhatToPlayStatsAnalyzer.valueLossSeverity(for: lostProjectedTeamPoints)
            )
        )
        XCTAssertEqual(reviewed.decisionQualityTitle, review.decisionQuality?.title)
        XCTAssertEqual(reviewed.decisionQualityDetail, review.decisionQuality?.detail)
        let confidence = try XCTUnwrap(
            WhatToPlayOptionComparison.summary(for: scenario, selectedCard: selected.card).bestMoveConfidence
        )
        XCTAssertEqual(reviewed.bestMoveConfidenceTitle, confidence.title)
        XCTAssertEqual(reviewed.bestMoveConfidenceDetail, confidence.detail)
        XCTAssertEqual(reviewed.nextActionTitle, "ثبّت القراءة".localized)
        XCTAssertTrue(reviewed.nextActionDetail?.contains(selected.card.accessibilityName) ?? false)
        XCTAssertNil(reviewed.nextActionExpectedImprovement)
        XCTAssertNil(reviewed.nextActionExpectedImprovementSourceTitle)
        XCTAssertNil(reviewed.retryPromptTitle)
        XCTAssertNil(reviewed.retryPromptDetail)
        XCTAssertNil(reviewed.retryPromptRecommendedCardName)
        XCTAssertNil(reviewed.retryPromptExpectedImprovement)
        XCTAssertNil(reviewed.retryPromptExpectedImprovementSourceTitle)
        XCTAssertEqual(reviewed.selectedImpact, selected.expectedImpact)
        XCTAssertEqual(reviewed.selectedImpactDetail, WhatToPlayImpactFormatter.detail(for: selected.impactBreakdown))
        XCTAssertEqual(reviewed.selectedProjectedTeamPoints, selected.projectedTeamPoints)
        let sortedOptions = scenario.options.sorted {
            if $0.card.suit.ordinal != $1.card.suit.ordinal {
                return $0.card.suit.ordinal < $1.card.suit.ordinal
            }
            return $0.card.rank.ordinal < $1.card.rank.ordinal
        }
        XCTAssertEqual(reviewed.legalCards.map(\.cardName), sortedOptions.map { $0.card.accessibilityName })
        XCTAssertEqual(reviewed.legalCards.map(\.expectedImpact), sortedOptions.map { Optional($0.expectedImpact) })
        XCTAssertEqual(reviewed.legalCards.map(\.projectedTeamPoints), sortedOptions.map { Optional($0.projectedTeamPoints) })
        XCTAssertEqual(
            reviewed.legalCards.map(\.expectedImprovement),
            sortedOptions.map {
                let improvement = WhatToPlayOptionComparison.expectedImprovement(for: $0, in: scenario)
                return improvement.points > 0 ? improvement.points : nil
            }
        )
        XCTAssertEqual(
            reviewed.legalCards.map(\.expectedImprovementSourceTitle),
            sortedOptions.map {
                let improvement = WhatToPlayOptionComparison.expectedImprovement(for: $0, in: scenario)
                return improvement.points > 0
                    ? WhatToPlayStatsAnalyzer.expectedImprovementSourceTitle(for: improvement.source)
                    : nil
            }
        )
        XCTAssertEqual(reviewed.legalCards.map(\.isExpertChoice), sortedOptions.map(\.isExpertChoice))
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
        let reason = WhatToPlayTacticalReviewReasonMetrics.classify(
            expectedImpact: selected.expectedImpact,
            impactBreakdown: selected.impactBreakdown
        )

        let content = WhatToPlayShareCard.content(for: scenario, selectedOption: selected)
        let text = WhatToPlayShareCard.text(for: scenario, selectedOption: selected)

        XCTAssertNotNil(reason.category)
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
        let action = try XCTUnwrap(WhatToPlayStatsAnalyzer.nextDecisionAction(for: selected, in: scenario))
        let content = WhatToPlayShareCard.content(for: scenario, selectedOption: selected)
        let text = WhatToPlayShareCard.text(for: scenario, selectedOption: selected)

        XCTAssertNotNil(content.decisionQualityTitle)
        XCTAssertNotNil(content.decisionQualityDetail)
        XCTAssertNotNil(content.nextActionTitle)
        XCTAssertNotNil(content.nextActionDetail)
        XCTAssertEqual(content.nextActionExpectedImprovement, action.expectedImprovement > 0 ? action.expectedImprovement : nil)
        XCTAssertEqual(
            content.nextActionExpectedImprovementSourceTitle,
            action.expectedImprovementSource.map(WhatToPlayStatsAnalyzer.expectedImprovementSourceTitle)
        )
        XCTAssertTrue(text.contains("\("تقييم القرار".localized): \(try XCTUnwrap(content.decisionQualityTitle))"))
        XCTAssertTrue(text.contains(try XCTUnwrap(content.decisionQualityDetail)))
        XCTAssertTrue(text.contains("\("الإجراء التالي".localized): \(try XCTUnwrap(content.nextActionTitle))"))
        XCTAssertTrue(text.contains(try XCTUnwrap(content.nextActionDetail)))
        if action.expectedImprovement > 0 {
            XCTAssertTrue(text.contains("\("تحسن متوقع".localized): +\(action.expectedImprovement)"))
        }
        if let source = action.expectedImprovementSource {
            XCTAssertTrue(text.contains("\("مصدر التحسن".localized): \(WhatToPlayStatsAnalyzer.expectedImprovementSourceTitle(for: source))"))
        }
    }

    func testShareTextIncludesRetryPromptAfterCostlySelection() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)
        let selected = try XCTUnwrap(scenario.options.first {
            WhatToPlayStatsAnalyzer.retryPrompt(for: $0, in: scenario) != nil
        })
        let prompt = try XCTUnwrap(WhatToPlayStatsAnalyzer.retryPrompt(for: selected, in: scenario))

        let content = WhatToPlayShareCard.content(for: scenario, selectedOption: selected)
        let text = WhatToPlayShareCard.text(for: scenario, selectedOption: selected)

        XCTAssertEqual(content.retryPromptTitle, prompt.title)
        XCTAssertEqual(content.retryPromptDetail, prompt.detail)
        XCTAssertEqual(content.retryPromptRecommendedCardName, prompt.recommendedCard?.accessibilityName)
        XCTAssertEqual(content.retryPromptExpectedImprovement, prompt.expectedImprovement > 0 ? prompt.expectedImprovement : nil)
        XCTAssertEqual(
            content.retryPromptExpectedImprovementSourceTitle,
            prompt.expectedImprovement > 0
                ? prompt.expectedImprovementSource.map(WhatToPlayStatsAnalyzer.expectedImprovementSourceTitle)
                : nil
        )
        XCTAssertTrue(text.contains("\("تدريب الإعادة".localized): \(prompt.title)"))
        XCTAssertTrue(text.contains(prompt.detail))
        if let recommendedCard = prompt.recommendedCard {
            XCTAssertTrue(text.contains("\("جرّب الورقة".localized): \(recommendedCard.accessibilityName)"))
        }
        XCTAssertTrue(text.contains("\("تحسن متوقع".localized): +\(prompt.expectedImprovement)"))
        if let source = prompt.expectedImprovementSource {
            XCTAssertTrue(text.contains("\("مصدر التحسن".localized): \(WhatToPlayStatsAnalyzer.expectedImprovementSourceTitle(for: source))"))
        }
    }

    func testShareDecisionQualityUsesProjectedLossWhenLarger() throws {
        let (scenario, selected) = try simulationLossShareSelection()
        let review = WhatToPlayTrainer.choiceReview(in: scenario, selectedCard: selected.card)
        let lostExpectedPoints = try XCTUnwrap(review.selectedLostExpectedPoints)
        let lostProjectedTeamPoints = try XCTUnwrap(review.selectedLostProjectedTeamPoints)

        let content = WhatToPlayShareCard.content(for: scenario, selectedOption: selected)
        let text = WhatToPlayShareCard.text(for: scenario, selectedOption: selected)

        XCTAssertLessThanOrEqual(lostExpectedPoints, 2)
        XCTAssertGreaterThanOrEqual(lostProjectedTeamPoints, 9)
        XCTAssertEqual(content.lostProjectedTeamPoints, lostProjectedTeamPoints)
        XCTAssertEqual(content.decisionQualityTitle, review.decisionQuality?.title)
        XCTAssertEqual(content.decisionQualityDetail, review.decisionQuality?.detail)
        XCTAssertEqual(content.valueLossTitle, "خسارة قيمة عالية".localized)
        XCTAssertTrue(text.contains("\("نقاط محاكاة ضائعة".localized): \(try XCTUnwrap(content.lostProjectedTeamPoints))"))
        XCTAssertTrue(text.contains("\("تقييم القرار".localized): \(try XCTUnwrap(review.decisionQuality?.title))"))
        XCTAssertTrue(text.contains(try XCTUnwrap(review.decisionQuality?.detail)))
        XCTAssertTrue(text.contains("\("شدة خسارة القيمة".localized): \("خسارة قيمة عالية".localized)"))
    }

    func testReviewShareTextContainsReplayCodeAndDecisionSummary() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(
            seed: 45,
            difficulty: .hard,
            preferredFocus: .trumpPressure,
            preferredMode: .hokum,
            preferredTrumpSuit: .spades
        )
        let reviewItem = try XCTUnwrap(
            scenario.options.lazy.compactMap { option -> WhatToPlayReviewItem? in
                guard !option.isExpertChoice,
                      let attempt = WhatToPlayAttemptFactory.makeAttempt(scenario: scenario, evaluated: option),
                      let item = WhatToPlayStatsAnalyzer.reviewQueue(for: [attempt], limit: 1).first
                else { return nil }
                let improvement = WhatToPlayExpectedImprovementMetrics.calculate(
                    lostExpectedPoints: item.lostExpectedPoints,
                    lostProjectedTeamPoints: item.lostProjectedTeamPoints,
                    lostProjectedAgainstSecondBestPoints: item.lostProjectedAgainstSecondBestPoints
                )
                return improvement.points > 0 ? item : nil
            }.first
        )
        let improvement = WhatToPlayExpectedImprovementMetrics.calculate(
            lostExpectedPoints: reviewItem.lostExpectedPoints,
            lostProjectedTeamPoints: reviewItem.lostProjectedTeamPoints,
            lostProjectedAgainstSecondBestPoints: reviewItem.lostProjectedAgainstSecondBestPoints
        )

        let text = WhatToPlayShareCard.reviewText(for: reviewItem)

        XCTAssertTrue(text.contains("موقف للمراجعة في وش تلعب؟".localized))
        XCTAssertTrue(text.contains("\("رمز الموقف".localized): \(reviewItem.scenarioCode)"))
        XCTAssertTrue(
            text.contains("\("اختيارك".localized): \(try XCTUnwrap(reviewItem.selectedCard).accessibilityName)")
        )
        XCTAssertTrue(
            text.contains("\("أفضل ورقة".localized): \(try XCTUnwrap(reviewItem.bestCard).accessibilityName)")
        )
        XCTAssertTrue(text.contains("\("نقاط متوقعة ضائعة".localized): \(reviewItem.lostExpectedPoints)"))
        XCTAssertTrue(text.contains("\("شدة خسارة القيمة".localized): \(reviewItem.valueLossTitle)"))
        XCTAssertTrue(text.contains("\("تحسن متوقع".localized): +\(improvement.points)"))
        XCTAssertTrue(
            text.contains("\("مصدر التحسن".localized): \(WhatToPlayStatsAnalyzer.expectedImprovementSourceTitle(for: improvement.source))")
        )
        XCTAssertTrue(text.contains("\("تركيز التدريب".localized): \("ضغط الحكم".localized)"))
        XCTAssertTrue(text.contains("\("النمط".localized): \(GameMode.hokum.arabicName) \(Suit.spades.spokenName)"))
        XCTAssertTrue(text.contains("افتح مدرب وش تلعب واستورد رمز الموقف.".localized))
        XCTAssertTrue(text.contains("أعد الموقف وحاول اختيار ورقة أفضل.".localized))
    }

    func testReviewShareTextIncludesSimulationAlternativesAndOutcomeLabels() throws {
        let selected = PlayingCard(suit: .clubs, rank: .seven)
        let best = PlayingCard(suit: .spades, rank: .ace)
        let secondBest = PlayingCard(suit: .hearts, rank: .king)
        let bestSimulation = PlayingCard(suit: .diamonds, rank: .ace)
        let secondBestSimulation = PlayingCard(suit: .hearts, rank: .jack)
        let attempt = WhatToPlayAttempt(
            difficulty: .hard,
            seed: 920,
            selectedCard: selected,
            bestCard: best,
            secondBestCard: secondBest,
            bestSimulationCard: bestSimulation,
            secondBestSimulationCard: secondBestSimulation,
            isCorrect: false,
            expectedImpact: 2,
            bestExpectedImpact: 4,
            secondBestExpectedImpact: 3,
            projectedTeamPoints: 50,
            bestProjectedTeamPoints: 68,
            secondBestProjectedTeamPoints: 62,
            focusKind: .trumpPressure,
            gameMode: .hokum,
            simulation: WhatToPlayOptionSimulation(
                phaseAfterPlay: .playing,
                currentTrickCardCount: 0,
                completedTrickWinnerID: UUID(),
                completedTrickWinnerTeamID: UUID(),
                completedTrickWonByPlayerTeam: false,
                completedTrickPoints: 12,
                nextTurnPlayerID: UUID(),
                playerRemainingCards: 4,
                actionHistoryCount: 20
            )
        )
        let item = try XCTUnwrap(WhatToPlayStatsAnalyzer.reviewQueue(for: [attempt]).first)

        let text = WhatToPlayShareCard.reviewText(for: item)

        XCTAssertTrue(text.contains("\("أفضل محاكاة".localized): \(bestSimulation.accessibilityName)"))
        XCTAssertTrue(text.contains("\("أفضل نتيجة محاكاة".localized): 68"))
        XCTAssertTrue(text.contains("\("ثاني محاكاة".localized): \(secondBestSimulation.accessibilityName)"))
        XCTAssertTrue(text.contains("\("ثاني نتيجة محاكاة".localized): 62"))
        XCTAssertTrue(text.contains("\("فاقد ثاني محاكاة".localized): 12"))
        XCTAssertTrue(text.contains("\("اتجاه الأكلة".localized): \("للخصم".localized)"))
    }

    func testTrainingSessionReviewShareTextContainsRetryStatusAndReviewDetails() throws {
        let recommendedCard = PlayingCard(suit: .spades, rank: .jack)
        let review = WhatToPlayTrainingSessionReview(
            action: .continueSession,
            title: "إعادة الموقف الخاطئ".localized,
            detail: "أعد موقف 901 قبل الانتقال؛ آخر محاولة عليه كانت غير صحيحة.".localized,
            contextLine: "صعب · ضغط الحكم · حكم سباتي",
            iconName: "arrow.clockwise.circle.fill",
            replaySeed: nil,
            replayScenarioCode: "WTP-901-hard-trumpPressure-hokum.3-C37",
            nextSeed: 901,
            difficulty: .hard,
            focusKind: .trumpPressure,
            gameMode: .hokum,
            trumpSuit: .spades,
            recommendedCard: recommendedCard,
            expectedImprovement: 12,
            expectedImprovementSource: .projectedTeamPoints,
            retriesIncorrectNextSeed: true,
            statusLine: "\("إعادة محاولة".localized): 901"
        )

        let text = WhatToPlayShareCard.trainingSessionReviewText(for: review)

        XCTAssertTrue(text.contains("مراجعة جلسة وش تلعب؟".localized))
        XCTAssertTrue(text.contains(review.title))
        XCTAssertTrue(text.contains(try XCTUnwrap(review.statusLine)))
        XCTAssertTrue(text.contains(review.detail))
        XCTAssertTrue(text.contains(review.contextLine))
        XCTAssertTrue(text.contains("\("الصعوبة".localized): \("صعب".localized)"))
        XCTAssertTrue(text.contains("\("تركيز التدريب".localized): \("ضغط الحكم".localized)"))
        XCTAssertTrue(text.contains("\("النمط".localized): \(GameMode.hokum.arabicName) \(Suit.spades.spokenName)"))
        XCTAssertTrue(text.contains("\("رمز الموقف".localized): \(try XCTUnwrap(review.replayScenarioCode))"))
        XCTAssertTrue(text.contains("\("Seed".localized): 901"))
        XCTAssertTrue(text.contains("\("ورقة المراجعة".localized): \(recommendedCard.accessibilityName)"))
        XCTAssertTrue(text.contains("\("سبب ورقة المراجعة".localized): \("محاكاة الجولة".localized)"))
        XCTAssertTrue(text.contains("\("تحسن متوقع".localized): +12"))
        XCTAssertTrue(text.contains("\("مصدر التحسن".localized): \("محاكاة الجولة".localized)"))
        XCTAssertTrue(text.contains("افتح مدرب وش تلعب وأكمل جلسة التدريب.".localized))
    }

    func testTrainingSessionReviewShareTextOmitsRetryStatusWhenStartingSession() {
        let review = WhatToPlayTrainingSessionReview(
            action: .start,
            title: "ابدأ جلسة تدريب".localized,
            detail: "ابدأ بثلاث مواقف متدرجة.".localized,
            contextLine: "متوسط · التلزيم",
            iconName: "play.circle.fill",
            replaySeed: nil,
            nextSeed: 2026,
            difficulty: .medium,
            focusKind: .followSuit,
            gameMode: nil,
            trumpSuit: nil,
            recommendedCard: nil,
            expectedImprovement: 0
        )

        let text = WhatToPlayShareCard.trainingSessionReviewText(for: review)

        XCTAssertTrue(text.contains("مراجعة جلسة وش تلعب؟".localized))
        XCTAssertTrue(text.contains("\("Seed".localized): 2026"))
        XCTAssertFalse(text.contains("إعادة محاولة".localized))
        XCTAssertFalse(text.contains("رمز الموقف".localized))
        XCTAssertFalse(text.contains("ورقة المراجعة".localized))
        XCTAssertFalse(text.contains("سبب ورقة المراجعة".localized))
        XCTAssertFalse(text.contains("تحسن متوقع".localized))
    }

    func testTrainingSessionReviewShareTextIncludesMistakeStatusLine() {
        let review = WhatToPlayTrainingSessionReview(
            action: .replayMistake,
            title: "راجع الخطأ الأعلى أثرًا".localized,
            detail: "ابدأ بإعادة موقف 202".localized,
            contextLine: "متوسط · اتباع اللون",
            iconName: "exclamationmark.triangle.fill",
            replaySeed: 202,
            replayScenarioCode: "WTP-202-medium-followSuit-sun-C37",
            nextSeed: 202,
            difficulty: .medium,
            focusKind: .followSuit,
            gameMode: .sun,
            trumpSuit: nil,
            recommendedCard: PlayingCard(suit: .clubs, rank: .ace),
            secondBestCard: PlayingCard(suit: .spades, rank: .king),
            secondBestExpectedImpact: 5,
            bestSimulationCard: PlayingCard(suit: .hearts, rank: .ace),
            bestProjectedTeamPoints: 66,
            secondBestSimulationCard: PlayingCard(suit: .diamonds, rank: .queen),
            secondBestProjectedTeamPoints: 58,
            lostProjectedAgainstSecondBestPoints: 8,
            expectedImprovement: 9,
            expectedImprovementSource: .expectedPoints,
            statusLine: "\("مراجعة خطأ".localized): 202"
        )

        let text = WhatToPlayShareCard.trainingSessionReviewText(for: review)

        XCTAssertTrue(text.contains("\("مراجعة خطأ".localized): 202"))
        XCTAssertTrue(text.contains("\("رمز الموقف".localized): WTP-202-medium-followSuit-sun-C37"))
        XCTAssertTrue(text.contains("\("Seed".localized): 202"))
        XCTAssertTrue(text.contains("\("ثاني أفضل".localized): \(PlayingCard(suit: .spades, rank: .king).accessibilityName)"))
        XCTAssertTrue(text.contains("\("أثر ثاني أفضل".localized): +5"))
        XCTAssertTrue(text.contains("\("أفضل محاكاة".localized): \(PlayingCard(suit: .hearts, rank: .ace).accessibilityName)"))
        XCTAssertTrue(text.contains("\("أفضل نتيجة محاكاة".localized): 66"))
        XCTAssertTrue(text.contains("\("ثاني محاكاة".localized): \(PlayingCard(suit: .diamonds, rank: .queen).accessibilityName)"))
        XCTAssertTrue(text.contains("\("ثاني نتيجة محاكاة".localized): 58"))
        XCTAssertTrue(text.contains("\("فاقد ثاني محاكاة".localized): 8"))
    }

    func testTrainingSessionProgressShareTextContainsNextSeedGuidanceAndMetrics() throws {
        let plan = WhatToPlayStatsAnalyzer.trainingSessionPlan(for: [])
        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: [], plan: plan)

        let text = WhatToPlayShareCard.trainingSessionProgressText(for: progress)

        XCTAssertTrue(text.contains("تقدم جلسة وش تلعب؟".localized))
        XCTAssertTrue(text.contains(progress.title))
        XCTAssertTrue(text.contains(progress.detail))
        XCTAssertTrue(text.contains(try XCTUnwrap(progress.nextSeedGuidance)))
        XCTAssertTrue(text.contains("\("المكتمل".localized): 0 \("من".localized) \(progress.targetAttempts)"))
        XCTAssertTrue(text.contains("\("الدقة الحالية".localized): 0%"))
        XCTAssertTrue(text.contains("\("أفضل دقة ممكنة".localized): 100%"))
        XCTAssertTrue(text.contains("\("هدف الدقة".localized): \("غير متحقق".localized)"))
        XCTAssertTrue(text.contains("\("إجابات صحيحة مطلوبة".localized): \(progress.correctAttemptsNeededForTarget)"))
        XCTAssertTrue(text.contains("\("إمكانية هدف الدقة".localized): \("متحقق".localized)"))
        XCTAssertTrue(text.contains("\("الموقف القادم".localized): \(try XCTUnwrap(progress.nextSeed))"))
        XCTAssertTrue(text.contains("\("تقييم الجلسة".localized): \(progress.gradeTitle) · \(progress.gradePercent)/100"))
        XCTAssertTrue(text.contains("\("الخطوة التالية".localized): \(progress.nextStepTitle)"))
        XCTAssertTrue(text.contains("افتح مدرب وش تلعب وأكمل جلسة التدريب.".localized))
    }

    func testTrainingSessionProgressShareTextOmitsNextSeedAfterCompletion() {
        let plan = WhatToPlayTrainingSessionPlan(
            difficulty: .easy,
            seedBase: 700,
            scenarioCount: 1,
            targetAccuracyPercent: 100,
            targetAverageExpectedImpact: 0,
            title: "خطة اختبار",
            detail: "تفاصيل اختبار",
            successMetric: "هدف اختبار",
            iconName: "target"
        )
        let attempt = WhatToPlayAttempt(
            difficulty: .easy,
            seed: 700,
            selectedCard: PlayingCard(suit: .spades, rank: .ace),
            bestCard: PlayingCard(suit: .spades, rank: .ace),
            isCorrect: true,
            expectedImpact: 4,
            bestExpectedImpact: 4
        )
        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: [attempt], plan: plan)

        let text = WhatToPlayShareCard.trainingSessionProgressText(for: progress)

        XCTAssertEqual(progress.nextSeedState, .complete)
        XCTAssertNil(progress.nextSeed)
        XCTAssertNil(progress.nextSeedGuidance)
        XCTAssertTrue(text.contains("\("هدف الدقة".localized): \("متحقق".localized)"))
        XCTAssertTrue(text.contains("\("هدف الأثر".localized): \("متحقق".localized)"))
        XCTAssertTrue(text.contains("\("تقييم الجلسة".localized): \(progress.gradeTitle) · \(progress.gradePercent)/100"))
        XCTAssertFalse(text.contains("إجابات صحيحة مطلوبة".localized))
        XCTAssertFalse(text.contains("أثر مطلوب للوصول للهدف".localized))
        XCTAssertFalse(text.contains("الموقف القادم".localized))
        XCTAssertFalse(text.contains("إعادة الموقف".localized))
    }

    func testTrainingSessionProgressShareTextIncludesNeededImpact() {
        let plan = WhatToPlayTrainingSessionPlan(
            difficulty: .medium,
            seedBase: 860,
            scenarioCount: 4,
            targetAccuracyPercent: 50,
            targetAverageExpectedImpact: 2,
            title: "خطة اختبار",
            detail: "تفاصيل اختبار",
            successMetric: "هدف اختبار",
            iconName: "target"
        )
        let attempts = [
            WhatToPlayAttempt(
                difficulty: .medium,
                seed: 860,
                selectedCard: PlayingCard(suit: .hearts, rank: .ace),
                bestCard: PlayingCard(suit: .hearts, rank: .ace),
                isCorrect: true,
                expectedImpact: -4,
                bestExpectedImpact: 8
            ),
            WhatToPlayAttempt(
                difficulty: .medium,
                seed: 861,
                selectedCard: PlayingCard(suit: .clubs, rank: .seven),
                bestCard: PlayingCard(suit: .clubs, rank: .ace),
                isCorrect: false,
                expectedImpact: 1,
                bestExpectedImpact: 7
            )
        ]
        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        let text = WhatToPlayShareCard.trainingSessionProgressText(for: progress)

        XCTAssertEqual(progress.expectedImpactNeededForTarget, 11)
        XCTAssertEqual(progress.expectedImpactNeededPerRemainingAttempt, 6)
        XCTAssertTrue(progress.impactRecoveryHighPressure)
        XCTAssertTrue(text.contains("\("أثر مطلوب للوصول للهدف".localized): +11"))
        XCTAssertTrue(text.contains("\("أثر مطلوب لكل موقف متبقٍ".localized): +6"))
        XCTAssertTrue(text.contains("\("ضغط الأثر".localized): \("غير متحقق".localized)"))
    }

    func testTrainingSessionProgressShareTextIncludesCostlyDecisionTarget() {
        let plan = WhatToPlayTrainingSessionPlan(
            difficulty: .medium,
            seedBase: 840,
            scenarioCount: 2,
            targetAccuracyPercent: 50,
            targetAverageExpectedImpact: 0,
            maxCostlyDecisions: 0,
            title: "خطة اختبار",
            detail: "تفاصيل اختبار",
            successMetric: "هدف اختبار",
            iconName: "target"
        )
        let attempts = [
            WhatToPlayAttempt(
                difficulty: .medium,
                seed: 840,
                selectedCard: PlayingCard(suit: .spades, rank: .seven),
                bestCard: PlayingCard(suit: .clubs, rank: .ace),
                isCorrect: false,
                expectedImpact: -4,
                bestExpectedImpact: 8
            )
        ]
        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        let text = WhatToPlayShareCard.trainingSessionProgressText(for: progress)

        XCTAssertEqual(progress.costlyDecisions, 1)
        XCTAssertFalse(progress.costlyDecisionTargetMet)
        XCTAssertTrue(text.contains("\("قرارات مكلفة".localized): 1/0"))
        XCTAssertTrue(text.contains("\("هدف القرارات المكلفة".localized): \("غير متحقق".localized)"))
    }

    func testTrainingSessionProgressShareTextIncludesSessionDecisionHighlights() throws {
        let bestCard = PlayingCard(suit: .hearts, rank: .ace)
        let worstCard = PlayingCard(suit: .spades, rank: .seven)
        let plan = WhatToPlayTrainingSessionPlan(
            difficulty: .medium,
            seedBase: 800,
            scenarioCount: 2,
            targetAccuracyPercent: 50,
            targetAverageExpectedImpact: 0,
            title: "خطة اختبار",
            detail: "تفاصيل اختبار",
            successMetric: "هدف اختبار",
            iconName: "target"
        )
        let attempts = [
            WhatToPlayAttempt(
                difficulty: .medium,
                seed: 800,
                selectedCard: bestCard,
                bestCard: bestCard,
                isCorrect: true,
                expectedImpact: 7,
                bestExpectedImpact: 7
            ),
            WhatToPlayAttempt(
                difficulty: .medium,
                seed: 801,
                selectedCard: worstCard,
                bestCard: PlayingCard(suit: .clubs, rank: .ace),
                isCorrect: false,
                expectedImpact: -2,
                bestExpectedImpact: 5
            )
        ]
        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        let text = WhatToPlayShareCard.trainingSessionProgressText(for: progress)

        XCTAssertTrue(text.contains("\("أفضل قرار في الجلسة".localized): \(bestCard.accessibilityName)"))
        XCTAssertTrue(text.contains("\("أثر القرار".localized): +7"))
        XCTAssertTrue(text.contains(try XCTUnwrap(progress.bestDecisionHighlight?.scenarioCode)))
        XCTAssertTrue(text.contains("\("Seed".localized): 800"))
        XCTAssertTrue(text.contains("\("أسوأ قرار في الجلسة".localized): \(worstCard.accessibilityName)"))
        XCTAssertTrue(text.contains("\("فاقد القرار".localized): 7"))
        XCTAssertTrue(text.contains(try XCTUnwrap(progress.worstDecisionHighlight?.scenarioCode)))
        XCTAssertTrue(text.contains("\("Seed".localized): 801"))
        XCTAssertTrue(text.contains("القيمة المتوقعة".localized))
        let reviewItem = try XCTUnwrap(progress.reviewItem)
        XCTAssertTrue(text.contains("\("أهم موقف للمراجعة".localized): \(reviewItem.title)"))
        XCTAssertTrue(text.contains("\("رمز الموقف".localized): \(reviewItem.scenarioCode)"))
        XCTAssertTrue(text.contains("\("اختيارك".localized): \(try XCTUnwrap(reviewItem.selectedCard).accessibilityName)"))
        XCTAssertTrue(text.contains("\("أفضل ورقة".localized): \(try XCTUnwrap(reviewItem.bestCard).accessibilityName)"))
        XCTAssertTrue(text.contains("\("سبب المراجعة".localized): \(reviewItem.detail)"))
        let reviewCardSourceTitle = try XCTUnwrap(
            WhatToPlayStatsAnalyzer.reviewCardSourceTitle(for: reviewItem)
        )
        XCTAssertTrue(text.contains("\("سبب ورقة المراجعة".localized): \(reviewCardSourceTitle)"))
    }

    func testTrainingSessionProgressShareTextIncludesSecondSimulationLossSource() {
        let selectedCard = PlayingCard(suit: .spades, rank: .seven)
        let plan = WhatToPlayTrainingSessionPlan(
            difficulty: .medium,
            seedBase: 820,
            scenarioCount: 2,
            targetAccuracyPercent: 50,
            targetAverageExpectedImpact: 0,
            title: "خطة اختبار",
            detail: "تفاصيل اختبار",
            successMetric: "هدف اختبار",
            iconName: "target"
        )
        let attempts = [
            WhatToPlayAttempt(
                difficulty: .medium,
                seed: 820,
                selectedCard: selectedCard,
                bestCard: PlayingCard(suit: .clubs, rank: .ace),
                secondBestSimulationCard: PlayingCard(suit: .diamonds, rank: .jack),
                isCorrect: false,
                expectedImpact: 2,
                bestExpectedImpact: 4,
                projectedTeamPoints: 50,
                bestProjectedTeamPoints: 52,
                secondBestProjectedTeamPoints: 82
            )
        ]
        let progress = WhatToPlayStatsAnalyzer.trainingSessionProgress(for: attempts, plan: plan)

        let text = WhatToPlayShareCard.trainingSessionProgressText(for: progress)

        XCTAssertEqual(progress.lostProjectedAgainstSecondBestPoints, 32)
        XCTAssertEqual(progress.expectedImprovement, 32)
        XCTAssertEqual(progress.expectedImprovementSource, .projectedSecondBestPoints)
        XCTAssertTrue(text.contains("\("فاقد ثاني محاكاة".localized): 32"))
        XCTAssertTrue(text.contains("\("تحسن متوقع".localized): +32"))
        XCTAssertTrue(text.contains("\("مصدر التحسن".localized): \("ثاني أفضل محاكاة".localized)"))
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
        let selected = try XCTUnwrap(scenario.options.first {
            WhatToPlayStatsAnalyzer.retryPrompt(for: $0, in: scenario) != nil
        })
        let content = WhatToPlayShareCard.content(for: scenario, selectedOption: selected)

        XCTAssertTrue(content.includesAnswerReview)
        XCTAssertNotNil(content.selectedCardName)
        XCTAssertNotNil(content.bestCardName)
        XCTAssertNotNil(content.retryPromptTitle)
        XCTAssertNotNil(content.retryPromptDetail)

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

    @MainActor
    func testShareCardImageRendererWritesBlockedCardReasonsPNGFile() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(
            seed: 2026,
            difficulty: .easy,
            preferredFocus: .followSuit
        )
        let content = WhatToPlayShareCard.content(for: scenario)

        XCTAssertFalse(content.blockedCards.isEmpty)
        XCTAssertTrue(content.blockedCards.allSatisfy { !$0.reason.isEmpty })

        let url = try WhatToPlayShareCardImageRenderer.render(
            content: content,
            fileName: "baloothub-share-card-blocked-cards-test.png",
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
        XCTAssertTrue(text.contains("\("فارق الصن والحكم".localized): \(analysis.sunHokumScoreGap > 0 ? "+\(analysis.sunHokumScoreGap)" : "\(analysis.sunHokumScoreGap)")"))
        XCTAssertTrue(text.contains("\("تفسير الفارق".localized):"))
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
            WhatToPlayTacticalReviewReasonMetrics.classify(
                expectedImpact: option.expectedImpact,
                impactBreakdown: option.impactBreakdown
            ).category != nil
        })
        return (scenario, option)
    }

    private func simulationLossShareSelection() throws -> (WhatToPlayScenario, WhatToPlayOption) {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 1, difficulty: .hard)
        let best = try XCTUnwrap(scenario.bestOption)
        let bestSimulation = try XCTUnwrap(WhatToPlayTrainer.bestProjectedOption(in: scenario.options))
        let option = try XCTUnwrap(scenario.options.first {
            $0.card != best.card
                && max(0, best.expectedImpact - $0.expectedImpact) <= 2
                && max(0, bestSimulation.projectedTeamPoints - $0.projectedTeamPoints) >= 9
        })
        return (scenario, option)
    }
}
