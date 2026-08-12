import Foundation

enum AchievementRarity: String, CaseIterable, Identifiable {
    case bronze
    case silver
    case gold
    case legendary

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bronze: "برونزي".localized
        case .silver: "فضي".localized
        case .gold: "ذهبي".localized
        case .legendary: "أسطوري".localized
        }
    }
}

struct LocalAchievement: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let requirement: String
    let iconName: String
    let rarity: AchievementRarity
}

enum AchievementCenter {
    static let all: [LocalAchievement] = [
        LocalAchievement(
            id: "first-kaboot",
            title: "أول كبوت",
            detail: "حقق كبوتًا في جولة بلوت.",
            requirement: "يفتح عند تسجيل أو لعب أول كبوت.",
            iconName: "crown.fill",
            rarity: .gold
        ),
        LocalAchievement(
            id: "sun-king",
            title: "ملك الصن",
            detail: "افز بعدة جولات صن متتالية.",
            requirement: "يفتح عند وصول سلسلة انتصارات الصن إلى 5.",
            iconName: "sun.max.fill",
            rarity: .silver
        ),
        LocalAchievement(
            id: "hokum-sheikh",
            title: "شيخ الحكم",
            detail: "أثبت قوتك في جولات الحكم.",
            requirement: "يفتح عند الفوز بـ10 جولات حكم.",
            iconName: "suit.spade.fill",
            rarity: .gold
        ),
        LocalAchievement(
            id: "scorekeeper",
            title: "الحاسب",
            detail: "أتقن حساب النتائج بدون أخطاء.",
            requirement: "يفتح عند حل 25 سؤالًا من تحدي حساب النقاط.",
            iconName: "function",
            rarity: .silver
        ),
        LocalAchievement(
            id: "expert-eye",
            title: "عين الخبير".localized,
            detail: "اقرأ مواقف وش تلعب واختر نفس قرار الخبير.".localized,
            requirement: "يفتح عند مطابقة قرار الخبير في 5 مواقف من مدرب وش تلعب.".localized,
            iconName: "eye.fill",
            rarity: .gold
        ),
        LocalAchievement(
            id: "academy-master",
            title: "إتقان المشاريع",
            detail: "أكمل دروس المشاريع والتكتيك في الأكاديمية.",
            requirement: "يفتح عند إكمال كل دروس الأكاديمية الحالية.",
            iconName: "graduationcap.fill",
            rarity: .gold
        ),
        LocalAchievement(
            id: "ten-win-streak",
            title: "10 انتصارات متتالية",
            detail: "حافظ على سلسلة انتصارات طويلة.",
            requirement: "يفتح عند تحقيق 10 انتصارات متتالية.",
            iconName: "flame.fill",
            rarity: .legendary
        ),
        LocalAchievement(
            id: "hundred-matches",
            title: "100 مباراة",
            detail: "استمر في اللعب والتدريب.",
            requirement: "يفتح عند لعب أو تسجيل 100 مباراة.",
            iconName: "100.circle.fill",
            rarity: .legendary
        ),
        LocalAchievement(
            id: "expert-slayer",
            title: "الفوز على أعلى AI",
            detail: "اهزم أصعب مستوى ذكاء اصطناعي.",
            requirement: "يفتح عند الفوز على مستوى شيخ البلوت.",
            iconName: "brain.head.profile",
            rarity: .legendary
        )
    ]

    static func unlockedAchievements(from unlockedIDs: Set<String>) -> [LocalAchievement] {
        all.filter { unlockedIDs.contains($0.id) }
    }

    static func earnedAchievementIDs(whatToPlayAttempts: [WhatToPlayAttempt]) -> Set<String> {
        let uniqueExpertMatchSeeds = Set(
            whatToPlayAttempts
                .filter(\.isCorrect)
                .map(\.replaySeed)
        )
        return uniqueExpertMatchSeeds.count >= 5 ? ["expert-eye"] : []
    }

    static func earnedAchievementIDs(
        whatToPlayAttempts: [WhatToPlayAttempt],
        scoringQuizAttempts: [ScoringQuizAttempt],
        scoreSessions: [ScoreSession] = [],
        rules: ScoreRules = .standard,
        academyProgress: [AcademyLessonProgress] = [],
        legacyCompletedAcademyLessonIDs: Set<String> = []
    ) -> Set<String> {
        var earned = earnedAchievementIDs(whatToPlayAttempts: whatToPlayAttempts)
        let correctScoringAnswers = scoringQuizAttempts.filter(\.isCorrect).count
        if correctScoringAnswers >= 25 {
            earned.insert("scorekeeper")
        }
        if BalootAcademyCatalog.progressSummary(
            progress: academyProgress,
            legacyCompletedLessonIDs: legacyCompletedAcademyLessonIDs
        ).isComplete {
            earned.insert("academy-master")
        }
        earned.formUnion(earnedScoreSessionAchievementIDs(scoreSessions: scoreSessions, rules: rules))
        return earned
    }

