import Foundation

enum OfflineTournamentPlanner {
    static func makeTournament(
        title: String,
        format: OfflineTournamentFormat,
        teamCount: Int,
        seed: UInt64
    ) -> OfflineTournament {
        let teams = (1...teamCount).map { "فريق \($0)" }
        let matches = schedule(format: format, teams: teams, seed: seed)
        return OfflineTournament(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? format.title : title,
            format: format,
            teams: teams,
            matches: matches
        )
    }

    static func schedule(format: OfflineTournamentFormat, teams: [String], seed: UInt64) -> [OfflineTournamentMatch] {
        let normalizedTeams = teams.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard normalizedTeams.count >= 4 else { return [] }

        switch format {
        case .knockout, .bestOfThreeCup:
            return knockoutSchedule(teams: shuffled(normalizedTeams, seed: seed), seed: seed)
        case .league:
            return leagueSchedule(teams: normalizedTeams, seed: seed)
        }
    }

    static func standings(for tournament: OfflineTournament) -> [(team: String, wins: Int, played: Int)] {
        tournament.teams
            .map { team in
                let matches = tournament.matches.filter { $0.homeTeam == team || $0.awayTeam == team }
                let wins = matches.reduce(0) { total, match in
                    if match.homeTeam == team { return total + match.homeWins }
                    if match.awayTeam == team { return total + match.awayWins }
                    return total
                }
                return (team: team, wins: wins, played: matches.count)
            }
            .sorted { lhs, rhs in
                if lhs.wins == rhs.wins { return lhs.team < rhs.team }
                return lhs.wins > rhs.wins
            }
    }

    private static func knockoutSchedule(teams: [String], seed: UInt64) -> [OfflineTournamentMatch] {
        stride(from: 0, to: teams.count, by: 2).compactMap { index in
            guard index + 1 < teams.count else { return nil }
            return makeMatch(seed: seed, index: index / 2, roundNumber: 1, homeTeam: teams[index], awayTeam: teams[index + 1])
        }
    }

    private static func leagueSchedule(teams: [String], seed: UInt64) -> [OfflineTournamentMatch] {
        var matches: [OfflineTournamentMatch] = []
        var matchIndex = 0
        for homeIndex in teams.indices {
            for awayIndex in teams.indices where awayIndex > homeIndex {
                matches.append(makeMatch(seed: seed, index: matchIndex, roundNumber: 1, homeTeam: teams[homeIndex], awayTeam: teams[awayIndex]))
                matchIndex += 1
            }
        }
        return matches
    }

    private static func makeMatch(seed: UInt64, index: Int, roundNumber: Int, homeTeam: String, awayTeam: String) -> OfflineTournamentMatch {
        OfflineTournamentMatch(
            id: stableUUID(seed: seed, index: index),
            roundNumber: roundNumber,
            homeTeam: homeTeam,
            awayTeam: awayTeam
        )
    }

    private static func stableUUID(seed: UInt64, index: Int) -> UUID {
        let value = seed &+ UInt64(index) &* 0x9E37_79B9_7F4A_7C15
        return UUID(uuid: (
            UInt8((value >> 56) & 0xff),
            UInt8((value >> 48) & 0xff),
            UInt8((value >> 40) & 0xff),
            UInt8((value >> 32) & 0xff),
            UInt8((value >> 24) & 0xff),
            UInt8((value >> 16) & 0xff),
            UInt8((value >> 8) & 0xff),
            UInt8(value & 0xff),
            UInt8((UInt64(index) >> 56) & 0xff),
            UInt8((UInt64(index) >> 48) & 0xff),
            UInt8((UInt64(index) >> 40) & 0xff),
            UInt8((UInt64(index) >> 32) & 0xff),
            UInt8((UInt64(index) >> 24) & 0xff),
            UInt8((UInt64(index) >> 16) & 0xff),
            UInt8((UInt64(index) >> 8) & 0xff),
            UInt8(UInt64(index) & 0xff)
        ))
    }

    private static func shuffled(_ teams: [String], seed: UInt64) -> [String] {
        var result = teams
        var generator = TournamentSeededGenerator(seed: seed)
        guard result.count > 1 else { return result }
        for index in stride(from: result.count - 1, through: 1, by: -1) {
            let swapIndex = generator.nextInt(upperBound: index + 1)
            result.swapAt(index, swapIndex)
        }
        return result
    }
}

private struct TournamentSeededGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0xD1B5_4A32_D192_ED03 : seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }

    mutating func nextInt(upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        return Int(next() % UInt64(upperBound))
    }
}
