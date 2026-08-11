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

    func testWeeklyChallengesRemainStableInsideSameWeek() {
        let firstDate = Date(timeIntervalSince1970: 1_785_888_000)
        let secondDate = firstDate.addingTimeInterval(2 * 86_400)

        XCTAssertEqual(
            DailyChallengeCenter.weeklyChallenges(for: firstDate),
            DailyChallengeCenter.weeklyChallenges(for: secondDate)
        )
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
}
