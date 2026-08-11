import Foundation

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
        var generator = ChallengeSeededGenerator(seed: dailySeed(for: date, calendar: calendar))
        let hokumMargin = generator.nextInt(in: 20...60)
        let scoringTarget = generator.nextInt(in: 3...6)
        let tacticsTarget = generator.nextInt(in: 2...4)
        return [
            makeChallenge(
                id: "daily-win-hokum-\(generator.nextInt(in: 2...8))",
                cadence: .daily,
                category: .match,
                title: "فز بجولة حكم",
                detail: "العب مباراة تدريبية وافز بجولة حكم بفارق لا يقل عن \(hokumMargin) نقطة.",
                targetCount: 1,
                rewardTitle: "نجمة تدريب"
            ),
            makeChallenge(
                id: "daily-score-\(generator.nextInt(in: 3...7))",
                cadence: .daily,
                category: .scoring,
                title: "حاسب البلوت",
                detail: "أجب إجابة صحيحة على \(scoringTarget) أسئلة من تحدي حساب النقاط.",
                targetCount: scoringTarget,
                rewardTitle: "شارة الحاسب"
            ),
            makeChallenge(
                id: "daily-what-play-\(generator.nextInt(in: 2...5))",
                cadence: .daily,
                category: .tactics,
                title: "وش تلعب؟",
                detail: "حل \(tacticsTarget) مواقف تدريبية وقارن قرارك بالخبير.",
                targetCount: tacticsTarget,
                rewardTitle: "نقطة تكتيك"
            )
        ]
    }

    static func weeklyChallenges(
        for date: Date = Date(),
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> [BalootChallenge] {
        var generator = ChallengeSeededGenerator(seed: weeklySeed(for: date, calendar: calendar))
        let streakTarget = generator.nextInt(in: 3...5)
        let academyTarget = generator.nextInt(in: 4...8)
        return [
            makeChallenge(
                id: "weekly-streak-\(generator.nextInt(in: 3...7))",
                cadence: .weekly,
                category: .match,
                title: "سلسلة انتصارات",
                detail: "حقق \(streakTarget) انتصارات خلال الأسبوع ضد أي مستوى AI.",
                targetCount: streakTarget,
                rewardTitle: "وسام الاستمرارية"
            ),
            makeChallenge(
                id: "weekly-academy-\(generator.nextInt(in: 4...9))",
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
        rewardTitle: String
    ) -> BalootChallenge {
        BalootChallenge(
            id: id,
            cadence: cadence,
            category: category,
            title: title,
            detail: detail,
            targetCount: max(1, targetCount),
            rewardTitle: rewardTitle
        )
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
