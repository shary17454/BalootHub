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

    func testWhatToPlayProgressCountsMatchingAttemptsInsideChallengeDay() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = Date(timeIntervalSince1970: 1_785_888_000)
        let challenge = try XCTUnwrap(DailyChallengeCenter.dailyChallenges(for: date, calendar: calendar).first { $0.category == .tactics })
        let difficulty = try XCTUnwrap(challenge.whatToPlayDifficulty)
        let focusKind = try XCTUnwrap(challenge.whatToPlayFocusKind)
        let otherDifficulty = WhatToPlayDifficulty.allCases.first { $0 != difficulty } ?? .easy
        let otherFocus = WhatToPlayScenarioFocusKind.allCases.first { $0 != focusKind } ?? .openingLead
        let dayStart = calendar.startOfDay(for: date)
        let attempts = [
            attempt(at: dayStart.addingTimeInterval(60), difficulty: difficulty, focusKind: focusKind),
            attempt(at: dayStart.addingTimeInterval(120), difficulty: difficulty, focusKind: focusKind),
            attempt(at: dayStart.addingTimeInterval(150), difficulty: difficulty, focusKind: focusKind, isCorrect: false),
            attempt(at: dayStart.addingTimeInterval(-60), difficulty: difficulty, focusKind: focusKind),
            attempt(at: dayStart.addingTimeInterval(180), difficulty: otherDifficulty, focusKind: focusKind),
            attempt(at: dayStart.addingTimeInterval(240), difficulty: difficulty, focusKind: otherFocus)
        ]

        let progress = try XCTUnwrap(DailyChallengeCenter.progress(
            for: challenge,
            attempts: attempts,
            now: date,
            calendar: calendar
        ))

        XCTAssertEqual(progress.completedCount, min(2, challenge.targetCount))
        XCTAssertEqual(progress.targetCount, challenge.targetCount)
    }

    func testWhatToPlayProgressCapsAtChallengeTarget() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = Date(timeIntervalSince1970: 1_785_888_000)
        let challenge = try XCTUnwrap(DailyChallengeCenter.dailyChallenges(for: date, calendar: calendar).first { $0.category == .tactics })
        let difficulty = try XCTUnwrap(challenge.whatToPlayDifficulty)
        let focusKind = try XCTUnwrap(challenge.whatToPlayFocusKind)
        let dayStart = calendar.startOfDay(for: date)
        let attempts = (0..<(challenge.targetCount + 3)).map {
            attempt(at: dayStart.addingTimeInterval(TimeInterval($0 + 1)), difficulty: difficulty, focusKind: focusKind)
        }

        let progress = try XCTUnwrap(DailyChallengeCenter.progress(
            for: challenge,
            attempts: attempts,
            now: date,
            calendar: calendar
        ))

        XCTAssertEqual(progress.completedCount, challenge.targetCount)
        XCTAssertTrue(progress.isComplete)
    }

    func testNonTacticsChallengesDoNotReturnWhatToPlayProgress() throws {
        let date = Date(timeIntervalSince1970: 1_785_888_000)
        let challenge = try XCTUnwrap(DailyChallengeCenter.dailyChallenges(for: date).first { $0.category == .match })

        XCTAssertNil(DailyChallengeCenter.progress(for: challenge, attempts: []))
    }

    private func attempt(
        at date: Date,
        difficulty: WhatToPlayDifficulty,
        focusKind: WhatToPlayScenarioFocusKind,
        isCorrect: Bool = true
    ) -> WhatToPlayAttempt {
        WhatToPlayAttempt(
            createdAt: date,
            difficulty: difficulty,
            seed: 1,
            selectedCard: PlayingCard(suit: .clubs, rank: .seven),
            bestCard: PlayingCard(suit: .clubs, rank: .seven),
            isCorrect: isCorrect,
            selectedRank: isCorrect ? 1 : 2,
            expectedImpact: isCorrect ? 1 : -1,
            bestExpectedImpact: 1,
            focusKind: focusKind,
            outcome: isCorrect ? .winsTrick : .losesTrick
        )
    }
}
