import XCTest
@testable import BalootHub

final class BalootAcademyTests: XCTestCase {
    func testAcademyHasLessonsForEveryLevel() {
        for level in AcademyLevel.allCases {
            XCTAssertFalse(BalootAcademyCatalog.lessons(for: level).isEmpty, "Missing lessons for \(level.rawValue)")
        }
    }

    func testEveryLessonHasPracticalDecisionAndCorrectOption() {
        for lesson in BalootAcademyCatalog.lessons {
            XCTAssertFalse(lesson.explanation.isEmpty)
            XCTAssertFalse(lesson.example.isEmpty)
            XCTAssertFalse(lesson.prompt.isEmpty)
            XCTAssertGreaterThanOrEqual(lesson.options.count, 2)
            XCTAssertNotNil(lesson.correctOption)
        }
    }

    func testLessonIDsAreUniqueForReplayableProgress() {
        let ids = BalootAcademyCatalog.lessons.map(\.id)

        XCTAssertEqual(ids.count, Set(ids).count)
    }
}