    private static func earnedScoreSessionAchievementIDs(scoreSessions: [ScoreSession], rules: ScoreRules) -> Set<String> {
        var earned: Set<String> = []
        var sunWinStreak = 0
        var hokumWins = 0

        let rounds = scoreSessions
            .flatMap(\.rounds)
            .sorted {
                if $0.createdAt != $1.createdAt { return $0.createdAt < $1.createdAt }
                return $0.roundNumber < $1.roundNumber
            }

        for round in rounds {
            let ours = round.teamOneFinalScore(rules: rules)
            let theirs = round.teamTwoFinalScore(rules: rules)
            let wonRound = ours > theirs

            if ours > 0, theirs == 0 {
                earned.insert("first-kaboot")
            }

            if round.mode == .sun, wonRound {
                sunWinStreak += 1
            } else {
                sunWinStreak = 0
            }
            if sunWinStreak >= 5 {
                earned.insert("sun-king")
            }

            if round.mode == .hokum, wonRound {
                hokumWins += 1
            }
            if hokumWins >= 10 {
                earned.insert("hokum-sheikh")
            }
        }

        let finishedMatches = scoreSessions.filter { $0.status == .finished || $0.winnerName(rules: rules) != nil }.count
        if finishedMatches >= 100 {
            earned.insert("hundred-matches")
        }

        return earned
    }
}

enum CareerRank: String, CaseIterable, Identifiable, Equatable {
    case newcomer
    case majlisRegular
    case tableReader
    case tournamentPlayer
    case balootSheikh

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newcomer: "لاعب مبتدئ".localized
        case .majlisRegular: "لاعب مجلس".localized
        case .tableReader: "قارئ طاولة".localized
        case .tournamentPlayer: "لاعب بطولات".localized
        case .balootSheikh: "شيخ البلوت".localized
        }
    }

    var requiredXP: Int {
        switch self {
        case .newcomer: 0
        case .majlisRegular: 250
        case .tableReader: 700
        case .tournamentPlayer: 1_400
        case .balootSheikh: 2_400
        }
    }
}

struct CareerUnlock: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let isUnlocked: Bool
}

struct CareerProgressSummary: Equatable {
    let xp: Int
    let rank: CareerRank
    let nextRank: CareerRank?
    let progressToNextRank: Double
    let completedMatches: Int
    let trainingAttempts: Int
    let correctTrainingAttempts: Int
    let correctScoringAnswers: Int
    let completedAcademyLessons: Int
    let unlockedAchievementCount: Int
    let unlocks: [CareerUnlock]
    let nextStepTitle: String
    let nextStepDetail: String
}

enum CareerProgressAnalyzer {
    static func summarize(
        scoreSessions: [ScoreSession] = [],
        whatToPlayAttempts: [WhatToPlayAttempt] = [],
        scoringQuizAttempts: [ScoringQuizAttempt] = [],
        academyProgress: [AcademyLessonProgress] = [],
        unlockedAchievementIDs: Set<String> = [],
        legacyCompletedAcademyLessonIDs: Set<String> = [],
        rules: ScoreRules = .standard
    ) -> CareerProgressSummary {
        let completedMatches = scoreSessions.filter { $0.status == .finished || $0.winnerName(rules: rules) != nil }.count
        let correctTrainingAttempts = whatToPlayAttempts.filter(\.isCorrect).count
        let correctScoringAnswers = scoringQuizAttempts.filter(\.isCorrect).count
        let completedAcademyLessonIDs = Set(academyProgress.map(\.lessonID))
            .union(legacyCompletedAcademyLessonIDs)
            .intersection(Set(BalootAcademyCatalog.lessons.map(\.id)))
        let earnedIDs = AchievementCenter.earnedAchievementIDs(
            whatToPlayAttempts: whatToPlayAttempts,
            scoringQuizAttempts: scoringQuizAttempts,
            scoreSessions: scoreSessions,
            rules: rules,
            academyProgress: academyProgress,
            legacyCompletedAcademyLessonIDs: legacyCompletedAcademyLessonIDs
        )
        let allUnlockedAchievementIDs = unlockedAchievementIDs.union(earnedIDs)
        let xp = completedMatches * 80
            + correctTrainingAttempts * 18
            + correctScoringAnswers * 10
            + completedAcademyLessonIDs.count * 35
            + allUnlockedAchievementIDs.count * 70
        let rank = CareerRank.allCases.last { xp >= $0.requiredXP } ?? .newcomer
        let nextRank = CareerRank.allCases.first { $0.requiredXP > xp }
        let progress = progressToNextRank(xp: xp, rank: rank, nextRank: nextRank)
        let unlocks = makeUnlocks(
            completedMatches: completedMatches,
            correctTrainingAttempts: correctTrainingAttempts,
            correctScoringAnswers: correctScoringAnswers,
            completedAcademyLessons: completedAcademyLessonIDs.count,
            unlockedAchievementCount: allUnlockedAchievementIDs.count
        )
        let nextStep = nextStep(
            completedMatches: completedMatches,
            correctTrainingAttempts: correctTrainingAttempts,
            correctScoringAnswers: correctScoringAnswers,
            completedAcademyLessons: completedAcademyLessonIDs.count
        )

        return CareerProgressSummary(
            xp: xp,
            rank: rank,
            nextRank: nextRank,
            progressToNextRank: progress,
            completedMatches: completedMatches,
            trainingAttempts: whatToPlayAttempts.count,
            correctTrainingAttempts: correctTrainingAttempts,
            correctScoringAnswers: correctScoringAnswers,
            completedAcademyLessons: completedAcademyLessonIDs.count,
            unlockedAchievementCount: allUnlockedAchievementIDs.count,
            unlocks: unlocks,
            nextStepTitle: nextStep.title,
            nextStepDetail: nextStep.detail
        )
    }

