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

struct WhatToPlayDifficultyImpactInsight: Equatable {
    let difficulty: WhatToPlayDifficulty
    let averageExpectedImpact: Int
    let attempts: Int
    let title: String
    let detail: String
    let iconName: String
}

struct WhatToPlayReviewItem: Equatable, Identifiable {
    let id: UUID
    let difficulty: WhatToPlayDifficulty
    let selectedCard: PlayingCard?
    let bestCard: PlayingCard?
    let expectedImpact: Int
    let createdAt: Date
    let title: String
    let detail: String
    let iconName: String
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

struct WhatToPlayTrainingSessionPlan: Equatable {
    let difficulty: WhatToPlayDifficulty
    let scenarioCount: Int
    let targetAccuracyPercent: Int
    let title: String
    let detail: String
    let successMetric: String
    let iconName: String
}

enum WhatToPlayTrainingSessionProgressState: Equatable {
    case notStarted
    case inProgress
    case achieved
    case needsRepeat
}

struct WhatToPlayTrainingSessionProgress: Equatable {
    let state: WhatToPlayTrainingSessionProgressState
    let completedAttempts: Int
    let targetAttempts: Int
    let correctAttempts: Int
    let accuracyPercent: Int
    let remainingAttempts: Int
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

struct WhatToPlayMasteryMilestone: Equatable {
    let targetScore: Int
    let targetTitle: String
    let pointsRemaining: Int
    let detail: String
}

struct WhatToPlayPracticeCoverage: Equatable {
    let sampledDifficulties: Int
    let totalDifficulties: Int
    let missingDifficulties: [WhatToPlayDifficulty]
    let title: String
    let detail: String
    let iconName: String

    var isBalanced: Bool {
        missingDifficulties.isEmpty
    }
}

enum WhatToPlaySessionState: Equatable {
    case noData
    case warmingUp
    case focused
    case reviewNeeded
}

struct WhatToPlaySessionPulse: Equatable {
    let state: WhatToPlaySessionState
    let title: String
    let detail: String
    let iconName: String
    let inspectedAttempts: Int
}

struct WhatToPlayMicroDrill: Equatable {
    let title: String
    let detail: String
    let iconName: String
    let steps: [String]
}

enum WhatToPlayStyleKind: Equatable {
    case measuring
    case foundational
    case cautious
    case inconsistent
    case expertAligned
}

struct WhatToPlayPlayStyle: Equatable {
    let kind: WhatToPlayStyleKind
    let title: String
    let detail: String
    let strength: String
    let weakness: String
    let advice: String
    let iconName: String
}

enum WhatToPlayDecisionPatternKind: Equatable {
    case noData
    case clean
    case usefulAlternatives
    case pointLeaks
}

struct WhatToPlayDecisionPattern: Equatable {
    let kind: WhatToPlayDecisionPatternKind
    let inspectedAttempts: Int
    let affectedAttempts: Int
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

    static func difficultyImpactInsight(
        for attempts: [WhatToPlayAttempt],
        minimumAttempts: Int = 2
    ) -> WhatToPlayDifficultyImpactInsight? {
        let candidates = summariesByDifficulty(attempts)
            .filter { $0.summary.attempts >= minimumAttempts }
        guard let weakest = candidates.min(by: { lhs, rhs in
            if lhs.summary.averageExpectedImpact != rhs.summary.averageExpectedImpact {
                return lhs.summary.averageExpectedImpact < rhs.summary.averageExpectedImpact
            }
            return difficultyOrder(lhs.difficulty) > difficultyOrder(rhs.difficulty)
        }) else { return nil }

        if weakest.summary.averageExpectedImpact < 0 {
            return WhatToPlayDifficultyImpactInsight(
                difficulty: weakest.difficulty,
                averageExpectedImpact: weakest.summary.averageExpectedImpact,
                attempts: weakest.summary.attempts,
                title: "أكبر نزيف حسب الصعوبة".localized,
                detail: "\("أكثر مستوى يخسر نقاطًا متوقعة الآن".localized): \(difficultyTitle(weakest.difficulty)). \("راجع اختيارات هذا المستوى قبل رفع التحدي.".localized)",
                iconName: "drop.fill"
            )
        }

        return WhatToPlayDifficultyImpactInsight(
            difficulty: weakest.difficulty,
            averageExpectedImpact: weakest.summary.averageExpectedImpact,
            attempts: weakest.summary.attempts,
            title: "لا يوجد نزيف واضح".localized,
            detail: "متوسط الأثر المتوقع غير سلبي في المستويات التي تملك عينات كافية؛ يمكنك رفع الصعوبة تدريجيًا.".localized,
            iconName: "checkmark.seal.fill"
        )
    }

