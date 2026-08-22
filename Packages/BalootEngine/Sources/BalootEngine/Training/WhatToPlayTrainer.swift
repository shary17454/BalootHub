import Foundation

/// مستوى صعوبة موقف «وش تلعب؟».
public enum WhatToPlayDifficulty: String, Sendable, Codable, CaseIterable {
    case easy
    case medium
    case hard
    case expert

    public var expertSamples: Int {
        switch self {
        case .easy: 2
        case .medium: 6
        case .hard: 12
        case .expert: 24
        }
    }

    public var trainingOrder: Int {
        Self.allCases.firstIndex(of: self) ?? Int.max
    }

    public static func next(after difficulty: WhatToPlayDifficulty) -> WhatToPlayDifficulty {
        let nextIndex = min(difficulty.trainingOrder + 1, allCases.count - 1)
        return allCases[nextIndex]
    }

    public static func highestAttempted(in difficulties: [WhatToPlayDifficulty]) -> WhatToPlayDifficulty? {
        difficulties.max { $0.trainingOrder < $1.trainingOrder }
    }
}

/// جودة قرار اللاعب في موقف «وش تلعب؟» مقارنة باختيار الخبير ومحاكاة الجولة.
public enum WhatToPlayDecisionQuality: String, Sendable, Codable, Equatable, CaseIterable {
    case expertMatch
    case close
    case acceptable
    case costly

    /// يصنف القرار من فاقد الأثر المباشر وفاقد نتيجة استكمال الجولة.
    ///
    /// يستخدم الأكبر بين الفاقدين حتى لا يظهر قرار قريب في الأكلة الحالية
    /// كقرار جيد عندما تكشف محاكاة الجولة أنه مكلف فعليًا.
    public static func classify(
        isExpertChoice: Bool,
        lostExpectedPoints: Int,
        lostProjectedTeamPoints: Int = 0,
        lostProjectedAgainstSecondBestPoints: Int = 0
    ) -> WhatToPlayDecisionQuality {
        let decisiveLoss = max(lostExpectedPoints, lostProjectedTeamPoints, lostProjectedAgainstSecondBestPoints)
        if isExpertChoice || decisiveLoss == 0 { return .expertMatch }
        if decisiveLoss <= 2 { return .close }
        if decisiveLoss <= 8 { return .acceptable }
        return .costly
    }
}

/// التصنيف الخام لرؤية قرار اللاعب في موقف «وش تلعب؟».
public enum WhatToPlayDecisionInsightCategory: String, Sendable, Codable, Equatable, CaseIterable {
    case expertMatch
    case closeAlternative
    case missedWinningChance
    case pointLeak
}

/// شدة خسارة القيمة عند مقارنة خيار اللاعب بأفضل خيار في «وش تلعب؟».
public enum WhatToPlayValueLossSeverityCategory: String, Sendable, Codable, Equatable, CaseIterable {
    case none
    case low
    case medium
    case high