    private static func progressToNextRank(xp: Int, rank: CareerRank, nextRank: CareerRank?) -> Double {
        guard let nextRank else { return 1 }
        let current = rank.requiredXP
        let span = max(1, nextRank.requiredXP - current)
        return min(1, max(0, Double(xp - current) / Double(span)))
    }

    private static func makeUnlocks(
        completedMatches: Int,
        correctTrainingAttempts: Int,
        correctScoringAnswers: Int,
        completedAcademyLessons: Int,
        unlockedAchievementCount: Int
    ) -> [CareerUnlock] {
        [
            CareerUnlock(
                id: "majlis-table",
                title: "طاولة المجلس".localized,
                detail: "تفتح بعد أول مباراة مكتملة.".localized,
                isUnlocked: completedMatches >= 1
            ),
            CareerUnlock(
                id: "trainer-path",
                title: "مسار قارئ الطاولة".localized,
                detail: "يفتح بعد 10 قرارات صحيحة في وش تلعب.".localized,
                isUnlocked: correctTrainingAttempts >= 10
            ),
            CareerUnlock(
                id: "accountant-badge",
                title: "لقب الحاسب".localized,
                detail: "يفتح بعد 25 إجابة صحيحة في تحدي النقاط.".localized,
                isUnlocked: correctScoringAnswers >= 25
            ),
            CareerUnlock(
                id: "academy-certificate",
                title: "شهادة الأكاديمية".localized,
                detail: "تفتح بعد 8 دروس مكتملة.".localized,
                isUnlocked: completedAcademyLessons >= 8
            ),
            CareerUnlock(
                id: "titles-room",
                title: "مجلس الألقاب".localized,
                detail: "يفتح بعد 5 إنجازات.".localized,
                isUnlocked: unlockedAchievementCount >= 5
            )
        ]
    }

    private static func nextStep(
        completedMatches: Int,
        correctTrainingAttempts: Int,
        correctScoringAnswers: Int,
        completedAcademyLessons: Int
    ) -> (title: String, detail: String) {
        if completedMatches == 0 {
            return ("ابدأ أول مباراة".localized, "أكمل مباراة أو جلسة تسجيل حتى يبدأ سجل المسيرة من نتيجة حقيقية.".localized)
        }
        if completedAcademyLessons < 4 {
            return ("أكمل دروس البداية".localized, "ادخل الأكاديمية وأنهِ دروس الأوراق، التوزيع، الصن والحكم، واحتساب النقاط.".localized)
        }
        if correctTrainingAttempts < 10 {
            return ("درّب قراءة الطاولة".localized, "حل مواقف وش تلعب حتى تجمع 10 قرارات صحيحة مرتبطة بتحليل الخبير.".localized)
        }
        if correctScoringAnswers < 25 {
            return ("ثبّت الحساب".localized, "أجب على تحديات النقاط حتى تصل إلى 25 إجابة صحيحة.".localized)
        }
        return ("ارفع مستوى الخصوم".localized, "المرحلة التالية هي اللعب ضد خصوم أقوى ومراجعة Replay بعد كل جولة.".localized)
    }
}
