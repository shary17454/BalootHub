import XCTest
import BalootEngine
@testable import BalootHub

final class DailyChallengeCenterTests: XCTestCase {
    func testDailyChallengesAreDeterministicForSameDate() {
        let date = Date(timeIntervalSince1970: 1_785_888_000)
        let first = DailyChallengeCenter.dailyChallenges(for: date)
        let second = DailyChallengeCenter.dailyChallenges(for: date)

        XCTAssertEqual(first, second)
    }

    func testDailyChallengesChangeAcrossDates() {
        let firstDate = Date(timeIntervalSince1970: 1_785_888_000)
        let secondDate = firstDate.addingTimeInterval(86_400)

        XCTAssertNotEqual(
            DailyChallengeCenter.dailyChallenges(for: firstDate),
            DailyChallengeCenter.dailyChallenges(for: secondDate)
        )
    }

    func testDailyChallengeIDsAreScopedToDate() {
        let firstDate = Date(timeIntervalSince1970: 1_785_888_000)
        let secondDate = firstDate.addingTimeInterval(86_400)
        let firstIDs = Set(DailyChallengeCenter.dailyChallenges(for: firstDate).map(\.id))
        let secondIDs = Set(DailyChallengeCenter.dailyChallenges(for: secondDate).map(\.id))

        XCTAssertTrue(firstIDs.isDisjoint(with: secondIDs))
    }

    func testWeeklyChallengesRemainStableInsideSameWeek() {
        let firstDate = Date(timeIntervalSince1970: 1_785_888_000)
        let secondDate = firstDate.addingTimeInterval(2 * 86_400)

        XCTAssertEqual(
            DailyChallengeCenter.weeklyChallenges(for: firstDate),
            DailyChallengeCenter.weeklyChallenges(for: secondDate)
        )
    }

    func testWeeklyChallengeIDsAreScopedToWeek() {
        let firstDate = Date(timeIntervalSince1970: 1_785_888_000)
        let nextWeek = firstDate.addingTimeInterval(7 * 86_400)
        let firstIDs = Set(DailyChallengeCenter.weeklyChallenges(for: firstDate).map(\.id))
        let nextWeekIDs = Set(DailyChallengeCenter.weeklyChallenges(for: nextWeek).map(\.id))

        XCTAssertTrue(firstIDs.isDisjoint(with: nextWeekIDs))
    }

    func testGeneratedChallengesHaveUniqueIDsAndTargets() {
        let challenges = DailyChallengeCenter.challenges(for: Date(timeIntervalSince1970: 1_785_888_000))
        let ids = challenges.map(\.id)

        XCTAssertEqual(ids.count, Set(ids).count)
        XCTAssertTrue(challenges.allSatisfy { $0.targetCount > 0 })
    }

    func testDailyWhatToPlayChallengeCarriesDeterministicScenarioRequest() throws {
        let date = Date(timeIntervalSince1970: 1_785_888_000)
        let challenge = DailyChallengeCenter.dailyChallenges(for: date).first { $0.category == .tactics }

        let tactics = try XCTUnwrap(challenge)
        let seed = try XCTUnwrap(tactics.whatToPlaySeed)
        let difficulty = try XCTUnwrap(tactics.whatToPlayDifficulty)
        let focusKind = try XCTUnwrap(tactics.whatToPlayFocusKind)

        XCTAssertEqual(
            seed,
            DailyChallengeCenter.dailyWhatToPlaySeed(
                for: date,
                difficulty: difficulty,
                focusKind: focusKind
            )
        )
    }

    func testDailyWhatToPlaySeedChangesByTrainingFocus() {
        let date = Date(timeIntervalSince1970: 1_785_888_000)
        let openingSeed = DailyChallengeCenter.dailyWhatToPlaySeed(
            for: date,
            difficulty: .medium,
            focusKind: .openingLead
        )
        let followSuitSeed = DailyChallengeCenter.dailyWhatToPlaySeed(
            for: date,
            difficulty: .medium,
            focusKind: .followSuit
        )

        XCTAssertNotEqual(openingSeed, followSuitSeed)
    }

    func testDailyWhatToPlayScenarioRequestIsCompleteForTrainerNavigation() throws {
        let date = Date(timeIntervalSince1970: 1_785_888_000)
        let challenge = try XCTUnwrap(DailyChallengeCenter.dailyChallenges(for: date).first { $0.category == .tactics })
        let seed = try XCTUnwrap(challenge.whatToPlaySeed)
        let difficulty = try XCTUnwrap(challenge.whatToPlayDifficulty)
        let focusKind = try XCTUnwrap(challenge.whatToPlayFocusKind)

        XCTAssertGreaterThan(seed, 0)
        XCTAssertTrue(WhatToPlayDifficulty.allCases.contains(difficulty))
        XCTAssertTrue(WhatToPlayScenarioFocusKind.allCases.contains(focusKind))
    }
}
