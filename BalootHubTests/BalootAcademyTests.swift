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

    func testNextLessonRecommendationMovesToNextIncompleteLesson() throws {
        let current = try XCTUnwrap(BalootAcademyCatalog.lesson(id: "beginner-cards"))
        let completed: Set<String> = [current.id]

        let recommendation = try XCTUnwrap(BalootAcademyCatalog.nextLessonRecommendation(
            currentLessonID: current.id,
            completedLessonIDs: completed
        ))

        XCTAssertEqual(recommendation.lesson.id, "beginner-deal")
        XCTAssertEqual(recommendation.title, "الدرس التالي".localized)
        XCTAssertTrue(recommendation.detail.contains(recommendation.lesson.title))
    }

    func testNextLessonRecommendationSkipsCompletedLessonsAndWrapsLevels() throws {
        let completed = Set(BalootAcademyCatalog.lessons.map(\.id))
            .subtracting(["intermediate-memory"])

        let recommendation = try XCTUnwrap(BalootAcademyCatalog.nextLessonRecommendation(
            currentLessonID: "advanced-mode-strategy",
            completedLessonIDs: completed
        ))

        XCTAssertEqual(recommendation.lesson.id, "intermediate-memory")
        XCTAssertEqual(recommendation.lesson.level, .intermediate)
    }

    func testNextLessonRecommendationReturnsNilWhenAcademyIsComplete() {
        let completed = Set(BalootAcademyCatalog.lessons.map(\.id))

        XCTAssertNil(BalootAcademyCatalog.nextLessonRecommendation(
            currentLessonID: "advanced-mode-strategy",
            completedLessonIDs: completed
        ))
    }
}
