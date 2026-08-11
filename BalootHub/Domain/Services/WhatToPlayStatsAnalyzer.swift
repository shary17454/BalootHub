import Foundation
import BalootEngine

struct WhatToPlayStatsSummary: Equatable {
    let attempts: Int
    let correct: Int
    let accuracyPercent: Int
    let currentStreak: Int
    let bestStreak: Int
    let averageExpectedImpact: Int

    static let empty = WhatToPlayStatsSummary(
        attempts: 0,
        correct: 0,
        accuracyPercent: 0,
        currentStreak: 0,
        bestStreak: 0,
        averageExpectedImpact: 0
    )
}

struct WhatToPlayCoachingTip: Equatable {
    let title: String
    let detail: String
    let iconName: String
}

struct WhatToPlayDifficultyFocus: Equatable {
    let difficulty: WhatToPlayDifficulty
    let summary: WhatToPlayStatsSummary
}

enum WhatToPlayTrendDirection: Equatable {
    case improving
    case stable
    case declining
}

struct WhatToPlayPerformanceTrend: Equatable {
    let direction: WhatToPlayTrendDirection
    let title: String
    let detail: String
    let iconName: String
    let recentAccuracyPercent: Int
    let previousAccuracyPercent: Int
}

enum WhatToPlayStatsAnalyzer {
    static func summarize(attempts: [WhatToPlayAttempt]) -> WhatToPlayStatsSummary {
        guard !attempts.isEmpty else { return .empty }

        let chronological = attempts.sorted { $0.createdAt < $1.createdAt }
        let correct = chronological.filter(\.isCorrect).count
        let accuracy = Int((Double(correct) / Double(chronological.count) * 100).rounded())
        let impact = chronological.reduce(0) { $0 + $1.expectedImpact }
        let averageImpact = Int((Double(impact) / Double(chronological.count)).rounded())

        var bestStreak = 0
        var running = 0
        for attempt in chronological {
            if attempt.isCorrect {
                running += 1
                bestStreak = max(bestStreak, running)
            } else {
                running = 0
            }
        }

        var currentStreak = 0
        for attempt in chronological.reversed() {
            guard attempt.isCorrect else { break }
            currentStreak += 1
        }

        return WhatToPlayStatsSummary(
            attempts: chronological.count,
            correct: correct,
            accuracyPercent: accuracy,
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            averageExpectedImpact: averageImpact
        )
    }

    static func recentAttempts(_ attempts: [WhatToPlayAttempt], limit: Int = 5) -> [WhatToPlayAttempt] {
        guard limit > 0 else { return [] }
        return Array(attempts.sorted { $0.createdAt > $1.createdAt }.prefix(limit))
    }

    static func summariesByDifficulty(_ attempts: [WhatToPlayAttempt]) -> [(difficulty: WhatToPlayDifficulty, summary: WhatToPlayStatsSummary)] {
        WhatToPlayDifficulty.allCases.compactMap { difficulty in
            let filtered = attempts.filter { $0.difficulty == difficulty }
            guard !filtered.isEmpty else { return nil }
            return (difficulty, summarize(attempts: filtered))
        }
    }

    static func focusDifficulty(_ attempts: [WhatToPlayAttempt], minimumAttempts: Int = 2) -> WhatToPlayDifficultyFocus? {
        summariesByDifficulty(attempts)
            .filter { $0.summary.attempts >= minimumAttempts }
            .sorted { lhs, rhs in
                if lhs.summary.accuracyPercent != rhs.summary.accuracyPercent {
                    return lhs.summary.accuracyPercent < rhs.summary.accuracyPercent
                }

                if lhs.summary.averageExpectedImpact != rhs.summary.averageExpectedImpact {
                    return lhs.summary.averageExpectedImpact < rhs.summary.averageExpectedImpact
                }

                return difficultyOrder(lhs.difficulty) < difficultyOrder(rhs.difficulty)
            }
            .first
            .map { WhatToPlayDifficultyFocus(difficulty: $0.difficulty, summary: $0.summary) }
    }

