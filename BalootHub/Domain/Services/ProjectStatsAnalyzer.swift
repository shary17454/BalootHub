import Foundation
import BalootEngine

/// تفصيل إحصائي لمشاريع نوع واحد عبر كل الجولات الفعلية المسجَّلة.
struct ProjectKindStat: Identifiable, Equatable {
    let kind: Project.Kind
    let declaredCount: Int
    let awardedCount: Int
    let totalPoints: Int

    var id: String { kind.rawValue }

    var successRatePercent: Int {
        guard declaredCount > 0 else { return 0 }
        return Int((Double(awardedCount) / Double(declaredCount) * 100).rounded())
    }
}

enum ProjectStatsAnalyzer {
    /// تفصيل الإعلانات حسب نوع المشروع، مرتّب من الأكثر إعلانًا إلى الأقل.
    static func kindBreakdown(records: [ProjectDeclarationRecord]) -> [ProjectKindStat] {
        let byKind = Dictionary(grouping: records.compactMap { record in
            record.kind.map { (kind: $0, record: record) }
        }) { $0.kind }

        return byKind.map { kind, pairs in
            let awarded = pairs.filter { $0.record.wasAwarded }
            return ProjectKindStat(
                kind: kind,
                declaredCount: pairs.count,
                awardedCount: awarded.count,
                totalPoints: awarded.reduce(0) { $0 + $1.record.points }
            )
        }
        .sorted { lhs, rhs in
            if lhs.declaredCount != rhs.declaredCount {
                return lhs.declaredCount > rhs.declaredCount
            }
            return lhs.kind.priorityOrder > rhs.kind.priorityOrder
        }
    }

    /// أكثر نوع مشروع إعلانًا، تُستخدم في بطاقة الأسلوب.
    static func mostDeclaredKind(records: [ProjectDeclarationRecord]) -> ProjectKindStat? {
        kindBreakdown(records: records).first
    }
}
