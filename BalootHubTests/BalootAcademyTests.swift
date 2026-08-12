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

    func testAcademyCoversRequiredLearningPathTopics() {
        let expectedIDs: Set<String> = [
            "beginner-cards",
            "beginner-deal",
            "beginner-ordering",
            "beginner-sun-hokum",
            "beginner-follow-suit",
            "beginner-cutting",
            "beginner-scoring",
            "intermediate-read-play",
            "intermediate-memory",
            "intermediate-cutting",
            "intermediate-pull-trump",
            "intermediate-partner",
            "intermediate-opening-lead",
            "intermediate-opponent-read",
            "advanced-card-counting",
            "advanced-deduction",
            "advanced-bidding-read",
            "advanced-probability",
            "advanced-pressure",
            "advanced-hand-management",
            "advanced-sacrifice",
            "advanced-mode-strategy"
        ]
        let actualIDs = Set(BalootAcademyCatalog.lessons.map(\.id))

        XCTAssertTrue(expectedIDs.isSubset(of: actualIDs), "Missing academy topics: \(expectedIDs.subtracting(actualIDs).sorted())")
    }

    func testAcademyProgressSummaryCombinesStoredAndLegacyLessons() throws {
        let first = try XCTUnwrap(BalootAcademyCatalog.lesson(id: "beginner-cards"))
        let second = try XCTUnwrap(BalootAcademyCatalog.lesson(id: "beginner-deal"))
        let progress = [
            AcademyLessonProgress(lesson: first, selectedOptionID: first.correctOptionID)
        ]

        let summary = BalootAcademyCatalog.progressSummary(
            progress: progress,
            legacyCompletedLessonIDs: [second.id, "missing-lesson"]
        )

        XCTAssertEqual(summary.completedLessonIDs, [first.id, second.id])
        XCTAssertEqual(summary.completedCount, 2)
        XCTAssertEqual(summary.totalLessons, BalootAcademyCatalog.lessons.count)
        XCTAssertGreaterThan(summary.completionPercent, 0)
        XCTAssertFalse(summary.isComplete)
    }

    func testAcademyProgressSummaryDetectsFullCompletion() {
        let progress = BalootAcademyCatalog.lessons.map {
            AcademyLessonProgress(lesson: $0, selectedOptionID: $0.correctOptionID)
        }

        let summary = BalootAcademyCatalog.progressSummary(progress: progress)

        XCTAssertEqual(summary.completedCount, BalootAcademyCatalog.lessons.count)
        XCTAssertEqual(summary.completionPercent, 100)
        XCTAssertTrue(summary.isComplete)
    }
}
