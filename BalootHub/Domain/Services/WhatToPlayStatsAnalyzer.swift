import Foundation
import BalootEngine

struct WhatToPlayStatsSummary: Equatable {
    let attempts: Int
    let correct: Int
    let accuracyPercent: Int
    let currentStreak: Int
    let bestStreak: Int
    let averageExpectedImpact: Int
    let lostExpectedPoints: Int
    let averageLostExpectedPoints: Int
    let lostAgainstSecondBestPoints: Int
    let secondBestComparisonAttempts: Int
    let averageSecondBestGap: Int
    let valueCapturePercent: Int
    let valueCaptureAttempts: Int

    static let empty = WhatToPlayStatsSummary(
        attempts: 0,
        correct: 0,
        accuracyPercent: 0,
        currentStreak: 0,
        bestStreak: 0,
        averageExpectedImpact: 0,
        lostExpectedPoints: 0,
        averageLostExpectedPoints: 0,
        lostAgainstSecondBestPoints: 0,
        secondBestComparisonAttempts: 0,
        averageSecondBestGap: 0,
        valueCapturePercent: 0,
        valueCaptureAttempts: 0
    )
}

struct WhatToPlayOutcomeSummary: Equatable {
    let trackedAttempts: Int
    let winningTrickAttempts: Int
    let losingTrickAttempts: Int
    let openTrickAttempts: Int

    static let empty = WhatToPlayOutcomeSummary(
        trackedAttempts: 0,
        winningTrickAttempts: 0,
        losingTrickAttempts: 0,
        openTrickAttempts: 0
    )

    var winningPercent: Int {
        guard trackedAttempts > 0 else { return 0 }
        return Int((Double(winningTrickAttempts) / Double(trackedAttempts) * 100).rounded())
    }

    var losingPercent: Int {
        guard trackedAttempts > 0 else { return 0 }
        return Int((Double(losingTrickAttempts) / Double(trackedAttempts) * 100).rounded())
    }
}

struct WhatToPlayChoiceRankSummary: Equatable {
    let trackedAttempts: Int
    let expertPicks: Int
    let secondBestPicks: Int
    let farPicks: Int

    static let empty = WhatToPlayChoiceRankSummary(
        trackedAttempts: 0,
        expertPicks: 0,
        secondBestPicks: 0,
        farPicks: 0
    )

    var expertPickPercent: Int {
        guard trackedAttempts > 0 else { return 0 }
        return Int((Double(expertPicks) / Double(trackedAttempts) * 100).rounded())
    }

    var nearMissPercent: Int {
        guard trackedAttempts > 0 else { return 0 }
        return Int((Double(secondBestPicks) / Double(trackedAttempts) * 100).rounded())
    }

    var farPickPercent: Int {
        guard trackedAttempts > 0 else { return 0 }
        return Int((Double(farPicks) / Double(trackedAttempts) * 100).rounded())
    }
}

struct WhatToPlayDecisionQualitySummary: Equatable {
    let trackedAttempts: Int
    let expertMatches: Int
    let closeDecisions: Int
    let acceptableDecisions: Int
    let costlyDecisions: Int

    static let empty = WhatToPlayDecisionQualitySummary(
        trackedAttempts: 0,
        expertMatches: 0,
        closeDecisions: 0,
        acceptableDecisions: 0,
        costlyDecisions: 0
    )

    var costlyPercent: Int {
        guard trackedAttempts > 0 else { return 0 }
        return Int((Double(costlyDecisions) / Double(trackedAttempts) * 100).rounded())
    }

    var strongPercent: Int {
        guard trackedAttempts > 0 else { return 0 }
        return Int((Double(expertMatches + closeDecisions) / Double(trackedAttempts) * 100).rounded())
    }
}

enum WhatToPlayDecisionQualityInsightKind: Equatable {
    case strong
    case costly
    case mixed
}

struct WhatToPlayDecisionQualityInsight: Equatable {
    let kind: WhatToPlayDecisionQualityInsightKind
    let title: String
    let detail: String
    let iconName: String
}

enum WhatToPlayChoiceRankInsightKind: Equatable {
    case expertAligned
    case nearMisses
    case farChoices
}

struct WhatToPlayChoiceRankInsight: Equatable {
    let kind: WhatToPlayChoiceRankInsightKind
    let title: String
    let detail: String
    let iconName: String
}

struct WhatToPlayCoachingTip: Equatable {
    let title: String
    let detail: String
    let iconName: String
}

struct WhatToPlayOutcomeInsight: Equatable {
    let title: String
    let detail: String
    let iconName: String
}

struct WhatToPlayDifficultyFocus: Equatable {
    let difficulty: WhatToPlayDifficulty
    let summary: WhatToPlayStatsSummary
}

struct WhatToPlayScenarioFocusSummary: Equatable {
    let focusKind: WhatToPlayScenarioFocusKind
    let summary: WhatToPlayStatsSummary
}

struct WhatToPlayFocusTrainingPriority: Equatable {
    let focusKind: WhatToPlayScenarioFocusKind
    let summary: WhatToPlayStatsSummary
    let title: String
    let detail: String
    let iconName: String
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
    let seed: UInt64
    let difficulty: WhatToPlayDifficulty
    let focusKind: WhatToPlayScenarioFocusKind?
    let selectedCard: PlayingCard?
    let bestCard: PlayingCard?
    let secondBestCard: PlayingCard?
    let expectedImpact: Int
    let lostExpectedPoints: Int
    let valueLossSeverity: WhatToPlayValueLossSeverity
    let valueLossTitle: String
    let secondBestExpectedImpact: Int?
    let createdAt: Date
    let title: String
    let detail: String
    let iconName: String
    let tacticalReasonTitle: String?
    let tacticalReasonDetail: String?
    let tacticalReasonIconName: String?
    let simulationSummary: String?
    let simulationTeamResult: String?
    let simulationTrickPoints: Int?
}

struct WhatToPlayReviewPriority: Equatable {
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

struct WhatToPlayValueProgress: Equatable {
    let direction: WhatToPlayTrendDirection
    let title: String
    let detail: String
    let iconName: String
    let earlyCapturePercent: Int
    let recentCapturePercent: Int
    let deltaPercent: Int
    let inspectedAttempts: Int
}

struct WhatToPlayPracticeRecommendation: Equatable {
    let difficulty: WhatToPlayDifficulty
    let title: String
    let detail: String
    let iconName: String
}

struct WhatToPlayTrainingSessionPlan: Equatable {
    let difficulty: WhatToPlayDifficulty
    let focusKind: WhatToPlayScenarioFocusKind?
    let scenarioCount: Int
    let targetAccuracyPercent: Int
    let targetAverageExpectedImpact: Int
    let title: String
    let detail: String
    let successMetric: String
    let iconName: String

    init(
        difficulty: WhatToPlayDifficulty,
        focusKind: WhatToPlayScenarioFocusKind? = nil,
        scenarioCount: Int,
        targetAccuracyPercent: Int,
        targetAverageExpectedImpact: Int,
        title: String,
        detail: String,
        successMetric: String,
        iconName: String
    ) {
        self.difficulty = difficulty
        self.focusKind = focusKind
        self.scenarioCount = scenarioCount
        self.targetAccuracyPercent = targetAccuracyPercent
        self.targetAverageExpectedImpact = targetAverageExpectedImpact
        self.title = title
        self.detail = detail
        self.successMetric = successMetric
        self.iconName = iconName
    }
}

struct WhatToPlayNextScenarioRecommendation: Equatable {
    let difficulty: WhatToPlayDifficulty
    let focusKind: WhatToPlayScenarioFocusKind?
    let title: String
    let detail: String
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
    let accuracyTargetMet: Bool
    let correctAttemptsNeededForTarget: Int
    let bestPossibleAccuracyPercent: Int
    let accuracyTargetReachable: Bool
    let totalExpectedImpact: Int
    let averageExpectedImpact: Int
    let bestExpectedImpact: Int?
    let bestExpectedImpactCard: PlayingCard?
    let bestExpectedImpactSeed: UInt64?
    let worstExpectedImpact: Int?
    let worstExpectedImpactCard: PlayingCard?
    let worstExpectedImpactSeed: UInt64?
    let impactTargetMet: Bool
    let averageExpectedImpactGap: Int
    let expectedImpactNeededForTarget: Int
    let expectedImpactNeededPerRemainingAttempt: Int
    let impactRecoveryHighPressure: Bool
    let lostExpectedPoints: Int
    let averageLostExpectedPoints: Int
    let valueCapturePercent: Int
    let valueCaptureAttempts: Int
    let impactTitle: String
    let impactDetail: String
    let impactIconName: String
    let reviewItem: WhatToPlayReviewItem?
    let remainingAttempts: Int
    let title: String
    let detail: String
    let iconName: String
    let nextStepTitle: String
    let nextStepDetail: String
    let nextStepIconName: String
    let gradePercent: Int
    let gradeAccuracyComponent: Int
    let gradeImpactComponent: Int
    let gradeTitle: String
    let gradeDetail: String
    let gradeIconName: String
    let gradeReasonTitle: String
    let gradeReasonDetail: String
}

enum WhatToPlayDecisionInsightKind: Equatable {
    case expertMatch
    case closeAlternative
    case missedWinningChance
    case pointLeak
}

enum WhatToPlayValueLossSeverity: Equatable {
    case none
    case low
    case medium
    case high
}

struct WhatToPlayDecisionInsight: Equatable {
    let kind: WhatToPlayDecisionInsightKind
    let title: String
    let detail: String
    let iconName: String
    let lostExpectedPoints: Int
    let secondBestGap: Int?
    let valueLossSeverity: WhatToPlayValueLossSeverity
    let valueLossTitle: String
}

struct WhatToPlayDecisionReview: Equatable {
    let title: String
    let detail: String
    let iconName: String
    let steps: [String]
}

struct WhatToPlayNextDecisionAction: Equatable {
    let title: String
    let detail: String
    let iconName: String
    let recommendedCard: PlayingCard?
    let expectedImprovement: Int
}

struct WhatToPlayRetryPrompt: Equatable {
    let title: String
    let detail: String
    let iconName: String
}

struct WhatToPlayScenarioBrief: Equatable {
    let title: String
    let detail: String
    let iconName: String
}

struct WhatToPlayPreDecisionChecklist: Equatable {
    let title: String
    let detail: String
    let iconName: String
    let items: [String]
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

struct WhatToPlayScenarioFocusCoverage: Equatable {
    let sampledFocusKinds: Int
    let totalFocusKinds: Int
    let missingFocusKinds: [WhatToPlayScenarioFocusKind]
    let title: String
    let detail: String
    let iconName: String

