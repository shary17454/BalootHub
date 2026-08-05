import Foundation

/// نوع اللاعب: إنسان أو لاعب آلي.
public enum PlayerKind: String, Codable, Sendable {
    case human
    case ai
}

/// موقع اللاعب حول الطاولة، يُستخدم لتحديد ترتيب الأدوار.
public enum SeatPosition: Int, CaseIterable, Codable, Sendable {
    case south = 0
    case west = 1
    case north = 2
    case east = 3

    /// الموقع التالي في اتجاه عقارب الساعة (ترتيب الأدوار المعتمد في البلوت).
    public var next: SeatPosition {
        SeatPosition(rawValue: (rawValue + 1) % 4) ?? .south
    }
}

/// لاعب داخل جولة بلوت محلية.
public struct Player: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var name: String
    public var kind: PlayerKind
    public var seat: SeatPosition
    public var teamID: Team.ID

    public init(id: UUID = UUID(), name: String, kind: PlayerKind, seat: SeatPosition, teamID: Team.ID) {
        self.id = id
        self.name = name
        self.kind = kind
        self.seat = seat
        self.teamID = teamID
    }
}
