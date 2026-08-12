import XCTest
import BalootEngine
@testable import BalootHub

final class AchievementCenterTests: XCTestCase {
    func testAchievementIDsAreUnique() {
        let ids = AchievementCenter.all.map(\.id)

        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func testEveryAchievementHasDisplayDataAndRequirement() {
        for achievement in AchievementCenter.all {
            XCTAssertFalse(achievement.title.isEmpty)
            XCTAssertFalse(achievement.detail.isEmpty)
            XCTAssertFalse(achievement.requirement.isEmpty)
            XCTAssertFalse(achievement.iconName.isEmpty)
        }
    }

    func testUnlockedAchievementsFilterByIDs() {
        let unlocked = AchievementCenter.unlockedAchievements(from: ["first-kaboot", "scorekeeper"])

        XCTAssertEqual(Set(unlocked.map(\.id)), ["first-kaboot", "scorekeeper"])
    }

    func testWhatToPlayExpertEyeAchievementExists() throws {
        let achievement = try XCTUnwrap(AchievementCenter.all.first { $0.id == "expert-eye" })

        XCTAssertEqual(achievement.rarity, .gold)
        XCTAssertEqual(achievement.iconName, "eye.fill")
        XCTAssertFalse(achievement.title.isEmpty)
        XCTAssertFalse(achievement.detail.isEmpty)
        XCTAssertFalse(achievement.requirement.isEmpty)
    }

    func testWhatToPlayExpertEyeUnlocksAfterFiveExpertMatches() {
        let attempts = (0..<5).map { index in
            makeWhatToPlayAttempt(seed: UInt64(index), isCorrect: true)
        }

        XCTAssertEqual(
            AchievementCenter.earnedAchievementIDs(whatToPlayAttempts: attempts),
            ["expert-eye"]
        )
    }

    func testWhatToPlayExpertEyeCountsUniqueCorrectScenarios() {
        let attempts = (0..<5).map { _ in
            makeWhatToPlayAttempt(seed: 2026, isCorrect: true)
        }

        XCTAssertTrue(AchievementCenter.earnedAchievementIDs(whatToPlayAttempts: attempts).isEmpty)
    }

    func testWhatToPlayExpertEyeStaysLockedBeforeRequirement() {
        let attempts = [
            makeWhatToPlayAttempt(seed: 1, isCorrect: true),
            makeWhatToPlayAttempt(seed: 2, isCorrect: true),
            makeWhatToPlayAttempt(seed: 3, isCorrect: true),
            makeWhatToPlayAttempt(seed: 4, isCorrect: true),
            makeWhatToPlayAttempt(seed: 5, isCorrect: false)
        ]

        XCTAssertTrue(AchievementCenter.earnedAchievementIDs(whatToPlayAttempts: attempts).isEmpty)
    }

    private func makeWhatToPlayAttempt(seed: UInt64, isCorrect: Bool) -> WhatToPlayAttempt {
        WhatToPlayAttempt(
            difficulty: .medium,
            seed: seed,
            selectedCard: PlayingCard(suit: .spades, rank: .ace),
            bestCard: PlayingCard(suit: .spades, rank: .ace),
            isCorrect: isCorrect,
            expectedImpact: isCorrect ? 12 : 5,
            bestExpectedImpact: 12
        )
    }
}
