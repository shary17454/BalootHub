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

struct WhatToPlayPracticeRecommendation: Equatable {
    let difficulty: WhatToPlayDifficulty
    let title: String
    let detail: String
    let iconName: String
}

enum WhatToPlayDecisionInsightKind: Equatable {
    case expertMatch
    case closeAlternative
    case missedWinningChance
    case pointLeak
}

struct WhatToPlayDecisionInsight: Equatable {
    let kind: WhatToPlayDecisionInsightKind
    let title: String
    let detail: String
    let iconName: String
    let lostExpectedPoints: Int
}

enum WhatToPlayMasteryLevel: Equatable {
    case starting
    case building
    case confident
    case sharp
}

struct WhatToPlayMastery: Equatable {
    let level: WhatToPlayMasteryLevel
    let score: Int
    let title: String
    let detail: String
    let iconName: String
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

    static func practiceRecommendation(for attempts: [WhatToPlayAttempt]) -> WhatToPlayPracticeRecommendation {
        let summary = summarize(attempts: attempts)
        guard summary.attempts > 0 else {
            return WhatToPlayPracticeRecommendation(
                difficulty: .easy,
                title: "ابدأ من السهل".localized,
                detail: "ابدأ بمواقف سهلة حتى يبني المدرب خط أساس واضحًا لطريقة لعبك.".localized,
                iconName: "play.circle.fill"
            )
        }

        if performanceTrend(attempts: attempts, recentWindow: 3)?.direction == .declining {
            return WhatToPlayPracticeRecommendation(
                difficulty: focusDifficulty(attempts)?.difficulty ?? .easy,
                title: "ارجع خطوة تكتيكية".localized,
                detail: "الأداء الأخير تراجع؛ العب مواقف أوضح قليلًا وراجع سبب كل ورقة قبل رفع الصعوبة.".localized,
                iconName: "arrow.uturn.backward.circle.fill"
            )
        }

        if let focus = focusDifficulty(attempts),
           focus.summary.accuracyPercent < 70 || focus.summary.averageExpectedImpact < 0 {
            return WhatToPlayPracticeRecommendation(
                difficulty: focus.difficulty,
                title: "درّب نقطة الضعف".localized,
                detail: "\("أفضل تدريب الآن".localized): \(difficultyTitle(focus.difficulty)). \("كرر هذا المستوى حتى ترفع الدقة وتقلل خسارة النقاط المتوقعة.".localized)",
                iconName: "scope"
            )
        }

        if summary.currentStreak >= 3 && summary.accuracyPercent >= 75 {
            let next = nextDifficulty(after: highestAttemptedDifficulty(in: attempts) ?? .medium)
            return WhatToPlayPracticeRecommendation(
                difficulty: next,
                title: "ارفع التحدي".localized,
                detail: "سلسلتك الحالية قوية؛ جرّب مستوى أعلى لاختبار القراءة تحت ضغط أكبر.".localized,
                iconName: "arrow.up.circle.fill"
            )
        }

        return WhatToPlayPracticeRecommendation(
            difficulty: .medium,
            title: "واصل التدريب المتوسط".localized,
            detail: "هذا المستوى يعطيك مواقف كافية لاختبار التلزيم والقطع وحماية الشريك بدون قفزة صعبة مبكرة.".localized,
            iconName: "target"
        )
    }

    static func decisionInsight(
        selectedRank: Int,
        selectedImpact: Int,
        bestImpact: Int,
        secondBestImpact: Int?
    ) -> WhatToPlayDecisionInsight {
        let lost = max(0, bestImpact - selectedImpact)
        if selectedRank == 1 || lost == 0 {
            return WhatToPlayDecisionInsight(
                kind: .expertMatch,
                title: "اختيار خبير".localized,
                detail: "قرارك يطابق أفضل خيار في هذا الموقف، لذلك ركز على تذكر سبب نجاحه للمواقف المشابهة.".localized,
                iconName: "checkmark.seal.fill",
                lostExpectedPoints: 0
            )
        }

        if selectedRank == 2 || lost <= 2 || secondBestImpact == selectedImpact {
            return WhatToPlayDecisionInsight(
                kind: .closeAlternative,
                title: "اختيار قريب".localized,
                detail: "قرارك قريب من الأفضل، لكن الفرق الصغير يتراكم مع الوقت؛ راجع لماذا رجّح الخبير الورقة الأولى.".localized,
                iconName: "2.circle.fill",
                lostExpectedPoints: lost
            )
        }

        if selectedImpact < 0 && bestImpact > 0 {
            return WhatToPlayDecisionInsight(
                kind: .missedWinningChance,
                title: "فاتتك فرصة ربح".localized,
                detail: "الخيار الأفضل كان يتوقع كسبًا، بينما اختيارك يميل لخسارة الأكلة أو نقاطها. هذه المواقف تستحق إعادة قراءة الطاولة.".localized,
                iconName: "exclamationmark.triangle.fill",
                lostExpectedPoints: lost
            )
        }

        return WhatToPlayDecisionInsight(
            kind: .pointLeak,
            title: "نزيف نقاط".localized,
            detail: "اختيارك خسر قيمة متوقعة مقارنة بالأفضل. ابحث عن الورقة التي تقلل الخسارة حتى لو لم تربح الأكلة.".localized,
            iconName: "drop.fill",
            lostExpectedPoints: lost
        )
    }

