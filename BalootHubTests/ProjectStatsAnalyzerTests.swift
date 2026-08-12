import XCTest
import BalootEngine
@testable import BalootHub

final class ProjectStatsAnalyzerTests: XCTestCase {
    func testBreaksDownDeclarationsByKindWithSuccessRate() {
        let records = [
            ProjectDeclarationRecord(kind: .sira, points: 20, wasAwarded: true),
            ProjectDeclarationRecord(kind: .sira, points: 20, wasAwarded: false),
            ProjectDeclarationRecord(kind: .sira, points: 20, wasAwarded: true),
            ProjectDeclarationRecord(kind: .belot, points: 20, wasAwarded: true)
        ]

        let breakdown = ProjectStatsAnalyzer.kindBreakdown(records: records)

        let sira = breakdown.first { $0.kind == .sira }
        XCTAssertEqual(sira?.declaredCount, 3)
        XCTAssertEqual(sira?.awardedCount, 2)
        XCTAssertEqual(sira?.totalPoints, 40)
        XCTAssertEqual(sira?.successRatePercent, 67)

        let belot = breakdown.first { $0.kind == .belot }
        XCTAssertEqual(belot?.declaredCount, 1)
        XCTAssertEqual(belot?.successRatePercent, 100)
    }

    func testOrdersByDeclaredCountDescending() {
        let records = [
            ProjectDeclarationRecord(kind: .fifty, points: 50, wasAwarded: true),
            ProjectDeclarationRecord(kind: .sira, points: 20, wasAwarded: true),
            ProjectDeclarationRecord(kind: .sira, points: 20, wasAwarded: true)
        ]

        let breakdown = ProjectStatsAnalyzer.kindBreakdown(records: records)

        XCTAssertEqual(breakdown.first?.kind, .sira)
        XCTAssertEqual(ProjectStatsAnalyzer.mostDeclaredKind(records: records)?.kind, .sira)
    }

    func testEmptyRecordsProduceEmptyBreakdown() {
        XCTAssertTrue(ProjectStatsAnalyzer.kindBreakdown(records: []).isEmpty)
        XCTAssertNil(ProjectStatsAnalyzer.mostDeclaredKind(records: []))
    }

    func testUnawardedProjectHasZeroSuccessRateAndPoints() {
        let records = [ProjectDeclarationRecord(kind: .hundred, points: 100, wasAwarded: false)]

        let stat = ProjectStatsAnalyzer.kindBreakdown(records: records).first

        XCTAssertEqual(stat?.declaredCount, 1)
        XCTAssertEqual(stat?.awardedCount, 0)
        XCTAssertEqual(stat?.totalPoints, 0)
        XCTAssertEqual(stat?.successRatePercent, 0)
    }
}
