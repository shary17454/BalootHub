import Foundation
import SwiftData

@Model
final class AcademyLessonProgress {
    var id: UUID
    var completedAt: Date
    var lessonID: String
    var levelRaw: String
    var selectedOptionID: String

    init(
        id: UUID = UUID(),
        completedAt: Date = .now,
        lesson: AcademyLesson,
        selectedOptionID: String
    ) {
        self.id = id
        self.completedAt = completedAt
        self.lessonID = lesson.id
        self.levelRaw = lesson.level.rawValue
        self.selectedOptionID = selectedOptionID
    }

    var level: AcademyLevel {
        AcademyLevel(rawValue: levelRaw) ?? .beginner
    }
}
