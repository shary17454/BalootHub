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

    func testWeeklyWhatToPlayChallengeCarriesDeterministicScenarioRequest() throws {
        let date = Date(timeIntervalSince1970: 1_785_888_000)
        let challenge = DailyChallengeCenter.weeklyChallenges(for: date).first { $0.category == .tactics }

        let tactics = try XCTUnwrap(challenge)
        let seed = try XCTUnwrap(tactics.whatToPlaySeed)
        let difficulty = try XCTUnwrap(tactics.whatToPlayDifficulty)
        let focusKind = try XCTUnwrap(tactics.whatToPlayFocusKind)
        let gameMode = try XCTUnwrap(tactics.whatToPlayGameMode)

        XCTAssertEqual(tactics.cadence, .weekly)
        XCTAssertEqual(
            seed,
            DailyChallengeCenter.weeklyWhatToPlaySeed(
                for: date,
                difficulty: difficulty,
                focusKind: focusKind,
                gameMode: gameMode
            )
        )
        XCTAssertEqual(DailyChallengeCenter.whatToPlaySeedSeries(for: tactics).count, tactics.targetCount)
    }

    func testWeeklyWhatToPlayProgressCountsMatchingAttemptsInsideChallengeWeek() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = Date(timeIntervalSince1970: 1_785_888_000)
        let challenge = try XCTUnwrap(DailyChallengeCenter.weeklyChallenges(for: date, calendar: calendar).first { $0.category == .tactics })
        let difficulty = try XCTUnwrap(challenge.whatToPlayDifficulty)
        let focusKind = try XCTUnwrap(challenge.whatToPlayFocusKind)
        let gameMode = try XCTUnwrap(challenge.whatToPlayGameMode)
        let seed = try XCTUnwrap(challenge.whatToPlaySeed)
        let weekStart = try XCTUnwrap(calendar.dateInterval(of: .weekOfYear, for: date)?.start)
        let attempts = [
            attempt(at: weekStart.addingTimeInterval(60), difficulty: difficulty, focusKind: focusKind, gameMode: gameMode, seed: seed),
            attempt(at: weekStart.addingTimeInterval(120), difficulty: difficulty, focusKind: focusKind, gameMode: gameMode, seed: seed &+ 1),
            attempt(at: weekStart.addingTimeInterval(-60), difficulty: difficulty, focusKind: focusKind, gameMode: gameMode, seed: seed &+ 2),
            attempt(at: weekStart.addingTimeInterval(180), difficulty: difficulty, focusKind: focusKind, gameMode: gameMode, seed: seed &+ 2, isCorrect: false)
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

    func testGeneratedChallengesHaveUniqueIDsAndTargets() {
        let challenges = DailyChallengeCenter.challenges(for: Date(timeIntervalSince1970: 1_785_888_000))
        let ids = challenges.map(\.id)

        XCTAssertEqual(ids.count, Set(ids).count)
        XCTAssertTrue(challenges.allSatisfy { $0.targetCount > 0 })
    }

    func testScoringChallengesCarryQuestionCategory() throws {
        let date = Date(timeIntervalSince1970: 1_785_888_000)
        let daily = try XCTUnwrap(DailyChallengeCenter.dailyChallenges(for: date).first { $0.category == .scoring })
        let weekly = try XCTUnwrap(DailyChallengeCenter.weeklyChallenges(for: date).first { $0.category == .scoring })

        XCTAssertNotNil(daily.scoringQuizCategory)
        XCTAssertNotNil(weekly.scoringQuizCategory)
        XCTAssertTrue(daily.detail.contains(try XCTUnwrap(daily.scoringQuizCategory).title))
        XCTAssertTrue(weekly.detail.contains(try XCTUnwrap(weekly.scoringQuizCategory).title))
    }

    func testDailyWhatToPlayChallengeCarriesDeterministicScenarioRequest() throws {
        let date = Date(timeIntervalSince1970: 1_785_888_000)
        let challenge = DailyChallengeCenter.dailyChallenges(for: date).first { $0.category == .tactics }

        let tactics = try XCTUnwrap(challenge)
        let seed = try XCTUnwrap(tactics.whatToPlaySeed)
        let difficulty = try XCTUnwrap(tactics.whatToPlayDifficulty)
        let focusKind = try XCTUnwrap(tactics.whatToPlayFocusKind)
        let gameMode = try XCTUnwrap(tactics.whatToPlayGameMode)

        XCTAssertEqual(
            seed,
            DailyChallengeCenter.dailyWhatToPlaySeed(
                for: date,
                difficulty: difficulty,
                focusKind: focusKind,
                gameMode: gameMode
            )
        )
    }

    func testDailyWhatToPlaySeedChangesByTrainingFocus() {
        let date = Date(timeIntervalSince1970: 1_785_888_000)
        let openingSeed = DailyChallengeCenter.dailyWhatToPlaySeed(
            for: date,
            difficulty: .medium,
            focusKind: .openingLead,
            gameMode: .hokum
        )
        let followSuitSeed = DailyChallengeCenter.dailyWhatToPlaySeed(
            for: date,
            difficulty: .medium,
            focusKind: .followSuit,
            gameMode: .hokum
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

    func testWhatToPlayChallengeSeedSeriesMatchesTargetCount() throws {
        let date = Date(timeIntervalSince1970: 1_785_888_000)
        let challenge = try XCTUnwrap(DailyChallengeCenter.dailyChallenges(for: date).first { $0.category == .tactics })
        let seed = try XCTUnwrap(challenge.whatToPlaySeed)

        let series = DailyChallengeCenter.whatToPlaySeedSeries(for: challenge)

        XCTAssertEqual(series.count, challenge.targetCount)
        XCTAssertEqual(series.first, seed)
        XCTAssertEqual(series.last, seed &+ UInt64(challenge.targetCount - 1))
    }

    func testWhatToPlayProgressCountsMatchingAttemptsInsideChallengeDay() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = Date(timeIntervalSince1970: 1_785_888_000)
        let challenge = try XCTUnwrap(DailyChallengeCenter.dailyChallenges(for: date, calendar: calendar).first { $0.category == .tactics })
        let difficulty = try XCTUnwrap(challenge.whatToPlayDifficulty)
        let focusKind = try XCTUnwrap(challenge.whatToPlayFocusKind)
        let gameMode = try XCTUnwrap(challenge.whatToPlayGameMode)
        let seed = try XCTUnwrap(challenge.whatToPlaySeed)
        let otherDifficulty = WhatToPlayDifficulty.allCases.first { $0 != difficulty } ?? .easy
        let otherFocus = WhatToPlayScenarioFocusKind.allCases.first { $0 != focusKind } ?? .openingLead
        let dayStart = calendar.startOfDay(for: date)
        let attempts = [
            attempt(at: dayStart.addingTimeInterval(60), difficulty: difficulty, focusKind: focusKind, gameMode: gameMode, seed: seed),
            attempt(at: dayStart.addingTimeInterval(120), difficulty: difficulty, focusKind: focusKind, gameMode: gameMode, seed: seed &+ 1),
            attempt(at: dayStart.addingTimeInterval(150), difficulty: difficulty, focusKind: focusKind, gameMode: gameMode, seed: seed &+ 2, isCorrect: false),
            attempt(at: dayStart.addingTimeInterval(-60), difficulty: difficulty, focusKind: focusKind, gameMode: gameMode, seed: seed),
            attempt(at: dayStart.addingTimeInterval(180), difficulty: otherDifficulty, focusKind: focusKind, gameMode: gameMode, seed: seed &+ 2),
            attempt(at: dayStart.addingTimeInterval(240), difficulty: difficulty, focusKind: otherFocus, gameMode: gameMode, seed: seed &+ 2),
            attempt(at: dayStart.addingTimeInterval(300), difficulty: difficulty, focusKind: focusKind, gameMode: gameMode, seed: seed &+ UInt64(challenge.targetCount + 5))
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

    func testScoringChallengeProgressCountsCorrectQuizAnswersInsideDay() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = Date(timeIntervalSince1970: 1_785_888_000)
        let challenge = try XCTUnwrap(DailyChallengeCenter.dailyChallenges(for: date, calendar: calendar).first { $0.category == .scoring })
        let category = try XCTUnwrap(challenge.scoringQuizCategory)
        let dayStart = calendar.startOfDay(for: date)
        let scoringAttempts = [
            try scoringAttempt(at: dayStart.addingTimeInterval(60), category: category, isCorrect: true),
            try scoringAttempt(at: dayStart.addingTimeInterval(120), category: category, isCorrect: true),
            try scoringAttempt(at: dayStart.addingTimeInterval(180), category: category, isCorrect: false),
            try scoringAttempt(at: dayStart.addingTimeInterval(-60), category: category, isCorrect: true)
        ]

        let progress = try XCTUnwrap(DailyChallengeCenter.progress(
            for: challenge,
            attempts: [],
            scoringQuizAttempts: scoringAttempts,
            now: date,
            calendar: calendar
        ))

        XCTAssertEqual(progress.completedCount, min(2, challenge.targetCount))
        XCTAssertEqual(progress.targetCount, challenge.targetCount)
    }

    func testScoringChallengeProgressCountsOnlyRequestedQuestionCategory() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = Date(timeIntervalSince1970: 1_785_888_000)
        let challenge = try XCTUnwrap(DailyChallengeCenter.dailyChallenges(for: date, calendar: calendar).first { $0.category == .scoring })
        let category = try XCTUnwrap(challenge.scoringQuizCategory)
        let otherCategory = try XCTUnwrap(ScoringQuizQuestionCategory.allCases.first { $0 != category })
        let dayStart = calendar.startOfDay(for: date)
        let scoringAttempts = [
            try scoringAttempt(at: dayStart.addingTimeInterval(60), category: category, isCorrect: true),
            try scoringAttempt(at: dayStart.addingTimeInterval(120), category: otherCategory, isCorrect: true),
            try scoringAttempt(at: dayStart.addingTimeInterval(180), category: category, isCorrect: false)
        ]

        let progress = try XCTUnwrap(DailyChallengeCenter.progress(
            for: challenge,
            attempts: [],
            scoringQuizAttempts: scoringAttempts,
            now: date,
            calendar: calendar
        ))

        XCTAssertEqual(progress.completedCount, 1)
    }

    func testScoringChallengeProgressCapsAtTarget() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = Date(timeIntervalSince1970: 1_785_888_000)
        let challenge = try XCTUnwrap(DailyChallengeCenter.dailyChallenges(for: date, calendar: calendar).first { $0.category == .scoring })
        let category = try XCTUnwrap(challenge.scoringQuizCategory)
        let dayStart = calendar.startOfDay(for: date)
        let scoringAttempts = try (0..<(challenge.targetCount + 4)).map { index in
            try scoringAttempt(
                at: dayStart.addingTimeInterval(TimeInterval(index + 1)),
                category: category,
                isCorrect: true
            )
        }

        let progress = try XCTUnwrap(DailyChallengeCenter.progress(
            for: challenge,
            attempts: [],
            scoringQuizAttempts: scoringAttempts,
            now: date,
            calendar: calendar
        ))

        XCTAssertEqual(progress.completedCount, challenge.targetCount)
        XCTAssertTrue(progress.isComplete)
    }

    func testCompletedChallengeIDsReturnsOnlyFinishedChallenges() {
        let calendar = Calendar(identifier: .gregorian)
        let date = Date(timeIntervalSince1970: 1_785_888_000)
        let dayStart = calendar.startOfDay(for: date)
        let completed = BalootChallenge(
            id: "completed-scoring",
            cadence: .daily,
            category: .scoring,
            title: "حساب",
            detail: "اختبار",
            targetCount: 2,
            rewardTitle: "اختبار",
            whatToPlaySeed: nil,
            whatToPlayDifficulty: nil,
            whatToPlayFocusKind: nil
        )
        let incomplete = BalootChallenge(
            id: "incomplete-scoring",
            cadence: .daily,
            category: .scoring,
            title: "حساب",
            detail: "اختبار",
            targetCount: 3,
            rewardTitle: "اختبار",
            whatToPlaySeed: nil,
            whatToPlayDifficulty: nil,
            whatToPlayFocusKind: nil
        )
        let scoringAttempts = [
            scoringAttempt(at: dayStart.addingTimeInterval(60), seed: 1, isCorrect: true),
            scoringAttempt(at: dayStart.addingTimeInterval(120), seed: 2, isCorrect: true)
        ]

        let ids = DailyChallengeCenter.completedChallengeIDs(
            for: [completed, incomplete],
            attempts: [],
            scoringQuizAttempts: scoringAttempts,
            now: date,
            calendar: calendar
        )

        XCTAssertEqual(ids, ["completed-scoring"])
    }

    func testAcademyChallengeProgressCountsCompletedLessonsInsideWeek() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = Date(timeIntervalSince1970: 1_785_888_000)
        let challenge = try XCTUnwrap(DailyChallengeCenter.weeklyChallenges(for: date, calendar: calendar).first { $0.category == .training })
        let weekStart = try XCTUnwrap(calendar.dateInterval(of: .weekOfYear, for: date)?.start)
        let first = try XCTUnwrap(BalootAcademyCatalog.lesson(id: "beginner-cards"))
        let second = try XCTUnwrap(BalootAcademyCatalog.lesson(id: "beginner-deal"))
        let third = try XCTUnwrap(BalootAcademyCatalog.lesson(id: "beginner-ordering"))
        let progressRows = [
            academyProgress(at: weekStart.addingTimeInterval(60), lesson: first),
            academyProgress(at: weekStart.addingTimeInterval(120), lesson: second),
            academyProgress(at: weekStart.addingTimeInterval(180), lesson: second),
            academyProgress(at: weekStart.addingTimeInterval(-60), lesson: third)
        ]

        let progress = try XCTUnwrap(DailyChallengeCenter.progress(
            for: challenge,
            attempts: [],
            academyProgress: progressRows,
            now: date,
            calendar: calendar
        ))

        XCTAssertEqual(progress.completedCount, min(2, challenge.targetCount))
        XCTAssertEqual(progress.targetCount, challenge.targetCount)
    }

    func testAcademyChallengeProgressIncludesLegacyCompletedLessons() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = Date(timeIntervalSince1970: 1_785_888_000)
        let challenge = try XCTUnwrap(DailyChallengeCenter.weeklyChallenges(for: date, calendar: calendar).first { $0.category == .training })

        let progress = try XCTUnwrap(DailyChallengeCenter.progress(
            for: challenge,
            attempts: [],
            academyProgress: [],
            legacyCompletedAcademyLessonIDs: ["beginner-cards", "beginner-deal", "missing"],
            now: date,
            calendar: calendar
        ))

        XCTAssertEqual(progress.completedCount, min(2, challenge.targetCount))
    }

    func testAcademyProgressReturnsNextIncompleteLessonRecommendation() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = Date(timeIntervalSince1970: 1_785_888_000)
        let challenge = try XCTUnwrap(DailyChallengeCenter.weeklyChallenges(for: date, calendar: calendar).first { $0.category == .training })
        let weekStart = try XCTUnwrap(calendar.dateInterval(of: .weekOfYear, for: date)?.start)
        let first = try XCTUnwrap(BalootAcademyCatalog.lesson(id: "beginner-cards"))
        let second = try XCTUnwrap(BalootAcademyCatalog.lesson(id: "beginner-deal"))
        let completed = [
            academyProgress(at: weekStart.addingTimeInterval(60), lesson: first),
            academyProgress(at: weekStart.addingTimeInterval(-60), lesson: second)
        ]

        let progress = try XCTUnwrap(DailyChallengeCenter.academyProgress(
            for: challenge,
            academyProgress: completed,
            now: date,
            calendar: calendar
        ))

        XCTAssertEqual(progress.base.completedCount, 1)
        XCTAssertEqual(progress.base.targetCount, challenge.targetCount)
        XCTAssertEqual(progress.nextLesson?.id, "beginner-ordering")
    }

    func testAcademyProgressReturnsNilForNonTrainingChallenge() throws {
        let date = Date(timeIntervalSince1970: 1_785_888_000)
        let challenge = try XCTUnwrap(DailyChallengeCenter.dailyChallenges(for: date).first { $0.category == .match })

        XCTAssertNil(DailyChallengeCenter.academyProgress(for: challenge, academyProgress: [], now: date))
    }

    func testAcademyProgressHasNoNextLessonWhenCatalogIsComplete() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = Date(timeIntervalSince1970: 1_785_888_000)
        let challenge = try XCTUnwrap(DailyChallengeCenter.weeklyChallenges(for: date, calendar: calendar).first { $0.category == .training })
        let completedIDs = Set(BalootAcademyCatalog.lessons.map(\.id))

        let progress = try XCTUnwrap(DailyChallengeCenter.academyProgress(
            for: challenge,
            academyProgress: [],
            legacyCompletedAcademyLessonIDs: completedIDs,
            now: date,
            calendar: calendar
        ))

        XCTAssertNil(progress.nextLesson)
    }

    func testDailyMatchChallengeCountsWinningHokumRoundInsideDay() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = Date(timeIntervalSince1970: 1_785_888_000)
        let challenge = try XCTUnwrap(DailyChallengeCenter.dailyChallenges(for: date, calendar: calendar).first { $0.category == .match })
        let dayStart = calendar.startOfDay(for: date)
        let session = scoreSession(
            createdAt: dayStart.addingTimeInterval(60),
            rounds: [
                ScoreRound(
                    roundNumber: 1,
                    createdAt: dayStart.addingTimeInterval(120),
                    mode: .hokum,
                    teamOneBaseScore: 100,
                    teamTwoBaseScore: 62
                )
            ]
        )

        let progress = try XCTUnwrap(DailyChallengeCenter.progress(
            for: challenge,
            attempts: [],
            scoreSessions: [session],
            now: date,
            calendar: calendar
        ))

        XCTAssertEqual(progress.completedCount, 1)
        XCTAssertTrue(progress.isComplete)
    }

    func testDailyMatchChallengeIgnoresSunOrLostRounds() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = Date(timeIntervalSince1970: 1_785_888_000)
        let challenge = try XCTUnwrap(DailyChallengeCenter.dailyChallenges(for: date, calendar: calendar).first { $0.category == .match })
        let dayStart = calendar.startOfDay(for: date)
        let session = scoreSession(
            createdAt: dayStart.addingTimeInterval(60),
            rounds: [
                ScoreRound(roundNumber: 1, createdAt: dayStart.addingTimeInterval(90), mode: .sun, teamOneBaseScore: 130, teamTwoBaseScore: 20),
                ScoreRound(roundNumber: 2, createdAt: dayStart.addingTimeInterval(120), mode: .hokum, teamOneBaseScore: 40, teamTwoBaseScore: 122)
            ]
        )

        let progress = try XCTUnwrap(DailyChallengeCenter.progress(
            for: challenge,
            attempts: [],
            scoreSessions: [session],
            now: date,
            calendar: calendar
        ))

        XCTAssertEqual(progress.completedCount, 0)
        XCTAssertFalse(progress.isComplete)
    }

    func testWeeklyMatchChallengeUsesConfiguredCoffeeRuleForWinnerEligibility() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = Date(timeIntervalSince1970: 1_785_888_000)
        let challenge = BalootChallenge(
            id: "weekly-coffee-rules",
            cadence: .weekly,
            category: .match,
            title: "سلسلة",
            detail: "اختبار",
            targetCount: 1,
            rewardTitle: "اختبار",
            whatToPlaySeed: nil,
            whatToPlayDifficulty: nil,
            whatToPlayFocusKind: nil
        )
        let weekStart = try XCTUnwrap(calendar.dateInterval(of: .weekOfYear, for: date)?.start)
        let session = scoreSession(
            createdAt: weekStart.addingTimeInterval(60),
            rounds: [
                ScoreRound(
                    roundNumber: 1,
                    createdAt: weekStart.addingTimeInterval(90),
                    mode: .hokum,
                    teamOneBaseScore: 50,
                    teamTwoBaseScore: 40,
                    multiplier: .coffee
                )
            ]
        )

        let coffeeEnabled = try XCTUnwrap(DailyChallengeCenter.progress(
            for: challenge,
            attempts: [],
            scoreSessions: [session],
            rules: ScoreRules.from(preset: .standard, coffeeEnabled: true),
            now: date,
            calendar: calendar
        ))
        let coffeeDisabled = try XCTUnwrap(DailyChallengeCenter.progress(
            for: challenge,
            attempts: [],
            scoreSessions: [session],
            rules: ScoreRules.from(preset: .standard, coffeeEnabled: false),
            now: date,
            calendar: calendar
        ))

        XCTAssertEqual(coffeeEnabled.completedCount, 1)
        XCTAssertEqual(coffeeDisabled.completedCount, 0)
    }

    func testWeeklyMatchChallengeCountsConsecutiveFinishedMatchWins() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = Date(timeIntervalSince1970: 1_785_888_000)
        let challenge = try XCTUnwrap(DailyChallengeCenter.weeklyChallenges(for: date, calendar: calendar).first { $0.category == .match })
        let weekStart = try XCTUnwrap(calendar.dateInterval(of: .weekOfYear, for: date)?.start)
        let sessions = (0..<challenge.targetCount).map { index in
            scoreSession(
                createdAt: weekStart.addingTimeInterval(TimeInterval(index + 1) * 60),
                status: .finished,
                rounds: [
                    ScoreRound(roundNumber: 1, mode: .hokum, teamOneBaseScore: 100, teamTwoBaseScore: 62)
                ]
            )
        }

        let progress = try XCTUnwrap(DailyChallengeCenter.progress(
            for: challenge,
            attempts: [],
            scoreSessions: sessions,
            now: date,
            calendar: calendar
        ))

        XCTAssertEqual(progress.completedCount, challenge.targetCount)
        XCTAssertTrue(progress.isComplete)
    }

    func testWeeklyMatchChallengeResetsStreakAfterLoss() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = Date(timeIntervalSince1970: 1_785_888_000)
        let challenge = BalootChallenge(
            id: "weekly-match-test",
            cadence: .weekly,
            category: .match,
            title: "سلسلة",
            detail: "اختبار",
            targetCount: 3,
            rewardTitle: "اختبار",
            whatToPlaySeed: nil,
            whatToPlayDifficulty: nil,
            whatToPlayFocusKind: nil
        )
        let weekStart = try XCTUnwrap(calendar.dateInterval(of: .weekOfYear, for: date)?.start)
        let sessions = [
            scoreSession(createdAt: weekStart.addingTimeInterval(60), status: .finished, rounds: [
                ScoreRound(roundNumber: 1, mode: .hokum, teamOneBaseScore: 100, teamTwoBaseScore: 62)
            ]),
            scoreSession(createdAt: weekStart.addingTimeInterval(120), status: .finished, rounds: [
                ScoreRound(roundNumber: 1, mode: .hokum, teamOneBaseScore: 40, teamTwoBaseScore: 122)
            ]),
            scoreSession(createdAt: weekStart.addingTimeInterval(180), status: .finished, rounds: [
                ScoreRound(roundNumber: 1, mode: .hokum, teamOneBaseScore: 100, teamTwoBaseScore: 62)
            ]),
            scoreSession(createdAt: weekStart.addingTimeInterval(240), status: .finished, rounds: [
                ScoreRound(roundNumber: 1, mode: .sun, teamOneBaseScore: 130, teamTwoBaseScore: 20)
            ])
        ]

        let progress = try XCTUnwrap(DailyChallengeCenter.progress(
            for: challenge,
            attempts: [],
            scoreSessions: sessions,
            now: date,
            calendar: calendar
        ))

        XCTAssertEqual(progress.completedCount, 2)
        XCTAssertFalse(progress.isComplete)
    }

    func testWhatToPlayProgressCapsAtChallengeTarget() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = Date(timeIntervalSince1970: 1_785_888_000)
        let challenge = try XCTUnwrap(DailyChallengeCenter.dailyChallenges(for: date, calendar: calendar).first { $0.category == .tactics })
        let difficulty = try XCTUnwrap(challenge.whatToPlayDifficulty)
        let focusKind = try XCTUnwrap(challenge.whatToPlayFocusKind)
        let gameMode = try XCTUnwrap(challenge.whatToPlayGameMode)
        let seed = try XCTUnwrap(challenge.whatToPlaySeed)
        let dayStart = calendar.startOfDay(for: date)
        let attempts = (0..<(challenge.targetCount + 3)).map {
            attempt(
                at: dayStart.addingTimeInterval(TimeInterval($0 + 1)),
                difficulty: difficulty,
                focusKind: focusKind,
                gameMode: gameMode,
                seed: seed &+ UInt64($0)
            )
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

    func testWhatToPlayProgressCountsDuplicateChallengeSeedOnce() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = Date(timeIntervalSince1970: 1_785_888_000)
        let challenge = try XCTUnwrap(DailyChallengeCenter.dailyChallenges(for: date, calendar: calendar).first { $0.category == .tactics })
        let difficulty = try XCTUnwrap(challenge.whatToPlayDifficulty)
        let focusKind = try XCTUnwrap(challenge.whatToPlayFocusKind)
        let gameMode = try XCTUnwrap(challenge.whatToPlayGameMode)
        let seed = try XCTUnwrap(challenge.whatToPlaySeed)
        let laterSeed = seed &+ UInt64(min(1, challenge.targetCount - 1))
        let dayStart = calendar.startOfDay(for: date)
        let attempts = [
            attempt(at: dayStart.addingTimeInterval(60), difficulty: difficulty, focusKind: focusKind, gameMode: gameMode, seed: seed),
            attempt(at: dayStart.addingTimeInterval(120), difficulty: difficulty, focusKind: focusKind, gameMode: gameMode, seed: seed),
            attempt(at: dayStart.addingTimeInterval(180), difficulty: difficulty, focusKind: focusKind, gameMode: gameMode, seed: laterSeed)
        ]

        let progress = try XCTUnwrap(DailyChallengeCenter.progress(
            for: challenge,
            attempts: attempts,
            now: date,
            calendar: calendar
        ))

        XCTAssertEqual(progress.completedCount, min(2, challenge.targetCount))
    }

    func testWhatToPlayProgressReturnsFirstMissingChallengeSeed() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = Date(timeIntervalSince1970: 1_785_888_000)
        let challenge = challengeWithWhatToPlaySeed(targetCount: 3)
        let difficulty = try XCTUnwrap(challenge.whatToPlayDifficulty)
        let focusKind = try XCTUnwrap(challenge.whatToPlayFocusKind)
        let gameMode = try XCTUnwrap(challenge.whatToPlayGameMode)
        let seed = try XCTUnwrap(challenge.whatToPlaySeed)
        let skippedSeed = seed &+ 2
        let dayStart = calendar.startOfDay(for: date)
        let attempts = [
            attempt(at: dayStart.addingTimeInterval(60), difficulty: difficulty, focusKind: focusKind, gameMode: gameMode, seed: seed),
            attempt(at: dayStart.addingTimeInterval(120), difficulty: difficulty, focusKind: focusKind, gameMode: gameMode, seed: skippedSeed)
        ]

        let progress = try XCTUnwrap(DailyChallengeCenter.whatToPlayProgress(
            for: challenge,
            attempts: attempts,
            now: date,
            calendar: calendar
        ))

        XCTAssertEqual(progress.base.completedCount, min(2, challenge.targetCount))
        XCTAssertEqual(progress.nextSeed, seed &+ 1)
        XCTAssertTrue(progress.completedSeeds.contains(seed))
        XCTAssertTrue(progress.completedSeeds.contains(skippedSeed))
        XCTAssertFalse(progress.completedSeeds.contains(seed &+ 1))
    }

    func testWhatToPlayProgressIgnoresMatchingTrainingOutsideChallengeSeedSeries() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = Date(timeIntervalSince1970: 1_785_888_000)
        let challenge = try XCTUnwrap(DailyChallengeCenter.dailyChallenges(for: date, calendar: calendar).first { $0.category == .tactics })
        let difficulty = try XCTUnwrap(challenge.whatToPlayDifficulty)
        let focusKind = try XCTUnwrap(challenge.whatToPlayFocusKind)
        let gameMode = try XCTUnwrap(challenge.whatToPlayGameMode)
        let seed = try XCTUnwrap(challenge.whatToPlaySeed)
        let dayStart = calendar.startOfDay(for: date)
        let attempts = [
            attempt(at: dayStart.addingTimeInterval(60), difficulty: difficulty, focusKind: focusKind, gameMode: gameMode, seed: seed &+ UInt64(challenge.targetCount + 10)),
            attempt(at: dayStart.addingTimeInterval(120), difficulty: difficulty, focusKind: focusKind, gameMode: gameMode, seed: seed &- 1)
        ]

        let progress = try XCTUnwrap(DailyChallengeCenter.progress(
            for: challenge,
            attempts: attempts,
            now: date,
            calendar: calendar
        ))

        XCTAssertEqual(progress.completedCount, 0)
        XCTAssertFalse(progress.isComplete)
    }

    func testNonTacticsChallengesDoNotReturnWhatToPlayProgress() throws {
        let date = Date(timeIntervalSince1970: 1_785_888_000)
        let challenge = try XCTUnwrap(DailyChallengeCenter.dailyChallenges(for: date).first { $0.category == .match })

        XCTAssertNil(DailyChallengeCenter.whatToPlayProgress(for: challenge, attempts: []))
    }

    private func attempt(
        at date: Date,
        difficulty: WhatToPlayDifficulty,
        focusKind: WhatToPlayScenarioFocusKind,
        gameMode: GameMode,
        seed: UInt64 = 1,
        isCorrect: Bool = true
    ) -> WhatToPlayAttempt {
        WhatToPlayAttempt(
            createdAt: date,
            difficulty: difficulty,
            seed: seed,
            selectedCard: PlayingCard(suit: .clubs, rank: .seven),
            bestCard: PlayingCard(suit: .clubs, rank: .seven),
            isCorrect: isCorrect,
            selectedRank: isCorrect ? 1 : 2,
            expectedImpact: isCorrect ? 1 : -1,
            bestExpectedImpact: 1,
            focusKind: focusKind,
            gameMode: gameMode,
            outcome: isCorrect ? .winsTrick : .losesTrick
        )
    }

    private func challengeWithWhatToPlaySeed(targetCount: Int) -> BalootChallenge {
        BalootChallenge(
            id: "test-what-to-play",
            cadence: .daily,
            category: .tactics,
            title: "وش تلعب؟",
            detail: "اختبار",
            targetCount: targetCount,
            rewardTitle: "اختبار",
            whatToPlaySeed: 9_000_000,
            whatToPlayDifficulty: .medium,
            whatToPlayFocusKind: .openingLead,
            whatToPlayGameMode: .hokum
        )
    }

    private func scoringAttempt(
        at date: Date,
        seed: UInt64,
        isCorrect: Bool
    ) -> ScoringQuizAttempt {
        let question = ScoringQuizGenerator.generate(seed: seed, difficulty: .medium)
        let submitted = isCorrect ? question.answer : question.answer + 1
        return ScoringQuizAttempt(
            createdAt: date,
            question: question,
            evaluation: ScoringQuizEvaluator.evaluate(answerText: "\(submitted)", question: question),
            remainingSeconds: isCorrect ? 10 : 0
        )
    }

    private func scoringAttempt(
        at date: Date,
        category: ScoringQuizQuestionCategory,
        isCorrect: Bool
    ) throws -> ScoringQuizAttempt {
        for seed in 1...800 {
            let question = ScoringQuizGenerator.generate(seed: UInt64(seed), difficulty: .hard)
            guard question.category == category else { continue }
            let submitted = isCorrect ? question.answer : question.answer + 1
            return ScoringQuizAttempt(
                createdAt: date,
                question: question,
                evaluation: ScoringQuizEvaluator.evaluate(answerText: "\(submitted)", question: question),
                remainingSeconds: isCorrect ? 10 : 0
            )
        }
        XCTFail("لم يتم العثور على سؤال من نوع \(category.rawValue)")
        throw NSError(domain: "DailyChallengeCenterTests", code: 1)
    }

    private func academyProgress(
        at date: Date,
        lesson: AcademyLesson
    ) -> AcademyLessonProgress {
        AcademyLessonProgress(
            completedAt: date,
            lesson: lesson,
            selectedOptionID: lesson.correctOptionID
        )
    }

    private func scoreSession(
        createdAt: Date,
        status: SessionStatus = .active,
        rounds: [ScoreRound]
    ) -> ScoreSession {
        let session = ScoreSession(
            createdAt: createdAt,
            teamOneName: "فريقنا",
            teamTwoName: "الخصم",
            targetScore: 152,
            status: status
        )
        for round in rounds {
            round.session = session
        }
        session.rounds = rounds
        return session
    }
}
