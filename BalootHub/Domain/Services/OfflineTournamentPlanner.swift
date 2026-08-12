import Foundation

enum OfflineTournamentPlanner {
    enum ResultSide {
        case home
        case away
    }

    struct StatsSummary: Equatable {
        let tournaments: Int
        let activeTournaments: Int
        let finishedTournaments: Int
        let fourTeamTournaments: Int
        let eightTeamTournaments: Int
        let finishedEightTeamTournaments: Int
        let scheduledMatches: Int
        let completedMatches: Int
        let championshipTeams: [String: Int]
        let mostDecoratedTeam: String?
        let mostDecoratedTeamTitles: Int
        let completionPercent: Int

        static let empty = StatsSummary(
            tournaments: 0,
            activeTournaments: 0,
            finishedTournaments: 0,
            fourTeamTournaments: 0,
            eightTeamTournaments: 0,
            finishedEightTeamTournaments: 0,
            scheduledMatches: 0,
            completedMatches: 0,
            championshipTeams: [:],
            mostDecoratedTeam: nil,
            mostDecoratedTeamTitles: 0,
            completionPercent: 0
        )
    }

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
        standingsSnapshot(teams: tournament.teams, matches: tournament.matches)
    }

    static func stats(for tournaments: [OfflineTournament]) -> StatsSummary {
        guard !tournaments.isEmpty else { return .empty }

        let active = tournaments.filter { $0.status == .active }.count
        let finished = tournaments.filter { $0.status == .finished }.count
        let fourTeamTournaments = tournaments.filter { $0.teams.count == 4 }.count
        let eightTeamTournaments = tournaments.filter { $0.teams.count == 8 }.count
        let finishedEightTeamTournaments = tournaments.filter {
            $0.status == .finished && $0.teams.count == 8
        }.count
        let scheduledMatches = tournaments.reduce(0) { $0 + $1.matches.count }
        let completedMatches = tournaments.reduce(0) { total, tournament in
            total + tournament.matches.filter { $0.isComplete(format: tournament.format) }.count
        }
        let champions = Dictionary(grouping: tournaments.compactMap(\.championName), by: { $0 })
            .mapValues(\.count)
        let decorated = champions.sorted { lhs, rhs in
            if lhs.value != rhs.value { return lhs.value > rhs.value }
            return lhs.key < rhs.key
        }.first
        let completionPercent = scheduledMatches == 0
            ? 0
            : Int((Double(completedMatches) / Double(scheduledMatches) * 100).rounded())

        return StatsSummary(
            tournaments: tournaments.count,
            activeTournaments: active,
            finishedTournaments: finished,
            fourTeamTournaments: fourTeamTournaments,
            eightTeamTournaments: eightTeamTournaments,
            finishedEightTeamTournaments: finishedEightTeamTournaments,
            scheduledMatches: scheduledMatches,
            completedMatches: completedMatches,
            championshipTeams: champions,
            mostDecoratedTeam: decorated?.key,
            mostDecoratedTeamTitles: decorated?.value ?? 0,
            completionPercent: completionPercent
        )
    }

    static func recordWin(
        for matchID: UUID,
        side: ResultSide,
        in tournament: OfflineTournament
    ) {
        guard tournament.status == .active else { return }
        var matches = tournament.matches
        guard let index = matches.firstIndex(where: { $0.id == matchID }) else { return }

        switch side {
        case .home:
            matches[index].homeWins += 1
        case .away:
            matches[index].awayWins += 1
        }

        advanceTournamentIfNeeded(matches: &matches, tournament: tournament)
        tournament.matches = matches
    }

    static func resetMatch(
        matchID: UUID,
        in tournament: OfflineTournament
    ) {
        guard tournament.status == .active else { return }
        var matches = tournament.matches
        guard let index = matches.firstIndex(where: { $0.id == matchID }) else { return }
        let match = matches[index]
        matches[index] = OfflineTournamentMatch(
            id: match.id,
            roundNumber: match.roundNumber,
            homeTeam: match.homeTeam,
            awayTeam: match.awayTeam
        )
        let resetRound = match.roundNumber
        matches.removeAll { $0.roundNumber > resetRound }
        tournament.championName = nil
        tournament.matches = matches
    }

    private static func advanceTournamentIfNeeded(
        matches: inout [OfflineTournamentMatch],
        tournament: OfflineTournament
    ) {
        switch tournament.format {
        case .league:
            let allComplete = !matches.isEmpty && matches.allSatisfy { $0.isComplete(format: tournament.format) }
            if allComplete, let leader = standingsSnapshot(teams: tournament.teams, matches: matches).first {
                tournament.finish(champion: leader.team)
            }

        case .knockout, .bestOfThreeCup:
            guard let currentRound = matches.map(\.roundNumber).max() else { return }
            let currentRoundMatches = matches.filter { $0.roundNumber == currentRound }
            guard !currentRoundMatches.isEmpty,
                  currentRoundMatches.allSatisfy({ $0.isComplete(format: tournament.format) })
            else { return }

            let winners = currentRoundMatches.compactMap { $0.winner(format: tournament.format) }
            guard winners.count == currentRoundMatches.count else { return }

            if winners.count == 1 {
                tournament.finish(champion: winners[0])
                return
            }

            let nextRound = currentRound + 1
            guard !matches.contains(where: { $0.roundNumber == nextRound }) else { return }
            matches.append(contentsOf: pairedMatches(
                teams: winners,
                roundNumber: nextRound,
                existingMatchCount: matches.count
            ))
        }
    }

    private static func standingsSnapshot(
        teams: [String],
        matches: [OfflineTournamentMatch]
    ) -> [(team: String, wins: Int, played: Int)] {
        teams
            .map { team in
                let teamMatches = matches.filter { $0.homeTeam == team || $0.awayTeam == team }
                let wins = teamMatches.reduce(0) { total, match in
                    if match.homeTeam == team { return total + match.homeWins }
                    if match.awayTeam == team { return total + match.awayWins }
                    return total
                }
                let played = teamMatches.filter { $0.homeWins > 0 || $0.awayWins > 0 }.count
                return (team: team, wins: wins, played: played)
            }
            .sorted { lhs, rhs in
                if lhs.wins == rhs.wins { return lhs.team < rhs.team }
                return lhs.wins > rhs.wins
            }
    }

    private static func knockoutSchedule(teams: [String], seed: UInt64) -> [OfflineTournamentMatch] {
        pairedMatches(teams: teams, roundNumber: 1, existingMatchCount: 0, seed: seed)
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

    private static func pairedMatches(
        teams: [String],
        roundNumber: Int,
        existingMatchCount: Int,
        seed: UInt64 = 0xB410_07A5_0000_0001
    ) -> [OfflineTournamentMatch] {
        stride(from: 0, to: teams.count, by: 2).compactMap { index in
            guard index + 1 < teams.count else { return nil }
            return makeMatch(
                seed: seed &+ UInt64(roundNumber) &* 10_000,
                index: existingMatchCount + index / 2,
                roundNumber: roundNumber,
                homeTeam: teams[index],
                awayTeam: teams[index + 1]
            )
        }
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