    static func reviewQueue(for attempts: [WhatToPlayAttempt], limit: Int = 3) -> [WhatToPlayReviewItem] {
        guard limit > 0 else { return [] }
        return Array(
            attempts
                .filter { !$0.isCorrect }
                .sorted { lhs, rhs in
                    if lhs.expectedImpact != rhs.expectedImpact {
                        return lhs.expectedImpact < rhs.expectedImpact
                    }
                    return lhs.createdAt > rhs.createdAt
                }
                .prefix(limit)
        )
        .map { attempt in
            let isCostly = attempt.expectedImpact < 0
            return WhatToPlayReviewItem(
                id: attempt.id,
                difficulty: attempt.difficulty,
                selectedCard: attempt.selectedCard,
                bestCard: attempt.bestCard,
                expectedImpact: attempt.expectedImpact,
                createdAt: attempt.createdAt,
                title: isCostly ? "راجع اختيارًا مكلفًا".localized : "قارن الاختيار القريب".localized,
                detail: isCostly
                    ? "\("هذا القرار خسر أثرًا متوقعًا في مستوى".localized) \(difficultyTitle(attempt.difficulty)). \("ابدأ بمقارنة اختيارك مع أفضل ورقة.".localized)"
                    : "\("الاختيار لم يكن الأفضل لكنه ليس نزيفًا واضحًا؛ ركز على سبب ترجيح ورقة الخبير.".localized)",
                iconName: isCostly ? "exclamationmark.triangle.fill" : "2.circle.fill"
            )
        }
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

    static func trainingSessionPlan(for attempts: [WhatToPlayAttempt]) -> WhatToPlayTrainingSessionPlan {
        let recommendation = practiceRecommendation(for: attempts)
        let summary = summarize(attempts: attempts)
        let style = playStyle(for: attempts)
        let pulse = sessionPulse(for: attempts)

        if style.kind == .measuring {
            return WhatToPlayTrainingSessionPlan(
                difficulty: .easy,
                scenarioCount: 3,
                targetAccuracyPercent: 60,
                title: "جلسة تأسيس قصيرة".localized,
                detail: "ابدأ بثلاثة مواقف سهلة لبناء خط أساس واضح قبل رفع الصعوبة.".localized,
                successMetric: "هدف الجلسة: إجابتان صحيحتان من 3.".localized,
                iconName: "play.rectangle.fill"
            )
        }

        if pulse.state == .reviewNeeded {
            return WhatToPlayTrainingSessionPlan(
                difficulty: recommendation.difficulty,
                scenarioCount: 3,
                targetAccuracyPercent: 67,
                title: "جلسة مراجعة مركزة".localized,
                detail: "اختر مواقف قليلة وراجع التفسير بعد كل قرار قبل الانتقال.".localized,
                successMetric: "هدف الجلسة: لا تكرر نفس سبب الخطأ مرتين.".localized,
                iconName: "magnifyingglass.circle.fill"
            )
        }

        if style.kind == .expertAligned || summary.currentStreak >= 3 {
            return WhatToPlayTrainingSessionPlan(
                difficulty: nextDifficulty(after: recommendation.difficulty),
                scenarioCount: 5,
                targetAccuracyPercent: 80,
                title: "جلسة رفع المستوى".localized,
                detail: "أداؤك يسمح بتحدٍ أعلى؛ اختبر قراءتك في مواقف أكثر ضغطًا.".localized,
                successMetric: "هدف الجلسة: 4 إجابات صحيحة من 5.".localized,
                iconName: "arrow.up.circle.fill"
            )
        }

        if style.kind == .cautious || summary.averageExpectedImpact < 0 {
            return WhatToPlayTrainingSessionPlan(
                difficulty: recommendation.difficulty,
                scenarioCount: 5,
                targetAccuracyPercent: 70,
                title: "جلسة تقليل النزيف".localized,
                detail: "ركز على مقارنة أفضل وثاني أفضل حتى تقل خسارة النقاط المتوقعة.".localized,
                successMetric: "هدف الجلسة: متوسط أثر غير سلبي.".localized,
                iconName: "shield.lefthalf.filled"
            )
        }

        return WhatToPlayTrainingSessionPlan(
            difficulty: recommendation.difficulty,
            scenarioCount: 4,
            targetAccuracyPercent: 70,
            title: "جلسة تثبيت القراءة".localized,
            detail: "درّب نفس المستوى في دفعة قصيرة حتى تصبح قراراتك أكثر ثباتًا.".localized,
            successMetric: "هدف الجلسة: 3 إجابات صحيحة من 4.".localized,
            iconName: "target"
        )
    }

    static func trainingSessionProgress(
        for attempts: [WhatToPlayAttempt],
        plan: WhatToPlayTrainingSessionPlan
    ) -> WhatToPlayTrainingSessionProgress {
        let target = max(1, plan.scenarioCount)
        let sessionAttempts = Array(
            attempts
                .filter { $0.difficulty == plan.difficulty }
                .sorted { $0.createdAt > $1.createdAt }
                .prefix(target)
        )
        let completed = sessionAttempts.count
        let correct = sessionAttempts.filter(\.isCorrect).count
        let accuracy = completed > 0
            ? Int((Double(correct) / Double(completed) * 100).rounded())
            : 0
        let remaining = max(0, target - completed)

        if completed == 0 {
            return WhatToPlayTrainingSessionProgress(
                state: .notStarted,
                completedAttempts: 0,
                targetAttempts: target,
                correctAttempts: 0,
                accuracyPercent: 0,
                remainingAttempts: target,
                title: "ابدأ الجلسة".localized,
                detail: "لم تبدأ هذه الجلسة بعد؛ اضغط زر البدء لتوليد أول موقف.".localized,
                iconName: "play.circle.fill"
            )
        }

        if completed < target {
            return WhatToPlayTrainingSessionProgress(
                state: .inProgress,
                completedAttempts: completed,
                targetAttempts: target,
                correctAttempts: correct,
                accuracyPercent: accuracy,
                remainingAttempts: remaining,
                title: "الجلسة قيد التنفيذ".localized,
                detail: "أكمل بقية المواقف قبل الحكم على هدف الجلسة.".localized,
                iconName: "timer.circle.fill"
            )
        }

        if accuracy >= plan.targetAccuracyPercent {
            return WhatToPlayTrainingSessionProgress(
                state: .achieved,
                completedAttempts: completed,
                targetAttempts: target,
                correctAttempts: correct,
                accuracyPercent: accuracy,
                remainingAttempts: 0,
                title: "هدف الجلسة تحقق".localized,
                detail: "أداؤك في هذه الدفعة وصل إلى هدف الخطة.".localized,
                iconName: "checkmark.seal.fill"
            )
        }

        return WhatToPlayTrainingSessionProgress(
            state: .needsRepeat,
            completedAttempts: completed,
            targetAttempts: target,
            correctAttempts: correct,
            accuracyPercent: accuracy,
            remainingAttempts: 0,
            title: "أعد الجلسة".localized,
            detail: "أكملتها، لكن الدقة أقل من هدف الخطة؛ أعد نفس المستوى.".localized,
            iconName: "arrow.counterclockwise.circle.fill"
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

    static func masteryMilestone(for attempts: [WhatToPlayAttempt]) -> WhatToPlayMasteryMilestone? {
        let mastery = mastery(for: attempts)
        let target: (score: Int, title: String)?

        switch mastery.score {
        case ..<35:
            target = (35, "تبني القراءة".localized)
        case 35..<60:
            target = (60, "متمكن".localized)
        case 60..<80:
            target = (80, "قراءة حادة".localized)
        default:
            target = nil
        }

        guard let target else { return nil }
        let remaining = max(0, target.score - mastery.score)
        return WhatToPlayMasteryMilestone(
            targetScore: target.score,
            targetTitle: target.title,
            pointsRemaining: remaining,
            detail: "\("باقي".localized) \(remaining) \("نقطة إتقان للوصول إلى".localized) \(target.title)."
        )
    }

    static func practiceCoverage(
        for attempts: [WhatToPlayAttempt],
        minimumAttemptsPerDifficulty: Int = 2
    ) -> WhatToPlayPracticeCoverage {
        let missing = WhatToPlayDifficulty.allCases.filter { difficulty in
            attempts.filter { $0.difficulty == difficulty }.count < minimumAttemptsPerDifficulty
        }
        let sampled = WhatToPlayDifficulty.allCases.count - missing.count

        if missing.isEmpty {
            return WhatToPlayPracticeCoverage(
                sampledDifficulties: sampled,
                totalDifficulties: WhatToPlayDifficulty.allCases.count,
                missingDifficulties: [],
                title: "تغطية متوازنة".localized,
                detail: "لديك عينات كافية من كل مستويات وش تلعب، لذلك تصبح توصيات المدرب أدق.".localized,
                iconName: "checkmark.seal.fill"
            )
        }

        let names = missing.map(difficultyTitle).joined(separator: "، ")
        return WhatToPlayPracticeCoverage(
            sampledDifficulties: sampled,
            totalDifficulties: WhatToPlayDifficulty.allCases.count,
            missingDifficulties: missing,
            title: "أكمل تغطية التدريب".localized,
            detail: "\("درّب هذه المستويات أكثر".localized): \(names).",
            iconName: "square.grid.3x3.fill"
        )
    }

    static func sessionPulse(for attempts: [WhatToPlayAttempt], window: Int = 3) -> WhatToPlaySessionPulse {
        guard attempts.count >= window, window > 0 else {
            return WhatToPlaySessionPulse(
                state: attempts.isEmpty ? .noData : .warmingUp,
                title: attempts.isEmpty ? "لا توجد جلسة بعد".localized : "بداية جلسة".localized,
                detail: attempts.isEmpty
                    ? "ابدأ أول موقف حتى تظهر قراءة الجلسة الحالية.".localized
                    : "أكمل عدة مواقف متتالية حتى يعطيك المدرب قراءة آنية أوضح.".localized,
                iconName: "timer",
                inspectedAttempts: attempts.count
            )
        }

        let recent = Array(recentAttempts(attempts, limit: window))
        let mistakes = recent.filter { !$0.isCorrect }.count
        let averageImpact = summarize(attempts: recent).averageExpectedImpact

        if mistakes == 0 && averageImpact >= 0 {
            return WhatToPlaySessionPulse(
                state: .focused,
                title: "جلسة مركزة".localized,
                detail: "آخر قراراتك صحيحة أو رابحة؛ استمر أو جرّب موقفًا أصعب.".localized,
                iconName: "bolt.circle.fill",
                inspectedAttempts: recent.count
            )
        }

        if mistakes >= 2 || averageImpact < -3 {
            return WhatToPlaySessionPulse(
                state: .reviewNeeded,
                title: "توقف للمراجعة".localized,
                detail: "آخر محاولاتك فيها أخطاء مؤثرة؛ راجع السبب قبل طلب موقف جديد.".localized,
                iconName: "pause.circle.fill",
                inspectedAttempts: recent.count
            )
        }

        return WhatToPlaySessionPulse(
            state: .warmingUp,
            title: "جلسة قيد البناء".localized,
            detail: "أداؤك الحالي مختلط؛ ركز على تقليل الخسارة في الاختيارات القريبة.".localized,
            iconName: "chart.xyaxis.line",
            inspectedAttempts: recent.count
        )
    }

    static func microDrill(for attempts: [WhatToPlayAttempt]) -> WhatToPlayMicroDrill {
        let pulse = sessionPulse(for: attempts)
        if pulse.state == .noData {
            return WhatToPlayMicroDrill(
                title: "خطة البداية".localized,
                detail: "ابدأ بخطوات قصيرة حتى تتكون بيانات كافية عن قراراتك.".localized,
                iconName: "list.clipboard.fill",
                steps: [
                    "ابدأ بمستوى سهل".localized,
                    "حل 3 مواقف متتالية".localized,
                    "راجع تفسير كل اختيار".localized
                ]
            )
        }

        if pulse.state == .reviewNeeded {
            return WhatToPlayMicroDrill(
                title: "خطة المراجعة".localized,
                detail: "الأولوية الآن ليست كثرة المواقف، بل فهم سبب الخطأ الأخير.".localized,
                iconName: "magnifyingglass.circle.fill",
                steps: [
                    "أعد قراءة بطاقة تحليل اختيارك".localized,
                    "كرر المستوى المقترح".localized,
                    "لا تنتقل قبل إجابة صحيحة".localized
                ]
            )
        }

        let coverage = practiceCoverage(for: attempts)
        if !coverage.isBalanced {
            return WhatToPlayMicroDrill(
                title: "خطة التوازن".localized,
                detail: "توصيات المدرب تصبح أدق عندما تغطي كل مستويات الصعوبة.".localized,
                iconName: "square.grid.3x3.fill",
                steps: [
                    "أكمل المستويات الناقصة".localized,
                    "حل موقفين من كل مستوى".localized,
                    "قارن أفضل وثاني أفضل".localized
                ]
            )
        }

        if mastery(for: attempts).level == .sharp {
            return WhatToPlayMicroDrill(
                title: "خطة التحدي".localized,
                detail: "أداؤك قوي؛ اجعل التدريب القادم على المواقف التي تضغط قراءة الشريك والخصم.".localized,
                iconName: "flame.fill",
                steps: [
                    "انتقل إلى الصعب".localized,
                    "استهدف 3 إجابات صحيحة".localized,
                    "شارك موقفًا صعبًا للمراجعة".localized
                ]
            )
        }

        return WhatToPlayMicroDrill(
            title: "خطة الاستمرار".localized,
            detail: "استمر على تدريب قصير ومتكرر، ثم ارفع الصعوبة عندما تثبت الدقة.".localized,
            iconName: "target",
            steps: [
                "ابدأ بالمستوى المقترح".localized,
                "حل 5 مواقف قصيرة".localized,
                "راجع النقاط الضائعة".localized
            ]
        )
    }

    static func playStyle(for attempts: [WhatToPlayAttempt]) -> WhatToPlayPlayStyle {
        let summary = summarize(attempts: attempts)
        guard summary.attempts >= 3 else {
            return WhatToPlayPlayStyle(
                kind: .measuring,
                title: "أسلوبك تحت القياس".localized,
                detail: "المدرب يحتاج عدة مواقف قبل أن يستنتج نمط قراراتك بثقة.".localized,
                strength: "بدأت تجمع سجلًا قابلًا للتحليل.".localized,
                weakness: "العينة الحالية قليلة ولا تكفي للحكم على أسلوبك.".localized,
                advice: "حل 3 مواقف من نفس المستوى ثم راجع أول تقرير أسلوب.".localized,
                iconName: "waveform.path.ecg"
            )
        }

        if summary.accuracyPercent >= 80 && summary.averageExpectedImpact >= 0 {
            return WhatToPlayPlayStyle(
                kind: .expertAligned,
                title: "قريب من الخبير".localized,
                detail: "اختياراتك غالبًا تطابق أفضل قرار أو تحافظ على قيمة متوقعة جيدة.".localized,
                strength: "تقرأ الأكلة وتختار الورقة الرابحة أو الأقل خسارة بثبات.".localized,
                weakness: "الخطر القادم هو التعود على المواقف السهلة وعدم اختبار القراءة تحت ضغط.".localized,
                advice: "ارفع الصعوبة وركز على مواقف الحكم وقراءة نية الشريك.".localized,
                iconName: "checkmark.seal.fill"
            )
        }

        if summary.accuracyPercent < 50 {
            return WhatToPlayPlayStyle(
                kind: .foundational,
                title: "تحتاج تأسيس".localized,
                detail: "قراراتك الحالية لا تزال بعيدة عن اختيار الخبير في أغلب المواقف.".localized,
                strength: "لديك فرصة واضحة للتحسن السريع بمجرد ضبط التلزيم والقطع.".localized,
                weakness: "أكبر نقطة ضعف هي اختيار الورقة قبل قراءة اللون المطلوب والحكم.".localized,
                advice: "ابدأ بالسهل وكرر تفسير كل خطأ قبل طلب موقف جديد.".localized,
                iconName: "target"
            )
        }

        if summary.accuracyPercent >= 65 && summary.averageExpectedImpact < 0 {
            return WhatToPlayPlayStyle(
                kind: .cautious,
                title: "لاعب حذر".localized,
                detail: "تقترب من القرار الصحيح كثيرًا، لكن بعض الاختيارات تسرّب نقاطًا متوقعة.".localized,
                strength: "غالبًا لا تبتعد كثيرًا عن أفضل خيار.".localized,
                weakness: "تميل أحيانًا لحفظ الورقة أو التخلص الآمن عندما توجد فرصة أفضل.".localized,
                advice: "راجع بطاقة أثر كل قرار وابحث عن الفرق بين الأفضل وثاني أفضل.".localized,
                iconName: "shield.lefthalf.filled"
            )
        }

        return WhatToPlayPlayStyle(
            kind: .inconsistent,
            title: "قراءة متذبذبة".localized,
            detail: "نتائجك بين قرارات قوية وأخطاء مؤثرة؛ تحتاج نمط تدريب أكثر ثباتًا.".localized,
            strength: "عند قراءة الموقف جيدًا تصل لاختيارات قريبة من الخبير.".localized,
            weakness: "التذبذب يظهر غالبًا عند وجود حكم أو أكثر من خيار قريب.".localized,
            advice: "درّب المستوى المقترح في جلسات قصيرة حتى تستقر الدقة.".localized,
            iconName: "chart.xyaxis.line"
        )
    }

    static func decisionPattern(for attempts: [WhatToPlayAttempt], limit: Int = 8) -> WhatToPlayDecisionPattern {
        let recent = recentAttempts(attempts, limit: limit)
        guard !recent.isEmpty else {
            return WhatToPlayDecisionPattern(
                kind: .noData,
                inspectedAttempts: 0,
                affectedAttempts: 0,
                title: "نمط قراراتك غير معروف".localized,
                detail: "حل مواقف أكثر حتى يحدد المدرب هل أخطاؤك قريبة من الأفضل أم تخسر نقاطًا واضحة.".localized,
                iconName: "questionmark.circle.fill"
            )
        }

        let mistakes = recent.filter { !$0.isCorrect }
        guard !mistakes.isEmpty else {
            return WhatToPlayDecisionPattern(
                kind: .clean,
                inspectedAttempts: recent.count,
                affectedAttempts: 0,
                title: "قراراتك الأخيرة نظيفة".localized,
                detail: "آخر محاولاتك تطابق أفضل قرار؛ جرّب صعوبة أعلى أو ركز على تفسير سبب التفوق.".localized,
                iconName: "checkmark.seal.fill"
            )
        }

        let pointLeaks = mistakes.filter { $0.expectedImpact < 0 }
        let usefulAlternatives = mistakes.count - pointLeaks.count
        if pointLeaks.count >= usefulAlternatives {
            return WhatToPlayDecisionPattern(
                kind: .pointLeaks,
                inspectedAttempts: recent.count,
                affectedAttempts: pointLeaks.count,
                title: "أخطاء مكلفة".localized,
                detail: "معظم الأخطاء الأخيرة خفضت الأثر المتوقع؛ توقف قبل اللعب واسأل: هل أحمي النقاط أم أرمي ورقة رابحة؟".localized,
                iconName: "exclamationmark.triangle.fill"
            )
        }

        return WhatToPlayDecisionPattern(
            kind: .usefulAlternatives,
            inspectedAttempts: recent.count,
            affectedAttempts: usefulAlternatives,
            title: "اختيارات قريبة من الأفضل".localized,
            detail: "أغلب أخطائك ليست مدمرة، لكنها تفوّت أفضلية صغيرة. ركز على الفرق بين أفضل وثاني أفضل ورقة.".localized,
            iconName: "2.circle.fill"
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
