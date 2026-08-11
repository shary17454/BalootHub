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
        XCTAssertTrue(text.contains("\("النمط".localized):"))
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
        XCTAssertEqual(content.mode.isEmpty, false)
        XCTAssertEqual(content.trickProgress, "\(scenario.state.completedTricks.count + 1) \("من".localized) 8")
        XCTAssertEqual(content.legalCardNames, scenario.options.sorted {
            if $0.card.suit.ordinal != $1.card.suit.ordinal {
                return $0.card.suit.ordinal < $1.card.suit.ordinal
            }
            return $0.card.rank.ordinal < $1.card.rank.ordinal
        }.map { $0.card.accessibilityName })
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
}
