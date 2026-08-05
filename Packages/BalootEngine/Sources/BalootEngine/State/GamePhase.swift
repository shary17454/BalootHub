import Foundation

/// المرحلة الحالية لجولة البلوت.
public enum GamePhase: String, Codable, Sendable, Equatable {
    case setup
    case dealing
    case bidding
    case playing
    case scoring
    case finished
}
