import Foundation

/// فريق مكوّن من لاعبين متقابلين على الطاولة.
public struct Team: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var name: String

    public init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