    var isBalanced: Bool {
        missingFocusKinds.isEmpty
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
    let reviewItem: WhatToPlayReviewItem?
    let seed: UInt64?
    let difficulty: WhatToPlayDifficulty?
    let focusKind: WhatToPlayScenarioFocusKind?
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
    case farRankChoices
    case pointLeaks
    case opponentTrickClosure
    case unprotectedPointDump
    case costlyOpeningLead
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
        let lostExpectedPoints = chronological.reduce(0) { $0 + $1.lostExpectedPoints }
        let averageLostExpectedPoints = Int((Double(lostExpectedPoints) / Double(chronological.count)).rounded())
        let secondBestComparisons = chronological.filter { $0.secondBestExpectedImpact != nil }
        let lostAgainstSecondBestPoints = secondBestComparisons.reduce(0) { $0 + $1.lostAgainstSecondBestPoints }
        let averageSecondBestGap = secondBestComparisons.isEmpty
            ? 0
            : Int((Double(lostAgainstSecondBestPoints) / Double(secondBestComparisons.count)).rounded())
        let valueAttempts = chronological.compactMap { attempt -> (selected: Int, best: Int)? in
            guard let best = attempt.bestExpectedImpact, best > 0 else { return nil }
            return (selected: max(0, min(attempt.expectedImpact, best)), best: best)
        }
        let totalBestValue = valueAttempts.reduce(0) { $0 + $1.best }
        let capturedValue = valueAttempts.reduce(0) { $0 + $1.selected }
        let valueCapturePercent = totalBestValue > 0
            ? Int((Double(capturedValue) / Double(totalBestValue) * 100).rounded())
            : 0

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
            averageExpectedImpact: averageImpact,
            lostExpectedPoints: lostExpectedPoints,
            averageLostExpectedPoints: averageLostExpectedPoints,
            lostAgainstSecondBestPoints: lostAgainstSecondBestPoints,
            secondBestComparisonAttempts: secondBestComparisons.count,
            averageSecondBestGap: averageSecondBestGap,
            valueCapturePercent: valueCapturePercent,
            valueCaptureAttempts: valueAttempts.count
        )
    }

    static func outcomeSummary(for attempts: [WhatToPlayAttempt]) -> WhatToPlayOutcomeSummary {
        let outcomes = attempts.compactMap(\.outcome)
        guard !outcomes.isEmpty else { return .empty }

        let winning = outcomes.filter { $0 == .winsTrick }.count
        let losing = outcomes.filter { $0 == .losesTrick }.count
        let open = outcomes.count - winning - losing

        return WhatToPlayOutcomeSummary(
            trackedAttempts: outcomes.count,
            winningTrickAttempts: winning,
            losingTrickAttempts: losing,
            openTrickAttempts: open
        )
    }

    static func choiceRankSummary(for attempts: [WhatToPlayAttempt]) -> WhatToPlayChoiceRankSummary {
        let ranks = attempts.compactMap(\.selectedRank)
        guard !ranks.isEmpty else { return .empty }

        let expertPicks = ranks.filter { $0 == 1 }.count
        let secondBestPicks = ranks.filter { $0 == 2 }.count
        let farPicks = ranks.filter { $0 > 2 }.count

        return WhatToPlayChoiceRankSummary(
            trackedAttempts: ranks.count,
            expertPicks: expertPicks,
            secondBestPicks: secondBestPicks,
            farPicks: farPicks
        )
    }

    static func decisionQualitySummary(for attempts: [WhatToPlayAttempt]) -> WhatToPlayDecisionQualitySummary {
        let losses = attempts.compactMap { attempt -> Int? in
            guard let best = attempt.bestExpectedImpact else { return nil }
            return max(0, best - attempt.expectedImpact)
        }
        guard !losses.isEmpty else { return .empty }

        return WhatToPlayDecisionQualitySummary(
            trackedAttempts: losses.count,
            expertMatches: losses.filter { $0 == 0 }.count,
            closeDecisions: losses.filter { (1...2).contains($0) }.count,
            acceptableDecisions: losses.filter { (3...8).contains($0) }.count,
            costlyDecisions: losses.filter { $0 > 8 }.count
        )
    }

    static func decisionQualityInsight(
        for summary: WhatToPlayDecisionQualitySummary,
        minimumTrackedAttempts: Int = 3
    ) -> WhatToPlayDecisionQualityInsight? {
        guard summary.trackedAttempts >= minimumTrackedAttempts else { return nil }

        if summary.costlyPercent >= 30 {
            return WhatToPlayDecisionQualityInsight(
                kind: .costly,
                title: "قرارات مكلفة متكررة".localized,
                detail: "نسبة القرارات التي تخسر أثرًا كبيرًا مرتفعة. قبل لعب الورقة، قارنها بأفضل قرار واسأل: هل سأخسر أكلة أو أرمي نقاطًا بلا مقابل؟".localized,
                iconName: "exclamationmark.triangle.fill"
            )
        }

        if summary.strongPercent >= 70 {
            return WhatToPlayDecisionQualityInsight(
                kind: .strong,
                title: "قراراتك قوية".localized,
                detail: "معظم اختياراتك مطابقة أو قريبة من تحليل الخبير. الخطوة التالية هي رفع الصعوبة أو مراجعة الفوارق الصغيرة بين أفضل وثاني أفضل قرار.".localized,
                iconName: "checkmark.seal.fill"
            )
        }

        return WhatToPlayDecisionQualityInsight(
            kind: .mixed,
            title: "قراراتك متوسطة الجودة".localized,
            detail: "لديك قرارات جيدة وأخرى تخسر قيمة. ركّز في التدريب القادم على تقليل الفاقد المتوقع لا على مطابقة ورقة الخبير فقط.".localized,
            iconName: "gauge.with.dots.needle.50percent"
        )
    }

    static func choiceRankInsight(
        for summary: WhatToPlayChoiceRankSummary,
        minimumTrackedAttempts: Int = 3
    ) -> WhatToPlayChoiceRankInsight? {
        guard summary.trackedAttempts >= minimumTrackedAttempts else { return nil }

        if summary.expertPickPercent >= 70 {
            return WhatToPlayChoiceRankInsight(
                kind: .expertAligned,
                title: "اختياراتك قريبة من الخبير".localized,
                detail: "أغلب قراراتك تطابق أفضل خيار؛ الخطوة القادمة هي رفع الصعوبة أو تفسير سبب تفوق الورقة قبل لعبها.".localized,
                iconName: "checkmark.seal.fill"
            )
        }

        if summary.farPicks > summary.expertPicks + summary.secondBestPicks {
            return WhatToPlayChoiceRankInsight(
                kind: .farChoices,
                title: "اختياراتك بعيدة عن التحليل".localized,
                detail: "عدد الاختيارات خارج أفضل خيارين مرتفع؛ توقف قبل اللعب واقرأ اللون المطلوب والحكم والنقاط الموجودة على الطاولة.".localized,
                iconName: "exclamationmark.triangle.fill"
            )
        }

        return WhatToPlayChoiceRankInsight(
            kind: .nearMisses,
            title: "أخطاؤك قريبة وقابلة للتصحيح".localized,
            detail: "كثير من اختياراتك حول ثاني أفضل ورقة؛ ركز على الفرق الصغير بين كسب الأكلة وحفظ ورقة قوية لاحقًا.".localized,
            iconName: "2.circle.fill"
        )
    }

