import SwiftUI
import SwiftData

/// يجمع الاستعلامات الثمانية اللازمة لحساب تقدّم المسار المهني في مكان واحد،
/// ويمرّر الملخّص لأي شاشة تحتاجه.
///
/// كانت هذه الاستعلامات مكرّرة حرفيًا داخل ``CareerModeView``، ومع ربط فتح أنماط
/// التخصيص بالرتبة صارت مطلوبة في شاشة ثانية — فجُمعت هنا بدل نسخها مرة أخرى.
struct CareerProgressContainer<Content: View>: View {
    @AppStorage("unlockedBalootAchievementIDs") private var unlockedAchievementIDs = ""
    @AppStorage("completedBalootChallengeIDs") private var completedChallengeIDs = ""
    @AppStorage("balootAcademyCompletedLessons") private var completedAcademyLessonIDs = ""
    @Query(sort: \ScoreSession.createdAt, order: .reverse) private var scoreSessions: [ScoreSession]
    @Query(sort: \WhatToPlayAttempt.createdAt, order: .reverse) private var whatToPlayAttempts: [WhatToPlayAttempt]
    @Query(sort: \ScoringQuizAttempt.createdAt, order: .reverse) private var scoringQuizAttempts: [ScoringQuizAttempt]
    @Query(sort: \AcademyLessonProgress.completedAt, order: .reverse) private var academyProgress: [AcademyLessonProgress]
    @Query(sort: \OfflineTournament.updatedAt, order: .reverse) private var offlineTournaments: [OfflineTournament]
    @Query private var settingsList: [AppSettings]

    @ViewBuilder let content: (CareerProgressSummary) -> Content

    var body: some View {
        content(summary)
    }

    private var scoreRules: ScoreRules {
        settingsList.first?.scoreRules ?? .standard
    }

    private var summary: CareerProgressSummary {
        CareerProgressAnalyzer.summarize(
            scoreSessions: scoreSessions,
            whatToPlayAttempts: whatToPlayAttempts,
            scoringQuizAttempts: scoringQuizAttempts,
            academyProgress: academyProgress,
            offlineTournaments: offlineTournaments,
            completedChallengeIDs: completedChallengeSet,
            unlockedAchievementIDs: unlockedSet,
            legacyCompletedAcademyLessonIDs: completedAcademySet,
            rules: scoreRules
        )
    }

    private var unlockedSet: Set<String> {
        Set(unlockedAchievementIDs.split(separator: ",").map(String.init))
    }

    private var completedAcademySet: Set<String> {
        Set(completedAcademyLessonIDs.split(separator: ",").map(String.init))
    }

    private var completedChallengeSet: Set<String> {
        Set(completedChallengeIDs.split(separator: ",").map(String.init))
            .union(DailyChallengeCenter.completedChallengeIDs(
                for: DailyChallengeCenter.challenges(),
                attempts: whatToPlayAttempts,
                scoringQuizAttempts: scoringQuizAttempts,
                academyProgress: academyProgress,
                scoreSessions: scoreSessions,
                rules: scoreRules,
                legacyCompletedAcademyLessonIDs: completedAcademySet
            ))
    }
}