    static func performanceTrend(
        attempts: [WhatToPlayAttempt],
        recentWindow: Int = 5,
        minimumWindow: Int = 3
    ) -> WhatToPlayPerformanceTrend? {
        guard recentWindow >= minimumWindow, attempts.count >= minimumWindow * 2 else { return nil }

        let chronological = attempts.sorted { $0.createdAt < $1.createdAt }
        let recent = Array(chronological.suffix(recentWindow))
        let previousPool = chronological.dropLast(recent.count)
        let previous = Array(previousPool.suffix(recent.count))

        guard recent.count >= minimumWindow, previous.count >= minimumWindow else { return nil }

        let recentSummary = summarize(attempts: recent)
        let previousSummary = summarize(attempts: previous)
        let accuracyDelta = recentSummary.accuracyPercent - previousSummary.accuracyPercent
        let impactDelta = recentSummary.averageExpectedImpact - previousSummary.averageExpectedImpact

        if accuracyDelta >= 15 || (accuracyDelta >= 0 && impactDelta >= 5) {
            return WhatToPlayPerformanceTrend(
                direction: .improving,
                title: "اتجاهك يتحسن".localized,
                detail: "آخر محاولاتك أفضل من السابق؛ استمر على نفس الصعوبة أو ارفعها إذا ثبتت الدقة.".localized,
                iconName: "arrow.up.right.circle.fill",
                recentAccuracyPercent: recentSummary.accuracyPercent,
                previousAccuracyPercent: previousSummary.accuracyPercent
            )
        }

        if accuracyDelta <= -15 || (accuracyDelta <= 0 && impactDelta <= -5) {
            return WhatToPlayPerformanceTrend(
                direction: .declining,
                title: "راجع قراراتك الأخيرة".localized,
                detail: "أداؤك الأخير انخفض؛ خذ وقتك في قراءة اللون المطلوب والحكم قبل اختيار الورقة.".localized,
                iconName: "arrow.down.right.circle.fill",
                recentAccuracyPercent: recentSummary.accuracyPercent,
                previousAccuracyPercent: previousSummary.accuracyPercent
            )
        }

        return WhatToPlayPerformanceTrend(
            direction: .stable,
            title: "أداؤك مستقر".localized,
            detail: "نتائجك متقاربة بين المحاولات السابقة والأخيرة؛ ركز على تقليل خسارة النقاط في الخيارات الثانية.".localized,
            iconName: "equal.circle.fill",
            recentAccuracyPercent: recentSummary.accuracyPercent,
            previousAccuracyPercent: previousSummary.accuracyPercent
        )
    }

    static func coachingTip(for attempts: [WhatToPlayAttempt]) -> WhatToPlayCoachingTip {
        let summary = summarize(attempts: attempts)
        guard summary.attempts > 0 else {
            return WhatToPlayCoachingTip(
                title: "ابدأ القياس".localized,
                detail: "حل عدة مواقف من كل مستوى حتى يعطيك المدرب قراءة أدق لأسلوبك.".localized,
                iconName: "target"
            )
        }

        if summary.accuracyPercent < 50 {
            return WhatToPlayCoachingTip(
                title: "خفف السرعة".localized,
                detail: "قبل اختيار الورقة، راجع اللون المطلوب والحكم الموجود ثم قارن هل تستطيع ربح الأكلة أو تقليل خسارتها.".localized,
                iconName: "pause.circle.fill"
            )
        }

        if summary.averageExpectedImpact < 0 {
            return WhatToPlayCoachingTip(
                title: "قلل نزيف النقاط".localized,
                detail: "اختياراتك الأخيرة تخسر نقاطًا متوقعة؛ جرّب حفظ الورق العالي عندما لا تستطيع الفوز بالأكلة.".localized,
                iconName: "shield.lefthalf.filled"
            )
        }

        if summary.currentStreak >= 3 {
            return WhatToPlayCoachingTip(
                title: "سلسلة ممتازة".localized,
                detail: "أنت تكرر قرارات قريبة من الخبير. ارفع الصعوبة أو ركز على مواقف الحكم لاختبار قراءة أقوى.".localized,
                iconName: "flame.fill"
            )
        }

        return WhatToPlayCoachingTip(
            title: "استمر بالمقارنة".localized,
            detail: "بعد كل إجابة راجع بطاقة أثر كل قرار؛ الفرق بين اختيارك والخيار الثاني يعلمك متى تكون المخاطرة مقبولة.".localized,
            iconName: "lightbulb.fill"
        )
    }

    private static func difficultyOrder(_ difficulty: WhatToPlayDifficulty) -> Int {
        WhatToPlayDifficulty.allCases.firstIndex(of: difficulty) ?? Int.max
    }
}
