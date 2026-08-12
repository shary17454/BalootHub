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

    func testScorekeeperUnlocksAfterTwentyFiveCorrectScoringQuizAnswers() {
        let scoringAttempts = (0..<25).map { index in
            makeScoringQuizAttempt(seed: UInt64(index), isCorrect: true)
        }

        XCTAssertTrue(
            AchievementCenter.earnedAchievementIDs(
                whatToPlayAttempts: [],
                scoringQuizAttempts: scoringAttempts
            )
            .contains("scorekeeper")
        )
    }

    func testScorekeeperIgnoresWrongScoringQuizAnswers() {
        let scoringAttempts = (0..<25).map { index in
            makeScoringQuizAttempt(seed: UInt64(index), isCorrect: index != 24)
        }

        XCTAssertFalse(
            AchievementCenter.earnedAchievementIDs(
                whatToPlayAttempts: [],
                scoringQuizAttempts: scoringAttempts
            )
            .contains("scorekeeper")
        )
    }

    func testScoringSheikhAchievementExists() throws {
        let achievement = try XCTUnwrap(AchievementCenter.all.first { $0.id == "scoring-sheikh" })

        XCTAssertEqual(achievement.rarity, .gold)
        XCTAssertEqual(achievement.iconName, "function")
        XCTAssertFalse(achievement.title.isEmpty)
        XCTAssertFalse(achievement.detail.isEmpty)
        XCTAssertFalse(achievement.requirement.isEmpty)
    }

    func testScoringSheikhUnlocksAfterFiveCorrectHardScoringQuizAnswers() {
        let scoringAttempts = (0..<5).map { index in
            makeScoringQuizAttempt(seed: UInt64(index), difficulty: .hard, isCorrect: true)
        }

        XCTAssertTrue(
            AchievementCenter.earnedAchievementIDs(
                whatToPlayAttempts: [],
                scoringQuizAttempts: scoringAttempts
            )
            .contains("scoring-sheikh")
        )
    }

    func testScoringSheikhIgnoresMediumAndWrongHardAnswers() {
        let scoringAttempts = [
            makeScoringQuizAttempt(seed: 1, difficulty: .hard, isCorrect: true),
            makeScoringQuizAttempt(seed: 2, difficulty: .hard, isCorrect: true),
            makeScoringQuizAttempt(seed: 3, difficulty: .hard, isCorrect: true),
            makeScoringQuizAttempt(seed: 4, difficulty: .hard, isCorrect: true),
            makeScoringQuizAttempt(seed: 5, difficulty: .hard, isCorrect: false),
            makeScoringQuizAttempt(seed: 6, difficulty: .medium, isCorrect: true)
        ]

        XCTAssertFalse(
            AchievementCenter.earnedAchievementIDs(
                whatToPlayAttempts: [],
                scoringQuizAttempts: scoringAttempts
            )
            .contains("scoring-sheikh")
        )
    }

    func testAcademyMasterUnlocksAfterAllLessonsCompleted() {
        let progress = BalootAcademyCatalog.lessons.map {
            AcademyLessonProgress(lesson: $0, selectedOptionID: $0.correctOptionID)
        }

        XCTAssertTrue(
            AchievementCenter.earnedAchievementIDs(
                whatToPlayAttempts: [],
                scoringQuizAttempts: [],
                academyProgress: progress
            )
            .contains("academy-master")
        )
    }

    func testAcademyMasterIncludesLegacyCompletedLessons() {
        let completed = Set(BalootAcademyCatalog.lessons.map(\.id))

        XCTAssertTrue(
            AchievementCenter.earnedAchievementIDs(
                whatToPlayAttempts: [],
                scoringQuizAttempts: [],
                legacyCompletedAcademyLessonIDs: completed
            )
            .contains("academy-master")
        )
    }

    func testFirstKabootUnlocksFromScoreSessionRound() {
        let session = makeScoreSession(rounds: [
            ScoreRound(roundNumber: 1, mode: .hokum, teamOneBaseScore: 162, teamTwoBaseScore: 0)
        ])

        XCTAssertTrue(
            AchievementCenter.earnedAchievementIDs(
                whatToPlayAttempts: [],
                scoringQuizAttempts: [],
                scoreSessions: [session]
            )
            .contains("first-kaboot")
        )
    }

    func testSunKingUnlocksAfterFiveConsecutiveSunRoundWins() {
        let session = makeScoreSession(rounds: (1...5).map {
            ScoreRound(roundNumber: $0, mode: .sun, teamOneBaseScore: 130, teamTwoBaseScore: 40)
        })

        XCTAssertTrue(
            AchievementCenter.earnedAchievementIDs(
                whatToPlayAttempts: [],
                scoringQuizAttempts: [],
                scoreSessions: [session]
            )
            .contains("sun-king")
        )
    }

    func testSunKingRequiresConsecutiveSunWins() {
        let session = makeScoreSession(rounds: [
            ScoreRound(roundNumber: 1, mode: .sun, teamOneBaseScore: 130, teamTwoBaseScore: 40),
            ScoreRound(roundNumber: 2, mode: .sun, teamOneBaseScore: 130, teamTwoBaseScore: 40),
            ScoreRound(roundNumber: 3, mode: .hokum, teamOneBaseScore: 90, teamTwoBaseScore: 72),
            ScoreRound(roundNumber: 4, mode: .sun, teamOneBaseScore: 130, teamTwoBaseScore: 40),
            ScoreRound(roundNumber: 5, mode: .sun, teamOneBaseScore: 130, teamTwoBaseScore: 40),
            ScoreRound(roundNumber: 6, mode: .sun, teamOneBaseScore: 130, teamTwoBaseScore: 40)
        ])

        XCTAssertFalse(
            AchievementCenter.earnedAchievementIDs(
                whatToPlayAttempts: [],
                scoringQuizAttempts: [],
                scoreSessions: [session]
            )
            .contains("sun-king")
        )
    }

    func testHokumSheikhUnlocksAfterTenHokumRoundWins() {
        let session = makeScoreSession(rounds: (1...10).map {
            ScoreRound(roundNumber: $0, mode: .hokum, teamOneBaseScore: 100, teamTwoBaseScore: 62)
        })

        XCTAssertTrue(
            AchievementCenter.earnedAchievementIDs(
                whatToPlayAttempts: [],
                scoringQuizAttempts: [],
                scoreSessions: [session]
            )
            .contains("hokum-sheikh")
        )
    }

    func testHundredMatchesUnlocksFromFinishedScoreSessions() {
        let sessions = (0..<100).map { index in
            makeScoreSession(
                createdAt: Date(timeIntervalSince1970: TimeInterval(index)),
                status: .finished,
                rounds: [
                    ScoreRound(roundNumber: 1, mode: .hokum, teamOneBaseScore: 100, teamTwoBaseScore: 62)
                ]
            )
        }

        XCTAssertTrue(
            AchievementCenter.earnedAchievementIDs(
                whatToPlayAttempts: [],
                scoringQuizAttempts: [],
                scoreSessions: sessions
            )
            .contains("hundred-matches")
        )
    }

    func testHundredMatchesIgnoresActiveSessionsBelowTarget() {
        let sessions = (0..<100).map { index in
            makeScoreSession(
                createdAt: Date(timeIntervalSince1970: TimeInterval(index)),
                status: .active,
                rounds: []
            )
        }

        XCTAssertFalse(
            AchievementCenter.earnedAchievementIDs(
                whatToPlayAttempts: [],
                scoringQuizAttempts: [],
                scoreSessions: sessions
            )
            .contains("hundred-matches")
        )
    }

    func testOfflineCupWinnerUnlocksFromFinishedTournament() throws {
        let tournament = try makeFinishedTournament(seed: 10)

        XCTAssertTrue(
            AchievementCenter.earnedAchievementIDs(
                whatToPlayAttempts: [],
                scoringQuizAttempts: [],
                offlineTournaments: [tournament]
            )
            .contains("offline-cup-winner")
        )
    }

    func testOfflineDynastyUnlocksWhenSameTeamWinsThreeTournaments() {
        let tournaments = (0..<3).map { index in
            OfflineTournament(
                createdAt: Date(timeIntervalSince1970: TimeInterval(index)),
                title: "بطولة \(index)",
                format: .knockout,
                teams: ["فريقنا", "الخصم", "فريق 3", "فريق 4"],
                matches: [],
                status: .finished,
                championName: "فريقنا"
            )
        }

        let earned = AchievementCenter.earnedAchievementIDs(
            whatToPlayAttempts: [],
            scoringQuizAttempts: [],
            offlineTournaments: tournaments
        )

        XCTAssertTrue(earned.contains("offline-cup-winner"))
        XCTAssertTrue(earned.contains("offline-dynasty"))
    }

    func testEightTeamChampionUnlocksOnlyAfterFinishedEightTeamTournament() throws {
        let activeEight = OfflineTournamentPlanner.makeTournament(title: "ثماني", format: .knockout, teamCount: 8, seed: 10)
        let finishedEight = try makeFinishedKnockoutTournament(teamCount: 8, seed: 11)

        let activeEarned = AchievementCenter.earnedAchievementIDs(
            whatToPlayAttempts: [],
            scoringQuizAttempts: [],
            offlineTournaments: [activeEight]
        )
        let finishedEarned = AchievementCenter.earnedAchievementIDs(
            whatToPlayAttempts: [],
            scoringQuizAttempts: [],
            offlineTournaments: [finishedEight]
        )

        XCTAssertFalse(activeEarned.contains("offline-eight-team-champion"))
        XCTAssertTrue(finishedEarned.contains("offline-eight-team-champion"))
    }

    func testChallengeRegularUnlocksAfterFiveCompletedChallenges() {
        let completedChallengeIDs = Set((0..<5).map { "challenge-\($0)" })

        let earned = AchievementCenter.earnedAchievementIDs(
            whatToPlayAttempts: [],
            scoringQuizAttempts: [],
            completedChallengeIDs: completedChallengeIDs
        )

        XCTAssertTrue(earned.contains("challenge-regular"))
    }

    func testCareerProgressStartsAsNewcomerWithFirstMatchNextStep() {
        let summary = CareerProgressAnalyzer.summarize()

        XCTAssertEqual(summary.xp, 0)
        XCTAssertEqual(summary.rank, .newcomer)
        XCTAssertEqual(summary.nextRank, .majlisRegular)
        XCTAssertEqual(summary.progressToNextRank, 0)
        XCTAssertEqual(summary.completedMatches, 0)
        XCTAssertEqual(summary.nextStepTitle, "ابدأ أول مباراة".localized)
        XCTAssertTrue(summary.unlocks.allSatisfy { !$0.isUnlocked })
    }

    func testCareerProgressAccumulatesXPAndUnlocksFromLocalData() {
        let session = makeScoreSession(
            status: .finished,
            rounds: [
                ScoreRound(roundNumber: 1, mode: .hokum, teamOneBaseScore: 100, teamTwoBaseScore: 62)
            ]
        )
        let whatToPlayAttempts = (0..<10).map { index in
            makeWhatToPlayAttempt(seed: UInt64(index), isCorrect: true)
        }
        let scoringAttempts = (0..<25).map { index in
            makeScoringQuizAttempt(seed: UInt64(index), isCorrect: true)
        }
        let academyProgress = BalootAcademyCatalog.lessons.prefix(8).map {
            AcademyLessonProgress(lesson: $0, selectedOptionID: $0.correctOptionID)
        }

        let summary = CareerProgressAnalyzer.summarize(
            scoreSessions: [session],
            whatToPlayAttempts: whatToPlayAttempts,
            scoringQuizAttempts: scoringAttempts,
            academyProgress: academyProgress
        )

        XCTAssertEqual(summary.completedMatches, 1)
        XCTAssertEqual(summary.correctTrainingAttempts, 10)
        XCTAssertEqual(summary.correctScoringAnswers, 25)
        XCTAssertEqual(summary.completedAcademyLessons, 8)
        XCTAssertGreaterThanOrEqual(summary.xp, CareerRank.tableReader.requiredXP)
        XCTAssertTrue(summary.unlocks.first { $0.id == "majlis-table" }?.isUnlocked == true)
        XCTAssertTrue(summary.unlocks.first { $0.id == "trainer-path" }?.isUnlocked == true)
        XCTAssertTrue(summary.unlocks.first { $0.id == "accountant-badge" }?.isUnlocked == true)
        XCTAssertTrue(summary.unlocks.first { $0.id == "academy-certificate" }?.isUnlocked == true)
    }

    func testCareerProgressIncludesFinishedOfflineTournaments() throws {
        let tournament = OfflineTournamentPlanner.makeTournament(title: "كأس", format: .knockout, teamCount: 4, seed: 10)
        let firstRound = tournament.matches
        OfflineTournamentPlanner.recordWin(for: firstRound[0].id, side: .home, in: tournament)
        OfflineTournamentPlanner.recordWin(for: firstRound[1].id, side: .away, in: tournament)
        let final = try XCTUnwrap(tournament.matches.first { $0.roundNumber == 2 })
        OfflineTournamentPlanner.recordWin(for: final.id, side: .home, in: tournament)

        let summary = CareerProgressAnalyzer.summarize(offlineTournaments: [tournament])

        XCTAssertEqual(summary.completedTournaments, 1)
        XCTAssertEqual(summary.tournamentTitles, 1)
        XCTAssertGreaterThanOrEqual(summary.xp, 120)
        XCTAssertTrue(summary.unlocks.first { $0.id == "offline-cup-path" }?.isUnlocked == true)
        XCTAssertTrue(summary.unlocks.first { $0.id == "champion-title" }?.isUnlocked == true)
    }

    func testCareerProgressIncludesCompletedChallenges() {
        let completedChallengeIDs = Set((0..<5).map { "challenge-\($0)" })

        let summary = CareerProgressAnalyzer.summarize(completedChallengeIDs: completedChallengeIDs)

        XCTAssertEqual(summary.completedChallenges, 5)
        XCTAssertGreaterThanOrEqual(summary.xp, 150)
        XCTAssertTrue(summary.unlocks.first { $0.id == "challenge-board" }?.isUnlocked == true)
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

    private func makeScoringQuizAttempt(
        seed: UInt64,
        difficulty: ScoringQuizDifficulty = .medium,
        isCorrect: Bool
    ) -> ScoringQuizAttempt {
        let question = ScoringQuizGenerator.generate(seed: seed, difficulty: difficulty)
        let submitted = isCorrect ? question.answer : question.answer + 1
        return ScoringQuizAttempt(
            question: question,
            evaluation: ScoringQuizEvaluator.evaluate(answerText: "\(submitted)", question: question),
            remainingSeconds: isCorrect ? 10 : 0
        )
    }

    private func makeScoreSession(
        createdAt: Date = Date(timeIntervalSince1970: 0),
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

    private func makeFinishedTournament(seed: UInt64) throws -> OfflineTournament {
        let tournament = OfflineTournamentPlanner.makeTournament(title: "كأس", format: .knockout, teamCount: 4, seed: seed)
        let firstRound = tournament.matches
        OfflineTournamentPlanner.recordWin(for: firstRound[0].id, side: .home, in: tournament)
        OfflineTournamentPlanner.recordWin(for: firstRound[1].id, side: .away, in: tournament)
        let final = try XCTUnwrap(tournament.matches.first { $0.roundNumber == 2 })
        OfflineTournamentPlanner.recordWin(for: final.id, side: .home, in: tournament)
        return tournament
    }

    private func makeFinishedKnockoutTournament(teamCount: Int, seed: UInt64) throws -> OfflineTournament {
        let tournament = OfflineTournamentPlanner.makeTournament(title: "كأس", format: .knockout, teamCount: teamCount, seed: seed)
        var completedMatchIDs: Set<UUID> = []
        while tournament.status == .active {
            let nextMatch = try XCTUnwrap(tournament.matches.first {
                !completedMatchIDs.contains($0.id) && !$0.isComplete(format: tournament.format)
            })
            OfflineTournamentPlanner.recordWin(for: nextMatch.id, side: .home, in: tournament)
            completedMatchIDs.insert(nextMatch.id)
        }
        return tournament
    }
}
