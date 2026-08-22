import Foundation
import BalootEngine

enum ChallengeCadence: String, CaseIterable, Identifiable {
    case daily
    case weekly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily: "يومي".localized
        case .weekly: "أسبوعي".localized
        }
    }
}

enum ChallengeCategory: String, CaseIterable, Identifiable {
    case match
    case scoring
    case training
    case tactics

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .match: "suit.spade.fill"
        case .scoring: "function"
        case .training: "graduationcap.fill"
        case .tactics: "brain.head.profile"
        }
    }
}

struct BalootChallenge: Identifiable, Equatable {
    let id: String
    let cadence: ChallengeCadence
    let category: ChallengeCategory
    let title: String
    let detail: String
    let targetCount: Int
    let rewardTitle: String
    let scoringQuizCategory: ScoringQuizQuestionCategory?
    let whatToPlaySeed: UInt64?
    let whatToPlayDifficulty: WhatToPlayDifficulty?
    let whatToPlayFocusKind: WhatToPlayScenarioFocusKind?
    let whatToPlayGameMode: GameMode?
    let whatToPlayTrumpSuit: Suit?

    init(
        id: String,
        cadence: ChallengeCadence,
        category: ChallengeCategory,
        title: String,
        detail: String,
        targetCount: Int,
        rewardTitle: String,
        scoringQuizCategory: ScoringQuizQuestionCategory? = nil,
        whatToPlaySeed: UInt64? = nil,
        whatToPlayDifficulty: WhatToPlayDifficulty? = nil,
        whatToPlayFocusKind: WhatToPlayScenarioFocusKind? = nil,
        whatToPlayGameMode: GameMode? = nil,
        whatToPlayTrumpSuit: Suit? = nil
    ) {
        self.id = id
        self.cadence = cadence
        self.category = category
        self.title = title
        self.detail = detail
        self.targetCount = targetCount
        self.rewardTitle = rewardTitle
        self.scoringQuizCategory = scoringQuizCategory
        self.whatToPlaySeed = whatToPlaySeed
        self.whatToPlayDifficulty = whatToPlayDifficulty
        self.whatToPlayFocusKind = whatToPlayFocusKind
        self.whatToPlayGameMode = whatToPlayGameMode
        self.whatToPlayTrumpSuit = whatToPlayTrumpSuit
    }
}

struct BalootChallengeProgress: Equatable {
    let completedCount: Int
    let targetCount: Int

    var isComplete: Bool {
        completedCount >= targetCount
    }
}

struct WhatToPlayChallengeProgress: Equatable {
    enum NextSeedState: Equatable {
        case fresh(UInt64)
        case retry(UInt64)
        case complete

        var seed: UInt64? {
            switch self {
            case let .fresh(seed), let .retry(seed):
                seed
            case .complete:
                nil
            }
        }
    }

    let base: BalootChallengeProgress
    let seedSeries: [UInt64]
    let completedSeeds: Set<UInt64>
    let attemptedSeeds: Set<UInt64>

    var isComplete: Bool {
        base.isComplete
    }

    var nextSeed: UInt64? {
        seedSeries.first { !completedSeeds.contains($0) }
    }

    var hasAttemptedNextSeed: Bool {
        guard let nextSeed else { return false }
        return attemptedSeeds.contains(nextSeed)
    }

    var nextSeedState: NextSeedState {
        guard let nextSeed else { return .complete }
        return attemptedSeeds.contains(nextSeed) ? .retry(nextSeed) : .fresh(nextSeed)
    }
}

struct AcademyChallengeProgress: Equatable {
    let base: BalootChallengeProgress
    let nextLesson: AcademyLesson?

    var isComplete: Bool {
        base.isComplete
    }
}