    static func decisionInsight(for selected: WhatToPlayOption, in scenario: WhatToPlayScenario) -> WhatToPlayDecisionInsight? {
        guard let best = scenario.bestOption else { return nil }
        return decisionInsight(
            selectedRank: selected.rank,
            selectedImpact: selected.expectedImpact,
            bestImpact: best.expectedImpact,
            secondBestImpact: scenario.secondBestOption?.expectedImpact
        )
    }

    static func mastery(for attempts: [WhatToPlayAttempt]) -> WhatToPlayMastery {
        let summary = summarize(attempts: attempts)
        guard summary.attempts > 0 else {
            return WhatToPlayMastery(
                level: .starting,
                score: 0,
                title: "بداية التدريب".localized,
                detail: "حل عدة مواقف حتى يظهر مستوى إتقانك الحقيقي في قراءة الطاولة.".localized,
                iconName: "flag.fill"
            )
        }

        let accuracyScore = Double(summary.accuracyPercent) * 0.6
        let streakScore = min(Double(summary.currentStreak), 5) / 5 * 20
        let impactScore = Double(max(-10, min(10, summary.averageExpectedImpact)) + 10)
        let score = max(0, min(100, Int((accuracyScore + streakScore + impactScore).rounded())))

        switch score {
        case 80...100:
            return WhatToPlayMastery(
                level: .sharp,
                score: score,
                title: "قراءة حادة".localized,
                detail: "قراراتك قريبة من الخبير؛ ركز الآن على المواقف الصعبة وقراءة نية الشريك.".localized,
                iconName: "bolt.fill"
            )
        case 60..<80:
            return WhatToPlayMastery(
                level: .confident,
                score: score,
                title: "متمكن".localized,
                detail: "أساسك جيد، لكن تحسين الخيارات القريبة سيزيد نقاطك على المدى الطويل.".localized,
                iconName: "checkmark.circle.fill"
            )
        case 35..<60:
            return WhatToPlayMastery(
                level: .building,
                score: score,
                title: "تبني القراءة".localized,
                detail: "أنت تجمع خبرة مفيدة؛ راجع سبب كل قرار وكرر المواقف التي تخسر فيها نقاطًا متوقعة.".localized,
                iconName: "chart.line.uptrend.xyaxis"
            )
        default:
            return WhatToPlayMastery(
                level: .starting,
                score: score,
                title: "تحتاج تأسيس".localized,
                detail: "ابدأ بمواقف أسهل وركز على اللون المطلوب والحكم قبل التفكير في المخاطرة.".localized,
                iconName: "target"
            )
        }
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

    private static func highestAttemptedDifficulty(in attempts: [WhatToPlayAttempt]) -> WhatToPlayDifficulty? {
        attempts.map(\.difficulty).max { difficultyOrder($0) < difficultyOrder($1) }
    }

    private static func nextDifficulty(after difficulty: WhatToPlayDifficulty) -> WhatToPlayDifficulty {
        let order = difficultyOrder(difficulty)
        let nextIndex = min(order + 1, WhatToPlayDifficulty.allCases.count - 1)
        return WhatToPlayDifficulty.allCases[nextIndex]
    }

    private static func difficultyTitle(_ difficulty: WhatToPlayDifficulty) -> String {
        switch difficulty {
        case .easy: return "سهل".localized
        case .medium: return "متوسط".localized
        case .hard: return "صعب".localized
        }
    }
}
