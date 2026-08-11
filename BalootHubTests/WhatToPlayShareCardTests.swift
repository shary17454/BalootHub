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
        XCTAssertFalse(text.contains("اختيار الخبير".localized))
    }

    func testShareTextIncludesAnswerReviewAfterSelection() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let selected = try XCTUnwrap(scenario.options.last)
        let best = try XCTUnwrap(scenario.bestOption)
        let text = WhatToPlayShareCard.text(for: scenario, selectedOption: selected)

        XCTAssertTrue(text.contains("مراجعة القرار".localized))
        XCTAssertTrue(text.contains("\("اختياري".localized): \(selected.card.accessibilityName)"))
        XCTAssertTrue(text.contains("\("أفضل ورقة".localized): \(best.card.accessibilityName)"))
        XCTAssertTrue(text.contains("\("ترتيب اختياري".localized): \(selected.rank)"))
        XCTAssertTrue(text.contains("\("نقاط متوقعة ضائعة".localized): \(max(0, best.expectedImpact - selected.expectedImpact))"))
        XCTAssertTrue(text.contains("\("الأثر المتوقع".localized): \(selected.expectedImpact >= 0 ? "+\(selected.expectedImpact)" : "\(selected.expectedImpact)")"))
        XCTAssertTrue(text.contains("\("تفصيل الأثر".localized): \(WhatToPlayImpactFormatter.detail(for: selected.impactBreakdown))"))
    }

    func testShareCardContentMarksAnswerReviewOnlyAfterSelection() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let selected = try XCTUnwrap(scenario.bestOption)

        XCTAssertFalse(WhatToPlayShareCard.content(for: scenario).includesAnswerReview)

        let reviewed = WhatToPlayShareCard.content(for: scenario, selectedOption: selected)

        XCTAssertTrue(reviewed.includesAnswerReview)
        XCTAssertEqual(reviewed.subtitle, "مراجعة قرار من Baloot Hub".localized)
        XCTAssertEqual(reviewed.selectedCardName, selected.card.accessibilityName)
        XCTAssertEqual(reviewed.bestCardName, selected.card.accessibilityName)
        XCTAssertEqual(reviewed.lostExpectedPoints, 0)
        XCTAssertEqual(reviewed.selectedImpact, selected.expectedImpact)
        XCTAssertEqual(reviewed.selectedImpactDetail, WhatToPlayImpactFormatter.detail(for: selected.impactBreakdown))
        XCTAssertEqual(reviewed.prompt, "راجع القرار وتدرّب على قراءة الموقف.".localized)
    }

    private func contentMode(for scenario: WhatToPlayScenario) -> String {
        WhatToPlayShareCard.content(for: scenario).mode
    }
}
