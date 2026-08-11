import Foundation
import SwiftData

enum OfflineTournamentFormat: String, Codable, CaseIterable, Identifiable {
    case knockout
    case league
    case bestOfThreeCup

    var id: String { rawValue }

    var title: String {
        switch self {
        case .knockout: "خروج مغلوب".localized
        case .league: "دوري".localized
        case .bestOfThreeCup: "كأس أفضل من 3".localized
        }
    }
}

enum OfflineTournamentStatus: String, Codable, CaseIterable {
    case active
    case finished
}

struct OfflineTournamentMatch: Codable, Equatable, Identifiable {
    let id: UUID
    let roundNumber: Int
    let homeTeam: String
    let awayTeam: String
    var homeWins: Int
    var awayWins: Int

    init(
        id: UUID = UUID(),
        roundNumber: Int,
        homeTeam: String,
        awayTeam: String,
        homeWins: Int = 0,
        awayWins: Int = 0
    ) {
        self.id = id
        self.roundNumber = roundNumber
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.homeWins = homeWins
        self.awayWins = awayWins
    }
}

@Model
final class OfflineTournament {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var title: String
    var formatRaw: String
    var statusRaw: String
    var teamsRaw: String
    var matchesRaw: String
    var championName: String?

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date = .now,
        title: String,
        format: OfflineTournamentFormat,
        teams: [String],
        matches: [OfflineTournamentMatch],
        status: OfflineTournamentStatus = .active,
        championName: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.title = title
        self.formatRaw = format.rawValue
        self.statusRaw = status.rawValue
        self.teamsRaw = teams.joined(separator: "\n")
        self.matchesRaw = Self.encodeMatches(matches)
        self.championName = championName
    }

    var format: OfflineTournamentFormat {
        get { OfflineTournamentFormat(rawValue: formatRaw) ?? .knockout }
        set { formatRaw = newValue.rawValue }
    }

    var status: OfflineTournamentStatus {
        get { OfflineTournamentStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    var teams: [String] {
        get { teamsRaw.split(separator: "\n").map(String.init) }
        set { teamsRaw = newValue.joined(separator: "\n") }
    }

    var matches: [OfflineTournamentMatch] {
        get { Self.decodeMatches(matchesRaw) }
        set {
            matchesRaw = Self.encodeMatches(newValue)
            updatedAt = .now
        }
    }

    func finish(champion: String) {
        championName = champion
        status = .finished
        updatedAt = .now
    }

    private static func encodeMatches(_ matches: [OfflineTournamentMatch]) -> String {
        guard let data = try? JSONEncoder().encode(matches) else { return "[]" }
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    private static func decodeMatches(_ raw: String) -> [OfflineTournamentMatch] {
        guard let data = raw.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([OfflineTournamentMatch].self, from: data)) ?? []
    }
}