    static func outcomeInsight(for summary: WhatToPlayOutcomeSummary, minimumTrackedAttempts: Int = 3) -> WhatToPlayOutcomeInsight? {
        guard summary.trackedAttempts >= minimumTrackedAttempts else { return nil }

        if summary.losingPercent >= 50 {
            return WhatToPlayOutcomeInsight(
                title: "خسارة الأكلة متكررة".localized,
                detail: "نصف قراراتك المفحوصة أو أكثر تنهي الأكلة للخصم. راجع اللون المطلوب والحكم قبل رمي ورقة عالية.".localized,
                iconName: "exclamationmark.triangle.fill"
            )
        }

        if summary.winningPercent >= 50 {
            return WhatToPlayOutcomeInsight(
                title: "تحسم الأكلات بثبات".localized,
                detail: "نصف قراراتك المفحوصة أو أكثر تكسب الأكلة لفريقك. ركز الآن على تقليل النقاط المتوقعة الضائعة عند البدائل القريبة.".localized,
                iconName: "checkmark.seal.fill"
            )
        }

        if summary.openTrickAttempts > summary.winningTrickAttempts + summary.losingTrickAttempts {
            return WhatToPlayOutcomeInsight(
                title: "قراراتك تترك الأكلة مفتوحة".localized,
                detail: "أغلب قراراتك لا تحسم الأكلة فورًا؛ تابع قراءة ردود الخصوم بعد ورقتك ولا تعتمد على أثر الورقة وحدها.".localized,
                iconName: "ellipsis.circle.fill"
            )
        }

        return WhatToPlayOutcomeInsight(
            title: "نتائج قراراتك متوازنة".localized,
            detail: "لا يظهر ميل واضح لكسب أو خسارة الأكلة. استخدم مقارنة أفضل وثاني أفضل لتقليل الفوارق الصغيرة.".localized,
            iconName: "scale.3d"
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

    static func summariesByScenarioFocus(_ attempts: [WhatToPlayAttempt]) -> [WhatToPlayScenarioFocusSummary] {
        WhatToPlayScenarioFocusKind.allCases.compactMap { focusKind in
            let filtered = attempts.filter { $0.focusKind == focusKind }
            guard !filtered.isEmpty else { return nil }
            return WhatToPlayScenarioFocusSummary(focusKind: focusKind, summary: summarize(attempts: filtered))
        }
    }

    static func focusScenarioKind(_ attempts: [WhatToPlayAttempt], minimumAttempts: Int = 2) -> WhatToPlayScenarioFocusSummary? {
        summariesByScenarioFocus(attempts)
            .filter { $0.summary.attempts >= minimumAttempts }
            .sorted { lhs, rhs in
                if lhs.summary.accuracyPercent != rhs.summary.accuracyPercent {
                    return lhs.summary.accuracyPercent < rhs.summary.accuracyPercent
                }

                if lhs.summary.lostExpectedPoints != rhs.summary.lostExpectedPoints {
                    return lhs.summary.lostExpectedPoints > rhs.summary.lostExpectedPoints
                }

                if lhs.summary.averageExpectedImpact != rhs.summary.averageExpectedImpact {
                    return lhs.summary.averageExpectedImpact < rhs.summary.averageExpectedImpact
                }

                return scenarioFocusOrder(lhs.focusKind) < scenarioFocusOrder(rhs.focusKind)
            }
            .first
    }

    static func focusTrainingPriority(
        for attempts: [WhatToPlayAttempt],
        minimumAttempts: Int = 2
    ) -> WhatToPlayFocusTrainingPriority? {
        let candidate = summariesByScenarioFocus(attempts)
            .filter { $0.summary.attempts >= minimumAttempts }
            .filter { $0.summary.lostExpectedPoints > 0 || $0.summary.accuracyPercent < 100 }
            .sorted { lhs, rhs in
                if lhs.summary.lostExpectedPoints != rhs.summary.lostExpectedPoints {
                    return lhs.summary.lostExpectedPoints > rhs.summary.lostExpectedPoints
                }

                if lhs.summary.accuracyPercent != rhs.summary.accuracyPercent {
                    return lhs.summary.accuracyPercent < rhs.summary.accuracyPercent
                }

                if lhs.summary.averageExpectedImpact != rhs.summary.averageExpectedImpact {
                    return lhs.summary.averageExpectedImpact < rhs.summary.averageExpectedImpact
                }

                return scenarioFocusOrder(lhs.focusKind) < scenarioFocusOrder(rhs.focusKind)
            }
            .first

        guard let candidate else { return nil }

        return WhatToPlayFocusTrainingPriority(
            focusKind: candidate.focusKind,
            summary: candidate.summary,
            title: "\("أولوية التدريب".localized): \(scenarioFocusTitle(candidate.focusKind))",
            detail: focusTrainingDetail(for: candidate.focusKind),
            iconName: focusTrainingIcon(for: candidate.focusKind)
        )
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

    static func valueProgress(
        attempts: [WhatToPlayAttempt],
        window: Int = 4
    ) -> WhatToPlayValueProgress? {
        guard window > 0 else { return nil }
        let valueAttempts = attempts
            .sorted { $0.createdAt < $1.createdAt }
            .compactMap { attempt -> (selected: Int, best: Int)? in
                guard let best = attempt.bestExpectedImpact, best > 0 else { return nil }
                return (selected: max(0, min(attempt.expectedImpact, best)), best: best)
            }
        guard valueAttempts.count >= window * 2 else { return nil }

        let early = Array(valueAttempts.prefix(window))
        let recent = Array(valueAttempts.suffix(window))
        let earlyPercent = valueCapturePercent(for: early)
        let recentPercent = valueCapturePercent(for: recent)
        let delta = recentPercent - earlyPercent

        if delta >= 10 {
            return WhatToPlayValueProgress(
                direction: .improving,
                title: "التقاط القيمة يتحسن".localized,
                detail: "\("آخر قراراتك تلتقط قيمة أعلى من بداية التدريب بفارق".localized) \(delta)%.",
                iconName: "arrow.up.right.circle.fill",
                earlyCapturePercent: earlyPercent,
                recentCapturePercent: recentPercent,
                deltaPercent: delta,
                inspectedAttempts: valueAttempts.count
            )
        }

        if delta <= -10 {
            return WhatToPlayValueProgress(
                direction: .declining,
                title: "التقاط القيمة يتراجع".localized,
                detail: "\("آخر قراراتك تلتقط قيمة أقل من بداية التدريب بفارق".localized) \(abs(delta))%. \("راجع المواقف التي ضيّعت فيها نقاطًا متوقعة.".localized)",
                iconName: "arrow.down.right.circle.fill",
                earlyCapturePercent: earlyPercent,
                recentCapturePercent: recentPercent,
                deltaPercent: delta,
                inspectedAttempts: valueAttempts.count
            )
        }

        return WhatToPlayValueProgress(
            direction: .stable,
            title: "التقاط القيمة مستقر".localized,
            detail: "التغيّر بين بداية التدريب وآخر محاولاتك محدود؛ ركز على رفع الجودة لا زيادة العدد فقط.".localized,
            iconName: "equal.circle.fill",
            earlyCapturePercent: earlyPercent,
            recentCapturePercent: recentPercent,
            deltaPercent: delta,
            inspectedAttempts: valueAttempts.count
        )
    }

    private static func valueCapturePercent(for attempts: [(selected: Int, best: Int)]) -> Int {
        let totalBest = attempts.reduce(0) { $0 + $1.best }
        guard totalBest > 0 else { return 0 }
        let selected = attempts.reduce(0) { $0 + $1.selected }
        return Int((Double(selected) / Double(totalBest) * 100).rounded())
    }

    static func reviewQueue(for attempts: [WhatToPlayAttempt], limit: Int = 3) -> [WhatToPlayReviewItem] {
        guard limit > 0 else { return [] }
        let missedOpportunityThreshold = 6
        return Array(
            attempts
                .filter { !$0.isCorrect }
                .sorted { lhs, rhs in
                    if lhs.lostExpectedPoints != rhs.lostExpectedPoints {
                        return lhs.lostExpectedPoints > rhs.lostExpectedPoints
                    }

                    if lhs.expectedImpact != rhs.expectedImpact {
                        return lhs.expectedImpact < rhs.expectedImpact
                    }

                    return lhs.createdAt > rhs.createdAt
                }
                .prefix(limit)
        )
        .map { attempt in
            let isCostly = attempt.expectedImpact < 0
            let isMissedOpportunity = !isCostly && attempt.lostExpectedPoints >= missedOpportunityThreshold
            let severity = valueLossSeverity(for: attempt.lostExpectedPoints)
            let tacticalReason = tacticalReviewReason(for: attempt)
            let simulationDisplay = WhatToPlaySimulationFormatter.display(for: attempt)
            return WhatToPlayReviewItem(
                id: attempt.id,
                seed: attempt.replaySeed,
                difficulty: attempt.difficulty,
                focusKind: attempt.focusKind,
                selectedCard: attempt.selectedCard,
                bestCard: attempt.bestCard,
                secondBestCard: attempt.secondBestCard,
                expectedImpact: attempt.expectedImpact,
                lostExpectedPoints: attempt.lostExpectedPoints,
                valueLossSeverity: severity,
                valueLossTitle: valueLossTitle(for: severity),
                secondBestExpectedImpact: attempt.secondBestExpectedImpact,
                createdAt: attempt.createdAt,
                title: reviewTitle(isCostly: isCostly, isMissedOpportunity: isMissedOpportunity),
                detail: reviewDetail(
                    for: attempt,
                    isCostly: isCostly,
                    isMissedOpportunity: isMissedOpportunity
                ),
                iconName: reviewIconName(isCostly: isCostly, isMissedOpportunity: isMissedOpportunity),
                tacticalReasonTitle: tacticalReason?.title,
                tacticalReasonDetail: tacticalReason?.detail,
                tacticalReasonIconName: tacticalReason?.iconName,
                simulationSummary: simulationDisplay?.summary,
                simulationTeamResult: simulationDisplay?.teamResult,
                simulationTrickPoints: simulationDisplay?.trickPoints
            )
        }
    }

    private static func tacticalReviewReason(for attempt: WhatToPlayAttempt) -> WhatToPlayReviewPriority? {
        tacticalReviewReason(
            expectedImpact: attempt.expectedImpact,
            impactBreakdown: attempt.impactBreakdown
        )
    }

    private static func tacticalReviewReason(
        expectedImpact: Int,
        impactBreakdown: WhatToPlayOptionImpactBreakdown?
    ) -> WhatToPlayReviewPriority? {
        guard expectedImpact < 0, let breakdown = impactBreakdown else { return nil }

        if breakdown.completesTrick,
           breakdown.winsForPlayerTeam == false,
           breakdown.trickPointsSwing < 0 {
            return WhatToPlayReviewPriority(
                title: "تغلق الأكلة للخصم".localized,
                detail: "اختيارك أضاف نقاطًا لأكلة انتهت للفريق الخصم. راجع هل كان يمكن تقليل الخسارة بدل تغذية الأكلة.".localized,
                iconName: "flag.slash.fill"
            )
        }

        if !breakdown.completesTrick,
           !breakdown.preservesLead,
           breakdown.playedCardPoints > 0,
           breakdown.immediateImpact < 0 {
            return WhatToPlayReviewPriority(
                title: "ترمي نقاطًا بلا حماية".localized,
                detail: "الورقة تحمل نقاطًا والأكلة لم تُحسم بعد. اسأل هل شريكك يحميها أو هل الأفضل التخلص من ورقة أرخص.".localized,
                iconName: "drop.triangle.fill"
            )
        }

        if breakdown.preservesLead, breakdown.immediateImpact < 0 {
            return WhatToPlayReviewPriority(
                title: "افتتاح مكلف".localized,
                detail: "بدأت الأكلة بورقة تخفض الأثر المتوقع. جرّب افتتاحًا يحفظ القوة أو يسحب الحكم بسبب واضح.".localized,
                iconName: "arrow.up.forward.circle.fill"
            )
        }

        return nil
    }

    private static func reviewTitle(isCostly: Bool, isMissedOpportunity: Bool) -> String {
        if isCostly { return "راجع اختيارًا مكلفًا".localized }
        if isMissedOpportunity { return "راجع فرصة ضائعة".localized }
        return "قارن الاختيار القريب".localized
    }

    private static func reviewDetail(
        for attempt: WhatToPlayAttempt,
        isCostly: Bool,
        isMissedOpportunity: Bool
    ) -> String {
        if isCostly {
            return "\("هذا القرار خسر أثرًا متوقعًا في مستوى".localized) \(difficultyTitle(attempt.difficulty)). \("ابدأ بمقارنة اختيارك مع أفضل ورقة.".localized)"
        }

        if isMissedOpportunity {
            return "\("قرارك لم يكن خاسرًا مباشرة، لكنه ضيّع نقاطًا متوقعة عن اختيار الخبير".localized): \(attempt.lostExpectedPoints). \("راجع لماذا كانت الورقة الأفضل أعلى قيمة.".localized)"
        }

        return "\("الاختيار لم يكن الأفضل لكنه ليس نزيفًا واضحًا؛ ركز على سبب ترجيح ورقة الخبير.".localized)"
    }

    private static func reviewIconName(isCostly: Bool, isMissedOpportunity: Bool) -> String {
        if isCostly { return "exclamationmark.triangle.fill" }
        if isMissedOpportunity { return "arrow.up.right.circle.fill" }
        return "2.circle.fill"
    }

    static func reviewPriority(for item: WhatToPlayReviewItem) -> WhatToPlayReviewPriority {
        if item.expectedImpact < 0 {
            return WhatToPlayReviewPriority(
                title: "أولوية عالية".localized,
                detail: "\("اختيارك خسر أثرًا متوقعًا".localized): \(impactTextValue(item.expectedImpact)). \("ابدأ بإعادة هذا الموقف قبل أي تدريب جديد.".localized)",
                iconName: "exclamationmark.triangle.fill"
            )
        }

        if item.lostExpectedPoints >= 6 {
            return WhatToPlayReviewPriority(
                title: "فرصة قيمة ضاعت".localized,
                detail: "\("الفارق عن اختيار الخبير".localized): \(item.lostExpectedPoints). \("راجع سبب ارتفاع قيمة أفضل ورقة.".localized)",
                iconName: "arrow.up.right.circle.fill"
            )
        }

        return WhatToPlayReviewPriority(
            title: "فرق تكتيكي قريب".localized,
            detail: "القرار ليس مكلفًا مباشرة، لكن مراجعة الفارق الصغير تثبت عادة اختيار أفضل ورقة.".localized,
            iconName: "2.circle.fill"
        )
    }

    private static func impactTextValue(_ value: Int) -> String {
        value > 0 ? "+\(value)" : "\(value)"
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

        let qualitySummary = decisionQualitySummary(for: attempts)
        if qualitySummary.trackedAttempts >= 3, qualitySummary.costlyPercent >= 30 {
            return WhatToPlayPracticeRecommendation(
                difficulty: focusDifficulty(attempts)?.difficulty ?? highestAttemptedDifficulty(in: attempts) ?? .medium,
                title: "قلّل القرارات المكلفة".localized,
                detail: "\("نسبة القرارات المكلفة".localized): \(qualitySummary.costlyPercent)%. \("اختر مواقف قريبة من مستواك وراجع Replay أفضل قرار قبل رفع الصعوبة.".localized)",
                iconName: "exclamationmark.triangle.fill"
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

        if summary.attempts >= 3 && summary.averageLostExpectedPoints >= 4 {
            return WhatToPlayPracticeRecommendation(
                difficulty: focusDifficulty(attempts)?.difficulty ?? highestAttemptedDifficulty(in: attempts) ?? .medium,
                title: "راجع القيمة قبل الصعوبة".localized,
                detail: "\("متوسط النقاط الضائعة".localized): \(summary.averageLostExpectedPoints). \("ابق على مستوى قريب وراجع لماذا اختار الخبير ورقة أعلى قيمة قبل رفع التحدي.".localized)",
                iconName: "chart.bar.doc.horizontal.fill"
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
        let focusKind = focusTrainingPriority(for: attempts)?.focusKind ?? focusScenarioKind(attempts)?.focusKind

        if style.kind == .measuring {
            return WhatToPlayTrainingSessionPlan(
                difficulty: .easy,
                scenarioCount: 3,
                targetAccuracyPercent: 60,
                targetAverageExpectedImpact: 0,
                title: "جلسة تأسيس قصيرة".localized,
                detail: "ابدأ بثلاثة مواقف سهلة لبناء خط أساس واضح قبل رفع الصعوبة.".localized,
                successMetric: "هدف الجلسة: إجابتان صحيحتان من 3.".localized,
                iconName: "play.rectangle.fill"
            )
        }

        if pulse.state == .reviewNeeded {
            return WhatToPlayTrainingSessionPlan(
                difficulty: recommendation.difficulty,
                focusKind: focusKind,
                scenarioCount: 3,
                targetAccuracyPercent: 67,
                targetAverageExpectedImpact: 0,
                title: "جلسة مراجعة مركزة".localized,
                detail: "اختر مواقف قليلة وراجع التفسير بعد كل قرار قبل الانتقال.".localized,
                successMetric: "هدف الجلسة: لا تكرر نفس سبب الخطأ مرتين.".localized,
                iconName: "magnifyingglass.circle.fill"
            )
        }

        if summary.attempts >= 3 && summary.averageLostExpectedPoints >= 4 {
            return WhatToPlayTrainingSessionPlan(
                difficulty: recommendation.difficulty,
                focusKind: focusKind,
                scenarioCount: 4,
                targetAccuracyPercent: 75,
                targetAverageExpectedImpact: 1,
                title: "جلسة مراجعة القيمة".localized,
                detail: "الدقة وحدها لا تكفي هنا؛ ركز على تقليل الفارق بين اختيارك واختيار الخبير قبل رفع المستوى.".localized,
                successMetric: "هدف الجلسة: متوسط نقاط ضائعة أقل من 4.".localized,
                iconName: "chart.bar.doc.horizontal.fill"
            )
        }

        if style.kind == .expertAligned || summary.currentStreak >= 3 {
            return WhatToPlayTrainingSessionPlan(
                difficulty: nextDifficulty(after: recommendation.difficulty),
                focusKind: focusKind,
                scenarioCount: 5,
                targetAccuracyPercent: 80,
                targetAverageExpectedImpact: 2,
                title: "جلسة رفع المستوى".localized,
                detail: "أداؤك يسمح بتحدٍ أعلى؛ اختبر قراءتك في مواقف أكثر ضغطًا.".localized,
                successMetric: "هدف الجلسة: 4 إجابات صحيحة من 5.".localized,
                iconName: "arrow.up.circle.fill"
            )
        }

        if style.kind == .cautious || summary.averageExpectedImpact < 0 {
            return WhatToPlayTrainingSessionPlan(
                difficulty: recommendation.difficulty,
                focusKind: focusKind,
                scenarioCount: 5,
                targetAccuracyPercent: 70,
                targetAverageExpectedImpact: 0,
                title: "جلسة تقليل النزيف".localized,
                detail: "ركز على مقارنة أفضل وثاني أفضل حتى تقل خسارة النقاط المتوقعة.".localized,
                successMetric: "هدف الجلسة: متوسط أثر غير سلبي.".localized,
                iconName: "shield.lefthalf.filled"
            )
        }

        return WhatToPlayTrainingSessionPlan(
            difficulty: recommendation.difficulty,
            focusKind: focusKind,
            scenarioCount: 4,
            targetAccuracyPercent: 70,
            targetAverageExpectedImpact: 1,
            title: "جلسة تثبيت القراءة".localized,
            detail: "درّب نفس المستوى في دفعة قصيرة حتى تصبح قراراتك أكثر ثباتًا.".localized,
            successMetric: "هدف الجلسة: 3 إجابات صحيحة من 4.".localized,
            iconName: "target"
        )
    }

    static func nextScenarioRecommendation(for attempts: [WhatToPlayAttempt]) -> WhatToPlayNextScenarioRecommendation {
        let plan = trainingSessionPlan(for: attempts)
        if let focusPriority = focusTrainingPriority(for: attempts) {
            return WhatToPlayNextScenarioRecommendation(
                difficulty: plan.difficulty,
                focusKind: focusPriority.focusKind,
                title: "الموقف القادم".localized,
                detail: "\("ابدأ بموقف".localized) \(scenarioFocusTitle(focusPriority.focusKind)) \("على مستوى".localized) \(difficultyTitle(plan.difficulty)). \(focusPriority.detail)",
                iconName: focusPriority.iconName
            )
        }

        return WhatToPlayNextScenarioRecommendation(
            difficulty: plan.difficulty,
            focusKind: plan.focusKind,
            title: "الموقف القادم".localized,
            detail: plan.focusKind.map {
                "\("ابدأ بموقف".localized) \(scenarioFocusTitle($0)) \("على مستوى".localized) \(difficultyTitle(plan.difficulty))."
            } ?? "\("ابدأ بموقف تلقائي على مستوى".localized) \(difficultyTitle(plan.difficulty)).",
            iconName: plan.iconName
        )
    }

    static func nextTrainingSessionSeed(
        for attempts: [WhatToPlayAttempt],
        plan: WhatToPlayTrainingSessionPlan
    ) -> UInt64 {
        let matchingAttemptCount = attempts.filter {
            $0.difficulty == plan.difficulty && (plan.focusKind == nil || $0.focusKind == plan.focusKind)
        }.count
        let difficultyComponent = UInt64(difficultyOrder(plan.difficulty)) * 1_000_000
        let focusComponent = UInt64(plan.focusKind.map(scenarioFocusOrder) ?? 0) * 100_000
        let countComponent = UInt64(max(1, plan.scenarioCount)) * 1_000
        let accuracyComponent = UInt64(max(0, plan.targetAccuracyPercent)) * 10
        let impactComponent = UInt64(max(0, plan.targetAverageExpectedImpact))

        return 9_000_000
            + difficultyComponent
            + focusComponent
            + countComponent
            + accuracyComponent
            + impactComponent
            + UInt64(matchingAttemptCount)
    }

    static func trainingSessionProgress(
        for attempts: [WhatToPlayAttempt],
        plan: WhatToPlayTrainingSessionPlan
    ) -> WhatToPlayTrainingSessionProgress {
        let target = max(1, plan.scenarioCount)
        let sessionAttempts = Array(
            attempts
                .filter { $0.difficulty == plan.difficulty }
                .filter { plan.focusKind == nil || $0.focusKind == plan.focusKind }
                .sorted { $0.createdAt > $1.createdAt }
                .prefix(target)
        )
        let completed = sessionAttempts.count
        let sessionSummary = summarize(attempts: sessionAttempts)
        let correct = sessionAttempts.filter(\.isCorrect).count
        let accuracy = completed > 0
            ? Int((Double(correct) / Double(completed) * 100).rounded())
            : 0
        let totalImpact = sessionAttempts.reduce(0) { $0 + $1.expectedImpact }
        let averageImpact = completed > 0
            ? Int((Double(totalImpact) / Double(completed)).rounded())
            : 0
        let bestImpact = sessionAttempts.map(\.expectedImpact).max()
        let worstImpact = sessionAttempts.map(\.expectedImpact).min()
        let bestImpactAttempt = sessionImpactExtreme(in: sessionAttempts, preferHighest: true)
        let worstImpactAttempt = sessionImpactExtreme(in: sessionAttempts, preferHighest: false)
        let accuracyTargetMet = completed > 0 && accuracy >= plan.targetAccuracyPercent
        let requiredCorrect = requiredCorrectAttempts(
            targetAttempts: target,
            targetAccuracyPercent: plan.targetAccuracyPercent
        )
        let correctNeeded = max(0, requiredCorrect - correct)
        let remaining = max(0, target - completed)
        let bestPossibleCorrect = min(target, correct + remaining)
        let bestPossibleAccuracy = Int((Double(bestPossibleCorrect) / Double(target) * 100).rounded())
        let accuracyTargetReachable = bestPossibleCorrect >= requiredCorrect
        let targetTotalImpact = target * plan.targetAverageExpectedImpact
        let impactNeeded = max(0, targetTotalImpact - totalImpact)
        let impactTargetMet = completed > 0 && impactNeeded == 0
        let impactNeededPerRemaining = remaining > 0
            ? Int((Double(impactNeeded) / Double(remaining)).rounded(.up))
            : 0
        let highPressureThreshold = max(
            plan.targetAverageExpectedImpact * 2,
            plan.targetAverageExpectedImpact + 1
        )
        let impactRecoveryHighPressure = remaining > 0
            && impactNeeded > 0
            && impactNeededPerRemaining > highPressureThreshold
        let impactGap = max(0, plan.targetAverageExpectedImpact - averageImpact)
        let impactReading = trainingSessionImpactReading(
            completedAttempts: completed,
            averageExpectedImpact: averageImpact
        )
        let reviewItem = reviewQueue(for: sessionAttempts, limit: 1).first
        let nextStep = trainingSessionNextStep(
            state: completed == 0 ? .notStarted : (completed < target ? .inProgress : (accuracyTargetMet && impactTargetMet ? .achieved : .needsRepeat)),
            remainingAttempts: remaining,
            correctAttemptsNeededForTarget: correctNeeded,
            accuracyTargetMet: accuracyTargetMet,
            impactTargetMet: impactTargetMet,
            averageLostExpectedPoints: sessionSummary.averageLostExpectedPoints
        )
        let grade = trainingSessionGrade(
            completedAttempts: completed,
            accuracyPercent: accuracy,
            averageExpectedImpact: averageImpact,
            targetAverageExpectedImpact: plan.targetAverageExpectedImpact
        )

        if completed == 0 {
            return WhatToPlayTrainingSessionProgress(
                state: .notStarted,
                completedAttempts: 0,
                targetAttempts: target,
                correctAttempts: 0,
                accuracyPercent: 0,
                accuracyTargetMet: false,
                correctAttemptsNeededForTarget: requiredCorrect,
                bestPossibleAccuracyPercent: 100,
                accuracyTargetReachable: true,
                totalExpectedImpact: 0,
                averageExpectedImpact: 0,
                bestExpectedImpact: nil,
                bestExpectedImpactCard: nil,
                bestExpectedImpactSeed: nil,
                worstExpectedImpact: nil,
                worstExpectedImpactCard: nil,
                worstExpectedImpactSeed: nil,
                impactTargetMet: false,
                averageExpectedImpactGap: plan.targetAverageExpectedImpact,
                expectedImpactNeededForTarget: max(0, targetTotalImpact),
                expectedImpactNeededPerRemainingAttempt: max(0, plan.targetAverageExpectedImpact),
                impactRecoveryHighPressure: false,
                lostExpectedPoints: 0,
                averageLostExpectedPoints: 0,
                valueCapturePercent: 0,
                valueCaptureAttempts: 0,
                impactTitle: impactReading.title,
                impactDetail: impactReading.detail,
                impactIconName: impactReading.iconName,
                reviewItem: nil,
                remainingAttempts: target,
                title: "ابدأ الجلسة".localized,
                detail: "لم تبدأ هذه الجلسة بعد؛ اضغط زر البدء لتوليد أول موقف.".localized,
                iconName: "play.circle.fill",
                nextStepTitle: nextStep.title,
                nextStepDetail: nextStep.detail,
                nextStepIconName: nextStep.iconName,
                gradePercent: grade.percent,
                gradeAccuracyComponent: grade.accuracyComponent,
                gradeImpactComponent: grade.impactComponent,
                gradeTitle: grade.title,
                gradeDetail: grade.detail,
                gradeIconName: grade.iconName,
                gradeReasonTitle: grade.reasonTitle,
                gradeReasonDetail: grade.reasonDetail
            )
        }

        if completed < target {
            return WhatToPlayTrainingSessionProgress(
                state: .inProgress,
                completedAttempts: completed,
                targetAttempts: target,
                correctAttempts: correct,
                accuracyPercent: accuracy,
                accuracyTargetMet: accuracyTargetMet,
                correctAttemptsNeededForTarget: correctNeeded,
                bestPossibleAccuracyPercent: bestPossibleAccuracy,
                accuracyTargetReachable: accuracyTargetReachable,
                totalExpectedImpact: totalImpact,
                averageExpectedImpact: averageImpact,
                bestExpectedImpact: bestImpact,
                bestExpectedImpactCard: bestImpactAttempt?.selectedCard,
                bestExpectedImpactSeed: bestImpactAttempt.map(\.replaySeed),
                worstExpectedImpact: worstImpact,
                worstExpectedImpactCard: worstImpactAttempt?.selectedCard,
                worstExpectedImpactSeed: worstImpactAttempt.map(\.replaySeed),
                impactTargetMet: impactTargetMet,
                averageExpectedImpactGap: impactGap,
                expectedImpactNeededForTarget: impactNeeded,
                expectedImpactNeededPerRemainingAttempt: impactNeededPerRemaining,
                impactRecoveryHighPressure: impactRecoveryHighPressure,
                lostExpectedPoints: sessionSummary.lostExpectedPoints,
                averageLostExpectedPoints: sessionSummary.averageLostExpectedPoints,
                valueCapturePercent: sessionSummary.valueCapturePercent,
                valueCaptureAttempts: sessionSummary.valueCaptureAttempts,
                impactTitle: impactReading.title,
                impactDetail: impactReading.detail,
                impactIconName: impactReading.iconName,
                reviewItem: reviewItem,
                remainingAttempts: remaining,
                title: "الجلسة قيد التنفيذ".localized,
                detail: "أكمل بقية المواقف قبل الحكم على هدف الجلسة.".localized,
                iconName: "timer.circle.fill",
                nextStepTitle: nextStep.title,
                nextStepDetail: nextStep.detail,
                nextStepIconName: nextStep.iconName,
                gradePercent: grade.percent,
                gradeAccuracyComponent: grade.accuracyComponent,
                gradeImpactComponent: grade.impactComponent,
                gradeTitle: grade.title,
                gradeDetail: grade.detail,
                gradeIconName: grade.iconName,
                gradeReasonTitle: grade.reasonTitle,
                gradeReasonDetail: grade.reasonDetail
            )
        }

        if accuracyTargetMet && impactTargetMet {
            return WhatToPlayTrainingSessionProgress(
                state: .achieved,
                completedAttempts: completed,
                targetAttempts: target,
                correctAttempts: correct,
                accuracyPercent: accuracy,
                accuracyTargetMet: true,
                correctAttemptsNeededForTarget: 0,
                bestPossibleAccuracyPercent: accuracy,
                accuracyTargetReachable: true,
                totalExpectedImpact: totalImpact,
                averageExpectedImpact: averageImpact,
                bestExpectedImpact: bestImpact,
                bestExpectedImpactCard: bestImpactAttempt?.selectedCard,
                bestExpectedImpactSeed: bestImpactAttempt.map(\.replaySeed),
                worstExpectedImpact: worstImpact,
                worstExpectedImpactCard: worstImpactAttempt?.selectedCard,
                worstExpectedImpactSeed: worstImpactAttempt.map(\.replaySeed),
                impactTargetMet: true,
                averageExpectedImpactGap: 0,
                expectedImpactNeededForTarget: 0,
                expectedImpactNeededPerRemainingAttempt: 0,
                impactRecoveryHighPressure: false,
                lostExpectedPoints: sessionSummary.lostExpectedPoints,
                averageLostExpectedPoints: sessionSummary.averageLostExpectedPoints,
                valueCapturePercent: sessionSummary.valueCapturePercent,
                valueCaptureAttempts: sessionSummary.valueCaptureAttempts,
                impactTitle: impactReading.title,
                impactDetail: impactReading.detail,
                impactIconName: impactReading.iconName,
                reviewItem: reviewItem,
                remainingAttempts: 0,
                title: "هدف الجلسة تحقق".localized,
                detail: "أداؤك في هذه الدفعة وصل إلى هدف الخطة.".localized,
                iconName: "checkmark.seal.fill",
                nextStepTitle: nextStep.title,
                nextStepDetail: nextStep.detail,
                nextStepIconName: nextStep.iconName,
                gradePercent: grade.percent,
                gradeAccuracyComponent: grade.accuracyComponent,
                gradeImpactComponent: grade.impactComponent,
                gradeTitle: grade.title,
                gradeDetail: grade.detail,
                gradeIconName: grade.iconName,
                gradeReasonTitle: grade.reasonTitle,
                gradeReasonDetail: grade.reasonDetail
            )
        }

        return WhatToPlayTrainingSessionProgress(
            state: .needsRepeat,
            completedAttempts: completed,
            targetAttempts: target,
            correctAttempts: correct,
            accuracyPercent: accuracy,
            accuracyTargetMet: accuracyTargetMet,
            correctAttemptsNeededForTarget: correctNeeded,
            bestPossibleAccuracyPercent: accuracy,
            accuracyTargetReachable: accuracyTargetMet,
            totalExpectedImpact: totalImpact,
            averageExpectedImpact: averageImpact,
            bestExpectedImpact: bestImpact,
            bestExpectedImpactCard: bestImpactAttempt?.selectedCard,
            bestExpectedImpactSeed: bestImpactAttempt.map(\.replaySeed),
            worstExpectedImpact: worstImpact,
            worstExpectedImpactCard: worstImpactAttempt?.selectedCard,
            worstExpectedImpactSeed: worstImpactAttempt.map(\.replaySeed),
            impactTargetMet: impactTargetMet,
            averageExpectedImpactGap: impactGap,
            expectedImpactNeededForTarget: impactNeeded,
            expectedImpactNeededPerRemainingAttempt: 0,
            impactRecoveryHighPressure: false,
            lostExpectedPoints: sessionSummary.lostExpectedPoints,
            averageLostExpectedPoints: sessionSummary.averageLostExpectedPoints,
            valueCapturePercent: sessionSummary.valueCapturePercent,
            valueCaptureAttempts: sessionSummary.valueCaptureAttempts,
            impactTitle: impactReading.title,
            impactDetail: impactReading.detail,
            impactIconName: impactReading.iconName,
            reviewItem: reviewItem,
            remainingAttempts: 0,
            title: "أعد الجلسة".localized,
            detail: trainingSessionRepeatDetail(
                accuracyTargetMet: accuracyTargetMet,
                impactTargetMet: impactTargetMet
            ),
            iconName: "arrow.counterclockwise.circle.fill",
            nextStepTitle: nextStep.title,
            nextStepDetail: nextStep.detail,
            nextStepIconName: nextStep.iconName,
            gradePercent: grade.percent,
            gradeAccuracyComponent: grade.accuracyComponent,
            gradeImpactComponent: grade.impactComponent,
            gradeTitle: grade.title,
            gradeDetail: grade.detail,
            gradeIconName: grade.iconName,
            gradeReasonTitle: grade.reasonTitle,
            gradeReasonDetail: grade.reasonDetail
        )
    }

    private static func sessionImpactExtreme(
        in attempts: [WhatToPlayAttempt],
        preferHighest: Bool
    ) -> WhatToPlayAttempt? {
        attempts.sorted { lhs, rhs in
            if lhs.expectedImpact != rhs.expectedImpact {
                return preferHighest
                    ? lhs.expectedImpact > rhs.expectedImpact
                    : lhs.expectedImpact < rhs.expectedImpact
            }

            return lhs.createdAt > rhs.createdAt
        }
        .first
    }

    private static func trainingSessionGrade(
        completedAttempts: Int,
        accuracyPercent: Int,
        averageExpectedImpact: Int,
        targetAverageExpectedImpact: Int
    ) -> (percent: Int, accuracyComponent: Int, impactComponent: Int, title: String, detail: String, iconName: String, reasonTitle: String, reasonDetail: String) {
        guard completedAttempts > 0 else {
            return (
                0,
                0,
                0,
                "لا يوجد تقييم بعد".localized,
                "ابدأ الجلسة حتى يظهر تقييم يجمع الدقة وأثر القرار.".localized,
                "gauge.low",
                "سبب التقييم".localized,
                "لا توجد محاولة في هذه الجلسة حتى الآن.".localized
            )
        }

        let normalizedImpact = min(100, max(0, 50 + ((averageExpectedImpact - targetAverageExpectedImpact) * 10)))
        let percent = min(100, max(0, Int((Double(accuracyPercent + normalizedImpact) / 2.0).rounded())))
        let reason = trainingSessionGradeReason(
            accuracyComponent: accuracyPercent,
            impactComponent: normalizedImpact
        )

        if percent >= 85 {
            return (
                percent,
                accuracyPercent,
                normalizedImpact,
                "جلسة ممتازة".localized,
                "قراراتك قريبة من الخبير وتحقق أثرًا قويًا؛ انتقل لتحدٍ أصعب.".localized,
                "gauge.high",
                reason.title,
                reason.detail
            )
        }

        if percent >= 70 {
            return (
                percent,
                accuracyPercent,
                normalizedImpact,
                "جلسة جيدة".localized,
                "أداؤك ثابت، لكن راجع الفروق الصغيرة بين أفضل وثاني أفضل ورقة.".localized,
                "gauge.medium",
                reason.title,
                reason.detail
            )
        }

        if percent >= 50 {
            return (
                percent,
                accuracyPercent,
                normalizedImpact,
                "جلسة تحتاج تثبيت".localized,
                "لديك أساس قابل للبناء، لكن القرار يحتاج قراءة أهدأ قبل اللعب.".localized,
                "gauge.medium",
                reason.title,
                reason.detail
            )
        }

        return (
            percent,
            accuracyPercent,
            normalizedImpact,
            "جلسة تحتاج إعادة".localized,
            "الدقة أو أثر القرار منخفض؛ أعد نفس الخطة ولا ترفع الصعوبة بعد.".localized,
            "gauge.low",
            reason.title,
            reason.detail
        )
    }

    private static func trainingSessionGradeReason(
        accuracyComponent: Int,
        impactComponent: Int
    ) -> (title: String, detail: String) {
        let gap = accuracyComponent - impactComponent
        if gap >= 15 {
            return (
                "الأثر يخفض التقييم".localized,
                "دقتك أفضل من أثر قراراتك؛ ركز على اختيار الورقة الأعلى قيمة لا الورقة الصحيحة فقط.".localized
            )
        }

        if gap <= -15 {
            return (
                "الدقة تخفض التقييم".localized,
                "أثر اختياراتك جيد عندما تصيب، لكنك تحتاج تقليل الأخطاء المباشرة.".localized
            )
        }

        return (
            "التقييم متوازن".localized,
            "الدقة وأثر القرار قريبان؛ حسّن الاثنين معًا برفع جودة القراءة قبل اللعب.".localized
        )
    }

    private static func trainingSessionNextStep(
        state: WhatToPlayTrainingSessionProgressState,
        remainingAttempts: Int,
        correctAttemptsNeededForTarget: Int,
        accuracyTargetMet: Bool,
        impactTargetMet: Bool,
        averageLostExpectedPoints: Int
    ) -> (title: String, detail: String, iconName: String) {
        switch state {
        case .notStarted:
            return (
                "الخطوة التالية".localized,
                "ابدأ أول موقف واحسب قرارك قبل كشف تحليل الخبير.".localized,
                "play.circle.fill"
            )
        case .inProgress:
            let neededCorrect = correctAttemptsNeededForTarget
            if neededCorrect > remainingAttempts {
                return (
                    "هدف الدقة تعثر".localized,
                    "\("باقي".localized) \(remainingAttempts) \("مواقف؛ حتى لو أجبتها كلها صح ستحتاج إعادة الجلسة لتحقق هدف الدقة.".localized)",
                    "exclamationmark.triangle.fill"
                )
            }
            if averageLostExpectedPoints >= 4 {
                return (
                    "قلل النقاط الضائعة".localized,
                    "\("متوسط الضياع".localized): \(averageLostExpectedPoints). \("قبل الموقف التالي، احذف الخيارات الضعيفة ثم قارن اختيارك بأفضل ورقة وثاني أفضل ورقة.".localized)",
                    "chart.bar.doc.horizontal.fill"
                )
            }
            return (
                "أكمل الدفعة".localized,
                "\("باقي".localized) \(remainingAttempts) \("مواقف، وتحتاج".localized) \(neededCorrect) \("إجابات صحيحة إضافية للوصول لهدف الدقة.".localized)",
                "timer.circle.fill"
            )
        case .achieved:
            return (
                "انتقل للتحدي التالي".localized,
                "حققت الدقة والأثر المطلوبين؛ ارفع الصعوبة أو ركز على نوع موقف أضعف.".localized,
                "arrow.up.circle.fill"
            )
        case .needsRepeat:
            if averageLostExpectedPoints >= 4 {
                return (
                    "راجع القيمة الضائعة".localized,
                    "\("متوسط الضياع".localized): \(averageLostExpectedPoints). \("أعد الجلسة وركّز على تقليل الفارق عن اختيار الخبير قبل رفع الصعوبة.".localized)",
                    "drop.fill"
                )
            }
            if accuracyTargetMet && !impactTargetMet {
                return (
                    "راجع جودة القرار".localized,
                    "الدقة كافية لكن الأثر ضعيف؛ قارن اختيارك بثاني أفضل ورقة قبل بدء جلسة جديدة.".localized,
                    "chart.line.downtrend.xyaxis"
                )
            }
            if !accuracyTargetMet && impactTargetMet {
                return (
                    "ثبّت الأساس".localized,
                    "أثرك مقبول لكن الدقة لم تصل؛ كرر نفس الخطة وراجع سبب كل رفض قانوني أو تكتيكي.".localized,
                    "target"
                )
            }
            return (
                "أعد نفس الخطة".localized,
                "الدقة والأثر لم يصلا للهدف؛ ابدأ من نفس المستوى ولا ترفع الصعوبة بعد.".localized,
                "arrow.counterclockwise.circle.fill"
            )
        }
    }

    private static func requiredCorrectAttempts(
        targetAttempts: Int,
        targetAccuracyPercent: Int
    ) -> Int {
        let target = max(1, targetAttempts)
        for correct in 0...target {
            let accuracy = Int((Double(correct) / Double(target) * 100).rounded())
            if accuracy >= targetAccuracyPercent {
                return correct
            }
        }
        return target
    }

    private static func trainingSessionRepeatDetail(
        accuracyTargetMet: Bool,
        impactTargetMet: Bool
    ) -> String {
        if !accuracyTargetMet && !impactTargetMet {
            return "أكملتها، لكن الدقة والأثر أقل من هدف الخطة؛ أعد نفس المستوى.".localized
        }
        if !accuracyTargetMet {
            return "أكملتها، لكن الدقة أقل من هدف الخطة؛ أعد نفس المستوى.".localized
        }
        return "أكملتها بدقة كافية، لكن متوسط الأثر أقل من هدف الخطة؛ راجع الاختيارات القريبة قبل تكرارها.".localized
    }

    private static func trainingSessionImpactReading(
        completedAttempts: Int,
        averageExpectedImpact: Int
    ) -> (title: String, detail: String, iconName: String) {
        guard completedAttempts > 0 else {
            return (
                "الأثر غير محسوب بعد".localized,
                "ابدأ أول موقف حتى يظهر أثر قرارات هذه الجلسة.".localized,
                "chart.line.uptrend.xyaxis"
            )
        }

        if averageExpectedImpact > 0 {
            return (
                "أثر الجلسة رابح".localized,
                "متوسط قراراتك في هذه الجلسة يضيف قيمة متوقعة لفريقك.".localized,
                "checkmark.seal.fill"
            )
        }

        if averageExpectedImpact == 0 {
            return (
                "أثر الجلسة متعادل".localized,
                "قراراتك لا تخسر نقاطًا متوقعة بوضوح، لكن ما زال بإمكانك رفع القيمة.".localized,
                "equal.circle.fill"
            )
        }

        return (
            "أثر الجلسة سلبي".localized,
            "متوسط قراراتك يسرّب نقاطًا متوقعة؛ راجع أفضل وثاني أفضل قبل تكرار الجلسة.".localized,
            "exclamationmark.triangle.fill"
        )
    }

    static func decisionInsight(
        selectedRank: Int,
        selectedImpact: Int,
        bestImpact: Int,
        secondBestImpact: Int?
    ) -> WhatToPlayDecisionInsight {
        let lost = max(0, bestImpact - selectedImpact)
        let secondBestGap = secondBestImpact.map { max(0, $0 - selectedImpact) }
        let severity = valueLossSeverity(for: lost)
        let severityTitle = valueLossTitle(for: severity)
        if selectedRank == 1 || lost == 0 {
            return WhatToPlayDecisionInsight(
                kind: .expertMatch,
                title: "اختيار خبير".localized,
                detail: "قرارك يطابق أفضل خيار في هذا الموقف، لذلك ركز على تذكر سبب نجاحه للمواقف المشابهة.".localized,
                iconName: "checkmark.seal.fill",
                lostExpectedPoints: 0,
                secondBestGap: secondBestGap,
                valueLossSeverity: .none,
                valueLossTitle: valueLossTitle(for: .none)
            )
        }

        if selectedRank == 2 || lost <= 2 || secondBestImpact == selectedImpact {
            return WhatToPlayDecisionInsight(
                kind: .closeAlternative,
                title: "اختيار قريب".localized,
                detail: "قرارك قريب من الأفضل، لكن الفرق الصغير يتراكم مع الوقت؛ راجع لماذا رجّح الخبير الورقة الأولى.".localized,
                iconName: "2.circle.fill",
                lostExpectedPoints: lost,
                secondBestGap: secondBestGap,
                valueLossSeverity: severity,
                valueLossTitle: severityTitle
            )
        }

        if selectedImpact < 0 && bestImpact > 0 {
            return WhatToPlayDecisionInsight(
                kind: .missedWinningChance,
                title: "فاتتك فرصة ربح".localized,
                detail: "الخيار الأفضل كان يتوقع كسبًا، بينما اختيارك يميل لخسارة الأكلة أو نقاطها. هذه المواقف تستحق إعادة قراءة الطاولة.".localized,
                iconName: "exclamationmark.triangle.fill",
                lostExpectedPoints: lost,
                secondBestGap: secondBestGap,
                valueLossSeverity: severity,
                valueLossTitle: severityTitle
            )
        }

        return WhatToPlayDecisionInsight(
            kind: .pointLeak,
            title: "نزيف نقاط".localized,
            detail: "اختيارك خسر قيمة متوقعة مقارنة بالأفضل. ابحث عن الورقة التي تقلل الخسارة حتى لو لم تربح الأكلة.".localized,
            iconName: "drop.fill",
            lostExpectedPoints: lost,
            secondBestGap: secondBestGap,
            valueLossSeverity: severity,
            valueLossTitle: severityTitle
        )
    }

    static func valueLossSeverity(for lostExpectedPoints: Int) -> WhatToPlayValueLossSeverity {
        switch lostExpectedPoints {
        case ...0:
            .none
        case 1...2:
            .low
        case 3...5:
            .medium
        default:
            .high
        }
    }

    static func valueLossTitle(for severity: WhatToPlayValueLossSeverity) -> String {
        switch severity {
        case .none:
            "لا توجد خسارة قيمة".localized
        case .low:
            "خسارة قيمة بسيطة".localized
        case .medium:
            "خسارة قيمة متوسطة".localized
        case .high:
            "خسارة قيمة عالية".localized
        }
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

    static func decisionReview(for selected: WhatToPlayOption, in scenario: WhatToPlayScenario) -> WhatToPlayDecisionReview? {
        guard let insight = decisionInsight(for: selected, in: scenario) else { return nil }
        return decisionReview(
            insight: insight,
            focusKind: scenario.context.focusKind,
            tacticalReason: tacticalReviewReason(
                expectedImpact: selected.expectedImpact,
                impactBreakdown: selected.impactBreakdown
            )
        )
    }

    static func nextDecisionAction(for selected: WhatToPlayOption, in scenario: WhatToPlayScenario) -> WhatToPlayNextDecisionAction? {
        guard let insight = decisionInsight(for: selected, in: scenario) else { return nil }
        return nextDecisionAction(
            insight: insight,
            focusKind: scenario.context.focusKind,
            bestCard: scenario.bestOption?.card
        )
    }

    static func retryPrompt(for selected: WhatToPlayOption, in scenario: WhatToPlayScenario) -> WhatToPlayRetryPrompt? {
        guard let insight = decisionInsight(for: selected, in: scenario) else { return nil }
        return retryPrompt(insight: insight)
    }

    static func retryPrompt(insight: WhatToPlayDecisionInsight) -> WhatToPlayRetryPrompt? {
        guard insight.kind != .expertMatch else { return nil }

        if insight.lostExpectedPoints <= 2 {
            return WhatToPlayRetryPrompt(
                title: "أعد نفس الموقف".localized,
                detail: "الفرق بسيط؛ أعد الموقف مرة واحدة وحاول تمييز سبب ترجيح الخبير للورقة الأفضل.".localized,
                iconName: "arrow.counterclockwise.circle.fill"
            )
        }

        return WhatToPlayRetryPrompt(
            title: "أعد نفس الموقف".localized,
            detail: "لن تُحسب الإعادة كمحاولة جديدة. ركّز على الورقة الأفضل قبل الانتقال للموقف التالي.".localized,
            iconName: "arrow.counterclockwise.circle.fill"
        )
    }

    static func scenarioBrief(for scenario: WhatToPlayScenario) -> WhatToPlayScenarioBrief {
        scenarioBrief(context: scenario.context)
    }

    static func preDecisionChecklist(for scenario: WhatToPlayScenario) -> WhatToPlayPreDecisionChecklist {
        preDecisionChecklist(context: scenario.context)
    }

    static func preDecisionChecklist(context: WhatToPlayScenarioContext) -> WhatToPlayPreDecisionChecklist {
        var items: [String] = []

        if context.isLeading {
            items.append("أنت تبدأ الأكلة: لا تكشف ورقتك القوية بلا سبب واضح.".localized)
        } else if let requiredSuit = context.requiredSuit {
            items.append("\("اللون المطلوب".localized): \(requiredSuit.spokenName). \("ابدأ بحصر الأوراق القانونية من هذا اللون.".localized)")
        } else {
            items.append("لا يوجد لون مطلوب واضح؛ اقرأ الأوراق المطروحة قبل حساب الربح.".localized)
        }

        if context.mode == .hokum, let trumpSuit = context.trumpSuit {
            let trumpState = context.hasTrumpInCurrentTrick
                ? "الحكم موجود على الطاولة؛ لا تعلّي إلا إذا كان العائد يستحق.".localized
                : "الحكم لم يظهر في الأكلة؛ احسب هل القطع الآن أفضل أم حفظ الحكم.".localized
            items.append("\("الحكم".localized): \(trumpSuit.spokenName). \(trumpState)")
        } else {
            items.append("صن: لا يوجد حكم، فقارن قوة اللون والنقاط بدل انتظار القطع.".localized)
        }

        items.append("\("الأوراق قبل دورك".localized): \(context.playedCardCount). \("كلما زادت الأوراق زادت دقة حساب ربح الأكلة.".localized)")

        if context.legalOptionCount <= 2 {
            items.append("خياراتك قليلة؛ اختر أقل خسارة متوقعة لا أعلى شكل للورقة.".localized)
        } else {
            items.append("رتّب الخيارات بين ربح الأكلة، تقليل الخسارة، وحفظ ورقة قوية لاحقًا.".localized)
        }

        return WhatToPlayPreDecisionChecklist(
            title: "افحص قبل اللعب".localized,
            detail: "استخدم هذه القراءة السريعة قبل لمس الورقة.".localized,
            iconName: "checklist",
            items: items
        )
    }

    static func scenarioBrief(context: WhatToPlayScenarioContext) -> WhatToPlayScenarioBrief {
        switch context.focusKind {
        case .openingLead:
            return WhatToPlayScenarioBrief(
                title: "اقرأ بداية الأكلة".localized,
                detail: "أنت تفتتح الأكلة؛ اختر ورقة تكشف أقل معلومات وتحافظ على قوة يدك للأكلة المناسبة.".localized,
                iconName: "arrowshape.turn.up.forward.fill"
            )
        case .followSuit:
            if let requiredSuit = context.requiredSuit {
                return WhatToPlayScenarioBrief(
                    title: "التزم باللون المطلوب".localized,
                    detail: "\("اللون المطلوب".localized): \(requiredSuit.spokenName). \("قارن هل تستطيع كسب الأكلة أم تقلل خسارة النقاط.".localized)",
                    iconName: "suit.club.fill"
                )
            }
            return WhatToPlayScenarioBrief(
                title: "راجع اللون المطلوب".localized,
                detail: "ابدأ بمعرفة اللون المطلوب ثم قرر هل الفوز بالأكلة ممكن أو الأفضل تقليل الخسارة.".localized,
                iconName: "suit.club.fill"
            )
        case .trumpPressure:
            let trumpText = context.trumpSuit?.spokenName ?? "غير محدد".localized
            let tableText = context.hasTrumpInCurrentTrick
                ? "يوجد حكم على الطاولة؛ لا تصرف حكمًا أعلى إلا إذا كان العائد يستحق.".localized
                : "لا يوجد حكم على الطاولة؛ اسأل هل القطع الآن يحسم الأكلة أو يكشف قوتك مبكرًا.".localized
            return WhatToPlayScenarioBrief(
                title: "\("ضغط الحكم".localized): \(trumpText)",
                detail: tableText,
                iconName: "crown.fill"
            )
        case .narrowChoice:
            return WhatToPlayScenarioBrief(
                title: "خياراتك محدودة".localized,
                detail: "\("الأوراق القانونية".localized): \(context.legalOptionCount). \("رتّبها حسب الأثر المتوقع لا حسب أعلى ورقة فقط.".localized)",
                iconName: "2.circle.fill"
            )
        }
    }

    static func nextDecisionAction(
        insight: WhatToPlayDecisionInsight,
        focusKind: WhatToPlayScenarioFocusKind,
        bestCard: PlayingCard?
    ) -> WhatToPlayNextDecisionAction {
        switch insight.kind {
        case .expertMatch:
            return WhatToPlayNextDecisionAction(
                title: "ثبّت القراءة".localized,
                detail: focusSuccessAction(for: focusKind),
                iconName: "checkmark.seal.fill",
                recommendedCard: bestCard,
                expectedImprovement: 0
            )
        case .closeAlternative:
            return WhatToPlayNextDecisionAction(
                title: closeAlternativeActionTitle(insight: insight),
                detail: closeAlternativeActionDetail(insight: insight),
                iconName: "equal.circle.fill",
                recommendedCard: bestCard,
                expectedImprovement: insight.lostExpectedPoints
            )
        case .missedWinningChance:
            return WhatToPlayNextDecisionAction(
                title: "ابحث عن الورقة الرابحة".localized,
                detail: "قبل اللعب، احسب هل عندك ورقة تنقل الأكلة لفريقك بدل الاكتفاء برمي ورقة قليلة الضرر.".localized,
                iconName: "exclamationmark.triangle.fill",
                recommendedCard: bestCard,
                expectedImprovement: insight.lostExpectedPoints
            )
        case .pointLeak:
            return WhatToPlayNextDecisionAction(
                title: "قلل النزيف القادم".localized,
                detail: "في الموقف القادم ابدأ بسؤال واحد: ما أقل ورقة تخسر أقل نقاط متوقعة إذا كانت الأكلة للخصم؟".localized,
                iconName: "drop.fill",
                recommendedCard: bestCard,
                expectedImprovement: insight.lostExpectedPoints
            )
        }
    }

    private static func closeAlternativeActionTitle(insight: WhatToPlayDecisionInsight) -> String {
        insight.lostExpectedPoints <= 2
            ? "درّب الفارق الصغير".localized
            : "راجع القيمة الضائعة".localized
    }

    private static func closeAlternativeActionDetail(insight: WhatToPlayDecisionInsight) -> String {
        if insight.lostExpectedPoints <= 2 {
            return "أعد قراءة نفس النوع من المواقف وركّز على سبب تفوق ورقة واحدة بنقطة أو نقطتين متوقعتين.".localized
        }

        return "\("الفارق عن اختيار الخبير".localized): \(insight.lostExpectedPoints). \("راجع سبب ارتفاع قيمة أفضل ورقة.".localized)"
    }

    static func decisionReview(
        insight: WhatToPlayDecisionInsight,
        focusKind: WhatToPlayScenarioFocusKind
    ) -> WhatToPlayDecisionReview {
        decisionReview(insight: insight, focusKind: focusKind, tacticalReason: nil)
    }

    private static func decisionReview(
        insight: WhatToPlayDecisionInsight,
        focusKind: WhatToPlayScenarioFocusKind,
        tacticalReason: WhatToPlayReviewPriority?
    ) -> WhatToPlayDecisionReview {
        let firstStep: String
        switch focusKind {
        case .openingLead:
            firstStep = "قارن هل افتتاحك يكشف قوة يدك مبكرًا أو يحفظها للأكلة القادمة.".localized
        case .followSuit:
            firstStep = "راجع اللون المطلوب أولًا، ثم اسأل هل تستطيع ربح الأكلة أم يجب تقليل خسارتها.".localized
        case .trumpPressure:
            firstStep = "افحص الحكم الموجود على الطاولة قبل رمي ورقة عالية أو حكم أعلى.".localized
        case .narrowChoice:
            firstStep = "عندما تكون الخيارات قليلة، رتّبها حسب أقل خسارة لا حسب أعلى ورقة.".localized
        }

        let secondStep: String
        switch insight.kind {
        case .expertMatch:
            secondStep = "اكتب سبب نجاح القرار في ذهنك وكرر نفس القراءة في موقف مشابه.".localized
        case .closeAlternative:
            secondStep = "قارن الفرق بين اختيارك وأفضل ورقة؛ هذا النوع من الفوارق الصغيرة يتراكم.".localized
        case .missedWinningChance:
            secondStep = "ابحث عن الورقة التي كانت ستحوّل الأكلة من خسارة إلى ربح.".localized
        case .pointLeak:
            secondStep = "حدد هل خسرت النقاط لأنك رميت ورقة ثمينة أو تركت ورقة أقل ضررًا.".localized
        }

        var steps = [
            firstStep,
            secondStep,
            "أعد الموقف إذا كان الفارق أكثر من نقطتين متوقعتين.".localized
        ]

        if let tacticalReason {
            steps.append("\("سبب تكتيكي".localized): \(tacticalReason.title). \(tacticalReason.detail)")
        }

        return WhatToPlayDecisionReview(
            title: "راجع القرار بهذه الطريقة".localized,
            detail: "استخدم هذه الخطوات القصيرة قبل الانتقال للموقف التالي.".localized,
            iconName: "checklist",
            steps: steps
        )
    }

    private static func focusSuccessAction(for focusKind: WhatToPlayScenarioFocusKind) -> String {
        switch focusKind {
        case .openingLead:
            return "احتفظ بنفس منطق الافتتاح: لا تكشف قوتك إلا عندما يعطيك ذلك سيطرة واضحة.".localized
        case .followSuit:
            return "استمر في قراءة اللون المطلوب أولًا ثم قارن بين ربح الأكلة وتقليل الخسارة.".localized
        case .trumpPressure:
            return "ثبت عادة فحص الحكم على الطاولة قبل صرف حكم قوي أو ورقة عالية.".localized
        case .narrowChoice:
            return "عند ضيق الخيارات، استمر في ترتيبها حسب الأثر المتوقع لا حسب شكل الورقة.".localized
        }
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

    static func scenarioFocusCoverage(
        for attempts: [WhatToPlayAttempt],
        minimumAttemptsPerFocus: Int = 2
    ) -> WhatToPlayScenarioFocusCoverage {
        let missing = WhatToPlayScenarioFocusKind.allCases.filter { focusKind in
            attempts.filter { $0.focusKind == focusKind }.count < minimumAttemptsPerFocus
        }
        let sampled = WhatToPlayScenarioFocusKind.allCases.count - missing.count

        if missing.isEmpty {
            return WhatToPlayScenarioFocusCoverage(
                sampledFocusKinds: sampled,
                totalFocusKinds: WhatToPlayScenarioFocusKind.allCases.count,
                missingFocusKinds: [],
                title: "تغطية مواقف متوازنة".localized,
                detail: "لديك عينات كافية من كل أنواع مواقف وش تلعب، لذلك تصبح توصيات التركيز أدق.".localized,
                iconName: "checkmark.seal.fill"
            )
        }

        let names = missing.map(scenarioFocusTitle).joined(separator: "، ")
        return WhatToPlayScenarioFocusCoverage(
            sampledFocusKinds: sampled,
            totalFocusKinds: WhatToPlayScenarioFocusKind.allCases.count,
            missingFocusKinds: missing,
            title: "أكمل أنواع المواقف".localized,
            detail: "\("درّب هذه المواقف أكثر".localized): \(names).",
            iconName: "scope"
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
                ],
                reviewItem: nil,
                seed: microDrillSeed(attempts: attempts, difficulty: .easy, focusKind: nil),
                difficulty: .easy,
                focusKind: nil
            )
        }

        if pulse.state == .reviewNeeded {
            let reviewItem = reviewQueue(for: attempts, limit: 1).first
            let firstStep = reviewItem.map {
                "\("أعد موقف".localized) \(difficultyTitle($0.difficulty)) · \("نقاط متوقعة ضائعة".localized): \($0.lostExpectedPoints)"
            } ?? "أعد قراءة بطاقة تحليل اختيارك".localized

            return WhatToPlayMicroDrill(
                title: "خطة المراجعة".localized,
                detail: "الأولوية الآن ليست كثرة المواقف، بل فهم سبب الخطأ الأخير.".localized,
                iconName: "magnifyingglass.circle.fill",
                steps: [
                    firstStep,
                    "كرر المستوى المقترح".localized,
                    "لا تنتقل قبل إجابة صحيحة".localized
                ],
                reviewItem: reviewItem,
                seed: reviewItem?.seed,
                difficulty: reviewItem?.difficulty,
                focusKind: reviewItem?.focusKind
            )
        }

        if let highValueReview = reviewQueue(for: attempts, limit: 1).first,
           highValueReview.valueLossSeverity == .high {
            return WhatToPlayMicroDrill(
                title: "خطة المراجعة".localized,
                detail: "الأولوية الآن ليست كثرة المواقف، بل فهم سبب الخطأ الأخير.".localized,
                iconName: "drop.fill",
                steps: [
                    "\("خسارة قيمة عالية".localized): \(highValueReview.lostExpectedPoints)",
                    "\("أعد موقف".localized) \(difficultyTitle(highValueReview.difficulty))",
                    "قارن أفضل وثاني أفضل".localized
                ],
                reviewItem: highValueReview,
                seed: highValueReview.seed,
                difficulty: highValueReview.difficulty,
                focusKind: highValueReview.focusKind
            )
        }

        let qualitySummary = decisionQualitySummary(for: attempts)
        if qualitySummary.trackedAttempts >= 3, qualitySummary.costlyPercent >= 30 {
            let recommendation = nextScenarioRecommendation(for: attempts)
            return WhatToPlayMicroDrill(
                title: "خطة تقليل القرارات المكلفة".localized,
                detail: "اجعل التدريب القادم قصيرًا ومبنيًا على مقارنة Replay اختيارك بأفضل قرار.".localized,
                iconName: "exclamationmark.triangle.fill",
                steps: [
                    "\("نسبة القرارات المكلفة".localized): \(qualitySummary.costlyPercent)%",
                    "شاهد Replay أفضل قرار".localized,
                    "لا ترفع الصعوبة حتى تنخفض القرارات المكلفة".localized
                ],
                reviewItem: nil,
                seed: microDrillSeed(attempts: attempts, difficulty: recommendation.difficulty, focusKind: recommendation.focusKind),
                difficulty: recommendation.difficulty,
                focusKind: recommendation.focusKind
            )
        }

        let coverage = practiceCoverage(for: attempts)
        if !coverage.isBalanced {
            let targetDifficulty = coverage.missingDifficulties.first ?? .easy
            return WhatToPlayMicroDrill(
                title: "خطة التوازن".localized,
                detail: "توصيات المدرب تصبح أدق عندما تغطي كل مستويات الصعوبة.".localized,
                iconName: "square.grid.3x3.fill",
                steps: [
                    "أكمل المستويات الناقصة".localized,
                    "حل موقفين من كل مستوى".localized,
                    "قارن أفضل وثاني أفضل".localized
                ],
                reviewItem: nil,
                seed: microDrillSeed(attempts: attempts, difficulty: targetDifficulty, focusKind: nil),
                difficulty: targetDifficulty,
                focusKind: nil
            )
        }

        let focusCoverage = scenarioFocusCoverage(for: attempts)
        if !focusCoverage.isBalanced {
            let targetFocus = focusCoverage.missingFocusKinds.first ?? .openingLead
            let targetDifficulty = nextScenarioRecommendation(for: attempts).difficulty
            return WhatToPlayMicroDrill(
                title: "خطة أنواع المواقف".localized,
                detail: "تغطية أنواع المواقف تجعل توصيات المدرب أعدل؛ لا تدرّب الصعوبة فقط.".localized,
                iconName: "scope",
                steps: [
                    "\("استهدف نوع موقف ناقص".localized): \(scenarioFocusTitle(targetFocus))",
                    "حل موقفين من نوع الموقف الناقص".localized,
                    "وازن بين الافتتاح والتلزيم والحكم".localized
                ],
                reviewItem: nil,
                seed: microDrillSeed(attempts: attempts, difficulty: targetDifficulty, focusKind: targetFocus),
                difficulty: targetDifficulty,
                focusKind: targetFocus
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
                ],
                reviewItem: nil,
                seed: microDrillSeed(attempts: attempts, difficulty: .hard, focusKind: .trumpPressure),
                difficulty: .hard,
                focusKind: .trumpPressure
            )
        }

        let recommendation = nextScenarioRecommendation(for: attempts)
        return WhatToPlayMicroDrill(
            title: "خطة الاستمرار".localized,
            detail: "استمر على تدريب قصير ومتكرر، ثم ارفع الصعوبة عندما تثبت الدقة.".localized,
            iconName: "target",
            steps: [
                "ابدأ بالمستوى المقترح".localized,
                "حل 5 مواقف قصيرة".localized,
                "راجع النقاط الضائعة".localized
            ],
            reviewItem: nil,
            seed: microDrillSeed(attempts: attempts, difficulty: recommendation.difficulty, focusKind: recommendation.focusKind),
            difficulty: recommendation.difficulty,
            focusKind: recommendation.focusKind
        )
    }

    private static func microDrillSeed(
        attempts: [WhatToPlayAttempt],
        difficulty: WhatToPlayDifficulty,
        focusKind: WhatToPlayScenarioFocusKind?
    ) -> UInt64 {
        let difficultyComponent = UInt64(difficultyOrder(difficulty)) * 1_000_000
        let focusComponent = UInt64(focusKind.map(scenarioFocusOrder) ?? 0) * 100_000
        return 8_000_000 + difficultyComponent + focusComponent + UInt64(attempts.count)
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

        if let impactPattern = impactAwareDecisionPattern(recent: recent, mistakes: mistakes) {
            return impactPattern
        }

        let farRankChoices = mistakes.filter { ($0.selectedRank ?? 1) > 2 }
        if farRankChoices.count >= 2 && farRankChoices.count >= mistakes.count - farRankChoices.count {
            return WhatToPlayDecisionPattern(
                kind: .farRankChoices,
                inspectedAttempts: recent.count,
                affectedAttempts: farRankChoices.count,
                title: "تبتعد عن أفضل خيارين".localized,
                detail: "الأخطاء الأخيرة ليست حول ثاني أفضل ورقة فقط؛ أكثر من اختيار جاء خارج أول خيارين. قبل اللعب، احذف الخيارات الضعيفة أولًا ثم قارن الأفضل والثاني.".localized,
                iconName: "list.bullet.clipboard.fill"
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

    private static func impactAwareDecisionPattern(
        recent: [WhatToPlayAttempt],
        mistakes: [WhatToPlayAttempt]
    ) -> WhatToPlayDecisionPattern? {
        let trackedMistakes = mistakes.compactMap { attempt -> WhatToPlayOptionImpactBreakdown? in
            guard attempt.expectedImpact < 0 else { return nil }
            return attempt.impactBreakdown
        }
        guard trackedMistakes.count >= 2 else { return nil }

        let opponentClosures = trackedMistakes.filter {
            $0.completesTrick && $0.winsForPlayerTeam == false && $0.trickPointsSwing < 0
        }.count
        let unprotectedDumps = trackedMistakes.filter {
            !$0.completesTrick && !$0.preservesLead && $0.playedCardPoints > 0 && $0.immediateImpact < 0
        }.count
        let costlyLeads = trackedMistakes.filter {
            $0.preservesLead && $0.immediateImpact < 0
        }.count

        let candidates: [(kind: WhatToPlayDecisionPatternKind, count: Int)] = [
            (.opponentTrickClosure, opponentClosures),
            (.unprotectedPointDump, unprotectedDumps),
            (.costlyOpeningLead, costlyLeads)
        ]
        let best = candidates.max { lhs, rhs in
            if lhs.count == rhs.count {
                return decisionPatternPriority(lhs.kind) < decisionPatternPriority(rhs.kind)
            }
            return lhs.count < rhs.count
        }

        guard let best, best.count >= 2 else { return nil }

        switch best.kind {
        case .opponentTrickClosure:
            return WhatToPlayDecisionPattern(
                kind: .opponentTrickClosure,
                inspectedAttempts: recent.count,
                affectedAttempts: best.count,
                title: "تغلق الأكلة للخصم".localized,
                detail: "أكثر من خطأ حديث أعطى الأكلة المكتملة للفريق الخصم. قبل الرمي، احسب من يربح الأكلة بعد ورقتك وهل تستحق النقاط التي ستضيفها.".localized,
                iconName: "flag.slash.fill"
            )
        case .unprotectedPointDump:
            return WhatToPlayDecisionPattern(
                kind: .unprotectedPointDump,
                inspectedAttempts: recent.count,
                affectedAttempts: best.count,
                title: "ترمي نقاطًا بلا حماية".localized,
                detail: "تكرر رمي أوراق عليها نقاط قبل أن تُحسم الأكلة. لا تضف العشرة أو الآس إلا إذا كنت تكسب الأكلة أو شريكك غالبًا سيحميها.".localized,
                iconName: "drop.triangle.fill"
            )
        case .costlyOpeningLead:
            return WhatToPlayDecisionPattern(
                kind: .costlyOpeningLead,
                inspectedAttempts: recent.count,
                affectedAttempts: best.count,
                title: "افتتاحاتك مكلفة".localized,
                detail: "بعض أخطائك جاءت من بداية الأكلة بورقة تخفض الأثر المتوقع. عند الافتتاح، اختر ورقة تكشف أقل قدر من قوتك أو تسحب الحكم لغرض واضح.".localized,
                iconName: "arrow.up.forward.circle.fill"
            )
        case .noData, .clean, .usefulAlternatives, .farRankChoices, .pointLeaks:
            return nil
        }
    }

    private static func decisionPatternPriority(_ kind: WhatToPlayDecisionPatternKind) -> Int {
        switch kind {
        case .opponentTrickClosure:
            return 3
        case .unprotectedPointDump:
            return 2
        case .costlyOpeningLead:
            return 1
        case .noData, .clean, .usefulAlternatives, .farRankChoices, .pointLeaks:
            return 0
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

        let rankSummary = choiceRankSummary(for: attempts)
        if rankSummary.trackedAttempts >= 3 && rankSummary.farPickPercent >= 40 {
            return WhatToPlayCoachingTip(
                title: "صفِّ الخيارات أولًا".localized,
                detail: "نسبة الاختيارات خارج أفضل خيارين مرتفعة. قبل المقارنة النهائية، استبعد الورق الذي لا يكسب الأكلة ولا يقلل الخسارة.".localized,
                iconName: "line.3.horizontal.decrease.circle.fill"
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

    private static func scenarioFocusOrder(_ focusKind: WhatToPlayScenarioFocusKind) -> Int {
        WhatToPlayScenarioFocusKind.allCases.firstIndex(of: focusKind) ?? Int.max
    }

    private static func scenarioFocusTitle(_ focusKind: WhatToPlayScenarioFocusKind) -> String {
        switch focusKind {
        case .openingLead:
            return "افتتاح الأكلة".localized
        case .followSuit:
            return "اتباع اللون".localized
        case .trumpPressure:
            return "ضغط الحكم".localized
        case .narrowChoice:
            return "خيارات محدودة".localized
        }
    }

    private static func focusTrainingDetail(for focusKind: WhatToPlayScenarioFocusKind) -> String {
        switch focusKind {
        case .openingLead:
            return "تدرّب على اختيار ورقة البداية التي تكشف أقل معلومات وتحافظ على ورقة القوة للوقت المناسب.".localized
        case .followSuit:
            return "راجع التلزيم: ابدأ بمعرفة اللون المطلوب ثم قرر هل تكسب الأكلة أم تخفف خسارة النقاط.".localized
        case .trumpPressure:
            return "ركّز على ضغط الحكم: لا تقطع بلا هدف، واحسب هل التعلية أو حفظ الحكم أقوى للفريق.".localized
        case .narrowChoice:
            return "في الخيارات المحدودة، قارن الأثر المتوقع لاختيارين فقط ولا ترم الورقة الأعلى تلقائيًا.".localized
        }
    }

    private static func focusTrainingIcon(for focusKind: WhatToPlayScenarioFocusKind) -> String {
        switch focusKind {
        case .openingLead:
            return "arrowshape.turn.up.forward.fill"
        case .followSuit:
            return "suit.club.fill"
        case .trumpPressure:
            return "crown.fill"
        case .narrowChoice:
            return "2.circle.fill"
        }
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
