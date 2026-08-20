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
            requirement: "يتحقق عند تسجيل أو لعب أول كبوت.",
            iconName: "crown.fill",
            rarity: .gold
        ),
        LocalAchievement(
            id: "sun-king",
            title: "ملك الصن",
            detail: "افز بعدة جولات صن متتالية.",
            requirement: "يتحقق عند وصول سلسلة انتصارات الصن إلى 5.",
            iconName: "sun.max.fill",
            rarity: .silver
        ),
        LocalAchievement(
            id: "hokum-sheikh",
            title: "شيخ الحكم",
            detail: "أثبت قوتك في جولات الحكم.",
            requirement: "يتحقق عند الفوز بـ10 جولات حكم.",
            iconName: "suit.spade.fill",
            rarity: .gold
        ),
        LocalAchievement(
            id: "scorekeeper",
            title: "الحاسب",
            detail: "أتقن حساب النتائج بدون أخطاء.",
            requirement: "يتحقق عند حل 25 سؤالًا من تحدي حساب النقاط.",
            iconName: "function",
            rarity: .silver
        ),
        LocalAchievement(
            id: "scoring-sheikh",
            title: "شيخ الحساب".localized,
            detail: "أتقن حساب النقاط في الأسئلة الصعبة التي تشمل المشاريع والمضاعفات.".localized,
            requirement: "يتحقق عند حل 5 أسئلة صعبة صحيحة في تحدي حساب النقاط.".localized,
            iconName: "function",
            rarity: .gold
        ),
        LocalAchievement(
            id: "coffee-calculator",
            title: "خبير القهوة".localized,
            detail: "أتقن حساب جولات القهوة والمضاعفات العالية في تحدي النقاط.".localized,
            requirement: "يتحقق عند حل 5 أسئلة قهوة صحيحة في تحدي حساب النقاط.".localized,
            iconName: "cup.and.saucer.fill",
            rarity: .gold
        ),
        LocalAchievement(
            id: "expert-eye",
            title: "عين الخبير".localized,
            detail: "اقرأ مواقف وش تلعب واختر نفس قرار الخبير.".localized,
            requirement: "يتحقق عند مطابقة قرار الخبير في 5 مواقف من مدرب وش تلعب.".localized,
            iconName: "eye.fill",
            rarity: .gold
        ),
        LocalAchievement(
            id: "academy-master",
            title: "إتقان المشاريع",
            detail: "أكمل دروس المشاريع والتكتيك في الأكاديمية.",
            requirement: "يتحقق عند إكمال كل دروس الأكاديمية الحالية.",
            iconName: "graduationcap.fill",
            rarity: .gold
        ),
        LocalAchievement(
            id: "offline-cup-winner",
            title: "بطل المجلس".localized,
            detail: "أنهى بطولة Offline واعتمد بطلها.".localized,
            requirement: "يتحقق عند إنهاء أول بطولة Offline.".localized,
            iconName: "trophy.fill",
            rarity: .silver
        ),
        LocalAchievement(
            id: "offline-dynasty",
            title: "سلالة بطولات".localized,
            detail: "فريق واحد سيطر على بطولات المجلس المحلية.".localized,
            requirement: "يتحقق عندما يحقق فريق واحد 3 بطولات Offline.".localized,
            iconName: "crown.fill",
            rarity: .legendary
        ),
        LocalAchievement(
            id: "offline-eight-team-champion",
            title: "بطل الثمانية".localized,
            detail: "أنهى بطولة Offline كاملة من 8 فرق واعتمد بطلها.".localized,
            requirement: "يتحقق عند إنهاء أول بطولة Offline من 8 فرق.".localized,
            iconName: "trophy.circle.fill",
            rarity: .gold
        ),
        LocalAchievement(
            id: "challenge-regular",
            title: "ملتزم التحديات".localized,
            detail: "أكمل عدة تحديات يومية أو أسبوعية محلية.".localized,
            requirement: "يتحقق عند إكمال 5 تحديات بلوت Offline.".localized,
            iconName: "calendar.badge.checkmark",
            rarity: .silver
        ),
        LocalAchievement(
            id: "ten-win-streak",
            title: "10 انتصارات متتالية",
            detail: "حافظ على سلسلة انتصارات طويلة.",
            requirement: "يتحقق عند تحقيق 10 انتصارات متتالية.",
            iconName: "flame.fill",
            rarity: .legendary
        ),
        LocalAchievement(
            id: "hundred-matches",
            title: "100 مباراة",
            detail: "استمر في اللعب والتدريب.",
            requirement: "يتحقق عند لعب أو تسجيل 100 مباراة.",
            iconName: "100.circle.fill",
            rarity: .legendary
        ),
        LocalAchievement(
            id: "expert-slayer",
            title: "الفوز على أعلى AI",
            detail: "اهزم أصعب مستوى ذكاء اصطناعي.",
            requirement: "يتحقق عند الفوز على مستوى شيخ البلوت.",
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
        offlineTournaments: [OfflineTournament] = [],
        completedChallengeIDs: Set<String> = [],
        rules: ScoreRules = .standard,
        academyProgress: [AcademyLessonProgress] = [],
        legacyCompletedAcademyLessonIDs: Set<String> = []
    ) -> Set<String> {
        var earned = earnedAchievementIDs(whatToPlayAttempts: whatToPlayAttempts)
        let correctScoringAnswers = scoringQuizAttempts.filter(\.isCorrect).count
        if correctScoringAnswers >= 25 {
            earned.insert("scorekeeper")
        }
        let correctHardScoringAnswers = scoringQuizAttempts.filter {
            $0.isCorrect && $0.difficulty == .hard
        }.count
        if correctHardScoringAnswers >= 5 {
            earned.insert("scoring-sheikh")
        }
        let correctCoffeeAnswers = scoringQuizAttempts.filter {
            $0.isCorrect && $0.category == .coffee
        }.count
        if correctCoffeeAnswers >= 5 {
            earned.insert("coffee-calculator")
        }
        if BalootAcademyCatalog.progressSummary(
            progress: academyProgress,
            legacyCompletedLessonIDs: legacyCompletedAcademyLessonIDs
        ).isComplete {
            earned.insert("academy-master")
        }
        earned.formUnion(earnedScoreSessionAchievementIDs(scoreSessions: scoreSessions, rules: rules))
        earned.formUnion(earnedOfflineTournamentAchievementIDs(tournaments: offlineTournaments))
        if completedChallengeIDs.count >= 5 {
            earned.insert("challenge-regular")
        }
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

    private static func earnedOfflineTournamentAchievementIDs(tournaments: [OfflineTournament]) -> Set<String> {
        var earned: Set<String> = []
        let stats = OfflineTournamentPlanner.stats(for: tournaments)

        if stats.finishedTournaments >= 1 {
            earned.insert("offline-cup-winner")
        }
        if stats.championshipTeams.values.contains(where: { $0 >= 3 }) {
            earned.insert("offline-dynasty")
        }
        if stats.finishedEightTeamTournaments >= 1 {
            earned.insert("offline-eight-team-champion")
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
    let correctAdvancedScoringAnswers: Int
    let completedAcademyLessons: Int
    let completedTournaments: Int
    let tournamentTitles: Int
    let completedChallenges: Int
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
        offlineTournaments: [OfflineTournament] = [],
        completedChallengeIDs: Set<String> = [],
        unlockedAchievementIDs: Set<String> = [],
        legacyCompletedAcademyLessonIDs: Set<String> = [],
        rules: ScoreRules = .standard
    ) -> CareerProgressSummary {
        let completedMatches = scoreSessions.filter { $0.status == .finished || $0.winnerName(rules: rules) != nil }.count
        let correctTrainingAttempts = whatToPlayAttempts.filter(\.isCorrect).count
        let correctScoringAnswers = scoringQuizAttempts.filter(\.isCorrect).count
        let correctAdvancedScoringAnswers = scoringQuizAttempts.filter {
            $0.isCorrect && $0.category != .basics
        }.count
        let tournamentStats = OfflineTournamentPlanner.stats(for: offlineTournaments)
        let completedAcademyLessonIDs = Set(academyProgress.map(\.lessonID))
            .union(legacyCompletedAcademyLessonIDs)
            .intersection(Set(BalootAcademyCatalog.lessons.map(\.id)))
        let earnedIDs = AchievementCenter.earnedAchievementIDs(
            whatToPlayAttempts: whatToPlayAttempts,
            scoringQuizAttempts: scoringQuizAttempts,
            scoreSessions: scoreSessions,
            offlineTournaments: offlineTournaments,
            completedChallengeIDs: completedChallengeIDs,
            rules: rules,
            academyProgress: academyProgress,
            legacyCompletedAcademyLessonIDs: legacyCompletedAcademyLessonIDs
        )
        let allUnlockedAchievementIDs = unlockedAchievementIDs.union(earnedIDs)
        let xp = completedMatches * 80
            + correctTrainingAttempts * 18
            + correctScoringAnswers * 10
            + correctAdvancedScoringAnswers * 6
            + completedAcademyLessonIDs.count * 35
            + tournamentStats.finishedTournaments * 120
            + completedChallengeIDs.count * 30
            + allUnlockedAchievementIDs.count * 70
        let rank = CareerRank.allCases.last { xp >= $0.requiredXP } ?? .newcomer
        let nextRank = CareerRank.allCases.first { $0.requiredXP > xp }
        let progress = progressToNextRank(xp: xp, rank: rank, nextRank: nextRank)
        let unlocks = makeUnlocks(
            completedMatches: completedMatches,
            correctTrainingAttempts: correctTrainingAttempts,
            correctScoringAnswers: correctScoringAnswers,
            correctAdvancedScoringAnswers: correctAdvancedScoringAnswers,
            completedAcademyLessons: completedAcademyLessonIDs.count,
            completedTournaments: tournamentStats.finishedTournaments,
            tournamentTitles: tournamentStats.championshipTeams.values.reduce(0, +),
            completedChallenges: completedChallengeIDs.count,
            unlockedAchievementCount: allUnlockedAchievementIDs.count
        )
        let nextStep = nextStep(
            completedMatches: completedMatches,
            correctTrainingAttempts: correctTrainingAttempts,
            correctScoringAnswers: correctScoringAnswers,
            completedAcademyLessons: completedAcademyLessonIDs.count,
            completedTournaments: tournamentStats.finishedTournaments
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
            correctAdvancedScoringAnswers: correctAdvancedScoringAnswers,
            completedAcademyLessons: completedAcademyLessonIDs.count,
            completedTournaments: tournamentStats.finishedTournaments,
            tournamentTitles: tournamentStats.championshipTeams.values.reduce(0, +),
            completedChallenges: completedChallengeIDs.count,
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
        correctAdvancedScoringAnswers: Int,
        completedAcademyLessons: Int,
        completedTournaments: Int,
        tournamentTitles: Int,
        completedChallenges: Int,
        unlockedAchievementCount: Int
    ) -> [CareerUnlock] {
        [
            CareerUnlock(
                id: "majlis-table",
                title: "طاولة المجلس".localized,
                detail: "تتحقق بعد أول مباراة مكتملة.".localized,
                isUnlocked: completedMatches >= 1
            ),
            CareerUnlock(
                id: "trainer-path",
                title: "مسار قارئ الطاولة".localized,
                detail: "يتحقق بعد 10 قرارات صحيحة في وش تلعب.".localized,
                isUnlocked: correctTrainingAttempts >= 10
            ),
            CareerUnlock(
                id: "accountant-badge",
                title: "لقب الحاسب".localized,
                detail: "يتحقق بعد 25 إجابة صحيحة في تحدي النقاط.".localized,
                isUnlocked: correctScoringAnswers >= 25
            ),
            CareerUnlock(
                id: "advanced-accountant",
                title: "محلل الحساب المتقدم".localized,
                detail: "يتحقق بعد 10 إجابات صحيحة في أسئلة المشاريع أو المضاعفات أو القهوة.".localized,
                isUnlocked: correctAdvancedScoringAnswers >= 10
            ),
            CareerUnlock(
                id: "academy-certificate",
                title: "شهادة الأكاديمية".localized,
                detail: "تتحقق بعد 8 دروس مكتملة.".localized,
                isUnlocked: completedAcademyLessons >= 8
            ),
            CareerUnlock(
                id: "offline-cup-path",
                title: "مسار البطولات".localized,
                detail: "يتحقق بعد إنهاء أول بطولة Offline.".localized,
                isUnlocked: completedTournaments >= 1
            ),
            CareerUnlock(
                id: "champion-title",
                title: "لقب بطل المجلس".localized,
                detail: "يتحقق بعد اعتماد بطل في بطولة Offline.".localized,
                isUnlocked: tournamentTitles >= 1
            ),
            CareerUnlock(
                id: "challenge-board",
                title: "لوحة التحديات".localized,
                detail: "تتحقق بعد 5 تحديات مكتملة.".localized,
                isUnlocked: completedChallenges >= 5
            ),
            CareerUnlock(
                id: "titles-room",
                title: "مجلس الألقاب".localized,
                detail: "يتحقق بعد 5 إنجازات.".localized,
                isUnlocked: unlockedAchievementCount >= 5
            )
        ]
    }

    private static func nextStep(
        completedMatches: Int,
        correctTrainingAttempts: Int,
        correctScoringAnswers: Int,
        completedAcademyLessons: Int,
        completedTournaments: Int
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
        if completedTournaments == 0 {
            return ("ابدأ بطولة Offline".localized, "أنشئ بطولة مجلس من 4 أو 8 فرق واعتمد بطلها حتى تدخل نتائج البطولات في مسيرتك.".localized)
        }
        return ("ارفع مستوى الخصوم".localized, "المرحلة التالية هي اللعب ضد خصوم أقوى ومراجعة Replay بعد كل جولة.".localized)
    }
}