enum DailyChallengeCenter {
    static func challenges(
        for date: Date = Date(),
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> [BalootChallenge] {
        dailyChallenges(for: date, calendar: calendar) + weeklyChallenges(for: date, calendar: calendar)
    }

    static func dailyChallenges(
        for date: Date = Date(),
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> [BalootChallenge] {
        let dayKey = dailySeed(for: date, calendar: calendar)
        var generator = ChallengeSeededGenerator(seed: dayKey)
        let hokumMargin = generator.nextInt(in: 20...60)
        let scoringTarget = generator.nextInt(in: 3...6)
        let scoringCategory = ScoringQuizQuestionCategory.allCases[generator.nextInt(in: 0...(ScoringQuizQuestionCategory.allCases.count - 1))]
        let tacticsTarget = generator.nextInt(in: 2...4)
        let tacticsDifficulty = WhatToPlayDifficulty.allCases[generator.nextInt(in: 0...(WhatToPlayDifficulty.allCases.count - 1))]
        let tacticsFocus = WhatToPlayScenarioFocusKind.allCases[generator.nextInt(in: 0...(WhatToPlayScenarioFocusKind.allCases.count - 1))]
        let tacticsMode = GameMode.allCases[generator.nextInt(in: 0...(GameMode.allCases.count - 1))]
        let tacticsTrumpSuit = tacticsMode == .hokum
            ? Suit.allCases[generator.nextInt(in: 0...(Suit.allCases.count - 1))]
            : nil
        let tacticsSeed = dailyWhatToPlaySeed(
            for: date,
            calendar: calendar,
            difficulty: tacticsDifficulty,
            focusKind: tacticsFocus,
            gameMode: tacticsMode,
            trumpSuit: tacticsTrumpSuit
        )
        return [
            makeChallenge(
                id: "daily-\(dayKey)-win-hokum-\(generator.nextInt(in: 2...8))",
                cadence: .daily,
                category: .match,
                title: "فز بجولة حكم",
                detail: "العب مباراة تدريبية وافز بجولة حكم بفارق لا يقل عن \(hokumMargin) نقطة.",
                targetCount: 1,
                rewardTitle: "نجمة تدريب"
            ),
            makeChallenge(
                id: "daily-\(dayKey)-score-\(generator.nextInt(in: 3...7))",
                cadence: .daily,
                category: .scoring,
                title: "حاسب البلوت",
                detail: "أجب إجابة صحيحة على \(scoringTarget) أسئلة من تحدي حساب النقاط ضمن \(scoringCategory.title).",
                targetCount: scoringTarget,
                rewardTitle: "شارة الحاسب",
                scoringQuizCategory: scoringCategory
            ),
            makeChallenge(
                id: "daily-\(dayKey)-what-play-\(generator.nextInt(in: 2...5))",
                cadence: .daily,
                category: .tactics,
                title: "وش تلعب؟",
                detail: "حل \(tacticsTarget) مواقف تدريبية في \(tacticsMode.arabicName) وقارن قرارك بالخبير.",
                targetCount: tacticsTarget,
                rewardTitle: "نقطة تكتيك",
                whatToPlaySeed: tacticsSeed,
                whatToPlayDifficulty: tacticsDifficulty,
                whatToPlayFocusKind: tacticsFocus,
                whatToPlayGameMode: tacticsMode,
                whatToPlayTrumpSuit: tacticsTrumpSuit
            )
        ]
    }

    static func weeklyChallenges(
        for date: Date = Date(),
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> [BalootChallenge] {
        let weekKey = weeklySeed(for: date, calendar: calendar)
        var generator = ChallengeSeededGenerator(seed: weekKey)
        let streakTarget = generator.nextInt(in: 3...5)
        let academyTarget = generator.nextInt(in: 4...8)
        let scoringTarget = generator.nextInt(in: 4...8)
        let scoringCategory = ScoringQuizQuestionCategory.allCases[generator.nextInt(in: 0...(ScoringQuizQuestionCategory.allCases.count - 1))]
        let tacticsTarget = generator.nextInt(in: 5...9)
        let tacticsDifficulty = WhatToPlayDifficulty.allCases[generator.nextInt(in: 0...(WhatToPlayDifficulty.allCases.count - 1))]
        let tacticsFocus = WhatToPlayScenarioFocusKind.allCases[generator.nextInt(in: 0...(WhatToPlayScenarioFocusKind.allCases.count - 1))]
        let tacticsMode = GameMode.allCases[generator.nextInt(in: 0...(GameMode.allCases.count - 1))]
        let tacticsTrumpSuit = tacticsMode == .hokum
            ? Suit.allCases[generator.nextInt(in: 0...(Suit.allCases.count - 1))]
            : nil
        let tacticsSeed = weeklyWhatToPlaySeed(
            for: date,
            calendar: calendar,
            difficulty: tacticsDifficulty,
            focusKind: tacticsFocus,
            gameMode: tacticsMode,
            trumpSuit: tacticsTrumpSuit
        )
        return [
            makeChallenge(
                id: "weekly-\(weekKey)-streak-\(generator.nextInt(in: 3...7))",
                cadence: .weekly,
                category: .match,
                title: "سلسلة انتصارات",
                detail: "حقق \(streakTarget) انتصارات خلال الأسبوع ضد أي مستوى AI.",
                targetCount: streakTarget,
                rewardTitle: "وسام الاستمرارية"
            ),
            makeChallenge(
                id: "weekly-\(weekKey)-score-\(generator.nextInt(in: 4...9))",
                cadence: .weekly,
                category: .scoring,
                title: "اختبار الحاسب",
                detail: "أكمل \(scoringTarget) إجابات صحيحة من نوع \(scoringCategory.title) في تحدي حساب النقاط.",
                targetCount: scoringTarget,
                rewardTitle: "وسام الحساب",
                scoringQuizCategory: scoringCategory
            ),
            makeChallenge(
                id: "weekly-\(weekKey)-academy-\(generator.nextInt(in: 4...9))",
                cadence: .weekly,
                category: .training,
                title: "تقدم في الأكاديمية",
                detail: "أكمل \(academyTarget) دروس تفاعلية من أكاديمية البلوت.",
                targetCount: academyTarget,
                rewardTitle: "لقب طالب المجلس"
            ),
            makeChallenge(
                id: "weekly-\(weekKey)-what-play-\(generator.nextInt(in: 5...11))",
                cadence: .weekly,
                category: .tactics,
                title: "شيخ القرار",
                detail: "حل \(tacticsTarget) مواقف من مدرب وش تلعب خلال الأسبوع بنفس مسار التركيز ونمط اللعب.",
                targetCount: tacticsTarget,
                rewardTitle: "وسام التكتيك",
                whatToPlaySeed: tacticsSeed,
                whatToPlayDifficulty: tacticsDifficulty,
                whatToPlayFocusKind: tacticsFocus,
                whatToPlayGameMode: tacticsMode,
                whatToPlayTrumpSuit: tacticsTrumpSuit
            )
        ]
    }

    private static func makeChallenge(
        id: String,
        cadence: ChallengeCadence,
        category: ChallengeCategory,
        title: String,
        detail: String,
        targetCount: Int,
        rewardTitle: String,
        scoringQuizCategory: ScoringQuizQuestionCategory? = nil,
        whatToPlaySeed: UInt64? = nil,
        whatToPlayDifficulty: WhatToPlayDifficulty? = nil,
        whatToPlayFocusKind: WhatToPlayScenarioFocusKind? = nil,
        whatToPlayGameMode: GameMode? = nil,
        whatToPlayTrumpSuit: Suit? = nil
    ) -> BalootChallenge {
        BalootChallenge(
            id: id,
            cadence: cadence,
            category: category,
            title: title,
            detail: detail,
            targetCount: max(1, targetCount),
            rewardTitle: rewardTitle,
            scoringQuizCategory: scoringQuizCategory,
            whatToPlaySeed: whatToPlaySeed,
            whatToPlayDifficulty: whatToPlayDifficulty,
            whatToPlayFocusKind: whatToPlayFocusKind,
            whatToPlayGameMode: whatToPlayGameMode,
            whatToPlayTrumpSuit: whatToPlayTrumpSuit
        )
    }

    static func dailyWhatToPlaySeed(
        for date: Date = Date(),
        calendar: Calendar = Calendar(identifier: .gregorian),
        difficulty: WhatToPlayDifficulty,
        focusKind: WhatToPlayScenarioFocusKind,
        gameMode: GameMode,
        trumpSuit: Suit? = nil
    ) -> UInt64 {
        let difficultyComponent = UInt64(WhatToPlayDifficulty.allCases.firstIndex(of: difficulty) ?? 0) * 1_000_000
        let focusComponent = UInt64(WhatToPlayScenarioFocusKind.allCases.firstIndex(of: focusKind) ?? 0) * 100_000
        let modeComponent = UInt64(GameMode.allCases.firstIndex(of: gameMode) ?? 0) * 10_000
        let trumpSuitComponent = UInt64(trumpSuit.map { $0.ordinal + 1 } ?? 0) * 100
        return 7_000_000
            + dailySeed(for: date, calendar: calendar)
            + difficultyComponent
            + focusComponent
            + modeComponent
            + trumpSuitComponent
    }

    static func weeklyWhatToPlaySeed(
        for date: Date = Date(),
        calendar: Calendar = Calendar(identifier: .gregorian),
        difficulty: WhatToPlayDifficulty,
        focusKind: WhatToPlayScenarioFocusKind,
        gameMode: GameMode,
        trumpSuit: Suit? = nil
    ) -> UInt64 {
        let difficultyComponent = UInt64(WhatToPlayDifficulty.allCases.firstIndex(of: difficulty) ?? 0) * 1_000_000
        let focusComponent = UInt64(WhatToPlayScenarioFocusKind.allCases.firstIndex(of: focusKind) ?? 0) * 100_000
        let modeComponent = UInt64(GameMode.allCases.firstIndex(of: gameMode) ?? 0) * 10_000
        let trumpSuitComponent = UInt64(trumpSuit.map { $0.ordinal + 1 } ?? 0) * 100
        return 8_000_000
            + weeklySeed(for: date, calendar: calendar)
            + difficultyComponent
            + focusComponent
            + modeComponent
            + trumpSuitComponent
    }

    static func whatToPlaySeedSeries(for challenge: BalootChallenge) -> [UInt64] {
        guard challenge.category == .tactics,
              let baseSeed = challenge.whatToPlaySeed
        else { return [] }

        return (0..<challenge.targetCount).map { baseSeed &+ UInt64($0) }
    }

    static func progress(
        for challenge: BalootChallenge,
        attempts: [WhatToPlayAttempt],
        scoringQuizAttempts: [ScoringQuizAttempt] = [],
        academyProgress: [AcademyLessonProgress] = [],
        scoreSessions: [ScoreSession] = [],
        rules: ScoreRules = .standard,
        legacyCompletedAcademyLessonIDs: Set<String> = [],
        now: Date = Date(),
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> BalootChallengeProgress? {
        guard let interval = dateInterval(for: challenge.cadence, containing: now, calendar: calendar) else {
            return nil
        }

        if challenge.category == .scoring {
            let completed = scoringQuizAttempts.filter { attempt in
                attempt.createdAt >= interval.start
                    && attempt.createdAt < interval.end
                    && attempt.isCorrect
                    && (challenge.scoringQuizCategory == nil || attempt.category == challenge.scoringQuizCategory)
            }.count

            return BalootChallengeProgress(
                completedCount: min(completed, challenge.targetCount),
                targetCount: challenge.targetCount
            )
        }

        if challenge.category == .training {
            let completedLessonIDs = completedAcademyLessonIDs(
                academyProgress: academyProgress,
                legacyCompletedAcademyLessonIDs: legacyCompletedAcademyLessonIDs,
                interval: interval
            )

            return BalootChallengeProgress(
                completedCount: min(completedLessonIDs.count, challenge.targetCount),
                targetCount: challenge.targetCount
            )
        }

        if challenge.category == .match {
            let completed = matchChallengeCompletedCount(
                challenge: challenge,
                scoreSessions: scoreSessions,
                rules: rules,
                interval: interval
            )

            return BalootChallengeProgress(
                completedCount: min(completed, challenge.targetCount),
                targetCount: challenge.targetCount
            )
        }

        guard challenge.category == .tactics,
              let difficulty = challenge.whatToPlayDifficulty,
              let focusKind = challenge.whatToPlayFocusKind,
              let gameMode = challenge.whatToPlayGameMode
        else { return nil }

        let completedSeeds = completedWhatToPlaySeeds(
            attempts: attempts,
            interval: interval,
            difficulty: difficulty,
            focusKind: focusKind,
            gameMode: gameMode,
            trumpSuit: challenge.whatToPlayTrumpSuit,
            challengeSeeds: Set(whatToPlaySeedSeries(for: challenge))
        )

        return BalootChallengeProgress(
            completedCount: min(completedSeeds.count, challenge.targetCount),
            targetCount: challenge.targetCount
        )
    }

    static func whatToPlayProgress(
        for challenge: BalootChallenge,
        attempts: [WhatToPlayAttempt],
        now: Date = Date(),
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> WhatToPlayChallengeProgress? {
        guard challenge.category == .tactics,
              let difficulty = challenge.whatToPlayDifficulty,
              let focusKind = challenge.whatToPlayFocusKind,
              let gameMode = challenge.whatToPlayGameMode,
              let interval = dateInterval(for: challenge.cadence, containing: now, calendar: calendar)
        else { return nil }

        let seedSeries = whatToPlaySeedSeries(for: challenge)
        let completedSeeds = completedWhatToPlaySeeds(
            attempts: attempts,
            interval: interval,
            difficulty: difficulty,
            focusKind: focusKind,
            gameMode: gameMode,
            trumpSuit: challenge.whatToPlayTrumpSuit,
            challengeSeeds: Set(seedSeries)
        )
        let attemptedSeeds = attemptedWhatToPlaySeeds(
            attempts: attempts,
            interval: interval,
            difficulty: difficulty,
            focusKind: focusKind,
            gameMode: gameMode,
            trumpSuit: challenge.whatToPlayTrumpSuit,
            challengeSeeds: Set(seedSeries)
        )
        let base = BalootChallengeProgress(
            completedCount: min(completedSeeds.count, challenge.targetCount),
            targetCount: challenge.targetCount
        )

        return WhatToPlayChallengeProgress(
            base: base,
            seedSeries: seedSeries,
            completedSeeds: completedSeeds,
            attemptedSeeds: attemptedSeeds
        )
    }

    static func academyProgress(
        for challenge: BalootChallenge,
        academyProgress: [AcademyLessonProgress],
        legacyCompletedAcademyLessonIDs: Set<String> = [],
        now: Date = Date(),
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> AcademyChallengeProgress? {
        guard challenge.category == .training,
              let interval = dateInterval(for: challenge.cadence, containing: now, calendar: calendar)
        else { return nil }

        let completedThisPeriod = completedAcademyLessonIDs(
            academyProgress: academyProgress,
            legacyCompletedAcademyLessonIDs: legacyCompletedAcademyLessonIDs,
            interval: interval
        )
        let base = BalootChallengeProgress(
            completedCount: min(completedThisPeriod.count, challenge.targetCount),
            targetCount: challenge.targetCount
        )
        let allCompleted = Set(academyProgress.map(\.lessonID))
            .union(legacyCompletedAcademyLessonIDs)
        let nextLesson = BalootAcademyCatalog.nextLessonRecommendation(
            currentLessonID: nil,
            completedLessonIDs: allCompleted
        )?.lesson

        return AcademyChallengeProgress(base: base, nextLesson: nextLesson)
    }

    static func completedChallengeIDs(
        for challenges: [BalootChallenge],
        attempts: [WhatToPlayAttempt],
        scoringQuizAttempts: [ScoringQuizAttempt] = [],
        academyProgress: [AcademyLessonProgress] = [],
        scoreSessions: [ScoreSession] = [],
        rules: ScoreRules = .standard,
        legacyCompletedAcademyLessonIDs: Set<String> = [],
        now: Date = Date(),
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> Set<String> {
        Set(challenges.compactMap { challenge in
            let progress = progress(
                for: challenge,
                attempts: attempts,
                scoringQuizAttempts: scoringQuizAttempts,
                academyProgress: academyProgress,
                scoreSessions: scoreSessions,
                rules: rules,
                legacyCompletedAcademyLessonIDs: legacyCompletedAcademyLessonIDs,
                now: now,
                calendar: calendar
            )
            return progress?.isComplete == true ? challenge.id : nil
        })
    }

    private static func completedWhatToPlaySeeds(
        attempts: [WhatToPlayAttempt],
        interval: DateInterval,
        difficulty: WhatToPlayDifficulty,
        focusKind: WhatToPlayScenarioFocusKind,
        gameMode: GameMode,
        trumpSuit: Suit?,
        challengeSeeds: Set<UInt64>
    ) -> Set<UInt64> {
        Set(attempts.compactMap { attempt -> UInt64? in
            guard attempt.createdAt >= interval.start,
                  attempt.createdAt < interval.end,
                  attempt.difficulty == difficulty,
                  attempt.focusKind == focusKind,
                  attempt.gameMode == gameMode,
                  trumpSuit == nil || attempt.contextTrumpSuit == trumpSuit,
                  attempt.isCorrect,
                  challengeSeeds.contains(attempt.replaySeed)
            else { return nil }

            return attempt.replaySeed
        })
    }

    private static func attemptedWhatToPlaySeeds(
        attempts: [WhatToPlayAttempt],
        interval: DateInterval,
        difficulty: WhatToPlayDifficulty,
        focusKind: WhatToPlayScenarioFocusKind,
        gameMode: GameMode,
        trumpSuit: Suit?,
        challengeSeeds: Set<UInt64>
    ) -> Set<UInt64> {
        Set(attempts.compactMap { attempt -> UInt64? in
            guard attempt.createdAt >= interval.start,
                  attempt.createdAt < interval.end,
                  attempt.difficulty == difficulty,
                  attempt.focusKind == focusKind,
                  attempt.gameMode == gameMode,
                  trumpSuit == nil || attempt.contextTrumpSuit == trumpSuit,
                  challengeSeeds.contains(attempt.replaySeed)
            else { return nil }

            return attempt.replaySeed
        })
    }

    private static func completedAcademyLessonIDs(
        academyProgress: [AcademyLessonProgress],
        legacyCompletedAcademyLessonIDs: Set<String>,
        interval: DateInterval
    ) -> Set<String> {
        Set(academyProgress.compactMap { progress -> String? in
            guard progress.completedAt >= interval.start,
                  progress.completedAt < interval.end
            else { return nil }
            return progress.lessonID
        })
        .union(legacyCompletedAcademyLessonIDs)
        .intersection(Set(BalootAcademyCatalog.lessons.map(\.id)))
    }

    private static func matchChallengeCompletedCount(
        challenge: BalootChallenge,
        scoreSessions: [ScoreSession],
        rules: ScoreRules,
        interval: DateInterval
    ) -> Int {
        let rounds = scoreSessions.flatMap(\.rounds).filter {
            $0.createdAt >= interval.start && $0.createdAt < interval.end
        }

        if challenge.cadence == .daily {
            return rounds.contains {
                $0.mode == .hokum && $0.teamOneFinalScore(rules: rules) > $0.teamTwoFinalScore(rules: rules)
            } ? 1 : 0
        }

        let finished = scoreSessions
            .filter {
                $0.createdAt >= interval.start
                    && $0.createdAt < interval.end
                    && ($0.status == .finished || $0.winnerName(rules: rules) != nil)
            }
            .sorted { $0.createdAt < $1.createdAt }

        var currentStreak = 0
        var bestStreak = 0
        for session in finished {
            let ours = session.teamOneTotal(rules: rules)
            let theirs = session.teamTwoTotal(rules: rules)
            if ours > theirs {
                currentStreak += 1
                bestStreak = max(bestStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        return bestStreak
    }

    private static func dateInterval(
        for cadence: ChallengeCadence,
        containing date: Date,
        calendar: Calendar
    ) -> DateInterval? {
        switch cadence {
        case .daily:
            let start = calendar.startOfDay(for: date)
            guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return nil }
            return DateInterval(start: start, end: end)
        case .weekly:
            return calendar.dateInterval(of: .weekOfYear, for: date)
        }
    }

    private static func dailySeed(for date: Date, calendar: Calendar) -> UInt64 {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = UInt64(components.year ?? 2_026)
        let month = UInt64(components.month ?? 1)
        let day = UInt64(components.day ?? 1)
        return year &* 10_000 &+ month &* 100 &+ day
    }

    private static func weeklySeed(for date: Date, calendar: Calendar) -> UInt64 {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let year = UInt64(components.yearForWeekOfYear ?? 2_026)
        let week = UInt64(components.weekOfYear ?? 1)
        return year &* 100 &+ week
    }
}

private struct ChallengeSeededGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0xA076_1D64_78BD_642F : seed
    }

    mutating func next() -> UInt64 {
        state = state &* 2_862_933_555_777_941_757 &+ 3_037_000_493
        return state
    }

    mutating func nextInt(in range: ClosedRange<Int>) -> Int {
        let width = UInt64(range.upperBound - range.lowerBound + 1)
        return range.lowerBound + Int(next() % width)
    }
}
