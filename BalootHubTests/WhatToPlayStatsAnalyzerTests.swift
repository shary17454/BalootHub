import XCTest
import SwiftData
import BalootEngine
@testable import BalootHub

final class WhatToPlayStatsAnalyzerTests: XCTestCase {
    func testSummaryCalculatesAccuracyStreaksAndAverageImpact() {
        let attempts = [
            attempt(daysAgo: 4, correct: true, impact: 10),
            attempt(daysAgo: 3, correct: true, impact: 4),
            attempt(daysAgo: 2, correct: false, impact: -8),
            attempt(daysAgo: 1, correct: true, impact: 2)
        ]

        let summary = WhatToPlayStatsAnalyzer.summarize(attempts: attempts)

        XCTAssertEqual(summary.attempts, 4)
        XCTAssertEqual(summary.correct, 3)
        XCTAssertEqual(summary.accuracyPercent, 75)
        XCTAssertEqual(summary.bestStreak, 2)
        XCTAssertEqual(summary.currentStreak, 1)
        XCTAssertEqual(summary.averageExpectedImpact, 2)
    }

    func testAttemptPersistsInSwiftDataSchemaAndRestoresCards() throws {
        let configuration = ModelConfiguration(schema: PersistenceController.appSchema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PersistenceController.appSchema, configurations: [configuration])
        let context = ModelContext(container)
        let selected = PlayingCard(suit: .spades, rank: .ace)
        let best = PlayingCard(suit: .hearts, rank: .jack)
        let attempt = WhatToPlayAttempt(
            difficulty: .hard,
            seed: 2_026,
            selectedCard: selected,
            bestCard: best,
            isCorrect: false,
            expectedImpact: -6
        )

        context.insert(attempt)
        try context.save()

        let saved = try XCTUnwrap(try context.fetch(FetchDescriptor<WhatToPlayAttempt>()).first)
        XCTAssertEqual(saved.difficulty, .hard)
        XCTAssertEqual(saved.seedValue, 2_026)
        XCTAssertEqual(saved.selectedCard, selected)
        XCTAssertEqual(saved.bestCard, best)
        XCTAssertFalse(saved.isCorrect)
        XCTAssertEqual(saved.expectedImpact, -6)
    }

    private func attempt(daysAgo: TimeInterval, correct: Bool, impact: Int) -> WhatToPlayAttempt {
        WhatToPlayAttempt(
            createdAt: Date(timeIntervalSince1970: 2_000_000 - daysAgo * 86_400),
            difficulty: .medium,
            seed: UInt64(Int(daysAgo)),
            selectedCard: PlayingCard(suit: .clubs, rank: .seven),
            bestCard: PlayingCard(suit: .clubs, rank: .seven),
            isCorrect: correct,
            expectedImpact: impact
        )
    }
}