    public static func classify(decisiveLoss: Int) -> WhatToPlayValueLossSeverityCategory {
        switch decisiveLoss {
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
}

/// أرقام وتصنيف قرار المستخدم دون نصوص واجهة أو أيقونات.
public struct WhatToPlayDecisionInsightMetrics: Sendable, Equatable {
    public let category: WhatToPlayDecisionInsightCategory
    public let lostExpectedPoints: Int
    public let lostProjectedTeamPoints: Int
    public let lostProjectedAgainstSecondBestPoints: Int
    public let secondBestGap: Int?
    public let valueLossSeverity: WhatToPlayValueLossSeverityCategory

    public init(
        category: WhatToPlayDecisionInsightCategory,
        lostExpectedPoints: Int,
        lostProjectedTeamPoints: Int,
        lostProjectedAgainstSecondBestPoints: Int = 0,
        secondBestGap: Int?,
        valueLossSeverity: WhatToPlayValueLossSeverityCategory
    ) {
        self.category = category
        self.lostExpectedPoints = lostExpectedPoints
        self.lostProjectedTeamPoints = lostProjectedTeamPoints
        self.lostProjectedAgainstSecondBestPoints = lostProjectedAgainstSecondBestPoints
        self.secondBestGap = secondBestGap
        self.valueLossSeverity = valueLossSeverity
    }

    public static func classify(
        selectedRank: Int,
        selectedImpact: Int,
        bestImpact: Int,
        secondBestImpact: Int?,
        selectedProjectedTeamPoints: Int? = nil,
        bestProjectedTeamPoints: Int? = nil,
        secondBestProjectedTeamPoints: Int? = nil
    ) -> WhatToPlayDecisionInsightMetrics {
        let lostExpectedPoints = max(0, bestImpact - selectedImpact)
        let lostProjectedTeamPoints: Int
        if let selectedProjectedTeamPoints, let bestProjectedTeamPoints {
            lostProjectedTeamPoints = max(0, bestProjectedTeamPoints - selectedProjectedTeamPoints)
        } else {
            lostProjectedTeamPoints = 0
        }
        let lostProjectedAgainstSecondBestPoints: Int
        if let selectedProjectedTeamPoints, let secondBestProjectedTeamPoints {
            lostProjectedAgainstSecondBestPoints = max(0, secondBestProjectedTeamPoints - selectedProjectedTeamPoints)
        } else {
            lostProjectedAgainstSecondBestPoints = 0
        }

        let decisiveLoss = max(lostExpectedPoints, lostProjectedTeamPoints, lostProjectedAgainstSecondBestPoints)
        let secondBestGap = secondBestImpact.map { max(0, $0 - selectedImpact) }
        let severity = WhatToPlayValueLossSeverityCategory.classify(decisiveLoss: decisiveLoss)

        let category: WhatToPlayDecisionInsightCategory
        if selectedRank == 1 || decisiveLoss == 0 {
            category = .expertMatch
        } else if max(lostProjectedTeamPoints, lostProjectedAgainstSecondBestPoints) > lostExpectedPoints {
            category = .pointLeak
        } else if selectedRank == 2 || decisiveLoss <= 2 || secondBestImpact == selectedImpact {
            category = .closeAlternative
        } else if selectedImpact < 0 && bestImpact > 0 {
            category = .missedWinningChance
        } else {
            category = .pointLeak
        }

        return WhatToPlayDecisionInsightMetrics(
            category: category,
            lostExpectedPoints: lostExpectedPoints,
            lostProjectedTeamPoints: lostProjectedTeamPoints,
            lostProjectedAgainstSecondBestPoints: lostProjectedAgainstSecondBestPoints,
            secondBestGap: secondBestGap,
            valueLossSeverity: severity
        )
    }
}

/// نوع أول خطوة في مراجعة قرار «وش تلعب؟» حسب محور الموقف.
public enum WhatToPlayDecisionReviewFocusStepCategory: String, Sendable, Codable, Equatable, CaseIterable {
    case openingLead
    case followSuit
    case trumpPressure
    case narrowChoice
}

/// تصنيف خطوة مراجعة القرار المرتبطة بمحور الموقف دون نصوص واجهة.
public struct WhatToPlayDecisionReviewFocusStepMetrics: Sendable, Equatable {
    public let category: WhatToPlayDecisionReviewFocusStepCategory

    public init(category: WhatToPlayDecisionReviewFocusStepCategory) {
        self.category = category
    }

    public static func classify(
        focusKind: WhatToPlayScenarioFocusKind
    ) -> WhatToPlayDecisionReviewFocusStepMetrics {
        switch focusKind {
        case .openingLead:
            WhatToPlayDecisionReviewFocusStepMetrics(category: .openingLead)
        case .followSuit:
            WhatToPlayDecisionReviewFocusStepMetrics(category: .followSuit)
        case .trumpPressure:
            WhatToPlayDecisionReviewFocusStepMetrics(category: .trumpPressure)
        case .narrowChoice:
            WhatToPlayDecisionReviewFocusStepMetrics(category: .narrowChoice)
        }
    }
}

/// نوع ثاني خطوة في مراجعة قرار «وش تلعب؟» حسب نتيجة تحليل القرار.
public enum WhatToPlayDecisionReviewInsightStepCategory: String, Sendable, Codable, Equatable, CaseIterable {
    case reinforceSuccess
    case compareAlternative
    case findWinningCard
    case identifyPointLeak
}

/// تصنيف خطوة مراجعة القرار المرتبطة بنتيجة تحليل الاختيار دون نصوص واجهة.
public struct WhatToPlayDecisionReviewInsightStepMetrics: Sendable, Equatable {
    public let category: WhatToPlayDecisionReviewInsightStepCategory

    public init(category: WhatToPlayDecisionReviewInsightStepCategory) {
        self.category = category
    }

    public static func classify(
        insightCategory: WhatToPlayDecisionInsightCategory
    ) -> WhatToPlayDecisionReviewInsightStepMetrics {
        switch insightCategory {
        case .expertMatch:
            WhatToPlayDecisionReviewInsightStepMetrics(category: .reinforceSuccess)
        case .closeAlternative:
            WhatToPlayDecisionReviewInsightStepMetrics(category: .compareAlternative)
        case .missedWinningChance:
            WhatToPlayDecisionReviewInsightStepMetrics(category: .findWinningCard)
        case .pointLeak:
            WhatToPlayDecisionReviewInsightStepMetrics(category: .identifyPointLeak)
        }
    }
}

/// نوع رسالة تثبيت القراءة بعد اختيار صحيح في «وش تلعب؟».
public enum WhatToPlayFocusSuccessActionCategory: String, Sendable, Codable, Equatable, CaseIterable {
    case openingLead
    case followSuit
    case trumpPressure
    case narrowChoice
}

/// تصنيف رسالة تثبيت القراءة حسب محور الموقف دون نصوص واجهة.
public struct WhatToPlayFocusSuccessActionMetrics: Sendable, Equatable {
    public let category: WhatToPlayFocusSuccessActionCategory

    public init(category: WhatToPlayFocusSuccessActionCategory) {
        self.category = category
    }

    public static func classify(
        focusKind: WhatToPlayScenarioFocusKind
    ) -> WhatToPlayFocusSuccessActionMetrics {
        switch focusKind {
        case .openingLead:
            WhatToPlayFocusSuccessActionMetrics(category: .openingLead)
        case .followSuit:
            WhatToPlayFocusSuccessActionMetrics(category: .followSuit)
        case .trumpPressure:
            WhatToPlayFocusSuccessActionMetrics(category: .trumpPressure)
        case .narrowChoice:
            WhatToPlayFocusSuccessActionMetrics(category: .narrowChoice)
        }
    }
}

/// مستوى إتقان اللاعب الخام في مدرب «وش تلعب؟».
public enum WhatToPlayMasteryCategory: String, Sendable, Codable, Equatable, CaseIterable {
    case starting
    case building
    case confident
    case sharp
}

/// درجة إتقان «وش تلعب؟» من أرقام الأداء دون نصوص واجهة.
public struct WhatToPlayMasteryMetrics: Sendable, Equatable {
    public let category: WhatToPlayMasteryCategory
    public let score: Int

    public init(category: WhatToPlayMasteryCategory, score: Int) {
        self.category = category
        self.score = score
    }

    public static func classify(
        attempts: Int,
        accuracyPercent: Int,
        currentStreak: Int,
        averageExpectedImpact: Int
    ) -> WhatToPlayMasteryMetrics {
        guard attempts > 0 else {
            return WhatToPlayMasteryMetrics(category: .starting, score: 0)
        }

        let boundedAccuracy = max(0, min(100, accuracyPercent))
        let accuracyScore = Double(boundedAccuracy) * 0.6
        let streakScore = min(Double(max(0, currentStreak)), 5) / 5 * 20
        let impactScore = Double(max(-10, min(10, averageExpectedImpact)) + 10)
        let score = max(0, min(100, Int((accuracyScore + streakScore + impactScore).rounded())))
        let category: WhatToPlayMasteryCategory

        switch score {
        case 80...100:
            category = .sharp
        case 60..<80:
            category = .confident
        case 35..<60:
            category = .building
        default:
            category = .starting
        }

        return WhatToPlayMasteryMetrics(category: category, score: score)
    }

    public var nextMilestoneScore: Int? {
        switch score {
        case ..<35:
            35
        case 35..<60:
            60
        case 60..<80:
            80
        default:
            nil
        }
    }
}

/// تغطية مستويات صعوبة مدرب «وش تلعب؟».
public struct WhatToPlayDifficultyCoverageMetrics: Sendable, Equatable {
    public let sampledDifficulties: Int
    public let totalDifficulties: Int
    public let missingDifficulties: [WhatToPlayDifficulty]

    public init(
        sampledDifficulties: Int,
        totalDifficulties: Int,
        missingDifficulties: [WhatToPlayDifficulty]
    ) {
        self.sampledDifficulties = sampledDifficulties
        self.totalDifficulties = totalDifficulties
        self.missingDifficulties = missingDifficulties
    }

    public var isBalanced: Bool { missingDifficulties.isEmpty }

    public static func classify(
        counts: [WhatToPlayDifficulty: Int],
        minimumAttemptsPerDifficulty: Int = 2
    ) -> WhatToPlayDifficultyCoverageMetrics {
        let missing = WhatToPlayDifficulty.allCases.filter {
            (counts[$0] ?? 0) < minimumAttemptsPerDifficulty
        }
        return WhatToPlayDifficultyCoverageMetrics(
            sampledDifficulties: WhatToPlayDifficulty.allCases.count - missing.count,
            totalDifficulties: WhatToPlayDifficulty.allCases.count,
            missingDifficulties: missing
        )
    }
}

/// تغطية أنواع مواقف مدرب «وش تلعب؟».
public struct WhatToPlayFocusCoverageMetrics: Sendable, Equatable {
    public let sampledFocusKinds: Int
    public let totalFocusKinds: Int
    public let missingFocusKinds: [WhatToPlayScenarioFocusKind]

    public init(
        sampledFocusKinds: Int,
        totalFocusKinds: Int,
        missingFocusKinds: [WhatToPlayScenarioFocusKind]
    ) {
        self.sampledFocusKinds = sampledFocusKinds
        self.totalFocusKinds = totalFocusKinds
        self.missingFocusKinds = missingFocusKinds
    }

    public var isBalanced: Bool { missingFocusKinds.isEmpty }

    public static func classify(
        counts: [WhatToPlayScenarioFocusKind: Int],
        minimumAttemptsPerFocus: Int = 2
    ) -> WhatToPlayFocusCoverageMetrics {
        let missing = WhatToPlayScenarioFocusKind.allCases.filter {
            (counts[$0] ?? 0) < minimumAttemptsPerFocus
        }
        return WhatToPlayFocusCoverageMetrics(
            sampledFocusKinds: WhatToPlayScenarioFocusKind.allCases.count - missing.count,
            totalFocusKinds: WhatToPlayScenarioFocusKind.allCases.count,
            missingFocusKinds: missing
        )
    }
}

/// تغطية نمطي الصن والحكم في مدرب «وش تلعب؟».
public struct WhatToPlayGameModeCoverageMetrics: Sendable, Equatable {
    public let sampledModes: Int
    public let totalModes: Int
    public let missingModes: [GameMode]

    public init(sampledModes: Int, totalModes: Int, missingModes: [GameMode]) {
        self.sampledModes = sampledModes
        self.totalModes = totalModes
        self.missingModes = missingModes
    }

    public var isBalanced: Bool { missingModes.isEmpty }

    public static func classify(
        counts: [GameMode: Int],
        minimumAttemptsPerMode: Int = 2
    ) -> WhatToPlayGameModeCoverageMetrics {
        let missing = GameMode.allCases.filter {
            (counts[$0] ?? 0) < minimumAttemptsPerMode
        }
        return WhatToPlayGameModeCoverageMetrics(
            sampledModes: GameMode.allCases.count - missing.count,
            totalModes: GameMode.allCases.count,
            missingModes: missing
        )
    }
}

/// تغطية ألوان الحكم في مدرب «وش تلعب؟».
public struct WhatToPlayTrumpSuitCoverageMetrics: Sendable, Equatable {
    public let sampledSuits: Int
    public let totalSuits: Int
    public let missingSuits: [Suit]

    public init(sampledSuits: Int, totalSuits: Int, missingSuits: [Suit]) {
        self.sampledSuits = sampledSuits
        self.totalSuits = totalSuits
        self.missingSuits = missingSuits
    }

    public var isBalanced: Bool { missingSuits.isEmpty }

    public static func classify(
        counts: [Suit: Int],
        minimumAttemptsPerSuit: Int = 2
    ) -> WhatToPlayTrumpSuitCoverageMetrics {
        let missing = Suit.allCases.filter {
            (counts[$0] ?? 0) < minimumAttemptsPerSuit
        }
        return WhatToPlayTrumpSuitCoverageMetrics(
            sampledSuits: Suit.allCases.count - missing.count,
            totalSuits: Suit.allCases.count,
            missingSuits: missing
        )
    }
}

/// حالة الجلسة الحالية في مدرب «وش تلعب؟» دون نصوص واجهة.
public enum WhatToPlaySessionPulseState: String, Sendable, Codable, Equatable, CaseIterable {
    case noData
    case warmingUp
    case focused
    case reviewNeeded
}

/// نبض الجلسة الحالي من آخر محاولات اللاعب في «وش تلعب؟».
public struct WhatToPlaySessionPulseMetrics: Sendable, Equatable {
    public let state: WhatToPlaySessionPulseState
    public let inspectedAttempts: Int

    public init(state: WhatToPlaySessionPulseState, inspectedAttempts: Int) {
        self.state = state
        self.inspectedAttempts = inspectedAttempts
    }

    public static func classify(
        totalAttempts: Int,
        recentMistakes: Int,
        recentAverageExpectedImpact: Int,
        window: Int = 3
    ) -> WhatToPlaySessionPulseMetrics {
        guard totalAttempts >= window, window > 0 else {
            return WhatToPlaySessionPulseMetrics(
                state: totalAttempts == 0 ? .noData : .warmingUp,
                inspectedAttempts: max(0, totalAttempts)
            )
        }

        let inspected = min(totalAttempts, window)
        if recentMistakes == 0 && recentAverageExpectedImpact >= 0 {
            return WhatToPlaySessionPulseMetrics(state: .focused, inspectedAttempts: inspected)
        }

        if recentMistakes >= 2 || recentAverageExpectedImpact < -3 {
            return WhatToPlaySessionPulseMetrics(state: .reviewNeeded, inspectedAttempts: inspected)
        }

        return WhatToPlaySessionPulseMetrics(state: .warmingUp, inspectedAttempts: inspected)
    }
}

/// نوع خطة الميكرو-تدريب التالية في «وش تلعب؟» دون نصوص واجهة أو اعتماد على SwiftData.
public enum WhatToPlayMicroDrillCategory: String, Sendable, Codable, Equatable, CaseIterable {
    case start
    case reviewMistake
    case simulationReview
    case highValueReview
    case costlyDecisionReduction
    case difficultyCoverage
    case focusCoverage
    case gameModeCoverage
    case trumpSuitCoverage
    case challenge
    case continuePractice
}

/// تصنيف خطة الميكرو-تدريب من نبض الجلسة وتغطية التدريب.
public struct WhatToPlayMicroDrillMetrics: Sendable, Equatable {
    public let category: WhatToPlayMicroDrillCategory

    public init(category: WhatToPlayMicroDrillCategory) {
        self.category = category
    }

    public static func classify(
        pulseState: WhatToPlaySessionPulseState,
        hasSimulationReview: Bool,
        hasHighValueReview: Bool,
        trackedDecisionQualityAttempts: Int,
        costlyDecisionPercent: Int,
        isDifficultyCoverageBalanced: Bool,
        isFocusCoverageBalanced: Bool,
        isGameModeCoverageBalanced: Bool,
        hasTrumpSuitSamples: Bool,
        isTrumpSuitCoverageBalanced: Bool,
        isMasterySharp: Bool,
        minimumDecisionQualityAttempts: Int = 3,
        costlyDecisionPercentThreshold: Int = 30
    ) -> WhatToPlayMicroDrillMetrics {
        if pulseState == .noData {
            return WhatToPlayMicroDrillMetrics(category: .start)
        }

        if pulseState == .reviewNeeded {
            return WhatToPlayMicroDrillMetrics(category: .reviewMistake)
        }

        if hasSimulationReview {
            return WhatToPlayMicroDrillMetrics(category: .simulationReview)
        }

        if hasHighValueReview {
            return WhatToPlayMicroDrillMetrics(category: .highValueReview)
        }

        let trackedAttempts = max(0, trackedDecisionQualityAttempts)
        let costlyPercent = max(0, min(100, costlyDecisionPercent))
        if trackedAttempts >= max(1, minimumDecisionQualityAttempts),
           costlyPercent >= max(0, min(100, costlyDecisionPercentThreshold)) {
            return WhatToPlayMicroDrillMetrics(category: .costlyDecisionReduction)
        }

        if !isDifficultyCoverageBalanced {
            return WhatToPlayMicroDrillMetrics(category: .difficultyCoverage)
        }

        if !isFocusCoverageBalanced {
            return WhatToPlayMicroDrillMetrics(category: .focusCoverage)
        }

        if !isGameModeCoverageBalanced {
            return WhatToPlayMicroDrillMetrics(category: .gameModeCoverage)
        }

        if hasTrumpSuitSamples && !isTrumpSuitCoverageBalanced {
            return WhatToPlayMicroDrillMetrics(category: .trumpSuitCoverage)
        }

        if isMasterySharp {
            return WhatToPlayMicroDrillMetrics(category: .challenge)
        }

        return WhatToPlayMicroDrillMetrics(category: .continuePractice)
    }
}

/// توليد بذرة حتمية لخطة الميكرو-تدريب في «وش تلعب؟».
public struct WhatToPlayMicroDrillSeedMetrics: Sendable, Equatable {
    public let seedBase: UInt64
    public let difficultyOrder: Int
    public let focusOrder: Int?
    public let gameModeOrder: Int?
    public let trumpSuitOrdinal: Int?
    public let totalAttemptCount: Int
    public let matchingAttemptSeeds: Set<UInt64>

    public init(
        seedBase: UInt64 = 8_000_000,
        difficultyOrder: Int,
        focusOrder: Int?,
        gameModeOrder: Int?,
        trumpSuitOrdinal: Int?,
        totalAttemptCount: Int,
        matchingAttemptSeeds: Set<UInt64>
    ) {
        self.seedBase = seedBase
        self.difficultyOrder = difficultyOrder
        self.focusOrder = focusOrder
        self.gameModeOrder = gameModeOrder
        self.trumpSuitOrdinal = trumpSuitOrdinal
        self.totalAttemptCount = totalAttemptCount
        self.matchingAttemptSeeds = matchingAttemptSeeds
    }

    public var nextSeed: UInt64 {
        let difficultyComponent = UInt64(max(0, difficultyOrder)) * 1_000_000
        let focusComponent = UInt64(max(0, focusOrder ?? 0)) * 100_000
        let modeComponent = UInt64(max(0, gameModeOrder ?? 0)) * 10_000
        let trumpSuitComponent = UInt64(max(0, (trumpSuitOrdinal ?? -1) + 1)) * 100
        var candidate = seedBase
            + difficultyComponent
            + focusComponent
            + modeComponent
            + trumpSuitComponent
            + UInt64(max(0, totalAttemptCount))

        while matchingAttemptSeeds.contains(candidate) {
            candidate &+= 1
        }
        return candidate
    }
}

/// نوع موجز موقف «وش تلعب؟» قبل اختيار الورقة دون نصوص واجهة.
public enum WhatToPlayScenarioBriefCategory: String, Sendable, Codable, Equatable, CaseIterable {
    case openingLead
    case followSuit
    case followSuitMissingRequiredSuit
    case trumpPressureWithTrumpOnTable
    case trumpPressureWithoutTrumpOnTable
    case narrowChoice
}

/// تصنيف موجز موقف «وش تلعب؟» من سياق المحرك.
public struct WhatToPlayScenarioBriefMetrics: Sendable, Equatable {
    public let category: WhatToPlayScenarioBriefCategory

    public init(category: WhatToPlayScenarioBriefCategory) {
        self.category = category
    }

    public static func classify(context: WhatToPlayScenarioContext) -> WhatToPlayScenarioBriefMetrics {
        switch context.focusKind {
        case .openingLead:
            return WhatToPlayScenarioBriefMetrics(category: .openingLead)
        case .followSuit:
            return WhatToPlayScenarioBriefMetrics(
                category: context.requiredSuit == nil ? .followSuitMissingRequiredSuit : .followSuit
            )
        case .trumpPressure:
            return WhatToPlayScenarioBriefMetrics(
                category: context.hasTrumpInCurrentTrick
                    ? .trumpPressureWithTrumpOnTable
                    : .trumpPressureWithoutTrumpOnTable
            )
        case .narrowChoice:
            return WhatToPlayScenarioBriefMetrics(category: .narrowChoice)
        }
    }
}

/// تصنيف أسلوب اللاعب الخام في مدرب «وش تلعب؟» دون نصوص واجهة.
public enum WhatToPlayPlayStyleCategory: String, Sendable, Codable, Equatable, CaseIterable {
    case measuring
    case foundational
    case cautious
    case inconsistent
    case expertAligned
}

/// قياس أسلوب اللاعب في «وش تلعب؟» من أرقام الأداء فقط.
public struct WhatToPlayPlayStyleMetrics: Sendable, Equatable {
    public let category: WhatToPlayPlayStyleCategory
    public let inspectedAttempts: Int

    public init(category: WhatToPlayPlayStyleCategory, inspectedAttempts: Int) {
        self.category = category
        self.inspectedAttempts = inspectedAttempts
    }

    public static func classify(
        attempts: Int,
        accuracyPercent: Int,
        averageExpectedImpact: Int,
        minimumAttempts: Int = 3
    ) -> WhatToPlayPlayStyleMetrics {
        guard attempts >= minimumAttempts else {
            return WhatToPlayPlayStyleMetrics(
                category: .measuring,
                inspectedAttempts: max(0, attempts)
            )
        }

        let boundedAccuracy = max(0, min(100, accuracyPercent))
        let category: WhatToPlayPlayStyleCategory
        if boundedAccuracy >= 80 && averageExpectedImpact >= 0 {
            category = .expertAligned
        } else if boundedAccuracy < 50 {
            category = .foundational
        } else if boundedAccuracy >= 65 && averageExpectedImpact < 0 {
            category = .cautious
        } else {
            category = .inconsistent
        }

        return WhatToPlayPlayStyleMetrics(
            category: category,
            inspectedAttempts: max(0, attempts)
        )
    }
}

/// تصنيف نمط أخطاء اللاعب في مدرب «وش تلعب؟» دون نصوص واجهة.
public enum WhatToPlayDecisionPatternCategory: String, Sendable, Codable, Equatable, CaseIterable {
    case noData
    case clean
    case usefulAlternatives
    case farRankChoices
    case pointLeaks
    case opponentTrickClosure
    case unprotectedPointDump
    case costlyOpeningLead
}

/// عينة قرار مختصرة تكفي لتصنيف نمط قرارات «وش تلعب؟».
public struct WhatToPlayDecisionPatternSample: Sendable, Equatable {
    public let isCorrect: Bool
    public let selectedRank: Int?
    public let expectedImpact: Int
    public let impactBreakdown: WhatToPlayOptionImpactBreakdown?

    public init(
        isCorrect: Bool,
        selectedRank: Int?,
        expectedImpact: Int,
        impactBreakdown: WhatToPlayOptionImpactBreakdown? = nil
    ) {
        self.isCorrect = isCorrect
        self.selectedRank = selectedRank
        self.expectedImpact = expectedImpact
        self.impactBreakdown = impactBreakdown
    }
}

/// قياس نمط قرارات اللاعب من آخر عينات مدرب «وش تلعب؟».
public struct WhatToPlayDecisionPatternMetrics: Sendable, Equatable {
    public let category: WhatToPlayDecisionPatternCategory
    public let inspectedAttempts: Int
    public let affectedAttempts: Int

    public init(
        category: WhatToPlayDecisionPatternCategory,
        inspectedAttempts: Int,
        affectedAttempts: Int
    ) {
        self.category = category
        self.inspectedAttempts = inspectedAttempts
        self.affectedAttempts = affectedAttempts
    }

    public static func classify(samples: [WhatToPlayDecisionPatternSample]) -> WhatToPlayDecisionPatternMetrics {
        guard !samples.isEmpty else {
            return WhatToPlayDecisionPatternMetrics(
                category: .noData,
                inspectedAttempts: 0,
                affectedAttempts: 0
            )
        }

        let mistakes = samples.filter { !$0.isCorrect }
        guard !mistakes.isEmpty else {
            return WhatToPlayDecisionPatternMetrics(
                category: .clean,
                inspectedAttempts: samples.count,
                affectedAttempts: 0
            )
        }

        if let impactPattern = impactAwareDecisionPattern(samples: samples, mistakes: mistakes) {
            return impactPattern
        }

        let farRankChoices = mistakes.filter { ($0.selectedRank ?? 1) > 2 }
        if farRankChoices.count >= 2 && farRankChoices.count >= mistakes.count - farRankChoices.count {
            return WhatToPlayDecisionPatternMetrics(
                category: .farRankChoices,
                inspectedAttempts: samples.count,
                affectedAttempts: farRankChoices.count
            )
        }

        let pointLeaks = mistakes.filter { $0.expectedImpact < 0 }
        let usefulAlternatives = mistakes.count - pointLeaks.count
        if pointLeaks.count >= usefulAlternatives {
            return WhatToPlayDecisionPatternMetrics(
                category: .pointLeaks,
                inspectedAttempts: samples.count,
                affectedAttempts: pointLeaks.count
            )
        }

        return WhatToPlayDecisionPatternMetrics(
            category: .usefulAlternatives,
            inspectedAttempts: samples.count,
            affectedAttempts: usefulAlternatives
        )
    }

    private static func impactAwareDecisionPattern(
        samples: [WhatToPlayDecisionPatternSample],
        mistakes: [WhatToPlayDecisionPatternSample]
    ) -> WhatToPlayDecisionPatternMetrics? {
        let trackedMistakes = mistakes.compactMap { sample -> WhatToPlayOptionImpactBreakdown? in
            guard sample.expectedImpact < 0 else { return nil }
            return sample.impactBreakdown
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

        let candidates: [(category: WhatToPlayDecisionPatternCategory, count: Int)] = [
            (.opponentTrickClosure, opponentClosures),
            (.unprotectedPointDump, unprotectedDumps),
            (.costlyOpeningLead, costlyLeads)
        ]
        let best = candidates.max { lhs, rhs in
            if lhs.count == rhs.count {
                return priority(lhs.category) < priority(rhs.category)
            }
            return lhs.count < rhs.count
        }

        guard let best, best.count >= 2 else { return nil }

        return WhatToPlayDecisionPatternMetrics(
            category: best.category,
            inspectedAttempts: samples.count,
            affectedAttempts: best.count
        )
    }

    private static func priority(_ category: WhatToPlayDecisionPatternCategory) -> Int {
        switch category {
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
}

/// تصنيف درجة جلسة تدريب «وش تلعب؟» دون نصوص واجهة.
public enum WhatToPlayTrainingSessionGradeCategory: String, Sendable, Codable, Equatable, CaseIterable {
    case excellent
    case good
    case stabilizing
    case repeatNeeded
}

/// السبب الخام المؤثر على درجة جلسة تدريب «وش تلعب؟».
public enum WhatToPlayTrainingSessionGradeReasonCategory: String, Sendable, Codable, Equatable, CaseIterable {
    case projectedLossPenalty
    case impactWeakness
    case accuracyWeakness
    case balanced
}

/// قياس درجة جلسة تدريب «وش تلعب؟» من الدقة وأثر القرار وفاقد المحاكاة.
public struct WhatToPlayTrainingSessionGradeMetrics: Sendable, Equatable {
    public let category: WhatToPlayTrainingSessionGradeCategory
    public let percent: Int
    public let accuracyComponent: Int
    public let impactComponent: Int
    public let reasonCategory: WhatToPlayTrainingSessionGradeReasonCategory

    public init(
        category: WhatToPlayTrainingSessionGradeCategory,
        percent: Int,
        accuracyComponent: Int,
        impactComponent: Int,
        reasonCategory: WhatToPlayTrainingSessionGradeReasonCategory
    ) {
        self.category = category
        self.percent = percent
        self.accuracyComponent = accuracyComponent
        self.impactComponent = impactComponent
        self.reasonCategory = reasonCategory
    }

    public static func classify(
        completedAttempts: Int,
        accuracyPercent: Int,
        averageExpectedImpact: Int,
        targetAverageExpectedImpact: Int,
        averageLostProjectedTeamPoints: Int
    ) -> WhatToPlayTrainingSessionGradeMetrics {
        guard completedAttempts > 0 else {
            return WhatToPlayTrainingSessionGradeMetrics(
                category: .repeatNeeded,
                percent: 0,
                accuracyComponent: 0,
                impactComponent: 0,
                reasonCategory: .balanced
            )
        }

        let boundedAccuracy = max(0, min(100, accuracyPercent))
        let baseImpact = min(100, max(0, 50 + ((averageExpectedImpact - targetAverageExpectedImpact) * 10)))
        let projectedLossPenalty = min(40, max(0, averageLostProjectedTeamPoints * 4))
        let normalizedImpact = max(0, baseImpact - projectedLossPenalty)
        let percent = min(100, max(0, Int((Double(boundedAccuracy + normalizedImpact) / 2.0).rounded())))

        let category: WhatToPlayTrainingSessionGradeCategory
        switch percent {
        case 85...100:
            category = .excellent
        case 70..<85:
            category = .good
        case 50..<70:
            category = .stabilizing
        default:
            category = .repeatNeeded
        }

        let reasonCategory = reason(
            accuracyComponent: boundedAccuracy,
            impactComponent: normalizedImpact,
            averageLostProjectedTeamPoints: averageLostProjectedTeamPoints
        )

        return WhatToPlayTrainingSessionGradeMetrics(
            category: category,
            percent: percent,
            accuracyComponent: boundedAccuracy,
            impactComponent: normalizedImpact,
            reasonCategory: reasonCategory
        )
    }

    private static func reason(
        accuracyComponent: Int,
        impactComponent: Int,
        averageLostProjectedTeamPoints: Int
    ) -> WhatToPlayTrainingSessionGradeReasonCategory {
        if averageLostProjectedTeamPoints >= 6 {
            return .projectedLossPenalty
        }

        let gap = accuracyComponent - impactComponent
        if gap >= 15 {
            return .impactWeakness
        }

        if gap <= -15 {
            return .accuracyWeakness
        }

        return .balanced
    }
}

/// حالة تقدم جلسة تدريب «وش تلعب؟» دون نصوص واجهة.
public enum WhatToPlayTrainingSessionProgressCategory: String, Sendable, Codable, Equatable, CaseIterable {
    case notStarted
    case inProgress
    case achieved
    case needsRepeat
}

/// قياسات تقدم جلسة تدريب «وش تلعب؟» من أهداف الخطة ومحاولات الجلسة.
public struct WhatToPlayTrainingSessionProgressMetrics: Sendable, Equatable {
    public let category: WhatToPlayTrainingSessionProgressCategory
    public let completedAttempts: Int
    public let targetAttempts: Int
    public let correctAttempts: Int
    public let accuracyPercent: Int
    public let accuracyTargetMet: Bool
    public let requiredCorrectAttempts: Int
    public let correctAttemptsNeededForTarget: Int
    public let bestPossibleAccuracyPercent: Int
    public let accuracyTargetReachable: Bool
    public let totalExpectedImpact: Int
    public let averageExpectedImpact: Int
    public let impactTargetMet: Bool
    public let averageExpectedImpactGap: Int
    public let expectedImpactNeededForTarget: Int
    public let expectedImpactNeededPerRemainingAttempt: Int
    public let impactRecoveryHighPressure: Bool
    public let remainingAttempts: Int
    public let maxCostlyDecisions: Int?
    public let costlyDecisions: Int
    public let costlyDecisionTargetMet: Bool

    public init(
        category: WhatToPlayTrainingSessionProgressCategory,
        completedAttempts: Int,
        targetAttempts: Int,
        correctAttempts: Int,
        accuracyPercent: Int,
        accuracyTargetMet: Bool,
        requiredCorrectAttempts: Int,
        correctAttemptsNeededForTarget: Int,
        bestPossibleAccuracyPercent: Int,
        accuracyTargetReachable: Bool,
        totalExpectedImpact: Int,
        averageExpectedImpact: Int,
        impactTargetMet: Bool,
        averageExpectedImpactGap: Int,
        expectedImpactNeededForTarget: Int,
        expectedImpactNeededPerRemainingAttempt: Int,
        impactRecoveryHighPressure: Bool,
        remainingAttempts: Int,
        maxCostlyDecisions: Int?,
        costlyDecisions: Int,
        costlyDecisionTargetMet: Bool
    ) {
        self.category = category
        self.completedAttempts = completedAttempts
        self.targetAttempts = targetAttempts
        self.correctAttempts = correctAttempts
        self.accuracyPercent = accuracyPercent
        self.accuracyTargetMet = accuracyTargetMet
        self.requiredCorrectAttempts = requiredCorrectAttempts
        self.correctAttemptsNeededForTarget = correctAttemptsNeededForTarget
        self.bestPossibleAccuracyPercent = bestPossibleAccuracyPercent
        self.accuracyTargetReachable = accuracyTargetReachable
        self.totalExpectedImpact = totalExpectedImpact
        self.averageExpectedImpact = averageExpectedImpact
        self.impactTargetMet = impactTargetMet
        self.averageExpectedImpactGap = averageExpectedImpactGap
        self.expectedImpactNeededForTarget = expectedImpactNeededForTarget
        self.expectedImpactNeededPerRemainingAttempt = expectedImpactNeededPerRemainingAttempt
        self.impactRecoveryHighPressure = impactRecoveryHighPressure
        self.remainingAttempts = remainingAttempts
        self.maxCostlyDecisions = maxCostlyDecisions
        self.costlyDecisions = costlyDecisions
        self.costlyDecisionTargetMet = costlyDecisionTargetMet
    }

    public static func classify(
        completedAttempts: Int,
        correctAttempts: Int,
        targetAttempts: Int,
        targetAccuracyPercent: Int,
        totalExpectedImpact: Int,
        targetAverageExpectedImpact: Int,
        costlyDecisions: Int,
        maxCostlyDecisions: Int?
    ) -> WhatToPlayTrainingSessionProgressMetrics {
        let target = max(1, targetAttempts)
        let completed = max(0, min(completedAttempts, target))
        let correct = max(0, min(correctAttempts, completed))
        let remaining = max(0, target - completed)
        let effectiveTotalImpact = completed > 0 ? totalExpectedImpact : 0
        let accuracy = completed > 0
            ? Int((Double(correct) / Double(completed) * 100).rounded())
            : 0
        let averageImpact = completed > 0
            ? Int((Double(effectiveTotalImpact) / Double(completed)).rounded())
            : 0
        let requiredCorrect = requiredCorrectAttempts(
            targetAttempts: target,
            targetAccuracyPercent: targetAccuracyPercent
        )
        let correctNeeded = max(0, requiredCorrect - correct)
        let accuracyTargetMet = completed > 0 && accuracy >= targetAccuracyPercent
        let bestPossibleCorrect = min(target, correct + remaining)
        let bestPossibleAccuracy = completed == 0
            ? 100
            : Int((Double(bestPossibleCorrect) / Double(target) * 100).rounded())
        let accuracyTargetReachable = completed >= target
            ? accuracyTargetMet
            : bestPossibleCorrect >= requiredCorrect
        let targetTotalImpact = target * targetAverageExpectedImpact
        let impactNeeded = max(0, targetTotalImpact - effectiveTotalImpact)
        let impactTargetMet = completed > 0 && impactNeeded == 0
        let costlyTargetMet = maxCostlyDecisions.map { costlyDecisions <= $0 } ?? true
        let impactNeededPerRemaining = remaining > 0
            ? Int((Double(impactNeeded) / Double(remaining)).rounded(.up))
            : 0
        let highPressureThreshold = max(
            targetAverageExpectedImpact * 2,
            targetAverageExpectedImpact + 1
        )
        let highPressure = remaining > 0
            && impactNeeded > 0
            && impactNeededPerRemaining > highPressureThreshold
        let impactGap = max(0, targetAverageExpectedImpact - averageImpact)

        let category: WhatToPlayTrainingSessionProgressCategory
        if completed == 0 {
            category = .notStarted
        } else if completed < target {
            category = .inProgress
        } else if accuracyTargetMet && impactTargetMet && costlyTargetMet {
            category = .achieved
        } else {
            category = .needsRepeat
        }

        return WhatToPlayTrainingSessionProgressMetrics(
            category: category,
            completedAttempts: completed,
            targetAttempts: target,
            correctAttempts: correct,
            accuracyPercent: accuracy,
            accuracyTargetMet: accuracyTargetMet,
            requiredCorrectAttempts: requiredCorrect,
            correctAttemptsNeededForTarget: category == .achieved ? 0 : correctNeeded,
            bestPossibleAccuracyPercent: category == .achieved || category == .needsRepeat
                ? accuracy
                : bestPossibleAccuracy,
            accuracyTargetReachable: category == .notStarted ? true : accuracyTargetReachable,
            totalExpectedImpact: effectiveTotalImpact,
            averageExpectedImpact: averageImpact,
            impactTargetMet: impactTargetMet,
            averageExpectedImpactGap: category == .achieved ? 0 : impactGap,
            expectedImpactNeededForTarget: category == .achieved ? 0 : impactNeeded,
            expectedImpactNeededPerRemainingAttempt: category == .needsRepeat ? 0 : impactNeededPerRemaining,
            impactRecoveryHighPressure: category == .inProgress ? highPressure : false,
            remainingAttempts: remaining,
            maxCostlyDecisions: maxCostlyDecisions,
            costlyDecisions: max(0, costlyDecisions),
            costlyDecisionTargetMet: category == .notStarted
                ? maxCostlyDecisions == nil
                : (category == .achieved ? true : costlyTargetMet)
        )
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
}

/// نوع الخطوة التالية داخل جلسة تدريب «وش تلعب؟» دون نصوص واجهة.
public enum WhatToPlayTrainingSessionNextStepCategory: String, Sendable, Codable, Equatable, CaseIterable {
    case start
    case accuracyUnreachable
    case reduceLostValue
    case continueBatch
    case nextChallenge
    case reduceCostlyDecisions
    case reviewLostValue
    case reviewDecisionQuality
    case stabilizeAccuracy
    case repeatPlan
}

/// تصنيف الخطوة التالية من حالة تقدم الجلسة وأهدافها.
public struct WhatToPlayTrainingSessionNextStepMetrics: Sendable, Equatable {
    public let category: WhatToPlayTrainingSessionNextStepCategory
    public let remainingAttempts: Int
    public let correctAttemptsNeededForTarget: Int
    public let averageLostExpectedPoints: Int
    public let averageLossPoints: Int

    public init(
        category: WhatToPlayTrainingSessionNextStepCategory,
        remainingAttempts: Int,
        correctAttemptsNeededForTarget: Int,
        averageLostExpectedPoints: Int,
        averageLossPoints: Int? = nil
    ) {
        self.category = category
        self.remainingAttempts = remainingAttempts
        self.correctAttemptsNeededForTarget = correctAttemptsNeededForTarget
        self.averageLostExpectedPoints = averageLostExpectedPoints
        self.averageLossPoints = averageLossPoints ?? averageLostExpectedPoints
    }

    public static func classify(
        progressCategory: WhatToPlayTrainingSessionProgressCategory,
        remainingAttempts: Int,
        correctAttemptsNeededForTarget: Int,
        accuracyTargetMet: Bool,
        impactTargetMet: Bool,
        costlyDecisionTargetMet: Bool,
        averageLostExpectedPoints: Int,
        averageLostProjectedTeamPoints: Int = 0,
        averageProjectedSecondBestGap: Int = 0,
        lostValueThreshold: Int = 4
    ) -> WhatToPlayTrainingSessionNextStepMetrics {
        let remaining = max(0, remainingAttempts)
        let neededCorrect = max(0, correctAttemptsNeededForTarget)
        let lostValue = max(0, averageLostExpectedPoints)
        let lossValue = max(
            lostValue,
            max(0, averageLostProjectedTeamPoints),
            max(0, averageProjectedSecondBestGap)
        )
        let threshold = max(0, lostValueThreshold)

        let category: WhatToPlayTrainingSessionNextStepCategory
        switch progressCategory {
        case .notStarted:
            category = .start
        case .inProgress:
            if neededCorrect > remaining {
                category = .accuracyUnreachable
            } else if lossValue >= threshold {
                category = .reduceLostValue
            } else {
                category = .continueBatch
            }
        case .achieved:
            category = .nextChallenge
        case .needsRepeat:
            if !costlyDecisionTargetMet {
                category = .reduceCostlyDecisions
            } else if lossValue >= threshold {
                category = .reviewLostValue
            } else if accuracyTargetMet && !impactTargetMet {
                category = .reviewDecisionQuality
            } else if !accuracyTargetMet && impactTargetMet {
                category = .stabilizeAccuracy
            } else {
                category = .repeatPlan
            }
        }

        return WhatToPlayTrainingSessionNextStepMetrics(
            category: category,
            remainingAttempts: remaining,
            correctAttemptsNeededForTarget: neededCorrect,
            averageLostExpectedPoints: lostValue,
            averageLossPoints: lossValue
        )
    }
}

/// إجراء مراجعة جلسة تدريب «وش تلعب؟» دون نصوص واجهة.
public enum WhatToPlayTrainingSessionReviewActionCategory: String, Sendable, Codable, Equatable, CaseIterable {
    case start
    case continueSession
    case replayMistake
    case repeatSession
    case nextChallenge
}

/// قرار خام لإجراء مراجعة جلسة تدريب «وش تلعب؟» من حالة التقدم ووجود خطأ قابل للإعادة.
public struct WhatToPlayTrainingSessionReviewMetrics: Sendable, Equatable {
    public let action: WhatToPlayTrainingSessionReviewActionCategory

    public init(action: WhatToPlayTrainingSessionReviewActionCategory) {
        self.action = action
    }

    public static func classify(
        progressCategory: WhatToPlayTrainingSessionProgressCategory,
        hasReviewItem: Bool,
        accuracyTargetReachable: Bool = true
    ) -> WhatToPlayTrainingSessionReviewMetrics {
        let action: WhatToPlayTrainingSessionReviewActionCategory
        switch progressCategory {
        case .notStarted:
            action = .start
        case .inProgress:
            action = !accuracyTargetReachable && hasReviewItem ? .replayMistake : .continueSession
        case .achieved:
            action = .nextChallenge
        case .needsRepeat:
            action = hasReviewItem ? .replayMistake : .repeatSession
        }

        return WhatToPlayTrainingSessionReviewMetrics(action: action)
    }
}

/// سبب أولوية عنصر مراجعة «وش تلعب؟» دون نصوص واجهة.
public enum WhatToPlayReviewPriorityCategory: String, Sendable, Codable, Equatable, CaseIterable {
    case negativeImpact
    case valueOpportunity
    case simulationLoss
    case closeTacticalGap
}

/// تصنيف خام لأولوية عنصر مراجعة «وش تلعب؟» من أثر القرار وفاقد الخبير والمحاكاة.
public struct WhatToPlayReviewPriorityMetrics: Sendable, Equatable {
    public let category: WhatToPlayReviewPriorityCategory

    public init(category: WhatToPlayReviewPriorityCategory) {
        self.category = category
    }

    public static func classify(
        expectedImpact: Int,
        lostExpectedPoints: Int,
        lostProjectedTeamPoints: Int,
        lostProjectedAgainstSecondBestPoints: Int = 0
    ) -> WhatToPlayReviewPriorityMetrics {
        if expectedImpact < 0 {
            return WhatToPlayReviewPriorityMetrics(category: .negativeImpact)
        }

        if lostExpectedPoints >= 6 {
            return WhatToPlayReviewPriorityMetrics(category: .valueOpportunity)
        }

        if max(lostProjectedTeamPoints, lostProjectedAgainstSecondBestPoints) >= 6 {
            return WhatToPlayReviewPriorityMetrics(category: .simulationLoss)
        }

        return WhatToPlayReviewPriorityMetrics(category: .closeTacticalGap)
    }
}

/// مفاتيح ترتيب قائمة مراجعة «وش تلعب؟» دون نصوص واجهة.
public struct WhatToPlayReviewQueueRankMetrics: Sendable, Equatable {
    public let lostExpectedPoints: Int
    public let lostProjectedTeamPoints: Int
    public let lostProjectedAgainstSecondBestPoints: Int
    public let expectedImpact: Int
    public let createdAt: Date

    public init(
        lostExpectedPoints: Int,
        lostProjectedTeamPoints: Int,
        lostProjectedAgainstSecondBestPoints: Int = 0,
        expectedImpact: Int,
        createdAt: Date
    ) {
        self.lostExpectedPoints = lostExpectedPoints
        self.lostProjectedTeamPoints = lostProjectedTeamPoints
        self.lostProjectedAgainstSecondBestPoints = lostProjectedAgainstSecondBestPoints
        self.expectedImpact = expectedImpact
        self.createdAt = createdAt
    }

    public static func ranksBefore(
        _ lhs: WhatToPlayReviewQueueRankMetrics,
        _ rhs: WhatToPlayReviewQueueRankMetrics
    ) -> Bool {
        if lhs.lostProjectedTeamPoints >= 6 || rhs.lostProjectedTeamPoints >= 6 {
            if lhs.lostProjectedTeamPoints != rhs.lostProjectedTeamPoints {
                return lhs.lostProjectedTeamPoints > rhs.lostProjectedTeamPoints
            }
        }

        if lhs.lostProjectedAgainstSecondBestPoints >= 6 || rhs.lostProjectedAgainstSecondBestPoints >= 6 {
            if lhs.lostProjectedAgainstSecondBestPoints != rhs.lostProjectedAgainstSecondBestPoints {
                return lhs.lostProjectedAgainstSecondBestPoints > rhs.lostProjectedAgainstSecondBestPoints
            }
        }

        if lhs.lostExpectedPoints != rhs.lostExpectedPoints {
            return lhs.lostExpectedPoints > rhs.lostExpectedPoints
        }

        if lhs.lostProjectedTeamPoints != rhs.lostProjectedTeamPoints {
            return lhs.lostProjectedTeamPoints > rhs.lostProjectedTeamPoints
        }

        if lhs.lostProjectedAgainstSecondBestPoints != rhs.lostProjectedAgainstSecondBestPoints {
            return lhs.lostProjectedAgainstSecondBestPoints > rhs.lostProjectedAgainstSecondBestPoints
        }

        if lhs.expectedImpact != rhs.expectedImpact {
            return lhs.expectedImpact < rhs.expectedImpact
        }

        return lhs.createdAt > rhs.createdAt
    }
}

/// نوع بطاقة مراجعة «وش تلعب؟» دون نصوص واجهة.
public enum WhatToPlayReviewCardCategory: String, Sendable, Codable, Equatable, CaseIterable {
    case costlyChoice
    case missedOpportunity
    case closeComparison
}

/// تصنيف خام لبطاقة مراجعة «وش تلعب؟» من أثر الاختيار وفاقد القيمة.
public struct WhatToPlayReviewCardMetrics: Sendable, Equatable {
    public let category: WhatToPlayReviewCardCategory

    public init(category: WhatToPlayReviewCardCategory) {
        self.category = category
    }

    public static func classify(
        expectedImpact: Int,
        lostExpectedPoints: Int,
        missedOpportunityThreshold: Int = 6
    ) -> WhatToPlayReviewCardMetrics {
        if expectedImpact < 0 {
            return WhatToPlayReviewCardMetrics(category: .costlyChoice)
        }

        if lostExpectedPoints >= missedOpportunityThreshold {
            return WhatToPlayReviewCardMetrics(category: .missedOpportunity)
        }

        return WhatToPlayReviewCardMetrics(category: .closeComparison)
    }
}

/// السبب التكتيكي الخام لمراجعة اختيار «وش تلعب؟» دون نصوص واجهة.
public enum WhatToPlayTacticalReviewReasonCategory: String, Sendable, Codable, Equatable, CaseIterable {
    case opponentTrickClosure
    case unprotectedPointDump
    case costlyOpeningLead
}

/// تصنيف السبب التكتيكي لمراجعة اختيار «وش تلعب؟» من تفكيك أثر الخيار.
public struct WhatToPlayTacticalReviewReasonMetrics: Sendable, Equatable {
    public let category: WhatToPlayTacticalReviewReasonCategory?

    public init(category: WhatToPlayTacticalReviewReasonCategory?) {
        self.category = category
    }

    public static func classify(
        expectedImpact: Int,
        impactBreakdown: WhatToPlayOptionImpactBreakdown?
    ) -> WhatToPlayTacticalReviewReasonMetrics {
        guard expectedImpact < 0, let impactBreakdown else {
            return WhatToPlayTacticalReviewReasonMetrics(category: nil)
        }

        if impactBreakdown.completesTrick,
           impactBreakdown.winsForPlayerTeam == false,
           impactBreakdown.trickPointsSwing < 0 {
            return WhatToPlayTacticalReviewReasonMetrics(category: .opponentTrickClosure)
        }

        if !impactBreakdown.completesTrick,
           !impactBreakdown.preservesLead,
           impactBreakdown.playedCardPoints > 0,
           impactBreakdown.immediateImpact < 0 {
            return WhatToPlayTacticalReviewReasonMetrics(category: .unprotectedPointDump)
        }

        if impactBreakdown.preservesLead,
           impactBreakdown.immediateImpact < 0 {
            return WhatToPlayTacticalReviewReasonMetrics(category: .costlyOpeningLead)
        }

        return WhatToPlayTacticalReviewReasonMetrics(category: nil)
    }
}

/// عينة أداء مختصرة من محاولة «وش تلعب؟» تكفي لحساب ملخص التدريب.
public struct WhatToPlayStatsSample: Sendable, Equatable {
    public let isCorrect: Bool
    public let expectedImpact: Int
    public let bestExpectedImpact: Int?
    public let secondBestExpectedImpact: Int?
    public let projectedTeamPoints: Int?
    public let bestProjectedTeamPoints: Int?
    public let secondBestProjectedTeamPoints: Int?

    public init(
        isCorrect: Bool,
        expectedImpact: Int,
        bestExpectedImpact: Int? = nil,
        secondBestExpectedImpact: Int? = nil,
        projectedTeamPoints: Int? = nil,
        bestProjectedTeamPoints: Int? = nil,
        secondBestProjectedTeamPoints: Int? = nil
    ) {
        self.isCorrect = isCorrect
        self.expectedImpact = expectedImpact
        self.bestExpectedImpact = bestExpectedImpact
        self.secondBestExpectedImpact = secondBestExpectedImpact
        self.projectedTeamPoints = projectedTeamPoints
        self.bestProjectedTeamPoints = bestProjectedTeamPoints
        self.secondBestProjectedTeamPoints = secondBestProjectedTeamPoints
    }

    public var lostExpectedPoints: Int {
        guard let bestExpectedImpact else { return 0 }
        return max(0, bestExpectedImpact - expectedImpact)
    }

    public var lostAgainstSecondBestPoints: Int {
        guard let secondBestExpectedImpact else { return 0 }
        return max(0, secondBestExpectedImpact - expectedImpact)
    }

    public var lostProjectedTeamPoints: Int {
        guard let bestProjectedTeamPoints, let projectedTeamPoints else { return 0 }
        return max(0, bestProjectedTeamPoints - projectedTeamPoints)
    }

    public var lostProjectedAgainstSecondBestPoints: Int {
        guard let secondBestProjectedTeamPoints, let projectedTeamPoints else { return 0 }
        return max(0, secondBestProjectedTeamPoints - projectedTeamPoints)
    }
}

/// ملخص أداء «وش تلعب؟» الرقمي دون اعتماد على SwiftData أو نصوص الواجهة.
public struct WhatToPlayStatsSummaryMetrics: Sendable, Equatable {
    public let attempts: Int
    public let correct: Int
    public let accuracyPercent: Int
    public let currentStreak: Int
    public let bestStreak: Int
    public let averageExpectedImpact: Int
    public let lostExpectedPoints: Int
    public let averageLostExpectedPoints: Int
    public let lostAgainstSecondBestPoints: Int
    public let secondBestComparisonAttempts: Int
    public let averageSecondBestGap: Int
    public let valueCapturePercent: Int
    public let valueCaptureAttempts: Int
    public let projectedTeamPointAttempts: Int
    public let averageProjectedTeamPoints: Int
    public let lostProjectedTeamPoints: Int
    public let averageLostProjectedTeamPoints: Int
    public let projectedSecondBestComparisonAttempts: Int
    public let lostProjectedAgainstSecondBestPoints: Int
    public let averageProjectedSecondBestGap: Int

    public static let empty = WhatToPlayStatsSummaryMetrics(
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
        valueCaptureAttempts: 0,
        projectedTeamPointAttempts: 0,
        averageProjectedTeamPoints: 0,
        lostProjectedTeamPoints: 0,
        averageLostProjectedTeamPoints: 0,
        projectedSecondBestComparisonAttempts: 0,
        lostProjectedAgainstSecondBestPoints: 0,
        averageProjectedSecondBestGap: 0
    )

    public init(
        attempts: Int,
        correct: Int,
        accuracyPercent: Int,
        currentStreak: Int,
        bestStreak: Int,
        averageExpectedImpact: Int,
        lostExpectedPoints: Int,
        averageLostExpectedPoints: Int,
        lostAgainstSecondBestPoints: Int,
        secondBestComparisonAttempts: Int,
        averageSecondBestGap: Int,
        valueCapturePercent: Int,
        valueCaptureAttempts: Int,
        projectedTeamPointAttempts: Int,
        averageProjectedTeamPoints: Int,
        lostProjectedTeamPoints: Int,
        averageLostProjectedTeamPoints: Int,
        projectedSecondBestComparisonAttempts: Int,
        lostProjectedAgainstSecondBestPoints: Int,
        averageProjectedSecondBestGap: Int
    ) {
        self.attempts = attempts
        self.correct = correct
        self.accuracyPercent = accuracyPercent
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.averageExpectedImpact = averageExpectedImpact
        self.lostExpectedPoints = lostExpectedPoints
        self.averageLostExpectedPoints = averageLostExpectedPoints
        self.lostAgainstSecondBestPoints = lostAgainstSecondBestPoints
        self.secondBestComparisonAttempts = secondBestComparisonAttempts
        self.averageSecondBestGap = averageSecondBestGap
        self.valueCapturePercent = valueCapturePercent
        self.valueCaptureAttempts = valueCaptureAttempts
        self.projectedTeamPointAttempts = projectedTeamPointAttempts
        self.averageProjectedTeamPoints = averageProjectedTeamPoints
        self.lostProjectedTeamPoints = lostProjectedTeamPoints
        self.averageLostProjectedTeamPoints = averageLostProjectedTeamPoints
        self.projectedSecondBestComparisonAttempts = projectedSecondBestComparisonAttempts
        self.lostProjectedAgainstSecondBestPoints = lostProjectedAgainstSecondBestPoints
        self.averageProjectedSecondBestGap = averageProjectedSecondBestGap
    }

    public static func summarize(chronologicalSamples samples: [WhatToPlayStatsSample]) -> WhatToPlayStatsSummaryMetrics {
        guard !samples.isEmpty else { return .empty }

        let correct = samples.filter(\.isCorrect).count
        let attempts = samples.count
        let accuracy = Int((Double(correct) / Double(attempts) * 100).rounded())
        let totalImpact = samples.reduce(0) { $0 + $1.expectedImpact }
        let averageImpact = Int((Double(totalImpact) / Double(attempts)).rounded())
        let lostExpectedPoints = samples.reduce(0) { $0 + $1.lostExpectedPoints }
        let averageLostExpectedPoints = Int((Double(lostExpectedPoints) / Double(attempts)).rounded())
        let secondBestComparisons = samples.filter { $0.secondBestExpectedImpact != nil }
        let lostAgainstSecondBestPoints = secondBestComparisons.reduce(0) { $0 + $1.lostAgainstSecondBestPoints }
        let averageSecondBestGap = secondBestComparisons.isEmpty
            ? 0
            : Int((Double(lostAgainstSecondBestPoints) / Double(secondBestComparisons.count)).rounded())
        let valueAttempts = samples.compactMap { sample -> (selected: Int, best: Int)? in
            guard let best = sample.bestExpectedImpact, best > 0 else { return nil }
            return (selected: max(0, min(sample.expectedImpact, best)), best: best)
        }
        let totalBestValue = valueAttempts.reduce(0) { $0 + $1.best }
        let capturedValue = valueAttempts.reduce(0) { $0 + $1.selected }
        let valueCapturePercent = totalBestValue > 0
            ? Int((Double(capturedValue) / Double(totalBestValue) * 100).rounded())
            : 0
        let projectedAttempts = samples.compactMap(\.projectedTeamPoints)
        let averageProjectedTeamPoints = projectedAttempts.isEmpty
            ? 0
            : Int((Double(projectedAttempts.reduce(0, +)) / Double(projectedAttempts.count)).rounded())
        let projectedComparisons = samples.filter {
            $0.projectedTeamPoints != nil && $0.bestProjectedTeamPoints != nil
        }
        let lostProjectedTeamPoints = projectedComparisons.reduce(0) { $0 + $1.lostProjectedTeamPoints }
        let averageLostProjectedTeamPoints = projectedComparisons.isEmpty
            ? 0
            : Int((Double(lostProjectedTeamPoints) / Double(projectedComparisons.count)).rounded())
        let projectedSecondBestComparisons = samples.filter {
            $0.projectedTeamPoints != nil && $0.secondBestProjectedTeamPoints != nil
        }
        let lostProjectedAgainstSecondBestPoints = projectedSecondBestComparisons.reduce(0) {
            $0 + $1.lostProjectedAgainstSecondBestPoints
        }
        let averageProjectedSecondBestGap = projectedSecondBestComparisons.isEmpty
            ? 0
            : Int((Double(lostProjectedAgainstSecondBestPoints) / Double(projectedSecondBestComparisons.count)).rounded())

        var bestStreak = 0
        var runningStreak = 0
        for sample in samples {
            if sample.isCorrect {
                runningStreak += 1
                bestStreak = max(bestStreak, runningStreak)
            } else {
                runningStreak = 0
            }
        }

        var currentStreak = 0
        for sample in samples.reversed() {
            guard sample.isCorrect else { break }
            currentStreak += 1
        }

        return WhatToPlayStatsSummaryMetrics(
            attempts: attempts,
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
            valueCaptureAttempts: valueAttempts.count,
            projectedTeamPointAttempts: projectedAttempts.count,
            averageProjectedTeamPoints: averageProjectedTeamPoints,
            lostProjectedTeamPoints: lostProjectedTeamPoints,
            averageLostProjectedTeamPoints: averageLostProjectedTeamPoints,
            projectedSecondBestComparisonAttempts: projectedSecondBestComparisons.count,
            lostProjectedAgainstSecondBestPoints: lostProjectedAgainstSecondBestPoints,
            averageProjectedSecondBestGap: averageProjectedSecondBestGap
        )
    }
}

/// نتيجة تتبع اتجاه أداء «وش تلعب؟» بين نافذة حديثة وسابقة دون نصوص واجهة.
public struct WhatToPlayPerformanceTrendMetrics: Sendable, Equatable {
    public let direction: WhatToPlayTrendDirectionCategory
    public let recentAccuracyPercent: Int
    public let previousAccuracyPercent: Int
    public let accuracyDelta: Int
    public let impactDelta: Int
    public let inspectedRecentAttempts: Int
    public let inspectedPreviousAttempts: Int

    public init(
        direction: WhatToPlayTrendDirectionCategory,
        recentAccuracyPercent: Int,
        previousAccuracyPercent: Int,
        accuracyDelta: Int,
        impactDelta: Int,
        inspectedRecentAttempts: Int,
        inspectedPreviousAttempts: Int
    ) {
        self.direction = direction
        self.recentAccuracyPercent = recentAccuracyPercent
        self.previousAccuracyPercent = previousAccuracyPercent
        self.accuracyDelta = accuracyDelta
        self.impactDelta = impactDelta
        self.inspectedRecentAttempts = inspectedRecentAttempts
        self.inspectedPreviousAttempts = inspectedPreviousAttempts
    }

    public static func classify(
        chronologicalSamples samples: [WhatToPlayStatsSample],
        recentWindow: Int = 5,
        minimumWindow: Int = 3
    ) -> WhatToPlayPerformanceTrendMetrics? {
        guard recentWindow >= minimumWindow, samples.count >= minimumWindow * 2 else { return nil }

        let recent = Array(samples.suffix(recentWindow))
        let previousPool = samples.dropLast(recent.count)
        let previous = Array(previousPool.suffix(recent.count))

        guard recent.count >= minimumWindow, previous.count >= minimumWindow else { return nil }

        let recentSummary = WhatToPlayStatsSummaryMetrics.summarize(chronologicalSamples: recent)
        let previousSummary = WhatToPlayStatsSummaryMetrics.summarize(chronologicalSamples: previous)
        let accuracyDelta = recentSummary.accuracyPercent - previousSummary.accuracyPercent
        let impactDelta = recentSummary.averageExpectedImpact - previousSummary.averageExpectedImpact

        let direction: WhatToPlayTrendDirectionCategory
        if accuracyDelta >= 15 || (accuracyDelta >= 0 && impactDelta >= 5) {
            direction = .improving
        } else if accuracyDelta <= -15 || (accuracyDelta <= 0 && impactDelta <= -5) {
            direction = .declining
        } else {
            direction = .stable
        }

        return WhatToPlayPerformanceTrendMetrics(
            direction: direction,
            recentAccuracyPercent: recentSummary.accuracyPercent,
            previousAccuracyPercent: previousSummary.accuracyPercent,
            accuracyDelta: accuracyDelta,
            impactDelta: impactDelta,
            inspectedRecentAttempts: recent.count,
            inspectedPreviousAttempts: previous.count
        )
    }
}

/// نتيجة تتبع تطور التقاط قيمة قرارات «وش تلعب؟» دون نصوص واجهة.
public struct WhatToPlayValueProgressMetrics: Sendable, Equatable {
    public let direction: WhatToPlayTrendDirectionCategory
    public let earlyCapturePercent: Int
    public let recentCapturePercent: Int
    public let deltaPercent: Int
    public let inspectedAttempts: Int

    public init(
        direction: WhatToPlayTrendDirectionCategory,
        earlyCapturePercent: Int,
        recentCapturePercent: Int,
        deltaPercent: Int,
        inspectedAttempts: Int
    ) {
        self.direction = direction
        self.earlyCapturePercent = earlyCapturePercent
        self.recentCapturePercent = recentCapturePercent
        self.deltaPercent = deltaPercent
        self.inspectedAttempts = inspectedAttempts
    }

    public static func classify(
        chronologicalSamples samples: [WhatToPlayStatsSample],
        window: Int = 4
    ) -> WhatToPlayValueProgressMetrics? {
        guard window > 0 else { return nil }

        let valueAttempts = samples.compactMap { sample -> (selected: Int, best: Int)? in
            guard let best = sample.bestExpectedImpact, best > 0 else { return nil }
            return (selected: max(0, min(sample.expectedImpact, best)), best: best)
        }
        guard valueAttempts.count >= window * 2 else { return nil }

        let early = Array(valueAttempts.prefix(window))
        let recent = Array(valueAttempts.suffix(window))
        let earlyPercent = valueCapturePercent(for: early)
        let recentPercent = valueCapturePercent(for: recent)
        let delta = recentPercent - earlyPercent

        let direction: WhatToPlayTrendDirectionCategory
        if delta >= 10 {
            direction = .improving
        } else if delta <= -10 {
            direction = .declining
        } else {
            direction = .stable
        }

        return WhatToPlayValueProgressMetrics(
            direction: direction,
            earlyCapturePercent: earlyPercent,
            recentCapturePercent: recentPercent,
            deltaPercent: delta,
            inspectedAttempts: valueAttempts.count
        )
    }

    private static func valueCapturePercent(for attempts: [(selected: Int, best: Int)]) -> Int {
        let totalBest = attempts.reduce(0) { $0 + $1.best }
        guard totalBest > 0 else { return 0 }
        let captured = attempts.reduce(0) { $0 + $1.selected }
        return Int((Double(captured) / Double(totalBest) * 100).rounded())
    }
}

/// مدخلات توليد بذرة جلسة تدريب «وش تلعب؟» دون اعتماد على طبقة التطبيق.
public struct WhatToPlayTrainingSessionSeedMetrics: Sendable, Equatable {
    public let seedBase: UInt64?
    public let difficultyOrder: Int
    public let focusOrder: Int?
    public let gameModeOrder: Int?
    public let trumpSuitOrdinal: Int?
    public let scenarioCount: Int
    public let targetAccuracyPercent: Int
    public let targetAverageExpectedImpact: Int
    public let matchingAttemptSeeds: [UInt64]

    public init(
        seedBase: UInt64?,
        difficultyOrder: Int,
        focusOrder: Int?,
        gameModeOrder: Int?,
        trumpSuitOrdinal: Int?,
        scenarioCount: Int,
        targetAccuracyPercent: Int,
        targetAverageExpectedImpact: Int,
        matchingAttemptSeeds: [UInt64]
    ) {
        self.seedBase = seedBase
        self.difficultyOrder = difficultyOrder
        self.focusOrder = focusOrder
        self.gameModeOrder = gameModeOrder
        self.trumpSuitOrdinal = trumpSuitOrdinal
        self.scenarioCount = scenarioCount
        self.targetAccuracyPercent = targetAccuracyPercent
        self.targetAverageExpectedImpact = targetAverageExpectedImpact
        self.matchingAttemptSeeds = matchingAttemptSeeds
    }

    public var nextSeed: UInt64 {
        Self.nextSeed(from: self)
    }

    public static func nextSeed(from metrics: WhatToPlayTrainingSessionSeedMetrics) -> UInt64 {
        let attemptedSeeds = Set(metrics.matchingAttemptSeeds)
        if let seedBase = metrics.seedBase {
            return firstUnattemptedSeed(startingAt: seedBase, attemptedSeeds: attemptedSeeds)
        }

        let difficultyComponent = UInt64(max(0, metrics.difficultyOrder)) * 1_000_000
        let focusComponent = UInt64(max(0, metrics.focusOrder ?? 0)) * 100_000
        let modeComponent = UInt64(max(0, metrics.gameModeOrder ?? 0)) * 10_000
        let trumpSuitComponent = UInt64(max(0, (metrics.trumpSuitOrdinal ?? -1) + 1)) * 100
        let countComponent = UInt64(max(1, metrics.scenarioCount)) * 1_000
        let accuracyComponent = UInt64(max(0, metrics.targetAccuracyPercent)) * 10
        let impactComponent = UInt64(max(0, metrics.targetAverageExpectedImpact))

        let firstCandidate = 9_000_000
            + difficultyComponent
            + focusComponent
            + modeComponent
            + trumpSuitComponent
            + countComponent
            + accuracyComponent
            + impactComponent
            + UInt64(metrics.matchingAttemptSeeds.count)

        return firstUnattemptedSeed(startingAt: firstCandidate, attemptedSeeds: attemptedSeeds)
    }

    private static func firstUnattemptedSeed(startingAt seed: UInt64, attemptedSeeds: Set<UInt64>) -> UInt64 {
        var candidate = seed
        while attemptedSeeds.contains(candidate) {
            candidate &+= 1
        }
        return candidate
    }
}

/// نوع خطة جلسة تدريب «وش تلعب؟» الخام دون نصوص واجهة.
public enum WhatToPlayTrainingSessionPlanCategory: String, Sendable, Codable, Equatable, CaseIterable {
    case foundation
    case focusedReview
    case reduceCostlyDecisions
    case simulationReview
    case valueReview
    case levelUp
    case reducePointLeak
    case stabilizeReading
}

/// مصدر اختيار الموقف القادم في تدريب «وش تلعب؟» دون نصوص واجهة.
public enum WhatToPlayNextScenarioRecommendationSource: String, Sendable, Codable, Equatable, CaseIterable {
    case focusPriority
    case sessionPlan
}

/// قرار خام يحدد هل الموقف القادم يتبع أولوية تدريب محددة أو خطة الجلسة العامة.
public struct WhatToPlayNextScenarioRecommendationMetrics: Sendable, Equatable {
    public let source: WhatToPlayNextScenarioRecommendationSource

    public init(source: WhatToPlayNextScenarioRecommendationSource) {
        self.source = source
    }

    public static func classify(hasFocusPriority: Bool) -> WhatToPlayNextScenarioRecommendationMetrics {
        WhatToPlayNextScenarioRecommendationMetrics(
            source: hasFocusPriority ? .focusPriority : .sessionPlan
        )
    }
}

/// مدخلات اختيار خطة جلسة تدريب «وش تلعب؟» من أرقام وتحليلات خام.
public struct WhatToPlayTrainingSessionPlanMetrics: Sendable, Equatable {
    public let category: WhatToPlayTrainingSessionPlanCategory
    public let scenarioCount: Int
    public let targetAccuracyPercent: Int
    public let targetAverageExpectedImpact: Int
    public let maxCostlyDecisions: Int?

    public init(
        category: WhatToPlayTrainingSessionPlanCategory,
        scenarioCount: Int,
        targetAccuracyPercent: Int,
        targetAverageExpectedImpact: Int,
        maxCostlyDecisions: Int? = nil
    ) {
        self.category = category
        self.scenarioCount = scenarioCount
        self.targetAccuracyPercent = targetAccuracyPercent
        self.targetAverageExpectedImpact = targetAverageExpectedImpact
        self.maxCostlyDecisions = maxCostlyDecisions
    }

    public static func classify(
        styleCategory: WhatToPlayPlayStyleCategory,
        pulseState: WhatToPlaySessionPulseState,
        summary: WhatToPlayStatsSummaryMetrics,
        decisionQualitySummary: WhatToPlayDecisionQualitySummaryMetrics
    ) -> WhatToPlayTrainingSessionPlanMetrics {
        if styleCategory == .measuring {
            return blueprint(for: .foundation)
        }

        if pulseState == .reviewNeeded {
            return blueprint(for: .focusedReview)
        }

        if decisionQualitySummary.trackedAttempts >= 3,
           decisionQualitySummary.costlyPercent >= 30 {
            return blueprint(for: .reduceCostlyDecisions)
        }

        if summary.projectedTeamPointAttempts >= 3,
           summary.averageLostProjectedTeamPoints >= 6 {
            return blueprint(for: .simulationReview)
        }

        if summary.attempts >= 3,
           summary.averageLostExpectedPoints >= 4 {
            return blueprint(for: .valueReview)
        }

        if styleCategory == .expertAligned || summary.currentStreak >= 3 {
            return blueprint(for: .levelUp)
        }

        if styleCategory == .cautious || summary.averageExpectedImpact < 0 {
            return blueprint(for: .reducePointLeak)
        }

        return blueprint(for: .stabilizeReading)
    }

    public static func blueprint(for category: WhatToPlayTrainingSessionPlanCategory) -> WhatToPlayTrainingSessionPlanMetrics {
        switch category {
        case .foundation:
            return WhatToPlayTrainingSessionPlanMetrics(
                category: .foundation,
                scenarioCount: 3,
                targetAccuracyPercent: 60,
                targetAverageExpectedImpact: 0
            )
        case .focusedReview:
            return WhatToPlayTrainingSessionPlanMetrics(
                category: .focusedReview,
                scenarioCount: 3,
                targetAccuracyPercent: 67,
                targetAverageExpectedImpact: 0
            )
        case .reduceCostlyDecisions:
            return WhatToPlayTrainingSessionPlanMetrics(
                category: .reduceCostlyDecisions,
                scenarioCount: 3,
                targetAccuracyPercent: 67,
                targetAverageExpectedImpact: 1,
                maxCostlyDecisions: 1
            )
        case .simulationReview:
            return WhatToPlayTrainingSessionPlanMetrics(
                category: .simulationReview,
                scenarioCount: 4,
                targetAccuracyPercent: 75,
                targetAverageExpectedImpact: 1
            )
        case .valueReview:
            return WhatToPlayTrainingSessionPlanMetrics(
                category: .valueReview,
                scenarioCount: 4,
                targetAccuracyPercent: 75,
                targetAverageExpectedImpact: 1
            )
        case .levelUp:
            return WhatToPlayTrainingSessionPlanMetrics(
                category: .levelUp,
                scenarioCount: 5,
                targetAccuracyPercent: 80,
                targetAverageExpectedImpact: 2
            )
        case .reducePointLeak:
            return WhatToPlayTrainingSessionPlanMetrics(
                category: .reducePointLeak,
                scenarioCount: 5,
                targetAccuracyPercent: 70,
                targetAverageExpectedImpact: 0
            )
        case .stabilizeReading:
            return WhatToPlayTrainingSessionPlanMetrics(
                category: .stabilizeReading,
                scenarioCount: 4,
                targetAccuracyPercent: 70,
                targetAverageExpectedImpact: 1
            )
        }
    }
}

/// السبب الخام لاختيار خطة جلسة تدريب «وش تلعب؟» دون نصوص واجهة.
public enum WhatToPlayTrainingSessionPlanRationaleCategory: String, Sendable, Codable, Equatable, CaseIterable {
    case trumpSuitPriority
    case gameModePriority
    case focusPriority
    case immediateReview
    case baseline
    case gameModeSampling
    case focusSampling
    case stabilizeReading
}

/// تصنيف سبب خطة الجلسة من أولويات التدريب والحالة الحالية.
public struct WhatToPlayTrainingSessionPlanRationaleMetrics: Sendable, Equatable {
    public let category: WhatToPlayTrainingSessionPlanRationaleCategory

    public init(category: WhatToPlayTrainingSessionPlanRationaleCategory) {
        self.category = category
    }

    public static func classify(
        hasTrumpSuitPriority: Bool,
        hasGameModePriority: Bool,
        hasFocusPriority: Bool,
        pulseState: WhatToPlaySessionPulseState,
        styleCategory: WhatToPlayPlayStyleCategory,
        attempts: Int,
        hasGameModeTarget: Bool,
        hasFocusTarget: Bool
    ) -> WhatToPlayTrainingSessionPlanRationaleMetrics {
        if hasTrumpSuitPriority {
            return WhatToPlayTrainingSessionPlanRationaleMetrics(category: .trumpSuitPriority)
        }

        if hasGameModePriority {
            return WhatToPlayTrainingSessionPlanRationaleMetrics(category: .gameModePriority)
        }

        if hasFocusPriority {
            return WhatToPlayTrainingSessionPlanRationaleMetrics(category: .focusPriority)
        }

        if pulseState == .reviewNeeded {
            return WhatToPlayTrainingSessionPlanRationaleMetrics(category: .immediateReview)
        }

        if styleCategory == .measuring || attempts <= 0 {
            return WhatToPlayTrainingSessionPlanRationaleMetrics(category: .baseline)
        }

        if hasGameModeTarget {
            return WhatToPlayTrainingSessionPlanRationaleMetrics(category: .gameModeSampling)
        }

        if hasFocusTarget {
            return WhatToPlayTrainingSessionPlanRationaleMetrics(category: .focusSampling)
        }

        return WhatToPlayTrainingSessionPlanRationaleMetrics(category: .stabilizeReading)
    }
}

/// ملخص نتائج قرارات «وش تلعب؟» حسب نتيجة الأكلة دون نصوص واجهة.
public struct WhatToPlayOutcomeSummaryMetrics: Sendable, Equatable {
    public let trackedAttempts: Int
    public let winningTrickAttempts: Int
    public let losingTrickAttempts: Int
    public let openTrickAttempts: Int

    public static let empty = WhatToPlayOutcomeSummaryMetrics(
        trackedAttempts: 0,
        winningTrickAttempts: 0,
        losingTrickAttempts: 0,
        openTrickAttempts: 0
    )

    public init(
        trackedAttempts: Int,
        winningTrickAttempts: Int,
        losingTrickAttempts: Int,
        openTrickAttempts: Int
    ) {
        self.trackedAttempts = trackedAttempts
        self.winningTrickAttempts = winningTrickAttempts
        self.losingTrickAttempts = losingTrickAttempts
        self.openTrickAttempts = openTrickAttempts
    }

    public var winningPercent: Int {
        guard trackedAttempts > 0 else { return 0 }
        return Int((Double(winningTrickAttempts) / Double(trackedAttempts) * 100).rounded())
    }

    public var losingPercent: Int {
        guard trackedAttempts > 0 else { return 0 }
        return Int((Double(losingTrickAttempts) / Double(trackedAttempts) * 100).rounded())
    }

    public static func summarize(outcomes: [WhatToPlayOptionOutcome]) -> WhatToPlayOutcomeSummaryMetrics {
        guard !outcomes.isEmpty else { return .empty }

        let winning = outcomes.filter { $0 == .winsTrick }.count
        let losing = outcomes.filter { $0 == .losesTrick }.count
        return WhatToPlayOutcomeSummaryMetrics(
            trackedAttempts: outcomes.count,
            winningTrickAttempts: winning,
            losingTrickAttempts: losing,
            openTrickAttempts: outcomes.count - winning - losing
        )
    }
}

/// ملخص رتبة اختيارات اللاعب في «وش تلعب؟» مقارنة بترتيب الخبير.
public struct WhatToPlayChoiceRankSummaryMetrics: Sendable, Equatable {
    public let trackedAttempts: Int
    public let expertPicks: Int
    public let secondBestPicks: Int
    public let farPicks: Int

    public static let empty = WhatToPlayChoiceRankSummaryMetrics(
        trackedAttempts: 0,
        expertPicks: 0,
        secondBestPicks: 0,
        farPicks: 0
    )

    public init(
        trackedAttempts: Int,
        expertPicks: Int,
        secondBestPicks: Int,
        farPicks: Int
    ) {
        self.trackedAttempts = trackedAttempts
        self.expertPicks = expertPicks
        self.secondBestPicks = secondBestPicks
        self.farPicks = farPicks
    }

    public var expertPickPercent: Int {
        guard trackedAttempts > 0 else { return 0 }
        return Int((Double(expertPicks) / Double(trackedAttempts) * 100).rounded())
    }

    public var nearMissPercent: Int {
        guard trackedAttempts > 0 else { return 0 }
        return Int((Double(secondBestPicks) / Double(trackedAttempts) * 100).rounded())
    }

    public var farPickPercent: Int {
        guard trackedAttempts > 0 else { return 0 }
        return Int((Double(farPicks) / Double(trackedAttempts) * 100).rounded())
    }

    public static func summarize(selectedRanks ranks: [Int]) -> WhatToPlayChoiceRankSummaryMetrics {
        guard !ranks.isEmpty else { return .empty }

        return WhatToPlayChoiceRankSummaryMetrics(
            trackedAttempts: ranks.count,
            expertPicks: ranks.filter { $0 == 1 }.count,
            secondBestPicks: ranks.filter { $0 == 2 }.count,
            farPicks: ranks.filter { $0 > 2 }.count
        )
    }
}

/// مفاتيح ترتيب أضعف محور تدريب في «وش تلعب؟» دون ربطها بنوع المحور أو نصوص الواجهة.
public struct WhatToPlayWeaknessFocusRankMetrics: Sendable, Equatable {
    public let accuracyPercent: Int
    public let lostExpectedPoints: Int
    public let averageExpectedImpact: Int
    public let stableOrder: Int

    public init(
        accuracyPercent: Int,
        lostExpectedPoints: Int,
        averageExpectedImpact: Int,
        stableOrder: Int
    ) {
        self.accuracyPercent = accuracyPercent
        self.lostExpectedPoints = lostExpectedPoints
        self.averageExpectedImpact = averageExpectedImpact
        self.stableOrder = stableOrder
    }

    public static func ranksBefore(
        _ lhs: WhatToPlayWeaknessFocusRankMetrics,
        _ rhs: WhatToPlayWeaknessFocusRankMetrics
    ) -> Bool {
        if lhs.accuracyPercent != rhs.accuracyPercent {
            return lhs.accuracyPercent < rhs.accuracyPercent
        }

        if lhs.lostExpectedPoints != rhs.lostExpectedPoints {
            return lhs.lostExpectedPoints > rhs.lostExpectedPoints
        }

        if lhs.averageExpectedImpact != rhs.averageExpectedImpact {
            return lhs.averageExpectedImpact < rhs.averageExpectedImpact
        }

        return lhs.stableOrder < rhs.stableOrder
    }
}

/// مفاتيح ترتيب مستوى الصعوبة صاحب أكبر نزيف في متوسط أثر قرارات «وش تلعب؟».
public struct WhatToPlayDifficultyImpactRankMetrics: Sendable, Equatable {
    public let averageExpectedImpact: Int
    public let difficultyOrder: Int

    public init(averageExpectedImpact: Int, difficultyOrder: Int) {
        self.averageExpectedImpact = averageExpectedImpact
        self.difficultyOrder = difficultyOrder
    }

    public static func ranksBefore(
        _ lhs: WhatToPlayDifficultyImpactRankMetrics,
        _ rhs: WhatToPlayDifficultyImpactRankMetrics
    ) -> Bool {
        if lhs.averageExpectedImpact != rhs.averageExpectedImpact {
            return lhs.averageExpectedImpact < rhs.averageExpectedImpact
        }

        return lhs.difficultyOrder > rhs.difficultyOrder
    }
}

/// ملخص جودة قرارات «وش تلعب؟» من تصنيفات المحرك نفسها.
public struct WhatToPlayDecisionQualitySummaryMetrics: Sendable, Equatable {
    public let trackedAttempts: Int
    public let expertMatches: Int
    public let closeDecisions: Int
    public let acceptableDecisions: Int
    public let costlyDecisions: Int

    public static let empty = WhatToPlayDecisionQualitySummaryMetrics(
        trackedAttempts: 0,
        expertMatches: 0,
        closeDecisions: 0,
        acceptableDecisions: 0,
        costlyDecisions: 0
    )

    public init(
        trackedAttempts: Int,
        expertMatches: Int,
        closeDecisions: Int,
        acceptableDecisions: Int,
        costlyDecisions: Int
    ) {
        self.trackedAttempts = trackedAttempts
        self.expertMatches = expertMatches
        self.closeDecisions = closeDecisions
        self.acceptableDecisions = acceptableDecisions
        self.costlyDecisions = costlyDecisions
    }

    public var costlyPercent: Int {
        guard trackedAttempts > 0 else { return 0 }
        return Int((Double(costlyDecisions) / Double(trackedAttempts) * 100).rounded())
    }

    public var strongPercent: Int {
        guard trackedAttempts > 0 else { return 0 }
        return Int((Double(expertMatches + closeDecisions) / Double(trackedAttempts) * 100).rounded())
    }

    public static func summarize(qualities: [WhatToPlayDecisionQuality]) -> WhatToPlayDecisionQualitySummaryMetrics {
        guard !qualities.isEmpty else { return .empty }

        return WhatToPlayDecisionQualitySummaryMetrics(
            trackedAttempts: qualities.count,
            expertMatches: qualities.filter { $0 == .expertMatch }.count,
            closeDecisions: qualities.filter { $0 == .close }.count,
            acceptableDecisions: qualities.filter { $0 == .acceptable }.count,
            costlyDecisions: qualities.filter { $0 == .costly }.count
        )
    }
}

/// التصنيف الخام لرؤية جودة قرارات «وش تلعب؟».
public enum WhatToPlayDecisionQualityInsightCategory: String, Sendable, Codable, Equatable, CaseIterable {
    case strong
    case costly
    case mixed
}

/// رؤية رقمية لجودة قرارات «وش تلعب؟» دون نصوص واجهة.
public struct WhatToPlayDecisionQualityInsightMetrics: Sendable, Equatable {
    public let category: WhatToPlayDecisionQualityInsightCategory
    public let trackedAttempts: Int
    public let strongPercent: Int
    public let costlyPercent: Int

    public init(
        category: WhatToPlayDecisionQualityInsightCategory,
        trackedAttempts: Int,
        strongPercent: Int,
        costlyPercent: Int
    ) {
        self.category = category
        self.trackedAttempts = trackedAttempts
        self.strongPercent = strongPercent
        self.costlyPercent = costlyPercent
    }

    public static func classify(
        summary: WhatToPlayDecisionQualitySummaryMetrics,
        minimumTrackedAttempts: Int = 3
    ) -> WhatToPlayDecisionQualityInsightMetrics? {
        guard summary.trackedAttempts >= minimumTrackedAttempts else { return nil }

        let category: WhatToPlayDecisionQualityInsightCategory
        if summary.costlyPercent >= 30 {
            category = .costly
        } else if summary.strongPercent >= 70 {
            category = .strong
        } else {
            category = .mixed
        }

        return WhatToPlayDecisionQualityInsightMetrics(
            category: category,
            trackedAttempts: summary.trackedAttempts,
            strongPercent: summary.strongPercent,
            costlyPercent: summary.costlyPercent
        )
    }
}

/// التصنيف الخام لرؤية رتبة اختيارات «وش تلعب؟».
public enum WhatToPlayChoiceRankInsightCategory: String, Sendable, Codable, Equatable, CaseIterable {
    case expertAligned
    case nearMisses
    case farChoices
}

/// رؤية رقمية لرتبة اختيارات اللاعب دون نصوص واجهة.
public struct WhatToPlayChoiceRankInsightMetrics: Sendable, Equatable {
    public let category: WhatToPlayChoiceRankInsightCategory
    public let trackedAttempts: Int
    public let expertPickPercent: Int
    public let nearMissPercent: Int
    public let farPickPercent: Int

    public init(
        category: WhatToPlayChoiceRankInsightCategory,
        trackedAttempts: Int,
        expertPickPercent: Int,
        nearMissPercent: Int,
        farPickPercent: Int
    ) {
        self.category = category
        self.trackedAttempts = trackedAttempts
        self.expertPickPercent = expertPickPercent
        self.nearMissPercent = nearMissPercent
        self.farPickPercent = farPickPercent
    }

    public static func classify(
        summary: WhatToPlayChoiceRankSummaryMetrics,
        minimumTrackedAttempts: Int = 3
    ) -> WhatToPlayChoiceRankInsightMetrics? {
        guard summary.trackedAttempts >= minimumTrackedAttempts else { return nil }

        let category: WhatToPlayChoiceRankInsightCategory
        if summary.expertPickPercent >= 70 {
            category = .expertAligned
        } else if summary.farPicks > summary.expertPicks + summary.secondBestPicks {
            category = .farChoices
        } else {
            category = .nearMisses
        }

        return WhatToPlayChoiceRankInsightMetrics(
            category: category,
            trackedAttempts: summary.trackedAttempts,
            expertPickPercent: summary.expertPickPercent,
            nearMissPercent: summary.nearMissPercent,
            farPickPercent: summary.farPickPercent
        )
    }
}

/// التصنيف الخام لنصيحة تدريب «وش تلعب؟» دون نصوص واجهة.
public enum WhatToPlayCoachingTipCategory: String, Sendable, Codable, Equatable, CaseIterable {
    case startMeasuring
    case slowDown
    case reducePointLeak
    case secondSimulationReview
    case narrowChoices
    case strongStreak
    case compareChoices
}

/// نتيجة اختيار نصيحة تدريب «وش تلعب؟» من مقاييس المحرك.
public struct WhatToPlayCoachingTipMetrics: Sendable, Equatable {
    public let category: WhatToPlayCoachingTipCategory
    public let attempts: Int
    public let accuracyPercent: Int
    public let averageExpectedImpact: Int
    public let currentStreak: Int
    public let trackedChoiceRanks: Int
    public let farPickPercent: Int
    public let projectedSecondBestComparisonAttempts: Int
    public let lostProjectedAgainstSecondBestPoints: Int
    public let averageProjectedSecondBestGap: Int

    public init(
        category: WhatToPlayCoachingTipCategory,
        attempts: Int,
        accuracyPercent: Int,
        averageExpectedImpact: Int,
        currentStreak: Int,
        trackedChoiceRanks: Int,
        farPickPercent: Int,
        projectedSecondBestComparisonAttempts: Int,
        lostProjectedAgainstSecondBestPoints: Int,
        averageProjectedSecondBestGap: Int
    ) {
        self.category = category
        self.attempts = attempts
        self.accuracyPercent = accuracyPercent
        self.averageExpectedImpact = averageExpectedImpact
        self.currentStreak = currentStreak
        self.trackedChoiceRanks = trackedChoiceRanks
        self.farPickPercent = farPickPercent
        self.projectedSecondBestComparisonAttempts = projectedSecondBestComparisonAttempts
        self.lostProjectedAgainstSecondBestPoints = lostProjectedAgainstSecondBestPoints
        self.averageProjectedSecondBestGap = averageProjectedSecondBestGap
    }

    public static func classify(
        summary: WhatToPlayStatsSummaryMetrics,
        choiceRankSummary: WhatToPlayChoiceRankSummaryMetrics,
        minimumTrackedChoiceRanks: Int = 3,
        minimumProjectedSecondBestAttempts: Int = 3,
        minimumAverageProjectedSecondBestGap: Int = 6
    ) -> WhatToPlayCoachingTipMetrics {
        let category: WhatToPlayCoachingTipCategory
        if summary.attempts == 0 {
            category = .startMeasuring
        } else if summary.accuracyPercent < 50 {
            category = .slowDown
        } else if summary.averageExpectedImpact < 0 {
            category = .reducePointLeak
        } else if summary.projectedSecondBestComparisonAttempts >= minimumProjectedSecondBestAttempts,
                  summary.averageProjectedSecondBestGap >= minimumAverageProjectedSecondBestGap {
            category = .secondSimulationReview
        } else if choiceRankSummary.trackedAttempts >= minimumTrackedChoiceRanks,
                  choiceRankSummary.farPickPercent >= 40 {
            category = .narrowChoices
        } else if summary.currentStreak >= 3 {
            category = .strongStreak
        } else {
            category = .compareChoices
        }

        return WhatToPlayCoachingTipMetrics(
            category: category,
            attempts: summary.attempts,
            accuracyPercent: summary.accuracyPercent,
            averageExpectedImpact: summary.averageExpectedImpact,
            currentStreak: summary.currentStreak,
            trackedChoiceRanks: choiceRankSummary.trackedAttempts,
            farPickPercent: choiceRankSummary.farPickPercent,
            projectedSecondBestComparisonAttempts: summary.projectedSecondBestComparisonAttempts,
            lostProjectedAgainstSecondBestPoints: summary.lostProjectedAgainstSecondBestPoints,
            averageProjectedSecondBestGap: summary.averageProjectedSecondBestGap
        )
    }
}

/// اتجاه أداء خام يمكن استخدامه بين تحليلات «وش تلعب؟» دون نصوص واجهة.
public enum WhatToPlayTrendDirectionCategory: String, Sendable, Codable, Equatable, CaseIterable {
    case improving
    case stable
    case declining
}

/// التصنيف الخام لتوصية التدريب التالية في «وش تلعب؟» دون نصوص واجهة.
public enum WhatToPlayPracticeRecommendationCategory: String, Sendable, Codable, Equatable, CaseIterable {
    case startEasy
    case tacticalStepBack
    case reduceCostlyDecisions
    case simulationReview
    case weaknessFocus
    case valueReview
    case levelUp
    case steadyMedium
}

/// مدخلات ونتيجة توصية التدريب التالية في «وش تلعب؟».
public struct WhatToPlayPracticeRecommendationMetrics: Sendable, Equatable {
    public let category: WhatToPlayPracticeRecommendationCategory
    public let difficulty: WhatToPlayDifficulty
    public let costlyPercent: Int
    public let averageLostProjectedTeamPoints: Int
    public let averageLostExpectedPoints: Int

    public init(
        category: WhatToPlayPracticeRecommendationCategory,
        difficulty: WhatToPlayDifficulty,
        costlyPercent: Int,
        averageLostProjectedTeamPoints: Int,
        averageLostExpectedPoints: Int
    ) {
        self.category = category
        self.difficulty = difficulty
        self.costlyPercent = costlyPercent
        self.averageLostProjectedTeamPoints = averageLostProjectedTeamPoints
        self.averageLostExpectedPoints = averageLostExpectedPoints
    }

    public static func classify(
        summary: WhatToPlayStatsSummaryMetrics,
        decisionQualitySummary: WhatToPlayDecisionQualitySummaryMetrics,
        trendDirection: WhatToPlayTrendDirectionCategory?,
        focusDifficulty: WhatToPlayDifficulty?,
        focusAccuracyPercent: Int?,
        focusAverageExpectedImpact: Int?,
        highestAttemptedDifficulty: WhatToPlayDifficulty?
    ) -> WhatToPlayPracticeRecommendationMetrics {
        let nearestDifficulty = focusDifficulty ?? highestAttemptedDifficulty ?? .medium
        let category: WhatToPlayPracticeRecommendationCategory
        let difficulty: WhatToPlayDifficulty

        if summary.attempts == 0 {
            category = .startEasy
            difficulty = .easy
        } else if trendDirection == .declining {
            category = .tacticalStepBack
            difficulty = focusDifficulty ?? .easy
        } else if decisionQualitySummary.trackedAttempts >= 3,
                  decisionQualitySummary.costlyPercent >= 30 {
            category = .reduceCostlyDecisions
            difficulty = nearestDifficulty
        } else if summary.projectedTeamPointAttempts >= 3,
                  summary.averageLostProjectedTeamPoints >= 6 {
            category = .simulationReview
            difficulty = nearestDifficulty
        } else if let focusDifficulty,
                  ((focusAccuracyPercent ?? 100) < 70 || (focusAverageExpectedImpact ?? 0) < 0) {
            category = .weaknessFocus
            difficulty = focusDifficulty
        } else if summary.attempts >= 3,
                  summary.averageLostExpectedPoints >= 4 {
            category = .valueReview
            difficulty = nearestDifficulty
        } else if summary.currentStreak >= 3,
                  summary.accuracyPercent >= 75 {
            category = .levelUp
            difficulty = WhatToPlayDifficulty.next(after: highestAttemptedDifficulty ?? .medium)
        } else {
            category = .steadyMedium
            difficulty = .medium
        }

        return WhatToPlayPracticeRecommendationMetrics(
            category: category,
            difficulty: difficulty,
            costlyPercent: decisionQualitySummary.costlyPercent,
            averageLostProjectedTeamPoints: summary.averageLostProjectedTeamPoints,
            averageLostExpectedPoints: summary.averageLostExpectedPoints
        )
    }
}

/// التصنيف الخام لرؤية نتيجة قرارات «وش تلعب؟».
public enum WhatToPlayOutcomeInsightCategory: String, Sendable, Codable, Equatable, CaseIterable {
    case losingOften
    case winningOften
    case openTrickPattern
    case balanced
}

/// رؤية رقمية لنتيجة القرار دون نصوص واجهة.
public struct WhatToPlayOutcomeInsightMetrics: Sendable, Equatable {
    public let category: WhatToPlayOutcomeInsightCategory
    public let trackedAttempts: Int
    public let winningPercent: Int
    public let losingPercent: Int

    public init(
        category: WhatToPlayOutcomeInsightCategory,
        trackedAttempts: Int,
        winningPercent: Int,
        losingPercent: Int
    ) {
        self.category = category
        self.trackedAttempts = trackedAttempts
        self.winningPercent = winningPercent
        self.losingPercent = losingPercent
    }

    public static func classify(
        summary: WhatToPlayOutcomeSummaryMetrics,
        minimumTrackedAttempts: Int = 3
    ) -> WhatToPlayOutcomeInsightMetrics? {
        guard summary.trackedAttempts >= minimumTrackedAttempts else { return nil }

        let category: WhatToPlayOutcomeInsightCategory
        if summary.losingPercent >= 50 {
            category = .losingOften
        } else if summary.winningPercent >= 50 {
            category = .winningOften
        } else if summary.openTrickAttempts > summary.winningTrickAttempts + summary.losingTrickAttempts {
            category = .openTrickPattern
        } else {
            category = .balanced
        }

        return WhatToPlayOutcomeInsightMetrics(
            category: category,
            trackedAttempts: summary.trackedAttempts,
            winningPercent: summary.winningPercent,
            losingPercent: summary.losingPercent
        )
    }
}

/// درجة وضوح أفضل ورقة في موقف «وش تلعب؟» مقارنة بثاني أفضل خيار.
public enum WhatToPlayBestMoveConfidence: String, Sendable, Codable, Equatable, CaseIterable {
    case tied
    case narrow
    case clear
    case decisive

    /// يصنف ثقة أفضل ورقة من فارق الأثر المتوقع بينها وبين ثاني أفضل خيار.
    public static func classify(bestToSecondGap: Int?) -> WhatToPlayBestMoveConfidence? {
        guard let bestToSecondGap else { return nil }
        if bestToSecondGap == 0 { return .tied }
        if bestToSecondGap <= 2 { return .narrow }
        if bestToSecondGap <= 8 { return .clear }
        return .decisive
    }
}

/// وسم تكتيكي مختصر لخيار ورقة في موقف «وش تلعب؟».
public enum WhatToPlayOptionTacticalTag: String, Sendable, Codable, Equatable, CaseIterable {
    case expertPick
    case closeAlternative
    case winsNow
    case holdsPosition
    case opensRisk
    case costly

    /// يصنف الخيار من أثره المباشر ونتيجة استكمال الجولة.
    public static func classify(
        option: WhatToPlayOption,
        bestExpectedImpact: Int,
        bestProjectedTeamPoints: Int,
        secondBestProjectedTeamPoints: Int? = nil
    ) -> WhatToPlayOptionTacticalTag {
        let lostExpectedPoints = max(0, bestExpectedImpact - option.expectedImpact)
        let lostProjectedTeamPoints = max(0, bestProjectedTeamPoints - option.projectedTeamPoints)
        let lostProjectedAgainstSecondBestPoints = secondBestProjectedTeamPoints.map {
            max(0, $0 - option.projectedTeamPoints)
        } ?? 0
        let decisiveLoss = max(lostExpectedPoints, lostProjectedTeamPoints, lostProjectedAgainstSecondBestPoints)

        if option.isExpertChoice { return .expertPick }
        if decisiveLoss <= 2 { return .closeAlternative }
        if decisiveLoss >= 9 || option.expectedImpact < 0 { return .costly }
        if option.outcome == .winsTrick && option.expectedImpact > 0 { return .winsNow }
        if option.outcome == .leadsTrick || option.outcome == .developsTrick { return .opensRisk }
        return .holdsPosition
    }
}

/// خيار ورقة في موقف تدريبي.
public struct WhatToPlayOption: Identifiable, Sendable, Equatable {
    public let card: PlayingCard
    public let rank: Int
    public let score: Int
    public let isExpertChoice: Bool
    public let expectedImpact: Int
    /// نقاط فريق اللاعب المتوقعة بعد فرض هذه الورقة واستكمال الجولة بسياسة ذكية حتمية.
    ///
    /// هذا يختلف عن ``expectedImpact``: الأثر المتوقع يشرح الأكلة الحالية مباشرة،
    /// أما هذه القيمة فتدعم تدريب "ماذا سيحدث لو؟" عبر تشغيل بقية الجولة من المحرك.
    public let projectedTeamPoints: Int
    public let impactBreakdown: WhatToPlayOptionImpactBreakdown
    public let simulation: WhatToPlayOptionSimulation
    public let outcome: WhatToPlayOptionOutcome
    public let outcomeReason: String
    public let explanation: String

    public var id: PlayingCard { card }
}

/// نوع الملخص التكتيكي لخيار ورقة في «وش تلعب؟» دون نصوص واجهة.
public enum WhatToPlayOptionTacticalSummaryCategory: String, Sendable, Codable, Equatable, CaseIterable {
    case expertPick
    case projectedLoss
    case noLossCloseAlternative
    case smallLossAlternative
    case negativeExpectedImpact
    case winsNowWithLowerValue
    case openTrickLoss
}

/// تصنيف الملخص التكتيكي لخيار ورقة من أرقام مراجعة المحرك.
public struct WhatToPlayOptionTacticalSummaryMetrics: Sendable, Equatable {
    public let category: WhatToPlayOptionTacticalSummaryCategory
    public let decisiveLoss: Int

    public init(category: WhatToPlayOptionTacticalSummaryCategory, decisiveLoss: Int) {
        self.category = category
        self.decisiveLoss = decisiveLoss
    }

    public static func classify(
        option: WhatToPlayOption,
        lostExpectedPoints: Int,
        lostProjectedTeamPoints: Int,
        lostProjectedAgainstSecondBestPoints: Int = 0
    ) -> WhatToPlayOptionTacticalSummaryMetrics {
        let decisiveLoss = max(lostExpectedPoints, lostProjectedTeamPoints, lostProjectedAgainstSecondBestPoints)

        if option.isExpertChoice {
            return WhatToPlayOptionTacticalSummaryMetrics(
                category: .expertPick,
                decisiveLoss: decisiveLoss
            )
        }

        if max(lostProjectedTeamPoints, lostProjectedAgainstSecondBestPoints) > lostExpectedPoints {
            return WhatToPlayOptionTacticalSummaryMetrics(
                category: .projectedLoss,
                decisiveLoss: decisiveLoss
            )
        }

        if decisiveLoss == 0 {
            return WhatToPlayOptionTacticalSummaryMetrics(
                category: .noLossCloseAlternative,
                decisiveLoss: decisiveLoss
            )
        }

        if decisiveLoss <= 2 {
            return WhatToPlayOptionTacticalSummaryMetrics(
                category: .smallLossAlternative,
                decisiveLoss: decisiveLoss
            )
        }

        if option.expectedImpact < 0 {
            return WhatToPlayOptionTacticalSummaryMetrics(
                category: .negativeExpectedImpact,
                decisiveLoss: decisiveLoss
            )
        }

        if option.outcome == .winsTrick {
            return WhatToPlayOptionTacticalSummaryMetrics(
                category: .winsNowWithLowerValue,
                decisiveLoss: decisiveLoss
            )
        }

        return WhatToPlayOptionTacticalSummaryMetrics(
            category: .openTrickLoss,
            decisiveLoss: decisiveLoss
        )
    }
}

/// تفكيك أثر لعب ورقة معيّنة في موقف «وش تلعب؟».
///
/// هذا لا يحاول توقّع الجولة كاملة؛ بل يشرح الأثر المباشر القابل للإعادة من حالة
/// المحرك: هل أغلقت الورقة الأكلة، كم نقطة كانت على الطاولة، ولأي فريق ذهبت.
public struct WhatToPlayOptionImpactBreakdown: Sendable, Codable, Equatable {
    public let playedCardPoints: Int
    public let immediateImpact: Int
    public let trickPointsSwing: Int
    public let completesTrick: Bool
    public let winsForPlayerTeam: Bool?
    public let preservesLead: Bool

    public init(
        playedCardPoints: Int,
        immediateImpact: Int,
        trickPointsSwing: Int,
        completesTrick: Bool,
        winsForPlayerTeam: Bool?,
        preservesLead: Bool
    ) {
        self.playedCardPoints = playedCardPoints
        self.immediateImpact = immediateImpact
        self.trickPointsSwing = trickPointsSwing
        self.completesTrick = completesTrick
        self.winsForPlayerTeam = winsForPlayerTeam
        self.preservesLead = preservesLead
    }

    public var signedImpact: Int {
        completesTrick ? trickPointsSwing : immediateImpact
    }
}

/// نوع شرح أثر خيار «وش تلعب؟» دون نصوص واجهة.
public enum WhatToPlayOptionImpactDetailCategory: String, Sendable, Codable, Equatable, CaseIterable {
    case completedTrick
    case preservedLead
    case openTrick
}

/// تصنيف أثر خيار «وش تلعب؟» من تفكيك المحرك.
public struct WhatToPlayOptionImpactDetailMetrics: Sendable, Equatable {
    public let category: WhatToPlayOptionImpactDetailCategory

    public init(category: WhatToPlayOptionImpactDetailCategory) {
        self.category = category
    }

    public static func classify(
        breakdown: WhatToPlayOptionImpactBreakdown
    ) -> WhatToPlayOptionImpactDetailMetrics {
        if breakdown.completesTrick {
            return WhatToPlayOptionImpactDetailMetrics(category: .completedTrick)
        }

        if breakdown.preservesLead {
            return WhatToPlayOptionImpactDetailMetrics(category: .preservedLead)
        }

        return WhatToPlayOptionImpactDetailMetrics(category: .openTrick)
    }
}

/// محاكاة مختصرة لما يحدث مباشرة إذا لعب المستخدم هذه الورقة.
///
/// تحفظ نتيجة تطبيق فعل اللعب على المحرك نفسه، لا على تقدير واجهة المستخدم. هذا يجعل
/// مدرب «وش تلعب؟» وReplay وSandbox يشتركون في مصدر حقيقة واحد عند شرح القرار.
public struct WhatToPlayOptionSimulation: Sendable, Codable, Equatable {
    public let phaseAfterPlay: GamePhase
    public let currentTrickCardCount: Int
    public let completedTrickWinnerID: Player.ID?
    public let completedTrickWinnerTeamID: Team.ID?
    public let completedTrickWonByPlayerTeam: Bool?
    public let completedTrickPoints: Int
    public let nextTurnPlayerID: Player.ID?
    public let playerRemainingCards: Int
    public let actionHistoryCount: Int

    public init(
        phaseAfterPlay: GamePhase,
        currentTrickCardCount: Int,
        completedTrickWinnerID: Player.ID?,
        completedTrickWinnerTeamID: Team.ID?,
        completedTrickWonByPlayerTeam: Bool?,
        completedTrickPoints: Int,
        nextTurnPlayerID: Player.ID?,
        playerRemainingCards: Int,
        actionHistoryCount: Int
    ) {
        self.phaseAfterPlay = phaseAfterPlay
        self.currentTrickCardCount = currentTrickCardCount
        self.completedTrickWinnerID = completedTrickWinnerID
        self.completedTrickWinnerTeamID = completedTrickWinnerTeamID
        self.completedTrickWonByPlayerTeam = completedTrickWonByPlayerTeam
        self.completedTrickPoints = completedTrickPoints
        self.nextTurnPlayerID = nextTurnPlayerID
        self.playerRemainingCards = playerRemainingCards
        self.actionHistoryCount = actionHistoryCount
    }
}

/// ورقة موجودة في يد اللاعب لكنها غير قانونية في موقف «وش تلعب؟» الحالي.
public struct WhatToPlayBlockedCard: Identifiable, Sendable, Equatable {
    public let card: PlayingCard
    public let reason: IllegalMoveReason

    public var id: PlayingCard { card }
}

/// نتيجة لعب خيار معيّن على حالة الأكلة الحالية.
public enum WhatToPlayOptionOutcome: String, Sendable, Codable, Equatable {
    case leadsTrick
    case developsTrick
    case winsTrick
    case losesTrick
}

/// محور الانتباه الأهم في موقف «وش تلعب؟».
public enum WhatToPlayScenarioFocusKind: String, Sendable, Codable, CaseIterable {
    case openingLead
    case followSuit
    case trumpPressure
    case narrowChoice
}

/// عامل قرار منظّم يشرح ما يجب الانتباه له قبل اختيار ورقة في موقف «وش تلعب؟».
public struct WhatToPlayDecisionFactor: Sendable, Codable, Equatable {
    public enum Kind: String, Sendable, Codable, Equatable {
        case openingLead
        case requiredSuit
        case noRequiredSuit
        case trumpOnTable
        case trumpAvailable
        case sunMode
        case trickProgress
        case narrowChoice
        case flexibleChoice
    }

    public let kind: Kind
    public let suit: Suit?
    public let count: Int?

    public init(kind: Kind, suit: Suit? = nil, count: Int? = nil) {
        self.kind = kind
        self.suit = suit
        self.count = count
    }
}

/// قراءة موجزة لسياق موقف «وش تلعب؟» من حالة المحرك.
public struct WhatToPlayScenarioContext: Sendable, Equatable {
    public let trickNumber: Int
    public let isLeading: Bool
    public let requiredSuit: Suit?
    public let playedCardCount: Int
    public let legalOptionCount: Int
    public let mode: GameMode?
    public let trumpSuit: Suit?
    public let hasTrumpInCurrentTrick: Bool
    public let playerTeamTrickPoints: Int
    public let opponentTeamTrickPoints: Int
    public let playerTeamPointMargin: Int
    public let focusKind: WhatToPlayScenarioFocusKind

    public init(
        trickNumber: Int,
        isLeading: Bool,
        requiredSuit: Suit?,
        playedCardCount: Int,
        legalOptionCount: Int,
        mode: GameMode?,
        trumpSuit: Suit?,
        hasTrumpInCurrentTrick: Bool,
        playerTeamTrickPoints: Int = 0,
        opponentTeamTrickPoints: Int = 0,
        playerTeamPointMargin: Int = 0,
        focusKind: WhatToPlayScenarioFocusKind
    ) {
        self.trickNumber = trickNumber
        self.isLeading = isLeading
        self.requiredSuit = requiredSuit
        self.playedCardCount = playedCardCount
        self.legalOptionCount = legalOptionCount
        self.mode = mode
        self.trumpSuit = trumpSuit
        self.hasTrumpInCurrentTrick = hasTrumpInCurrentTrick
        self.playerTeamTrickPoints = playerTeamTrickPoints
        self.opponentTeamTrickPoints = opponentTeamTrickPoints
        self.playerTeamPointMargin = playerTeamPointMargin
        self.focusKind = focusKind
    }
}

/// موقف «وش تلعب؟» قابل للإعادة من نفس البذرة.
public struct WhatToPlayScenario: Sendable {
    public let seed: UInt64
    public let difficulty: WhatToPlayDifficulty
    public let playerID: Player.ID
    public let initialState: GameState
    public let state: GameState
    public let context: WhatToPlayScenarioContext
    public let options: [WhatToPlayOption]
    public let blockedCards: [WhatToPlayBlockedCard]

    public var bestOption: WhatToPlayOption? {
        options.first { $0.rank == 1 }
    }

    public var secondBestOption: WhatToPlayOption? {
        options.first { $0.rank == 2 }
    }

    /// أفضل خيار عند استكمال الجولة من نفس حالة المحرك بعد فرض الورقة.
    ///
    /// قد يختلف هذا عن اختيار الخبير اللحظي عندما تكشف المحاكاة أن ورقة أخرى
    /// تحفظ نقاط الفريق في نهاية الجولة بشكل أفضل. يبقى الترتيب حتميًا عند
    /// التعادل حتى تصل نفس البذرة ونفس الحالة إلى نفس بطاقة التدريب دائمًا.
    public var bestProjectedOption: WhatToPlayOption? {
        WhatToPlayTrainer.bestProjectedOption(in: options)
    }

    /// ثاني أفضل خيار حسب نقاط الفريق المتوقعة بعد استكمال الجولة.
    public var secondBestProjectedOption: WhatToPlayOption? {
        WhatToPlayTrainer.secondBestProjectedOption(in: options)
    }
}

/// Replay مرئي لقرار تدريب «وش تلعب؟».
///
/// يعيد الجولة من البداية حتى حالة الموقف، ثم يضيف ورقة المستخدم المختارة كآخر فعل.
/// بهذا يمكن للواجهة فتح نفس عارض Replay المستخدم في اللعبة بدون بناء منطق جانبي.
public struct WhatToPlayDecisionReplay: Sendable {
    public let initialState: GameState
    public let actions: [GameAction]
    public let playerID: Player.ID
    public let selectedCard: PlayingCard

    public init(initialState: GameState, actions: [GameAction], playerID: Player.ID, selectedCard: PlayingCard) {
        self.initialState = initialState
        self.actions = actions
        self.playerID = playerID
        self.selectedCard = selectedCard
    }
}

/// مراجعة رقمية لاختيار اللاعب في موقف «وش تلعب؟».
///
/// لا تحتوي هذه البنية على نصوص واجهة؛ هدفها أن تكون مصدر الحقيقة للفوارق
/// وجودة القرار بين التدريب والReplay وSandbox.
public struct WhatToPlayChoiceReview: Sendable, Equatable {
    public let bestOption: WhatToPlayOption?
    public let secondBestOption: WhatToPlayOption?
    public let bestProjectedOption: WhatToPlayOption?
    public let secondBestProjectedOption: WhatToPlayOption?
    public let selectedOption: WhatToPlayOption?
    public let bestToSecondExpectedImpactGap: Int?
    public let expertToBestProjectedTeamPointsGap: Int?
    public let selectedLostExpectedPoints: Int?
    public let selectedLostProjectedTeamPoints: Int?
    public let selectedLostProjectedAgainstSecondBestPoints: Int?
    public let decisionQuality: WhatToPlayDecisionQuality?
    public let bestMoveConfidence: WhatToPlayBestMoveConfidence?

    public init(
        bestOption: WhatToPlayOption?,
        secondBestOption: WhatToPlayOption?,
        bestProjectedOption: WhatToPlayOption?,
        secondBestProjectedOption: WhatToPlayOption?,
        selectedOption: WhatToPlayOption?,
        bestToSecondExpectedImpactGap: Int?,
        expertToBestProjectedTeamPointsGap: Int?,
        selectedLostExpectedPoints: Int?,
        selectedLostProjectedTeamPoints: Int?,
        selectedLostProjectedAgainstSecondBestPoints: Int? = nil,
        decisionQuality: WhatToPlayDecisionQuality?,
        bestMoveConfidence: WhatToPlayBestMoveConfidence?
    ) {
        self.bestOption = bestOption
        self.secondBestOption = secondBestOption
        self.bestProjectedOption = bestProjectedOption
        self.secondBestProjectedOption = secondBestProjectedOption
        self.selectedOption = selectedOption
        self.bestToSecondExpectedImpactGap = bestToSecondExpectedImpactGap
        self.expertToBestProjectedTeamPointsGap = expertToBestProjectedTeamPointsGap
        self.selectedLostExpectedPoints = selectedLostExpectedPoints
        self.selectedLostProjectedTeamPoints = selectedLostProjectedTeamPoints
        self.selectedLostProjectedAgainstSecondBestPoints = selectedLostProjectedAgainstSecondBestPoints
        self.decisionQuality = decisionQuality
        self.bestMoveConfidence = bestMoveConfidence
    }
}

/// مراجعة رقمية لخيار واحد داخل موقف «وش تلعب؟».
public struct WhatToPlayOptionReview: Identifiable, Sendable, Equatable {
    public let option: WhatToPlayOption
    public let lostExpectedPoints: Int
    public let lostProjectedTeamPoints: Int
    public let lostProjectedAgainstSecondBestPoints: Int
    public let tacticalTag: WhatToPlayOptionTacticalTag
    public let tacticalSummaryMetrics: WhatToPlayOptionTacticalSummaryMetrics
    public let isBestProjectedResult: Bool

    public var id: PlayingCard { option.card }

    public init(
        option: WhatToPlayOption,
        lostExpectedPoints: Int,
        lostProjectedTeamPoints: Int,
        lostProjectedAgainstSecondBestPoints: Int = 0,
        tacticalTag: WhatToPlayOptionTacticalTag,
        tacticalSummaryMetrics: WhatToPlayOptionTacticalSummaryMetrics,
        isBestProjectedResult: Bool
    ) {
        self.option = option
        self.lostExpectedPoints = lostExpectedPoints
        self.lostProjectedTeamPoints = lostProjectedTeamPoints
        self.lostProjectedAgainstSecondBestPoints = lostProjectedAgainstSecondBestPoints
        self.tacticalTag = tacticalTag
        self.tacticalSummaryMetrics = tacticalSummaryMetrics
        self.isBestProjectedResult = isBestProjectedResult
    }
}

/// نوع الإجراء التدريبي التالي بعد اختيار اللاعب في «وش تلعب؟».
public enum WhatToPlayNextActionKind: String, Sendable, Codable, Equatable, CaseIterable {
    case reviewExpertSimulation
    case reinforceRead
    case reviewSimulation
    case reviewSmallGap
    case compareBeforePlay
    case replayScenario
}

/// توصية الإجراء التالي بعد اختيار ورقة في موقف «وش تلعب؟».
public struct WhatToPlayNextActionRecommendation: Sendable, Equatable {
    public let kind: WhatToPlayNextActionKind
    public let selectedOption: WhatToPlayOption
    public let bestOption: WhatToPlayOption
    public let bestProjectedOption: WhatToPlayOption
    public let secondBestOption: WhatToPlayOption?
    public let secondBestProjectedOption: WhatToPlayOption?
    public let lostExpectedPoints: Int
    public let lostProjectedTeamPoints: Int
    public let lostProjectedAgainstSecondBestPoints: Int

    public init(
        kind: WhatToPlayNextActionKind,
        selectedOption: WhatToPlayOption,
        bestOption: WhatToPlayOption,
        bestProjectedOption: WhatToPlayOption,
        secondBestOption: WhatToPlayOption?,
        secondBestProjectedOption: WhatToPlayOption? = nil,
        lostExpectedPoints: Int,
        lostProjectedTeamPoints: Int,
        lostProjectedAgainstSecondBestPoints: Int = 0
    ) {
        self.kind = kind
        self.selectedOption = selectedOption
        self.bestOption = bestOption
        self.bestProjectedOption = bestProjectedOption
        self.secondBestOption = secondBestOption
        self.secondBestProjectedOption = secondBestProjectedOption
        self.lostExpectedPoints = lostExpectedPoints
        self.lostProjectedTeamPoints = lostProjectedTeamPoints
        self.lostProjectedAgainstSecondBestPoints = lostProjectedAgainstSecondBestPoints
    }

    public var recommendedCard: PlayingCard {
        switch WhatToPlayExpectedImprovementMetrics.calculate(
            lostExpectedPoints: lostExpectedPoints,
            lostProjectedTeamPoints: lostProjectedTeamPoints,
            lostProjectedAgainstSecondBestPoints: lostProjectedAgainstSecondBestPoints
        ).source {
        case .projectedTeamPoints:
            return bestProjectedOption.card
        case .projectedSecondBestPoints:
            return secondBestProjectedOption?.card ?? bestProjectedOption.card
        case .expectedPoints:
            return bestOption.card
        }
    }

    public var expectedImprovement: Int {
        max(lostExpectedPoints, lostProjectedTeamPoints, lostProjectedAgainstSecondBestPoints)
    }
}

/// نوع توصية إعادة موقف «وش تلعب؟».
public enum WhatToPlayRetryRecommendationKind: String, Sendable, Codable, Equatable, CaseIterable {
    case smallGapPractice
    case replayUncounted

    public static func classify(expectedImprovement: Int) -> WhatToPlayRetryRecommendationKind? {
        guard expectedImprovement > 0 else { return nil }
        return expectedImprovement <= 2 ? .smallGapPractice : .replayUncounted
    }
}

/// توصية خام لإعادة موقف «وش تلعب؟» دون نصوص واجهة.
public struct WhatToPlayRetryRecommendation: Sendable, Equatable {
    public let kind: WhatToPlayRetryRecommendationKind
    public let selectedOption: WhatToPlayOption
    public let bestOption: WhatToPlayOption
    public let bestProjectedOption: WhatToPlayOption
    public let secondBestProjectedOption: WhatToPlayOption?
    public let recommendedCard: PlayingCard
    public let improvementSource: WhatToPlayExpectedImprovementSource
    public let lostExpectedPoints: Int
    public let lostProjectedTeamPoints: Int
    public let lostProjectedAgainstSecondBestPoints: Int
    public let expectedImprovement: Int

    public init(
        kind: WhatToPlayRetryRecommendationKind,
        selectedOption: WhatToPlayOption,
        bestOption: WhatToPlayOption,
        bestProjectedOption: WhatToPlayOption,
        secondBestProjectedOption: WhatToPlayOption? = nil,
        recommendedCard: PlayingCard,
        improvementSource: WhatToPlayExpectedImprovementSource,
        lostExpectedPoints: Int,
        lostProjectedTeamPoints: Int,
        lostProjectedAgainstSecondBestPoints: Int = 0,
        expectedImprovement: Int
    ) {
        self.kind = kind
        self.selectedOption = selectedOption
        self.bestOption = bestOption
        self.bestProjectedOption = bestProjectedOption
        self.secondBestProjectedOption = secondBestProjectedOption
        self.recommendedCard = recommendedCard
        self.improvementSource = improvementSource
        self.lostExpectedPoints = lostExpectedPoints
        self.lostProjectedTeamPoints = lostProjectedTeamPoints
        self.lostProjectedAgainstSecondBestPoints = lostProjectedAgainstSecondBestPoints
        self.expectedImprovement = expectedImprovement
    }
}

/// مصدر التحسن المتوقع عند إعادة موقف «وش تلعب؟».
public enum WhatToPlayExpectedImprovementSource: String, Sendable, Codable, Equatable, CaseIterable {
    case projectedTeamPoints
    case projectedSecondBestPoints
    case expectedPoints
}

/// قياس التحسن المتوقع من إعادة موقف «وش تلعب؟» دون نصوص واجهة.
public struct WhatToPlayExpectedImprovementMetrics: Sendable, Equatable {
    public let source: WhatToPlayExpectedImprovementSource
    public let points: Int

    public init(source: WhatToPlayExpectedImprovementSource, points: Int) {
        self.source = source
        self.points = points
    }

    public static func calculate(
        lostExpectedPoints: Int,
        lostProjectedTeamPoints: Int,
        lostProjectedAgainstSecondBestPoints: Int = 0
    ) -> WhatToPlayExpectedImprovementMetrics {
        let expectedPoints = max(0, lostExpectedPoints)
        let projectedPoints = max(0, lostProjectedTeamPoints)
        let projectedSecondBestPoints = max(0, lostProjectedAgainstSecondBestPoints)

        if projectedPoints >= expectedPoints
            && projectedPoints >= projectedSecondBestPoints {
            return WhatToPlayExpectedImprovementMetrics(
                source: .projectedTeamPoints,
                points: projectedPoints
            )
        }

        if projectedSecondBestPoints >= expectedPoints {
            return WhatToPlayExpectedImprovementMetrics(
                source: .projectedSecondBestPoints,
                points: projectedSecondBestPoints
            )
        }

        return WhatToPlayExpectedImprovementMetrics(
            source: .expectedPoints,
            points: expectedPoints
        )
    }
}

/// مفاتيح اختيار أفضل قرار في ملخص «وش تلعب؟» دون نصوص واجهة.
public struct WhatToPlayBestDecisionHighlightRankMetrics: Sendable, Equatable {
    public let expectedImpact: Int
    public let isCorrect: Bool
    public let createdAt: Date

    public init(expectedImpact: Int, isCorrect: Bool, createdAt: Date) {
        self.expectedImpact = expectedImpact
        self.isCorrect = isCorrect
        self.createdAt = createdAt
    }

    public static func ranksBefore(
        _ lhs: WhatToPlayBestDecisionHighlightRankMetrics,
        _ rhs: WhatToPlayBestDecisionHighlightRankMetrics
    ) -> Bool {
        if lhs.expectedImpact != rhs.expectedImpact {
            return lhs.expectedImpact > rhs.expectedImpact
        }

        if lhs.isCorrect != rhs.isCorrect {
            return lhs.isCorrect
        }

        return lhs.createdAt > rhs.createdAt
    }
}

/// مفاتيح اختيار أسوأ قرار في ملخص «وش تلعب؟» دون نصوص واجهة.
public struct WhatToPlayWorstDecisionHighlightRankMetrics: Sendable, Equatable {
    public let lostExpectedPoints: Int
    public let lostProjectedTeamPoints: Int
    public let lostProjectedAgainstSecondBestPoints: Int
    public let expectedImpact: Int
    public let createdAt: Date

    public init(
        lostExpectedPoints: Int,
        lostProjectedTeamPoints: Int,
        lostProjectedAgainstSecondBestPoints: Int = 0,
        expectedImpact: Int,
        createdAt: Date
    ) {
        self.lostExpectedPoints = lostExpectedPoints
        self.lostProjectedTeamPoints = lostProjectedTeamPoints
        self.lostProjectedAgainstSecondBestPoints = lostProjectedAgainstSecondBestPoints
        self.expectedImpact = expectedImpact
        self.createdAt = createdAt
    }

    public var decisiveLoss: Int {
        max(lostExpectedPoints, lostProjectedTeamPoints, lostProjectedAgainstSecondBestPoints)
    }

    public static func ranksBefore(
        _ lhs: WhatToPlayWorstDecisionHighlightRankMetrics,
        _ rhs: WhatToPlayWorstDecisionHighlightRankMetrics
    ) -> Bool {
        if lhs.decisiveLoss != rhs.decisiveLoss {
            return lhs.decisiveLoss > rhs.decisiveLoss
        }

        if lhs.expectedImpact != rhs.expectedImpact {
            return lhs.expectedImpact < rhs.expectedImpact
        }

        return lhs.createdAt > rhs.createdAt
    }
}

/// نمط ترتيب أولويات تدريب «وش تلعب؟» دون نصوص واجهة.
public enum WhatToPlayTrainingPriorityRankMode: String, Sendable, Codable, Equatable, CaseIterable {
    case projectedLossFirst
    case expectedLossFirst
}

/// مفاتيح ترتيب أولوية تدريب «وش تلعب؟» بين بعدين تدريبيين مثل النمط أو الحكم أو نوع الموقف.
public struct WhatToPlayTrainingPriorityRankMetrics: Sendable, Equatable {
    public let lostExpectedPoints: Int
    public let lostProjectedTeamPoints: Int
    public let lostProjectedAgainstSecondBestPoints: Int
    public let accuracyPercent: Int
    public let averageExpectedImpact: Int
    public let stableOrder: Int

    public init(
        lostExpectedPoints: Int,
        lostProjectedTeamPoints: Int,
        lostProjectedAgainstSecondBestPoints: Int = 0,
        accuracyPercent: Int,
        averageExpectedImpact: Int,
        stableOrder: Int
    ) {
        self.lostExpectedPoints = lostExpectedPoints
        self.lostProjectedTeamPoints = lostProjectedTeamPoints
        self.lostProjectedAgainstSecondBestPoints = lostProjectedAgainstSecondBestPoints
        self.accuracyPercent = accuracyPercent
        self.averageExpectedImpact = averageExpectedImpact
        self.stableOrder = stableOrder
    }

    public var simulationLoss: Int {
        max(lostProjectedTeamPoints, lostProjectedAgainstSecondBestPoints)
    }

    public var needsTraining: Bool {
        lostExpectedPoints > 0 || simulationLoss > 0 || accuracyPercent < 100
    }

    public static func ranksBefore(
        _ lhs: WhatToPlayTrainingPriorityRankMetrics,
        _ rhs: WhatToPlayTrainingPriorityRankMetrics,
        mode: WhatToPlayTrainingPriorityRankMode
    ) -> Bool {
        switch mode {
        case .projectedLossFirst:
            if lhs.simulationLoss != rhs.simulationLoss {
                return lhs.simulationLoss > rhs.simulationLoss
            }

            if lhs.lostExpectedPoints != rhs.lostExpectedPoints {
                return lhs.lostExpectedPoints > rhs.lostExpectedPoints
            }

        case .expectedLossFirst:
            if lhs.lostExpectedPoints != rhs.lostExpectedPoints {
                return lhs.lostExpectedPoints > rhs.lostExpectedPoints
            }

            if lhs.simulationLoss != rhs.simulationLoss {
                return lhs.simulationLoss > rhs.simulationLoss
            }
        }

        if lhs.accuracyPercent != rhs.accuracyPercent {
            return lhs.accuracyPercent < rhs.accuracyPercent
        }

        if lhs.averageExpectedImpact != rhs.averageExpectedImpact {
            return lhs.averageExpectedImpact < rhs.averageExpectedImpact
        }

        return lhs.stableOrder < rhs.stableOrder
    }
}

/// تصنيف سياق Replay لقرار تدريب «وش تلعب؟» دون نصوص واجهة.
public enum WhatToPlayReplayContextCategory: String, Sendable, Codable, Equatable, CaseIterable {
    case projectedLoss
    case expertChoice
    case selectedChoice
}

/// أرقام موجزة تستخدم عند فتح Replay لقرار تدريب «وش تلعب؟».
public struct WhatToPlayReplayMetrics: Sendable, Equatable {
    public let selectedOption: WhatToPlayOption
    public let lostProjectedTeamPoints: Int
    public let lostProjectedAgainstSecondBestPoints: Int
    public let isExpertChoice: Bool

    public init(
        selectedOption: WhatToPlayOption,
        lostProjectedTeamPoints: Int,
        lostProjectedAgainstSecondBestPoints: Int = 0,
        isExpertChoice: Bool
    ) {
        self.selectedOption = selectedOption
        self.lostProjectedTeamPoints = lostProjectedTeamPoints
        self.lostProjectedAgainstSecondBestPoints = lostProjectedAgainstSecondBestPoints
        self.isExpertChoice = isExpertChoice
    }

    public var contextCategory: WhatToPlayReplayContextCategory {
        if lostProjectedTeamPoints > 0 || lostProjectedAgainstSecondBestPoints > 0 {
            return .projectedLoss
        }

        if isExpertChoice {
            return .expertChoice
        }

        return .selectedChoice
    }
}

/// مولّد ومحلّل مواقف «وش تلعب؟».
public enum WhatToPlayTrainer {
    public enum ScenarioError: Error, Sendable, Equatable {
        case unableToGenerate
        case noLegalCards
        case unknownPlayer
    }

    /// يولّد موقفًا حقيقيًا من محرك اللعبة، ثم يوقفه عند دور اللاعب البشري في مرحلة اللعب.
    public static func generateScenario(
        seed: UInt64,
        difficulty: WhatToPlayDifficulty = .medium,
        preferredFocus: WhatToPlayScenarioFocusKind? = nil,
        preferredMode: GameMode? = nil,
        preferredTrumpSuit: Suit? = nil,
        rules: BalootRulesConfiguration = .standard
    ) throws -> WhatToPlayScenario {
        let agent = ExpertBalootAgent(samples: difficulty.expertSamples)
        let requestedTrumpSuit = preferredMode == .hokum ? preferredTrumpSuit : nil

        let hasPreference = preferredFocus != nil || preferredMode != nil || requestedTrumpSuit != nil
        let searchLimit = hasPreference ? 1_200 : 40
        for offset in 0..<searchLimit {
            let initialState = GameState.newLocalMatch(rules: rules)
            var state = initialState
            state = try GameEngine.apply(.dealCards(seed: seed &+ UInt64(offset)), to: state)

            guard let humanID = state.players.first(where: { $0.kind == .human })?.id else {
                throw ScenarioError.unknownPlayer
            }

            var guardSteps = 0
            while guardSteps < 96 {
                guardSteps += 1

                if state.phase == .playing, state.currentTurnPlayerID == humanID {
                    let options = try analyzeOptions(state: state, playerID: humanID, difficulty: difficulty)
                    guard options.count > 1 else { break }
                    let context = scenarioContext(state: state, options: options, playerID: humanID)
                    let matchesFocus = preferredFocus == nil || context.focusKind == preferredFocus
                    let matchesMode = preferredMode == nil || state.mode == preferredMode
                    let matchesTrumpSuit = requestedTrumpSuit == nil || (state.mode == .hokum && state.trumpSuit == requestedTrumpSuit)
                    if matchesFocus && matchesMode && matchesTrumpSuit {
                        return WhatToPlayScenario(
                            seed: seed &+ UInt64(offset),
                            difficulty: difficulty,
                            playerID: humanID,
                            initialState: initialState,
                            state: state,
                            context: context,
                            options: options,
                            blockedCards: blockedCards(state: state, playerID: humanID, legalOptions: options)
                        )
                    }

                    guard let bestCard = options.first(where: \.isExpertChoice)?.card else { break }
                    state = try GameEngine.apply(.playCard(playerID: humanID, card: bestCard), to: state)
                    continue
                }

                guard let action = nextTrainingAction(state: state, humanID: humanID, agent: agent) else { break }
                state = try GameEngine.apply(action, to: state)
            }
        }

        throw ScenarioError.unableToGenerate
    }

    /// فعل تدريب واحد يتصرف عن كل اللاعبين في المزايدة والإعلان، ويتوقف عند دور
    /// اللاعب البشري في اللعب فقط. بهذه الطريقة تأتي مواقف «وش تلعب؟» من جولة بلوت
    /// كاملة فعلًا، لا من اختيار نمط مبسّط خارج دورة المزايدة.
    private static func nextTrainingAction(state: GameState, humanID: Player.ID, agent: BalootAgent) -> GameAction? {
        guard let playerID = state.currentTurnPlayerID,
              let hand = state.hands[playerID] else {
            return state.phase == .scoring ? .finishRound : nil
        }

        switch state.phase {
        case .bidding:
            switch state.bidding.stage {
            case .firstRound, .secondRound:
                if state.rules.biddingStyle == .simple {
                    let recommendation = HandAnalyzer.analyze(hand: hand, rules: state.rules).recommendedBid
                    let mode = recommendation.mode ?? .sun
                    return .chooseMode(playerID: playerID, mode: mode, trumpSuit: recommendation.trumpSuit)
                }

                let legal = GameEngine.legalBids(for: playerID, state: state)
                guard !legal.isEmpty else { return nil }
                return .placeBid(playerID: playerID, bid: agent.chooseBid(hand: hand, legalBids: legal, state: state))

            case .doubling:
                let legal = GameEngine.legalMultiplierActions(for: playerID, state: state)
                guard !legal.isEmpty else { return nil }
                return GameEngine.legalMultiplierGameAction(
                    playerID: playerID,
                    decision: agent.chooseMultiplierAction(hand: hand, state: state),
                    legal: legal
                )

            case .completed, .voided:
                return nil
            }

        case .declaring:
            let available = GameEngine.declarableProjects(for: playerID, state: state)
            return .declareProjects(playerID: playerID, projects: agent.chooseProjectsToDeclare(available: available, state: state))

        case .playing:
            guard playerID != humanID else { return nil }
            let legal = GameEngine.legalCards(for: playerID, state: state)
            guard !legal.isEmpty else { return nil }
            return .playCard(playerID: playerID, card: agent.chooseCard(hand: hand, legalCards: legal, state: state))

        case .scoring:
            return .finishRound

        case .setup, .dealing, .finished:
            return nil
        }
    }

    /// يحلل كل الأوراق القانونية الحالية ويضع اختيار الخبير أولًا.
    public static func analyzeOptions(
        state: GameState,
        playerID: Player.ID,
        difficulty: WhatToPlayDifficulty = .medium
    ) throws -> [WhatToPlayOption] {
        guard let hand = state.hands[playerID], let player = state.player(id: playerID) else {
            throw ScenarioError.unknownPlayer
        }

        let legal = GameEngine.legalCards(for: playerID, state: state)
        guard !legal.isEmpty else { throw ScenarioError.noLegalCards }

        let expert = ExpertBalootAgent(samples: difficulty.expertSamples)
        let expertChoice = expert.chooseCard(hand: hand, legalCards: legal, state: state)
        let evaluated: [(
            card: PlayingCard,
            score: Int,
            projectedTeamPoints: Int,
            breakdown: WhatToPlayOptionImpactBreakdown,
            outcome: WhatToPlayOptionOutcome
        )] = legal.map { card in
            let breakdown = impactBreakdown(of: card, by: player, in: state)
            let projectedTeamPoints = projectedTeamPoints(afterPlaying: card, by: player, in: state)
            let score = heuristicScore(
                card: card,
                impact: breakdown.signedImpact,
                projectedTeamPoints: projectedTeamPoints,
                expertChoice: expertChoice,
                state: state
            )
            let outcome = optionOutcome(of: card, by: player, in: state)
            return (
                card: card,
                score: score,
                projectedTeamPoints: projectedTeamPoints,
                breakdown: breakdown,
                outcome: outcome
            )
        }
        .sorted { lhs, rhs in
            if lhs.card == expertChoice { return true }
            if rhs.card == expertChoice { return false }
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            if lhs.card.suit.ordinal != rhs.card.suit.ordinal { return lhs.card.suit.ordinal < rhs.card.suit.ordinal }
            return lhs.card.rank.ordinal < rhs.card.rank.ordinal
        }

        let best = evaluated.first

        return evaluated.enumerated().map { index, entry in
            WhatToPlayOption(
                card: entry.card,
                rank: index + 1,
                score: entry.score,
                isExpertChoice: entry.card == expertChoice,
                expectedImpact: entry.breakdown.signedImpact,
                projectedTeamPoints: entry.projectedTeamPoints,
                impactBreakdown: entry.breakdown,
                simulation: simulation(of: entry.card, by: player, in: state),
                outcome: entry.outcome,
                outcomeReason: outcomeReason(for: entry.outcome),
                explanation: explanation(
                    rank: index + 1,
                    impact: entry.breakdown.signedImpact,
                    projectedTeamPoints: entry.projectedTeamPoints,
                    best: best,
                    isExpertChoice: entry.card == expertChoice,
                    state: state
                )
            )
        }
    }

    /// يقيّم اختيار المستخدم مقارنة باختيار الخبير.
    public static func evaluateChoice(card: PlayingCard, in scenario: WhatToPlayScenario) -> WhatToPlayOption? {
        scenario.options.first { $0.card == card }
    }

    /// يراجع اختيار اللاعب رقميًا من المحرك بدل حساب الفوارق في الواجهة.
    public static func choiceReview(
        in scenario: WhatToPlayScenario,
        selectedCard: PlayingCard? = nil
    ) -> WhatToPlayChoiceReview {
        let sorted = rankedOptions(scenario.options)
        let best = sorted.first
        let second = sorted.dropFirst().first
        let bestProjected = bestProjectedOption(in: scenario.options)
        let secondBestProjected = secondBestProjectedOption(in: scenario.options)
        let selected = selectedCard.flatMap { card in
            sorted.first { $0.card == card }
        }
        let bestToSecondGap = best.flatMap { bestOption in
            second.map { max(0, bestOption.expectedImpact - $0.expectedImpact) }
        }
        let expertToBestProjectedGap = best.flatMap { bestOption in
            bestProjected.map { max(0, $0.projectedTeamPoints - bestOption.projectedTeamPoints) }
        }
        let selectedLostExpected = selected.flatMap { selectedOption in
            best.map { max(0, $0.expectedImpact - selectedOption.expectedImpact) }
        }
        let selectedLostProjected = selected.flatMap { selectedOption in
            bestProjected.map { max(0, $0.projectedTeamPoints - selectedOption.projectedTeamPoints) }
        }
        let selectedLostProjectedAgainstSecondBest = selected.flatMap { selectedOption in
            secondBestProjected.map { max(0, $0.projectedTeamPoints - selectedOption.projectedTeamPoints) }
        }
        let decisionQuality = selected.flatMap { selectedOption in
            selectedLostExpected.map {
                WhatToPlayDecisionQuality.classify(
                    isExpertChoice: selectedOption.isExpertChoice,
                    lostExpectedPoints: $0,
                    lostProjectedTeamPoints: selectedLostProjected ?? 0,
                    lostProjectedAgainstSecondBestPoints: selectedLostProjectedAgainstSecondBest ?? 0
                )
            }
        }

        return WhatToPlayChoiceReview(
            bestOption: best,
            secondBestOption: second,
            bestProjectedOption: bestProjected,
            secondBestProjectedOption: secondBestProjected,
            selectedOption: selected,
            bestToSecondExpectedImpactGap: bestToSecondGap,
            expertToBestProjectedTeamPointsGap: expertToBestProjectedGap,
            selectedLostExpectedPoints: selectedLostExpected,
            selectedLostProjectedTeamPoints: selectedLostProjected,
            selectedLostProjectedAgainstSecondBestPoints: selectedLostProjectedAgainstSecondBest,
            decisionQuality: decisionQuality,
            bestMoveConfidence: WhatToPlayBestMoveConfidence.classify(bestToSecondGap: bestToSecondGap)
        )
    }

    /// يراجع كل خيار قانوني في الموقف من المحرك، لا من الواجهة.
    public static func optionReviews(in scenario: WhatToPlayScenario) -> [WhatToPlayOptionReview] {
        let sorted = rankedOptions(scenario.options)
        let bestExpectedImpact = scenario.bestOption?.expectedImpact
            ?? scenario.options.map(\.expectedImpact).max()
            ?? 0
        let bestProjected = bestProjectedOption(in: scenario.options)
        let bestProjectedTeamPoints = bestProjected?.projectedTeamPoints
            ?? scenario.options.map(\.projectedTeamPoints).max()
            ?? 0
        let secondBestProjected = secondBestProjectedOption(in: scenario.options)
        let secondBestProjectedTeamPoints = secondBestProjected?.projectedTeamPoints

        return sorted.map { option in
            let lostExpectedPoints = max(0, bestExpectedImpact - option.expectedImpact)
            let lostProjectedTeamPoints = max(0, bestProjectedTeamPoints - option.projectedTeamPoints)
            let lostProjectedAgainstSecondBestPoints = secondBestProjectedTeamPoints.map {
                max(0, $0 - option.projectedTeamPoints)
            } ?? 0
            return WhatToPlayOptionReview(
                option: option,
                lostExpectedPoints: lostExpectedPoints,
                lostProjectedTeamPoints: lostProjectedTeamPoints,
                lostProjectedAgainstSecondBestPoints: lostProjectedAgainstSecondBestPoints,
                tacticalTag: WhatToPlayOptionTacticalTag.classify(
                    option: option,
                    bestExpectedImpact: bestExpectedImpact,
                    bestProjectedTeamPoints: bestProjectedTeamPoints,
                    secondBestProjectedTeamPoints: secondBestProjectedTeamPoints
                ),
                tacticalSummaryMetrics: WhatToPlayOptionTacticalSummaryMetrics.classify(
                    option: option,
                    lostExpectedPoints: lostExpectedPoints,
                    lostProjectedTeamPoints: lostProjectedTeamPoints,
                    lostProjectedAgainstSecondBestPoints: lostProjectedAgainstSecondBestPoints
                ),
                isBestProjectedResult: option.card == bestProjected?.card
            )
        }
    }

    /// يقرر الإجراء التدريبي التالي بعد اختيار اللاعب، مع ترك النصوص للواجهة.
    public static func nextActionRecommendation(
        in scenario: WhatToPlayScenario,
        selectedCard: PlayingCard?
    ) -> WhatToPlayNextActionRecommendation? {
        nextActionRecommendation(from: choiceReview(in: scenario, selectedCard: selectedCard))
    }

    /// يقرر الإجراء التدريبي التالي من مراجعة اختيار جاهزة.
    public static func nextActionRecommendation(
        from review: WhatToPlayChoiceReview
    ) -> WhatToPlayNextActionRecommendation? {
        guard let selected = review.selectedOption,
              let best = review.bestOption,
              let lostExpectedPoints = review.selectedLostExpectedPoints
        else { return nil }

        let bestProjected = review.bestProjectedOption ?? best
        let lostProjectedTeamPoints = review.selectedLostProjectedTeamPoints ?? 0
        let lostProjectedAgainstSecondBestPoints = review.selectedLostProjectedAgainstSecondBestPoints ?? 0
        let decisiveLoss = max(lostExpectedPoints, lostProjectedTeamPoints, lostProjectedAgainstSecondBestPoints)
        let simulationLoss = max(lostProjectedTeamPoints, lostProjectedAgainstSecondBestPoints)
        let kind: WhatToPlayNextActionKind

        if selected.isExpertChoice && simulationLoss >= 9 {
            kind = .reviewExpertSimulation
        } else if selected.isExpertChoice || decisiveLoss == 0 {
            kind = .reinforceRead
        } else if simulationLoss > lostExpectedPoints {
            kind = .reviewSimulation
        } else if decisiveLoss <= 2 {
            kind = .reviewSmallGap
        } else if decisiveLoss <= 8 {
            kind = .compareBeforePlay
        } else {
            kind = .replayScenario
        }

        return WhatToPlayNextActionRecommendation(
            kind: kind,
            selectedOption: selected,
            bestOption: best,
            bestProjectedOption: bestProjected,
            secondBestOption: review.secondBestOption,
            secondBestProjectedOption: review.secondBestProjectedOption,
            lostExpectedPoints: lostExpectedPoints,
            lostProjectedTeamPoints: lostProjectedTeamPoints,
            lostProjectedAgainstSecondBestPoints: lostProjectedAgainstSecondBestPoints
        )
    }

    /// يقرر هل يستحق موقف «وش تلعب؟» إعادة مباشرة، مع توصية الورقة الأفضل.
    public static func retryRecommendation(
        in scenario: WhatToPlayScenario,
        selectedCard: PlayingCard?
    ) -> WhatToPlayRetryRecommendation? {
        retryRecommendation(from: choiceReview(in: scenario, selectedCard: selectedCard))
    }

    /// يقرر توصية الإعادة من مراجعة اختيار جاهزة.
    public static func retryRecommendation(
        from review: WhatToPlayChoiceReview
    ) -> WhatToPlayRetryRecommendation? {
        guard let selected = review.selectedOption,
              let best = review.bestOption,
              !selected.isExpertChoice,
              let lostExpectedPoints = review.selectedLostExpectedPoints
        else { return nil }

        let bestProjected = review.bestProjectedOption ?? best
        let lostProjectedTeamPoints = review.selectedLostProjectedTeamPoints ?? 0
        let lostProjectedAgainstSecondBestPoints = review.selectedLostProjectedAgainstSecondBestPoints ?? 0
        let metrics = WhatToPlayExpectedImprovementMetrics.calculate(
            lostExpectedPoints: lostExpectedPoints,
            lostProjectedTeamPoints: lostProjectedTeamPoints,
            lostProjectedAgainstSecondBestPoints: lostProjectedAgainstSecondBestPoints
        )
        let expectedImprovement = metrics.points
        guard expectedImprovement > 0 else { return nil }

        let recommendedCard: PlayingCard
        switch metrics.source {
        case .projectedTeamPoints:
            recommendedCard = bestProjected.card
        case .projectedSecondBestPoints:
            recommendedCard = review.secondBestProjectedOption?.card ?? bestProjected.card
        case .expectedPoints:
            recommendedCard = best.card
        }
        guard let kind = WhatToPlayRetryRecommendationKind.classify(
            expectedImprovement: expectedImprovement
        ) else { return nil }

        return WhatToPlayRetryRecommendation(
            kind: kind,
            selectedOption: selected,
            bestOption: best,
            bestProjectedOption: bestProjected,
            secondBestProjectedOption: review.secondBestProjectedOption,
            recommendedCard: recommendedCard,
            improvementSource: metrics.source,
            lostExpectedPoints: lostExpectedPoints,
            lostProjectedTeamPoints: lostProjectedTeamPoints,
            lostProjectedAgainstSecondBestPoints: lostProjectedAgainstSecondBestPoints,
            expectedImprovement: expectedImprovement
        )
    }

    /// يرجع أرقام سياق Replay لورقة مختارة من مصدر المحرك نفسه.
    public static func replayMetrics(
        in scenario: WhatToPlayScenario,
        selectedCard: PlayingCard
    ) -> WhatToPlayReplayMetrics? {
        optionReviews(in: scenario)
            .first { $0.option.card == selectedCard }
            .map {
                WhatToPlayReplayMetrics(
                    selectedOption: $0.option,
                    lostProjectedTeamPoints: $0.lostProjectedTeamPoints,
                    lostProjectedAgainstSecondBestPoints: $0.lostProjectedAgainstSecondBestPoints,
                    isExpertChoice: $0.option.isExpertChoice
                )
            }
    }

    /// يعيد أفضل خيار حسب نقاط فريق اللاعب المتوقعة بعد استكمال الجولة.
    public static func bestProjectedOption(in options: [WhatToPlayOption]) -> WhatToPlayOption? {
        projectedOptions(in: options).first
    }

    /// يعيد ثاني أفضل خيار حسب نقاط فريق اللاعب المتوقعة بعد استكمال الجولة.
    public static func secondBestProjectedOption(in options: [WhatToPlayOption]) -> WhatToPlayOption? {
        projectedOptions(in: options).dropFirst().first
    }

    /// يعيد خيارات «وش تلعب؟» مرتبة حسب نتيجة استكمال الجولة من المحرك.
    ///
    /// يستخدم هذا الترتيب نقاط فريق اللاعب المتوقعة أولًا، ثم الأثر المباشر،
    /// ثم ترتيب الخبير، ثم ترتيبًا ثابتًا للأوراق. الهدف أن تعتمد الواجهة
    /// وReplay وSandbox على نفس مصدر الحقيقة عند عرض أفضل نتائج المحاكاة.
    public static func projectedOptions(in options: [WhatToPlayOption]) -> [WhatToPlayOption] {
        projectedOptionRanking(options)
    }

    /// يبني Replay قابلًا للتشغيل لقرار معيّن في موقف «وش تلعب؟».
    public static func decisionReplay(
        for card: PlayingCard,
        in scenario: WhatToPlayScenario
    ) -> WhatToPlayDecisionReplay? {
        guard evaluateChoice(card: card, in: scenario) != nil else { return nil }

        return WhatToPlayDecisionReplay(
            initialState: scenario.initialState,
            actions: scenario.state.actionHistory + [.playCard(playerID: scenario.playerID, card: card)],
            playerID: scenario.playerID,
            selectedCard: card
        )
    }

    /// كل أوراق يد اللاعب غير القانونية في هذا الموقف، مع سبب الرفض من المحرك.
    public static func blockedCards(
        state: GameState,
        playerID: Player.ID,
        legalOptions: [WhatToPlayOption]
    ) -> [WhatToPlayBlockedCard] {
        let legalCards = Set(legalOptions.map(\.card))
        return GameEngine.moveValidations(for: playerID, state: state)
            .filter { !legalCards.contains($0.card) }
            .compactMap { validation in
                guard let reason = validation.invalidReason else {
                    return nil
                }
                return WhatToPlayBlockedCard(card: validation.card, reason: reason)
            }
            .sorted { lhs, rhs in
                if lhs.card.suit.ordinal != rhs.card.suit.ordinal {
                    return lhs.card.suit.ordinal < rhs.card.suit.ordinal
                }
                return lhs.card.rank.ordinal < rhs.card.rank.ordinal
            }
    }

    public static func scenarioContext(state: GameState, options: [WhatToPlayOption]) -> WhatToPlayScenarioContext {
        scenarioContext(state: state, options: options, playerID: state.currentTurnPlayerID)
    }

    public static func scenarioContext(
        state: GameState,
        options: [WhatToPlayOption],
        playerID: Player.ID?
    ) -> WhatToPlayScenarioContext {
        let trick = state.currentTrick
        let trumpSuit = state.trumpSuit
        let hasTrump = state.mode == .hokum
            && trumpSuit != nil
            && (trick?.playedCards.contains { $0.card.suit == trumpSuit } ?? false)
        let scoreboard = scenarioScoreboard(state: state, playerID: playerID)

        return WhatToPlayScenarioContext(
            trickNumber: state.completedTricks.count + 1,
            isLeading: trick?.playedCards.isEmpty ?? true,
            requiredSuit: trick?.requiredSuit,
            playedCardCount: trick?.playedCards.count ?? 0,
            legalOptionCount: options.count,
            mode: state.mode,
            trumpSuit: trumpSuit,
            hasTrumpInCurrentTrick: hasTrump,
            playerTeamTrickPoints: scoreboard.player,
            opponentTeamTrickPoints: scoreboard.opponent,
            playerTeamPointMargin: scoreboard.player - scoreboard.opponent,
            focusKind: scenarioFocusKind(
                isLeading: trick?.playedCards.isEmpty ?? true,
                requiredSuit: trick?.requiredSuit,
                hasTrumpInCurrentTrick: hasTrump,
                legalOptionCount: options.count
            )
        )
    }

    private static func scenarioScoreboard(state: GameState, playerID: Player.ID?) -> (player: Int, opponent: Int) {
        guard let playerID, let player = state.player(id: playerID) else {
            return (0, 0)
        }

        let playerPoints = state.teamTrickPoints[player.teamID] ?? 0
        let opponentPoints = state.teams
            .filter { $0.id != player.teamID }
            .reduce(0) { $0 + (state.teamTrickPoints[$1.id] ?? 0) }
        return (playerPoints, opponentPoints)
    }

    public static func scenarioFocusKind(
        isLeading: Bool,
        requiredSuit: Suit?,
        hasTrumpInCurrentTrick: Bool,
        legalOptionCount: Int
    ) -> WhatToPlayScenarioFocusKind {
        if hasTrumpInCurrentTrick {
            return .trumpPressure
        }
        if !isLeading, requiredSuit != nil {
            return .followSuit
        }
        if legalOptionCount <= 2 {
            return .narrowChoice
        }
        return .openingLead
    }

    /// عوامل قرار قابلة للتنسيق في الواجهة والتعليم والمشاركة من مصدر حقيقة واحد.
    public static func decisionFactors(context: WhatToPlayScenarioContext) -> [WhatToPlayDecisionFactor] {
        var factors: [WhatToPlayDecisionFactor] = []

        if context.isLeading {
            factors.append(.init(kind: .openingLead))
        } else if let requiredSuit = context.requiredSuit {
            factors.append(.init(kind: .requiredSuit, suit: requiredSuit))
        } else {
            factors.append(.init(kind: .noRequiredSuit))
        }

        if context.mode == .hokum, let trumpSuit = context.trumpSuit {
            factors.append(.init(
                kind: context.hasTrumpInCurrentTrick ? .trumpOnTable : .trumpAvailable,
                suit: trumpSuit
            ))
        } else {
            factors.append(.init(kind: .sunMode))
        }

        factors.append(.init(kind: .trickProgress, count: context.playedCardCount))
        factors.append(.init(kind: context.legalOptionCount <= 2 ? .narrowChoice : .flexibleChoice, count: context.legalOptionCount))
        return factors
    }

    public static func impactBreakdown(
        of card: PlayingCard,
        by playerID: Player.ID,
        in state: GameState
    ) -> WhatToPlayOptionImpactBreakdown? {
        guard let player = state.player(id: playerID),
              GameEngine.legalCards(for: playerID, state: state).contains(card)
        else { return nil }
        return impactBreakdown(of: card, by: player, in: state)
    }

    private static func impactBreakdown(
        of card: PlayingCard,
        by player: Player,
        in state: GameState
    ) -> WhatToPlayOptionImpactBreakdown {
        let mode = state.mode ?? .sun
        let playedCardPoints = card.points(mode: mode, trumpSuit: state.trumpSuit)
        guard let after = try? GameEngine.apply(.playCard(playerID: player.id, card: card), to: state) else {
            return WhatToPlayOptionImpactBreakdown(
                playedCardPoints: playedCardPoints,
                immediateImpact: Int.min,
                trickPointsSwing: Int.min,
                completesTrick: false,
                winsForPlayerTeam: nil,
                preservesLead: false
            )
        }

        if let last = after.completedTricks.last,
           let winnerID = last.winnerPlayerID,
           let winner = after.player(id: winnerID) {
            let trickPoints = last.playedCards.reduce(0) {
                $0 + $1.card.points(mode: mode, trumpSuit: state.trumpSuit)
            }
            let wins = winner.teamID == player.teamID
            return WhatToPlayOptionImpactBreakdown(
                playedCardPoints: playedCardPoints,
                immediateImpact: wins ? trickPoints : -trickPoints,
                trickPointsSwing: wins ? trickPoints : -trickPoints,
                completesTrick: true,
                winsForPlayerTeam: wins,
                preservesLead: wins
            )
        }

        let isLeading = state.currentTrick?.playedCards.isEmpty ?? true
        return WhatToPlayOptionImpactBreakdown(
            playedCardPoints: playedCardPoints,
            immediateImpact: isLeading ? leadValue(card: card, points: playedCardPoints, state: state) : -playedCardPoints,
            trickPointsSwing: 0,
            completesTrick: false,
            winsForPlayerTeam: nil,
            preservesLead: isLeading
        )
    }

    private static func optionOutcome(of card: PlayingCard, by player: Player, in state: GameState) -> WhatToPlayOptionOutcome {
        let wasLeading = state.currentTrick?.playedCards.isEmpty ?? true
        guard let after = try? GameEngine.apply(.playCard(playerID: player.id, card: card), to: state) else {
            return wasLeading ? .leadsTrick : .developsTrick
        }

        if let last = after.completedTricks.last,
           let winnerID = last.winnerPlayerID,
           let winner = after.player(id: winnerID) {
            return winner.teamID == player.teamID ? .winsTrick : .losesTrick
        }

        return wasLeading ? .leadsTrick : .developsTrick
    }

    private static func simulation(of card: PlayingCard, by player: Player, in state: GameState) -> WhatToPlayOptionSimulation {
        let mode = state.mode ?? .sun
        guard let after = try? GameEngine.apply(.playCard(playerID: player.id, card: card), to: state) else {
            return WhatToPlayOptionSimulation(
                phaseAfterPlay: state.phase,
                currentTrickCardCount: state.currentTrick?.playedCards.count ?? 0,
                completedTrickWinnerID: nil,
                completedTrickWinnerTeamID: nil,
                completedTrickWonByPlayerTeam: nil,
                completedTrickPoints: 0,
                nextTurnPlayerID: state.currentTurnPlayerID,
                playerRemainingCards: state.hands[player.id]?.count ?? 0,
                actionHistoryCount: state.actionHistory.count
            )
        }

        let completedTrick = after.completedTricks.last
        let winnerID = completedTrick?.winnerPlayerID
        let winnerTeamID = winnerID.flatMap { after.player(id: $0)?.teamID }
        let wonByPlayerTeam = winnerTeamID.map { $0 == player.teamID }
        let completedTrickPoints = completedTrick?.playedCards.reduce(0) {
            $0 + $1.card.points(mode: mode, trumpSuit: state.trumpSuit)
        } ?? 0

        return WhatToPlayOptionSimulation(
            phaseAfterPlay: after.phase,
            currentTrickCardCount: after.currentTrick?.playedCards.count ?? 0,
            completedTrickWinnerID: winnerID,
            completedTrickWinnerTeamID: winnerTeamID,
            completedTrickWonByPlayerTeam: wonByPlayerTeam,
            completedTrickPoints: completedTrickPoints,
            nextTurnPlayerID: after.currentTurnPlayerID,
            playerRemainingCards: after.hands[player.id]?.count ?? 0,
            actionHistoryCount: after.actionHistory.count
        )
    }

    private static func outcomeReason(for outcome: WhatToPlayOptionOutcome) -> String {
        switch outcome {
        case .leadsTrick:
            return "هذه الورقة تبدأ الأكلة، لذلك يعتمد أثرها النهائي على ردود بقية اللاعبين."
        case .developsTrick:
            return "هذه الورقة لا تحسم الأكلة فورًا؛ ما زالت نتيجة الأكلة معلقة على الأوراق التالية."
        case .winsTrick:
            return "هذه الورقة تحسم الأكلة لفريقك حسب الأوراق المطروحة وقواعد الحكم والصن."
        case .losesTrick:
            return "هذه الورقة تنهي الأكلة لصالح الخصم، لذلك تُحسب نقاطها عليه في هذا الموقف."
        }
    }

    private static func heuristicScore(
        card: PlayingCard,
        impact: Int,
        projectedTeamPoints: Int,
        expertChoice: PlayingCard,
        state: GameState
    ) -> Int {
        var score = projectedTeamPoints == Int.min ? impact : projectedTeamPoints
        if card == expertChoice { score += 10_000 }
        if state.currentTrick?.playedCards.isEmpty == true {
            score += card.points(mode: state.mode ?? .sun, trumpSuit: state.trumpSuit) / 2
        }
        return score
    }

    private static func leadValue(card: PlayingCard, points: Int, state: GameState) -> Int {
        if state.mode == .hokum, card.suit == state.trumpSuit {
            return points - 8
        }
        return points
    }

    private static func projectedTeamPoints(
        afterPlaying card: PlayingCard,
        by player: Player,
        in state: GameState
    ) -> Int {
        guard var current = try? GameEngine.apply(.playCard(playerID: player.id, card: card), to: state) else {
            return Int.min
        }

        let policy = SmartBalootAgent()
        var steps = 0
        while current.phase == .playing, steps < 40 {
            steps += 1
            guard let playerID = current.currentTurnPlayerID,
                  let hand = current.hands[playerID], !hand.isEmpty
            else { break }

            let legal = GameEngine.legalCards(for: playerID, state: current)
            guard !legal.isEmpty else { break }

            let selected = policy.chooseCard(hand: hand, legalCards: legal, state: current)
            guard let next = try? GameEngine.apply(.playCard(playerID: playerID, card: selected), to: current) else {
                break
            }
            current = next
        }

        if current.phase == .scoring, let finished = try? GameEngine.apply(.finishRound, to: current) {
            current = finished
        }

        return current.lastRoundResult?.teamPoints[player.teamID]
            ?? current.teamTrickPoints[player.teamID]
            ?? 0
    }

    private static func explanation(
        rank: Int,
        impact: Int,
        projectedTeamPoints: Int,
        best: (
            card: PlayingCard,
            score: Int,
            projectedTeamPoints: Int,
            breakdown: WhatToPlayOptionImpactBreakdown,
            outcome: WhatToPlayOptionOutcome
        )?,
        isExpertChoice: Bool,
        state: GameState
    ) -> String {
        let selectedComparableScore = heuristicComparableScore(projectedTeamPoints: projectedTeamPoints, impact: impact)
        let bestGap = best.map {
            max(
                0,
                heuristicComparableScore(
                    projectedTeamPoints: $0.projectedTeamPoints,
                    impact: $0.breakdown.signedImpact
                ) - selectedComparableScore
            )
        } ?? 0
        let projectedGap = best.map { max(0, $0.projectedTeamPoints - projectedTeamPoints) } ?? 0

        if isExpertChoice {
            return "اختيار الخبير رقم \(rank) لأنه أعلى تقييم في هذا الموقف ويوازن بين حفظ القوة ونتيجة الجولة المتوقعة."
        }
        if projectedGap > max(2, abs(impact)) {
            return "هذا الخيار يبدو مقبولًا في الأكلة الحالية، لكنه يخسر بعد استكمال الجولة؛ الفارق عن الخبير \(bestGap) في التقييم و\(projectedGap) في نقاط المحاكاة."
        }
        if impact > 0 {
            return "خيار جيد لأنه يتوقع ربح نقاط هذه الأكلة، لكنه أقل من اختيار الخبير بفارق تقييم \(bestGap) وفارق نقاط المحاكاة \(projectedGap)."
        }
        if impact < 0 {
            return "خيار مخاطِر لأنه يتوقع خسارة نقاط في هذه الأكلة أو رمي ورقة ثمينة؛ الفارق عن الخبير \(bestGap) في التقييم و\(projectedGap) في نقاط المحاكاة."
        }
        if state.currentTrick?.playedCards.isEmpty == true {
            return "افتتاح محايد؛ قد يختبر أوراق الخصوم، لكنه أدنى من اختيار الخبير بفارق تقييم \(bestGap) وفارق نقاط المحاكاة \(projectedGap)."
        }
        return "تأثيره محدود في الأكلة الحالية مقارنة بالخيار الأفضل؛ فارق التقييم \(bestGap) وفارق نقاط المحاكاة \(projectedGap)."
    }

    private static func heuristicComparableScore(projectedTeamPoints: Int, impact: Int) -> Int {
        projectedTeamPoints == Int.min ? impact : projectedTeamPoints
    }

    private static func projectedOptionRanking(_ options: [WhatToPlayOption]) -> [WhatToPlayOption] {
        options.sorted { lhs, rhs in
            if lhs.projectedTeamPoints != rhs.projectedTeamPoints {
                return lhs.projectedTeamPoints > rhs.projectedTeamPoints
            }
            if lhs.expectedImpact != rhs.expectedImpact {
                return lhs.expectedImpact > rhs.expectedImpact
            }
            if lhs.rank != rhs.rank {
                return lhs.rank < rhs.rank
            }
            if lhs.card.suit.ordinal != rhs.card.suit.ordinal {
                return lhs.card.suit.ordinal < rhs.card.suit.ordinal
            }
            return lhs.card.rank.ordinal < rhs.card.rank.ordinal
        }
    }

    private static func rankedOptions(_ options: [WhatToPlayOption]) -> [WhatToPlayOption] {
        options.sorted { lhs, rhs in
            if lhs.rank != rhs.rank { return lhs.rank < rhs.rank }
            if lhs.card.suit.ordinal != rhs.card.suit.ordinal {
                return lhs.card.suit.ordinal < rhs.card.suit.ordinal
            }
            return lhs.card.rank.ordinal < rhs.card.rank.ordinal
        }
    }
}
