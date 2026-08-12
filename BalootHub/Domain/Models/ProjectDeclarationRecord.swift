import Foundation
import SwiftData
import BalootEngine

/// سجل إعلان مشروع واحد من لاعب بشري في جولة فعلية، يُستخدم لإحصائيات المشاريع
/// حسب النوع (تكرار الإعلان ونسبة نجاحه) في ``PlayerStatsView``.
@Model
final class ProjectDeclarationRecord {
    var id: UUID
    var createdAt: Date
    var kindRaw: String
    var points: Int
    var wasAwarded: Bool

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        kind: Project.Kind,
        points: Int,
        wasAwarded: Bool
    ) {
        self.id = id
        self.createdAt = createdAt
        self.kindRaw = kind.rawValue
        self.points = points
        self.wasAwarded = wasAwarded
    }

    var kind: Project.Kind? {
        Project.Kind(rawValue: kindRaw)
    }
}
