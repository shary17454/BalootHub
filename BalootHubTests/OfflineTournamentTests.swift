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
