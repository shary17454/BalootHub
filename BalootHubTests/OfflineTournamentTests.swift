import XCTest
import SwiftData
@testable import BalootHub

final class OfflineTournamentTests: XCTestCase {
    func testKnockoutScheduleIsDeterministic() {
        let teams = ["A", "B", "C", "D", "E", "F", "G", "H"]
        let first = OfflineTournamentPlanner.schedule(format: .knockout, teams: teams, seed: 44)
        let second = OfflineTournamentPlanner.schedule(format: .knockout, teams: teams, seed: 44)

        XCTAssertEqual(first, second)
        XCTAssertEqual(first.count, 4)
    }

    func testLeagueScheduleCreatesRoundRobinPairs() {
        let matches = OfflineTournamentPlanner.schedule(format: .league, teams: ["A", "B", "C", "D"], seed: 1)

        XCTAssertEqual(matches.count, 6)
        XCTAssertTrue(matches.contains { $0.homeTeam == "A" && $0.awayTeam == "D" })
    }

    func testRecordWinUpdatesMatchAndStandings() throws {
        let tournament = OfflineTournamentPlanner.makeTournament(title: "دوري", format: .league, teamCount: 4, seed: 10)
        let firstMatch = try XCTUnwrap(tournament.matches.first)

        OfflineTournamentPlanner.recordWin(for: firstMatch.id, side: .home, in: tournament)

        let updated = try XCTUnwrap(tournament.matches.first { $0.id == firstMatch.id })
        XCTAssertEqual(updated.homeWins, 1)
        XCTAssertEqual(updated.awayWins, 0)
        XCTAssertEqual(updated.winner(format: .league), firstMatch.homeTeam)
        XCTAssertEqual(OfflineTournamentPlanner.standings(for: tournament).first?.team, firstMatch.homeTeam)
        XCTAssertEqual(OfflineTournamentPlanner.standings(for: tournament).first?.played, 1)
    }

    func testTournamentStatsSummarizeHistoryAndChampionCounts() throws {
        let active = OfflineTournamentPlanner.makeTournament(title: "نشطة", format: .league, teamCount: 4, seed: 9)
        let finished = OfflineTournamentPlanner.makeTournament(title: "كأس", format: .knockout, teamCount: 4, seed: 10)
        let firstRound = finished.matches
        OfflineTournamentPlanner.recordWin(for: firstRound[0].id, side: .home, in: finished)
        OfflineTournamentPlanner.recordWin(for: firstRound[1].id, side: .away, in: finished)
        let final = try XCTUnwrap(finished.matches.first { $0.roundNumber == 2 })
        OfflineTournamentPlanner.recordWin(for: final.id, side: .home, in: finished)

        let summary = OfflineTournamentPlanner.stats(for: [active, finished])

        XCTAssertEqual(summary.tournaments, 2)
        XCTAssertEqual(summary.activeTournaments, 1)
        XCTAssertEqual(summary.finishedTournaments, 1)
        XCTAssertEqual(summary.completedMatches, 3)
        XCTAssertEqual(summary.scheduledMatches, active.matches.count + finished.matches.count)
        XCTAssertEqual(summary.championshipTeams[final.homeTeam], 1)
        XCTAssertEqual(summary.mostDecoratedTeam, final.homeTeam)
        XCTAssertEqual(summary.mostDecoratedTeamTitles, 1)
        XCTAssertGreaterThan(summary.completionPercent, 0)
    }

    func testBestOfThreeRequiresTwoWins() throws {
        let tournament = OfflineTournamentPlanner.makeTournament(title: "كأس", format: .bestOfThreeCup, teamCount: 4, seed: 10)
        let firstMatch = try XCTUnwrap(tournament.matches.first)

        OfflineTournamentPlanner.recordWin(for: firstMatch.id, side: .home, in: tournament)
        XCTAssertNil(tournament.matches.first { $0.id == firstMatch.id }?.winner(format: .bestOfThreeCup))

        OfflineTournamentPlanner.recordWin(for: firstMatch.id, side: .home, in: tournament)
        XCTAssertEqual(tournament.matches.first { $0.id == firstMatch.id }?.winner(format: .bestOfThreeCup), firstMatch.homeTeam)
    }

