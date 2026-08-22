import SwiftUI
import SwiftData

struct BalootAcademyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AcademyLessonProgress.completedAt, order: .reverse) private var lessonProgress: [AcademyLessonProgress]

    @State private var level: AcademyLevel = .beginner
    @State private var selectedLessonID: String = BalootAcademyCatalog.lessons(for: .beginner).first?.id ?? ""
    @State private var selectedOptionID: String?
    @AppStorage("balootAcademyCompletedLessons") private var completedLessonIDs = ""

    init(initialLessonID: String? = nil) {
        if let lessonID = initialLessonID,
           let lesson = BalootAcademyCatalog.lesson(id: lessonID) {
            _level = State(initialValue: lesson.level)
            _selectedLessonID = State(initialValue: lesson.id)
        }
    }

    private var lessons: [AcademyLesson] {
        BalootAcademyCatalog.lessons(for: level)
    }

    private var selectedLesson: AcademyLesson? {
        lessons.first { $0.id == selectedLessonID } ?? lessons.first
    }

    private var completedSet: Set<String> {
        progressSummary.completedLessonIDs
    }

    private var legacyCompletedSet: Set<String> {
        Set(completedLessonIDs.split(separator: ",").map(String.init))
    }

    private var progressSummary: AcademyProgressSummary {
        BalootAcademyCatalog.progressSummary(
            progress: lessonProgress,
            legacyCompletedLessonIDs: legacyCompletedSet
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                header
                levelPicker
                lessonStrip

                if let selectedLesson {
                    lessonCard(selectedLesson)
                    practicalCard(selectedLesson)
                }
            }
            .padding(AppSpacing.md)
            .adaptiveContentWidth()
        }
        .background(AppColor.background)
        .navigationTitle("أكاديمية البلوت")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: level) { _, newLevel in
            selectedLessonID = BalootAcademyCatalog.lessons(for: newLevel).first?.id ?? ""
            selectedOptionID = nil
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label("تعلّم بالقرار", systemImage: "graduationcap.fill")
                .font(AppTypography.title)
                .foregroundStyle(AppColor.primary)
            Text("كل درس يعطيك شرحًا مختصرًا، مثالًا، ثم موقفًا عمليًا تقرر فيه وتقرأ سبب القرار.")
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColor.textSecondary)
            HStack {
                StatusBadge("\(progressSummary.completedCount)/\(progressSummary.totalLessons)", systemImage: "checkmark.seal.fill", tint: AppColor.success)
                StatusBadge("\(progressSummary.completionPercent)%", systemImage: "chart.pie.fill", tint: AppColor.primary)
                StatusBadge(level.title, systemImage: level.iconName, tint: AppColor.accent)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private var levelPicker: some View {
        Picker("المستوى", selection: $level) {
            ForEach(AcademyLevel.allCases) { level in
                Text(level.title).tag(level)
            }
        }
        .pickerStyle(.segmented)
    }

    private var lessonStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(lessons) { lesson in
                    Button {
                        selectedLessonID = lesson.id
                        selectedOptionID = nil
                    } label: {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Image(systemName: completedSet.contains(lesson.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(completedSet.contains(lesson.id) ? AppColor.success : AppColor.textSecondary)
                            Text(lesson.title)
                                .font(AppTypography.caption.weight(.semibold))
                                .foregroundStyle(AppColor.textPrimary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(width: 150, height: 86, alignment: .leading)
                        .padding(AppSpacing.sm)
                        .background(
                            selectedLessonID == lesson.id ? AppColor.primary.opacity(0.14) : AppColor.surface,
                            in: RoundedRectangle(cornerRadius: AppRadius.medium)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func lessonCard(_ lesson: AcademyLesson) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(lesson.title)
                .font(AppTypography.title)
                .foregroundStyle(AppColor.textPrimary)
            academyBlock(title: "الشرح", icon: "book.fill", body: lesson.explanation)
            academyBlock(title: "مثال", icon: "rectangle.and.pencil.and.ellipsis", body: lesson.example)
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private func practicalCard(_ lesson: AcademyLesson) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            academyBlock(title: "الموقف العملي", icon: "hand.point.up.left.fill", body: lesson.prompt)

            ForEach(lesson.options) { option in
                optionButton(option, lesson: lesson)
            }

            if let selectedOptionID,
               let selectedOption = lesson.options.first(where: { $0.id == selectedOptionID }) {
                resultCard(option: selectedOption, lesson: lesson)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))
    }

    private func optionButton(_ option: AcademyOption, lesson: AcademyLesson) -> some View {
        let isSelected = selectedOptionID == option.id
        let isCorrect = option.id == lesson.correctOptionID

        return Button {
            selectedOptionID = option.id
            if isCorrect {
                markCompleted(lesson: lesson, selectedOptionID: option.id)
            }
        } label: {
            HStack {
                Text(option.title)
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(isCorrect ? AppColor.success : AppColor.danger)
                }
            }
            .padding(AppSpacing.md)
            .background(isSelected ? AppColor.accent.opacity(0.12) : AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        }
        .buttonStyle(.plain)
    }

    private func resultCard(option: AcademyOption, lesson: AcademyLesson) -> some View {
        let isCorrect = option.id == lesson.correctOptionID

        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label(isCorrect ? lesson.successResult : lesson.failureResult, systemImage: isCorrect ? "checkmark.seal.fill" : "lightbulb.fill")
                .font(AppTypography.headline)
                .foregroundStyle(isCorrect ? AppColor.success : AppColor.warning)
            Text(option.rationale)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColor.textPrimary)
            Text(option.expectedImpact)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
            if !isCorrect, let correct = lesson.correctOption {
                Text("أفضل قرار: \(correct.title)")
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.primary)
            } else if isCorrect,
                      let next = BalootAcademyCatalog.nextLessonRecommendation(
                          currentLessonID: lesson.id,
                          completedLessonIDs: completedSet
                      ) {
                Button {
                    level = next.lesson.level
                    selectedLessonID = next.lesson.id
                    selectedOptionID = nil
                } label: {
                    Label(next.detail, systemImage: next.iconName)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.primary)
                .accessibilityLabel(next.title)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.medium))
        .accessibilityElement(children: .combine)
    }

    private func academyBlock(title: String, icon: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label(title, systemImage: icon)
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.primary)
            Text(body)
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func markCompleted(lesson: AcademyLesson, selectedOptionID: String) {
        var set = completedSet
        set.insert(lesson.id)
        completedLessonIDs = set.sorted().joined(separator: ",")

        guard !lessonProgress.contains(where: { $0.lessonID == lesson.id }) else { return }
        modelContext.insert(AcademyLessonProgress(
            lesson: lesson,
            selectedOptionID: selectedOptionID
        ))
        try? modelContext.save()
    }
}
