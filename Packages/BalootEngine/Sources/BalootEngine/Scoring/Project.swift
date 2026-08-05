import Foundation

/// نوع المشروع (الإعلان) المكتشف في يد لاعب.
/// النسخة الحالية تدعم "البلوت" فقط (شايب وبنت الحكم)، وهو المشروع الوحيد
/// المتفق عليه بلا خلاف بين المجالس. أنواع أخرى (سرا، خمسين، مية) تُترك
/// كامتداد مستقبلي ولا تُحتسب هنا حتى لا تُدَّعى ميزة غير مكتملة.
public struct Project: Identifiable, Codable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case belot
    }

    public let id: UUID
    public let kind: Kind
    public let teamID: Team.ID
    public let playerID: Player.ID
    public let points: Int

    public init(id: UUID = UUID(), kind: Kind, teamID: Team.ID, playerID: Player.ID, points: Int) {
        self.id = id
        self.kind = kind
        self.teamID = teamID
        self.playerID = playerID
        self.points = points
    }
}