    func testKnockoutAdvancesWinnersToNextRoundAndFinishesChampion() throws {
        let tournament = OfflineTournamentPlanner.makeTournament(title: "كأس", format: .knockout, teamCount: 4, seed: 10)
        let firstRound = tournament.matches
        XCTAssertEqual(firstRound.count, 2)

        OfflineTournamentPlanner.recordWin(for: firstRound[0].id, side: .home, in: tournament)
        OfflineTournamentPlanner.recordWin(for: firstRound[1].id, side: .away, in: tournament)

        let final = tournament.matches.filter { $0.roundNumber == 2 }
        XCTAssertEqual(final.count, 1)
        XCTAssertEqual(final.first?.homeTeam, firstRound[0].homeTeam)
        XCTAssertEqual(final.first?.awayTeam, firstRound[1].awayTeam)
        XCTAssertEqual(tournament.status, .active)

        let finalMatch = try XCTUnwrap(final.first)
        OfflineTournamentPlanner.recordWin(for: finalMatch.id, side: .away, in: tournament)

        XCTAssertEqual(tournament.status, .finished)
        XCTAssertEqual(tournament.championName, firstRound[1].awayTeam)
    }

    func testResetMatchRemovesLaterKnockoutRounds() throws {
        let tournament = OfflineTournamentPlanner.makeTournament(title: "كأس", format: .knockout, teamCount: 4, seed: 10)
        let firstRound = tournament.matches
        OfflineTournamentPlanner.recordWin(for: firstRound[0].id, side: .home, in: tournament)
        OfflineTournamentPlanner.recordWin(for: firstRound[1].id, side: .away, in: tournament)
        XCTAssertTrue(tournament.matches.contains { $0.roundNumber == 2 })

        OfflineTournamentPlanner.resetMatch(matchID: firstRound[0].id, in: tournament)

        XCTAssertFalse(tournament.matches.contains { $0.roundNumber == 2 })
        let reset = try XCTUnwrap(tournament.matches.first { $0.id == firstRound[0].id })
        XCTAssertEqual(reset.homeWins, 0)
        XCTAssertEqual(reset.awayWins, 0)
        XCTAssertEqual(tournament.status, .active)
    }

    func testTournamentTextSummaryIsDeterministicAndIncludesResults() throws {
        let tournament = OfflineTournamentPlanner.makeTournament(title: "دوري المجلس", format: .league, teamCount: 4, seed: 10)
        let firstMatch = try XCTUnwrap(tournament.matches.first)
        OfflineTournamentPlanner.recordWin(for: firstMatch.id, side: .home, in: tournament)

        let first = tournament.textSummary()
        let second = tournament.textSummary()

        XCTAssertEqual(first, second)
        XCTAssertTrue(first.contains("ملخص بطولة البلوت"))
        XCTAssertTrue(first.contains("دوري المجلس"))
        XCTAssertTrue(first.contains("الترتيب"))
        XCTAssertTrue(first.contains("الجدول"))
        XCTAssertTrue(first.contains("\(firstMatch.homeTeam) 1-0 \(firstMatch.awayTeam)"))
        XCTAssertTrue(first.contains("الفائز: \(firstMatch.homeTeam)"))
    }

    func testTournamentTextSummaryIncludesChampionWhenFinished() throws {
        let tournament = OfflineTournamentPlanner.makeTournament(title: "كأس", format: .knockout, teamCount: 4, seed: 10)
        let firstRound = tournament.matches
        OfflineTournamentPlanner.recordWin(for: firstRound[0].id, side: .home, in: tournament)
        OfflineTournamentPlanner.recordWin(for: firstRound[1].id, side: .away, in: tournament)
        let final = try XCTUnwrap(tournament.matches.first { $0.roundNumber == 2 })
        OfflineTournamentPlanner.recordWin(for: final.id, side: .home, in: tournament)

        let summary = tournament.textSummary()

        XCTAssertEqual(tournament.status, .finished)
        XCTAssertTrue(summary.contains("الحالة: منتهية"))
        XCTAssertTrue(summary.contains("البطل: \(final.homeTeam)"))
    }

    func testTournamentPersistsInSwiftDataSchema() throws {
        let configuration = ModelConfiguration(schema: PersistenceController.appSchema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PersistenceController.appSchema, configurations: [configuration])
        let context = ModelContext(container)
        let tournament = OfflineTournamentPlanner.makeTournament(title: "كأس", format: .bestOfThreeCup, teamCount: 4, seed: 10)

        context.insert(tournament)
        try context.save()

        let saved = try context.fetch(FetchDescriptor<OfflineTournament>())
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved.first?.matches.count, 2)
    }
}
