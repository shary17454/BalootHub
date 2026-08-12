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
    let whatToPlaySeed: UInt64?
    let whatToPlayDifficulty: WhatToPlayDifficulty?
    let whatToPlayFocusKind: WhatToPlayScenarioFocusKind?
}

struct BalootChallengeProgress: Equatable {
    let completedCount: Int
    let targetCount: Int

    var isComplete: Bool {
        completedCount >= targetCount
    }
}

struct WhatToPlayChallengeProgress: Equatable {
    let base: BalootChallengeProgress
    let seedSeries: [UInt64]
    let completedSeeds: Set<UInt64>

    var isComplete: Bool {
        base.isComplete
    }

    var nextSeed: UInt64? {
        seedSeries.first { !completedSeeds.contains($0) } ?? seedSeries.last
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
        let tacticsTarget = generator.nextInt(in: 2...4)
        let tacticsDifficulty = WhatToPlayDifficulty.allCases[generator.nextInt(in: 0...(WhatToPlayDifficulty.allCases.count - 1))]
        let tacticsFocus = WhatToPlayScenarioFocusKind.allCases[generator.nextInt(in: 0...(WhatToPlayScenarioFocusKind.allCases.count - 1))]
        let tacticsSeed = dailyWhatToPlaySeed(
            for: date,
            calendar: calendar,
            difficulty: tacticsDifficulty,
            focusKind: tacticsFocus
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
                detail: "أجب إجابة صحيحة على \(scoringTarget) أسئلة من تحدي حساب النقاط.",
                targetCount: scoringTarget,
                rewardTitle: "شارة الحاسب"
            ),
            makeChallenge(
                id: "daily-\(dayKey)-what-play-\(generator.nextInt(in: 2...5))",
                cadence: .daily,
                category: .tactics,
                title: "وش تلعب؟",
                detail: "حل \(tacticsTarget) مواقف تدريبية وقارن قرارك بالخبير.",
                targetCount: tacticsTarget,
                rewardTitle: "نقطة تكتيك",
                whatToPlaySeed: tacticsSeed,
                whatToPlayDifficulty: tacticsDifficulty,
                whatToPlayFocusKind: tacticsFocus
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
                id: "weekly-\(weekKey)-academy-\(generator.nextInt(in: 4...9))",
                cadence: .weekly,
                category: .training,
                title: "تقدم في الأكاديمية",
                detail: "أكمل \(academyTarget) دروس تفاعلية من أكاديمية البلوت.",
                targetCount: academyTarget,
                rewardTitle: "لقب طالب المجلس"
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
        whatToPlaySeed: UInt64? = nil,
        whatToPlayDifficulty: WhatToPlayDifficulty? = nil,
        whatToPlayFocusKind: WhatToPlayScenarioFocusKind? = nil
    ) -> BalootChallenge {
        BalootChallenge(
            id: id,
            cadence: cadence,
            category: category,
            title: title,
            detail: detail,
            targetCount: max(1, targetCount),
            rewardTitle: rewardTitle,
            whatToPlaySeed: whatToPlaySeed,
            whatToPlayDifficulty: whatToPlayDifficulty,
            whatToPlayFocusKind: whatToPlayFocusKind
        )
    }

    static func dailyWhatToPlaySeed(
        for date: Date = Date(),
        calendar: Calendar = Calendar(identifier: .gregorian),
        difficulty: WhatToPlayDifficulty,
        focusKind: WhatToPlayScenarioFocusKind
    ) -> UInt64 {
        let difficultyComponent = UInt64(WhatToPlayDifficulty.allCases.firstIndex(of: difficulty) ?? 0) * 1_000_000
        let focusComponent = UInt64(WhatToPlayScenarioFocusKind.allCases.firstIndex(of: focusKind) ?? 0) * 100_000
        return 7_000_000 + dailySeed(for: date, calendar: calendar) + difficultyComponent + focusComponent
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
        now: Date = Date(),
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> BalootChallengeProgress? {
        guard challenge.category == .tactics,
              let difficulty = challenge.whatToPlayDifficulty,
              let focusKind = challenge.whatToPlayFocusKind,
              let interval = dateInterval(for: challenge.cadence, containing: now, calendar: calendar)
        else { return nil }

        let completedSeeds = completedWhatToPlaySeeds(
            attempts: attempts,
            interval: interval,
            difficulty: difficulty,
            focusKind: focusKind,
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
              let interval = dateInterval(for: challenge.cadence, containing: now, calendar: calendar)
        else { return nil }

        let seedSeries = whatToPlaySeedSeries(for: challenge)
        let completedSeeds = completedWhatToPlaySeeds(
            attempts: attempts,
            interval: interval,
            difficulty: difficulty,
            focusKind: focusKind,
            challengeSeeds: Set(seedSeries)
        )
        let base = BalootChallengeProgress(
            completedCount: min(completedSeeds.count, challenge.targetCount),
            targetCount: challenge.targetCount
        )

        return WhatToPlayChallengeProgress(
            base: base,
            seedSeries: seedSeries,
            completedSeeds: completedSeeds
        )
    }

    private static func completedWhatToPlaySeeds(
        attempts: [WhatToPlayAttempt],
        interval: DateInterval,
        difficulty: WhatToPlayDifficulty,
        focusKind: WhatToPlayScenarioFocusKind,
        challengeSeeds: Set<UInt64>
    ) -> Set<UInt64> {
        Set(attempts.compactMap { attempt -> UInt64? in
            guard attempt.createdAt >= interval.start,
                  attempt.createdAt < interval.end,
                  attempt.difficulty == difficulty,
                  attempt.focusKind == focusKind,
                  attempt.isCorrect,
                  challengeSeeds.contains(attempt.replaySeed)
            else { return nil }

            return attempt.replaySeed
        })
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
