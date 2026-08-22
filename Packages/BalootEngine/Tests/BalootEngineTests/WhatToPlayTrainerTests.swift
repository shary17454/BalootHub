import Foundation
import Testing
@testable import BalootEngine

@Suite("مدرب وش تلعب")
struct WhatToPlayTrainerTests {
    @Test("مستويات وش تلعب تزيد عمق تحليل الخبير تدريجيًا")
    func difficultySamplesIncreaseWithExpertLevel() {
        #expect(WhatToPlayDifficulty.easy.expertSamples < WhatToPlayDifficulty.medium.expertSamples)
        #expect(WhatToPlayDifficulty.medium.expertSamples < WhatToPlayDifficulty.hard.expertSamples)
        #expect(WhatToPlayDifficulty.hard.expertSamples < WhatToPlayDifficulty.expert.expertSamples)
    }

    @Test("تدرج صعوبة وش تلعب يأتي من المحرك")
    func difficultyProgressionComesFromEngine() {
        #expect(WhatToPlayDifficulty.easy.trainingOrder < WhatToPlayDifficulty.medium.trainingOrder)
        #expect(WhatToPlayDifficulty.medium.trainingOrder < WhatToPlayDifficulty.hard.trainingOrder)
        #expect(WhatToPlayDifficulty.hard.trainingOrder < WhatToPlayDifficulty.expert.trainingOrder)
        #expect(WhatToPlayDifficulty.next(after: .easy) == .medium)
        #expect(WhatToPlayDifficulty.next(after: .medium) == .hard)
        #expect(WhatToPlayDifficulty.next(after: .hard) == .expert)
        #expect(WhatToPlayDifficulty.next(after: .expert) == .expert)
        #expect(WhatToPlayDifficulty.highestAttempted(in: []) == nil)
        #expect(WhatToPlayDifficulty.highestAttempted(in: [.medium, .easy, .hard]) == .hard)
    }

    @Test("تصنيف جودة القرار يأتي من المحرك ويستخدم فاقد المحاكاة الأكبر")
    func decisionQualityClassifiesProjectedLoss() {
        #expect(WhatToPlayDecisionQuality.classify(isExpertChoice: true, lostExpectedPoints: 20) == .expertMatch)
        #expect(WhatToPlayDecisionQuality.classify(isExpertChoice: false, lostExpectedPoints: 0) == .expertMatch)
        #expect(WhatToPlayDecisionQuality.classify(isExpertChoice: false, lostExpectedPoints: 2) == .close)
        #expect(WhatToPlayDecisionQuality.classify(isExpertChoice: false, lostExpectedPoints: 8) == .acceptable)
        #expect(WhatToPlayDecisionQuality.classify(isExpertChoice: false, lostExpectedPoints: 9) == .costly)
        #expect(
            WhatToPlayDecisionQuality.classify(
                isExpertChoice: false,
                lostExpectedPoints: 1,
                lostProjectedTeamPoints: 12
            ) == .costly
        )
    }

    @Test("تصنيف ثقة أفضل ورقة يأتي من المحرك بعتبات ثابتة")
    func bestMoveConfidenceClassifiesGap() {
        #expect(WhatToPlayBestMoveConfidence.classify(bestToSecondGap: nil) == nil)
        #expect(WhatToPlayBestMoveConfidence.classify(bestToSecondGap: 0) == .tied)
        #expect(WhatToPlayBestMoveConfidence.classify(bestToSecondGap: 1) == .narrow)
        #expect(WhatToPlayBestMoveConfidence.classify(bestToSecondGap: 2) == .narrow)
        #expect(WhatToPlayBestMoveConfidence.classify(bestToSecondGap: 3) == .clear)
        #expect(WhatToPlayBestMoveConfidence.classify(bestToSecondGap: 8) == .clear)
        #expect(WhatToPlayBestMoveConfidence.classify(bestToSecondGap: 9) == .decisive)
    }

    @Test("درجة إتقان وش تلعب تأتي من المحرك بعتبات ثابتة")
    func masteryMetricsClassifyPerformance() {
        let empty = WhatToPlayMasteryMetrics.classify(
            attempts: 0,
            accuracyPercent: 100,
            currentStreak: 5,
            averageExpectedImpact: 10
        )
        #expect(empty.category == .starting)
        #expect(empty.score == 0)
        #expect(empty.nextMilestoneScore == 35)

        let building = WhatToPlayMasteryMetrics.classify(
            attempts: 4,
            accuracyPercent: 50,
            currentStreak: 1,
            averageExpectedImpact: 0
        )
        #expect(building.category == .building)
        #expect(building.score == 44)
        #expect(building.nextMilestoneScore == 60)

        let confident = WhatToPlayMasteryMetrics.classify(
            attempts: 4,
            accuracyPercent: 75,
            currentStreak: 2,
            averageExpectedImpact: 0
        )
        #expect(confident.category == .confident)
        #expect(confident.score == 63)
        #expect(confident.nextMilestoneScore == 80)

        let sharp = WhatToPlayMasteryMetrics.classify(
            attempts: 5,
            accuracyPercent: 100,
            currentStreak: 5,
            averageExpectedImpact: 10
        )
        #expect(sharp.category == .sharp)
        #expect(sharp.score == 100)
        #expect(sharp.nextMilestoneScore == nil)
    }

    @Test("تغطية تدريب وش تلعب تأتي من المحرك")
    func coverageMetricsReportMissingTrainingDimensions() {
        let difficulty = WhatToPlayDifficultyCoverageMetrics.classify(counts: [.easy: 2])
        #expect(difficulty.sampledDifficulties == 1)
        #expect(difficulty.totalDifficulties == 4)
        #expect(difficulty.missingDifficulties == [.medium, .hard, .expert])
        #expect(!difficulty.isBalanced)

        let focus = WhatToPlayFocusCoverageMetrics.classify(counts: [
            .openingLead: 2,
            .trumpPressure: 1
        ])
        #expect(focus.sampledFocusKinds == 1)
        #expect(focus.missingFocusKinds == [.followSuit, .trumpPressure, .narrowChoice])

        let mode = WhatToPlayGameModeCoverageMetrics.classify(counts: [.sun: 2, .hokum: 2])
        #expect(mode.isBalanced)
        #expect(mode.sampledModes == 2)
        #expect(mode.missingModes.isEmpty)

        let trump = WhatToPlayTrumpSuitCoverageMetrics.classify(counts: [
            .hearts: 2,
            .clubs: 1
        ])
        #expect(trump.sampledSuits == 1)
        #expect(trump.missingSuits == [.diamonds, .clubs, .spades])
    }

    @Test("نبض جلسة وش تلعب يأتي من المحرك")
    func sessionPulseMetricsClassifyRecentAttempts() {
        let empty = WhatToPlaySessionPulseMetrics.classify(
            totalAttempts: 0,
            recentMistakes: 0,
            recentAverageExpectedImpact: 0,
            window: 3
        )
        #expect(empty.state == .noData)
        #expect(empty.inspectedAttempts == 0)

        let warming = WhatToPlaySessionPulseMetrics.classify(
            totalAttempts: 2,
            recentMistakes: 1,
            recentAverageExpectedImpact: 0,
            window: 3
        )
        #expect(warming.state == .warmingUp)
        #expect(warming.inspectedAttempts == 2)

        let focused = WhatToPlaySessionPulseMetrics.classify(
            totalAttempts: 4,
            recentMistakes: 0,
            recentAverageExpectedImpact: 2,
            window: 3
        )
        #expect(focused.state == .focused)
        #expect(focused.inspectedAttempts == 3)

        let reviewByMistakes = WhatToPlaySessionPulseMetrics.classify(
            totalAttempts: 4,
            recentMistakes: 2,
            recentAverageExpectedImpact: 1,
            window: 3
        )
        #expect(reviewByMistakes.state == .reviewNeeded)

        let reviewByImpact = WhatToPlaySessionPulseMetrics.classify(
            totalAttempts: 4,
            recentMistakes: 1,
            recentAverageExpectedImpact: -4,
            window: 3
        )
        #expect(reviewByImpact.state == .reviewNeeded)
    }

    @Test("خطة الميكرو تدريب في وش تلعب تأتي من المحرك")
    func microDrillMetricsClassifyPriorityOrder() {
        #expect(microDrill(pulse: .noData).category == .start)
        #expect(microDrill(pulse: .reviewNeeded).category == .reviewMistake)
        #expect(microDrill(hasSimulationReview: true).category == .simulationReview)
        #expect(microDrill(hasHighValueReview: true).category == .highValueReview)
        #expect(
            microDrill(
                trackedDecisionQualityAttempts: 3,
                costlyDecisionPercent: 30
            ).category == .costlyDecisionReduction
        )
        #expect(microDrill(isDifficultyCoverageBalanced: false).category == .difficultyCoverage)
        #expect(microDrill(isFocusCoverageBalanced: false).category == .focusCoverage)
        #expect(microDrill(isGameModeCoverageBalanced: false).category == .gameModeCoverage)
        #expect(
            microDrill(
                hasTrumpSuitSamples: true,
                isTrumpSuitCoverageBalanced: false
            ).category == .trumpSuitCoverage
        )
        #expect(microDrill(isMasterySharp: true).category == .challenge)
        #expect(microDrill().category == .continuePractice)

        let reviewBeatsSimulation = microDrill(
            pulse: .reviewNeeded,
            hasSimulationReview: true,
            isDifficultyCoverageBalanced: false
        )
        #expect(reviewBeatsSimulation.category == .reviewMistake)
    }

    @Test("بذرة الميكرو تدريب في وش تلعب حتمية وتتجاوز التصادم")
    func microDrillSeedMetricsGenerateStableSeed() {
        let seed = WhatToPlayMicroDrillSeedMetrics(
            difficultyOrder: 3,
            focusOrder: 2,
            gameModeOrder: 1,
            trumpSuitOrdinal: 0,
            totalAttemptCount: 5,
            matchingAttemptSeeds: []
        )
        #expect(seed.nextSeed == 11_210_105)

        let collided = WhatToPlayMicroDrillSeedMetrics(
            difficultyOrder: 3,
            focusOrder: 2,
            gameModeOrder: 1,
            trumpSuitOrdinal: 0,
            totalAttemptCount: 5,
            matchingAttemptSeeds: [11_210_105, 11_210_106]
        )
        #expect(collided.nextSeed == 11_210_107)

        let clamped = WhatToPlayMicroDrillSeedMetrics(
            seedBase: 10,
            difficultyOrder: -1,
            focusOrder: nil,
            gameModeOrder: nil,
            trumpSuitOrdinal: nil,
            totalAttemptCount: -9,
            matchingAttemptSeeds: []
        )
        #expect(clamped.nextSeed == 10)
    }

    @Test("تصنيف أسلوب لاعب وش تلعب يأتي من المحرك")
    func playStyleMetricsClassifyPerformance() {
        let measuring = WhatToPlayPlayStyleMetrics.classify(
            attempts: 2,
            accuracyPercent: 100,
            averageExpectedImpact: 4
        )
        #expect(measuring.category == .measuring)
        #expect(measuring.inspectedAttempts == 2)

        let expert = WhatToPlayPlayStyleMetrics.classify(
            attempts: 3,
            accuracyPercent: 80,
            averageExpectedImpact: 0
        )
        #expect(expert.category == .expertAligned)

        let foundational = WhatToPlayPlayStyleMetrics.classify(
            attempts: 5,
            accuracyPercent: 49,
            averageExpectedImpact: 8
        )
        #expect(foundational.category == .foundational)

        let cautious = WhatToPlayPlayStyleMetrics.classify(
            attempts: 5,
            accuracyPercent: 65,
            averageExpectedImpact: -1
        )
        #expect(cautious.category == .cautious)

        let inconsistent = WhatToPlayPlayStyleMetrics.classify(
            attempts: 5,
            accuracyPercent: 64,
            averageExpectedImpact: -1
        )
        #expect(inconsistent.category == .inconsistent)
    }

    @Test("تصنيف نمط قرارات وش تلعب يأتي من المحرك")
    func decisionPatternMetricsClassifyRecentSamples() {
        #expect(WhatToPlayDecisionPatternMetrics.classify(samples: []).category == .noData)

        let clean = WhatToPlayDecisionPatternMetrics.classify(samples: [
            decisionPatternSample(correct: true, impact: 3),
            decisionPatternSample(correct: true, impact: 1)
        ])
        #expect(clean.category == .clean)
        #expect(clean.inspectedAttempts == 2)
        #expect(clean.affectedAttempts == 0)

        let usefulAlternatives = WhatToPlayDecisionPatternMetrics.classify(samples: [
            decisionPatternSample(correct: false, impact: 2),
            decisionPatternSample(correct: false, impact: 0),
            decisionPatternSample(correct: false, impact: -1)
        ])
        #expect(usefulAlternatives.category == .usefulAlternatives)
        #expect(usefulAlternatives.affectedAttempts == 2)

        let pointLeaks = WhatToPlayDecisionPatternMetrics.classify(samples: [
            decisionPatternSample(correct: false, impact: -5),
            decisionPatternSample(correct: false, impact: -2),
            decisionPatternSample(correct: false, impact: 1)
        ])
        #expect(pointLeaks.category == .pointLeaks)
        #expect(pointLeaks.affectedAttempts == 2)

        let farRank = WhatToPlayDecisionPatternMetrics.classify(samples: [
            decisionPatternSample(correct: false, impact: 1, rank: 4),
            decisionPatternSample(correct: false, impact: 0, rank: 3),
            decisionPatternSample(correct: false, impact: 2, rank: 2)
        ])
        #expect(farRank.category == .farRankChoices)
        #expect(farRank.affectedAttempts == 2)
    }

    @Test("تصنيف نمط قرارات وش تلعب يلتقط الأخطاء التكتيكية من تفكيك الأثر")
    func decisionPatternMetricsClassifyImpactBreakdowns() {
        let opponentClosure = WhatToPlayDecisionPatternMetrics.classify(samples: [
            decisionPatternSample(correct: false, impact: -8, breakdown: .opponentTrickClosure(points: 18)),
            decisionPatternSample(correct: false, impact: -3, breakdown: .unprotectedPointDump(points: 10)),
            decisionPatternSample(correct: false, impact: -6, breakdown: .opponentTrickClosure(points: 14))
        ])
        #expect(opponentClosure.category == .opponentTrickClosure)
        #expect(opponentClosure.affectedAttempts == 2)

        let unprotectedDump = WhatToPlayDecisionPatternMetrics.classify(samples: [
            decisionPatternSample(correct: false, impact: -4, breakdown: .unprotectedPointDump(points: 10)),
            decisionPatternSample(correct: false, impact: -5, breakdown: .unprotectedPointDump(points: 11)),
            decisionPatternSample(correct: false, impact: -2, breakdown: .costlyOpeningLead(points: 0))
        ])
        #expect(unprotectedDump.category == .unprotectedPointDump)
        #expect(unprotectedDump.affectedAttempts == 2)

        let openingLead = WhatToPlayDecisionPatternMetrics.classify(samples: [
            decisionPatternSample(correct: false, impact: -4, breakdown: .costlyOpeningLead(points: 4)),
            decisionPatternSample(correct: false, impact: -3, breakdown: .costlyOpeningLead(points: 0)),
            decisionPatternSample(correct: false, impact: -2, breakdown: .unprotectedPointDump(points: 10))
        ])
        #expect(openingLead.category == .costlyOpeningLead)
        #expect(openingLead.affectedAttempts == 2)
    }

    @Test("درجة جلسة تدريب وش تلعب تأتي من المحرك")
    func trainingSessionGradeMetricsClassifyPerformance() {
        let empty = WhatToPlayTrainingSessionGradeMetrics.classify(
            completedAttempts: 0,
            accuracyPercent: 100,
            averageExpectedImpact: 10,
            targetAverageExpectedImpact: 0,
            averageLostProjectedTeamPoints: 0
        )
        #expect(empty.category == .repeatNeeded)
        #expect(empty.percent == 0)
        #expect(empty.accuracyComponent == 0)
        #expect(empty.impactComponent == 0)
        #expect(empty.reasonCategory == .balanced)

        let excellent = WhatToPlayTrainingSessionGradeMetrics.classify(
            completedAttempts: 3,
            accuracyPercent: 100,
            averageExpectedImpact: 5,
            targetAverageExpectedImpact: 0,
            averageLostProjectedTeamPoints: 0
        )
        #expect(excellent.category == .excellent)
        #expect(excellent.percent == 100)
        #expect(excellent.accuracyComponent == 100)
        #expect(excellent.impactComponent == 100)

        let good = WhatToPlayTrainingSessionGradeMetrics.classify(
            completedAttempts: 3,
            accuracyPercent: 100,
            averageExpectedImpact: 4,
            targetAverageExpectedImpact: 0,
            averageLostProjectedTeamPoints: 10
        )
        #expect(good.category == .good)
        #expect(good.percent == 75)
        #expect(good.impactComponent == 50)
        #expect(good.reasonCategory == .projectedLossPenalty)

        let stabilizing = WhatToPlayTrainingSessionGradeMetrics.classify(
            completedAttempts: 3,
            accuracyPercent: 67,
            averageExpectedImpact: 1,
            targetAverageExpectedImpact: 2,
            averageLostProjectedTeamPoints: 0
        )
        #expect(stabilizing.category == .stabilizing)
        #expect(stabilizing.percent == 54)
        #expect(stabilizing.reasonCategory == .impactWeakness)

        let repeatNeeded = WhatToPlayTrainingSessionGradeMetrics.classify(
            completedAttempts: 4,
            accuracyPercent: 50,
            averageExpectedImpact: -1,
            targetAverageExpectedImpact: 0,
            averageLostProjectedTeamPoints: 0
        )
        #expect(repeatNeeded.category == .repeatNeeded)
        #expect(repeatNeeded.percent == 45)
        #expect(repeatNeeded.reasonCategory == .balanced)
    }

    @Test("سبب درجة جلسة تدريب وش تلعب يميز ضعف الدقة")
    func trainingSessionGradeMetricsClassifyAccuracyWeakness() {
        let metrics = WhatToPlayTrainingSessionGradeMetrics.classify(
            completedAttempts: 4,
            accuracyPercent: 25,
            averageExpectedImpact: 5,
            targetAverageExpectedImpact: 0,
            averageLostProjectedTeamPoints: 0
        )

        #expect(metrics.category == .stabilizing)
        #expect(metrics.percent == 63)
        #expect(metrics.accuracyComponent == 25)
        #expect(metrics.impactComponent == 100)
        #expect(metrics.reasonCategory == .accuracyWeakness)
    }

    @Test("تقدم جلسة وش تلعب يحسب الأهداف والحالة داخل المحرك")
    func trainingSessionProgressMetricsClassifyTargets() {
        let notStarted = WhatToPlayTrainingSessionProgressMetrics.classify(
            completedAttempts: 0,
            correctAttempts: 0,
            targetAttempts: 3,
            targetAccuracyPercent: 67,
            totalExpectedImpact: 0,
            targetAverageExpectedImpact: 1,
            costlyDecisions: 0,
            maxCostlyDecisions: nil
        )
        #expect(notStarted.category == .notStarted)
        #expect(notStarted.requiredCorrectAttempts == 2)
        #expect(notStarted.correctAttemptsNeededForTarget == 2)
        #expect(notStarted.bestPossibleAccuracyPercent == 100)
        #expect(notStarted.expectedImpactNeededForTarget == 3)
        #expect(notStarted.expectedImpactNeededPerRemainingAttempt == 1)

        let notStartedWithCostlyLimit = WhatToPlayTrainingSessionProgressMetrics.classify(
            completedAttempts: 0,
            correctAttempts: 0,
            targetAttempts: 3,
            targetAccuracyPercent: 67,
            totalExpectedImpact: 5,
            targetAverageExpectedImpact: 1,
            costlyDecisions: 0,
            maxCostlyDecisions: 1
        )
        #expect(notStartedWithCostlyLimit.totalExpectedImpact == 0)
        #expect(notStartedWithCostlyLimit.costlyDecisionTargetMet == false)

        let inProgress = WhatToPlayTrainingSessionProgressMetrics.classify(
            completedAttempts: 2,
            correctAttempts: 0,
            targetAttempts: 3,
            targetAccuracyPercent: 67,
            totalExpectedImpact: -2,
            targetAverageExpectedImpact: 1,
            costlyDecisions: 1,
            maxCostlyDecisions: 1
        )
        #expect(inProgress.category == .inProgress)
        #expect(inProgress.accuracyTargetReachable == false)
        #expect(inProgress.bestPossibleAccuracyPercent == 33)
        #expect(inProgress.expectedImpactNeededForTarget == 5)
        #expect(inProgress.expectedImpactNeededPerRemainingAttempt == 5)
        #expect(inProgress.impactRecoveryHighPressure)

        let achieved = WhatToPlayTrainingSessionProgressMetrics.classify(
            completedAttempts: 3,
            correctAttempts: 2,
            targetAttempts: 3,
            targetAccuracyPercent: 67,
            totalExpectedImpact: 4,
            targetAverageExpectedImpact: 1,
            costlyDecisions: 0,
            maxCostlyDecisions: 1
        )
        #expect(achieved.category == .achieved)
        #expect(achieved.accuracyPercent == 67)
        #expect(achieved.correctAttemptsNeededForTarget == 0)
        #expect(achieved.expectedImpactNeededForTarget == 0)
        #expect(achieved.averageExpectedImpactGap == 0)

        let needsRepeat = WhatToPlayTrainingSessionProgressMetrics.classify(
            completedAttempts: 3,
            correctAttempts: 3,
            targetAttempts: 3,
            targetAccuracyPercent: 67,
            totalExpectedImpact: 5,
            targetAverageExpectedImpact: 1,
            costlyDecisions: 2,
            maxCostlyDecisions: 1
        )
        #expect(needsRepeat.category == .needsRepeat)
        #expect(needsRepeat.accuracyTargetMet)
        #expect(needsRepeat.impactTargetMet)
        #expect(needsRepeat.costlyDecisionTargetMet == false)
    }

    @Test("الخطوة التالية في جلسة وش تلعب تأتي من المحرك")
    func trainingSessionNextStepMetricsClassifyProgressGuidance() {
        #expect(
            nextStep(progress: .notStarted).category == .start
        )
        #expect(
            nextStep(
                progress: .inProgress,
                remainingAttempts: 1,
                correctNeeded: 2
            ).category == .accuracyUnreachable
        )
        #expect(
            nextStep(
                progress: .inProgress,
                remainingAttempts: 2,
                correctNeeded: 1,
                averageLostExpectedPoints: 4
            ).category == .reduceLostValue
        )
        let projectedLossStep = nextStep(
            progress: .inProgress,
            remainingAttempts: 2,
            correctNeeded: 1,
            averageLostExpectedPoints: 1,
            averageLostProjectedTeamPoints: 7
        )
        #expect(projectedLossStep.category == .reduceLostValue)
        #expect(projectedLossStep.averageLossPoints == 7)
        #expect(
            nextStep(
                progress: .inProgress,
                remainingAttempts: 2,
                correctNeeded: 1,
                averageLostExpectedPoints: 3
            ).category == .continueBatch
        )
        #expect(
            nextStep(progress: .achieved).category == .nextChallenge
        )
        #expect(
            nextStep(
                progress: .needsRepeat,
                accuracyMet: true,
                impactMet: true,
                costlyMet: false
            ).category == .reduceCostlyDecisions
        )
        #expect(
            nextStep(
                progress: .needsRepeat,
                accuracyMet: true,
                impactMet: true,
                averageLostExpectedPoints: 4
            ).category == .reviewLostValue
        )
        let secondSimulationReview = nextStep(
            progress: .needsRepeat,
            accuracyMet: true,
            impactMet: true,
            averageLostExpectedPoints: 1,
            averageProjectedSecondBestGap: 6
        )
        #expect(secondSimulationReview.category == .reviewLostValue)
        #expect(secondSimulationReview.averageLossPoints == 6)
        #expect(
            nextStep(
                progress: .needsRepeat,
                accuracyMet: true,
                impactMet: false
            ).category == .reviewDecisionQuality
        )
        #expect(
            nextStep(
                progress: .needsRepeat,
                accuracyMet: false,
                impactMet: true
            ).category == .stabilizeAccuracy
        )
        #expect(
            nextStep(progress: .needsRepeat).category == .repeatPlan
        )
    }

    @Test("إجراء مراجعة جلسة وش تلعب يأتي من المحرك")
    func trainingSessionReviewMetricsClassifyAction() {
        #expect(
            WhatToPlayTrainingSessionReviewMetrics.classify(
                progressCategory: .notStarted,
                hasReviewItem: false
            ).action == .start
        )
        #expect(
            WhatToPlayTrainingSessionReviewMetrics.classify(
                progressCategory: .inProgress,
                hasReviewItem: false
            ).action == .continueSession
        )
        #expect(
            WhatToPlayTrainingSessionReviewMetrics.classify(
                progressCategory: .achieved,
                hasReviewItem: true
            ).action == .nextChallenge
        )
        #expect(
            WhatToPlayTrainingSessionReviewMetrics.classify(
                progressCategory: .needsRepeat,
                hasReviewItem: true
            ).action == .replayMistake
        )
        #expect(
            WhatToPlayTrainingSessionReviewMetrics.classify(
                progressCategory: .needsRepeat,
                hasReviewItem: false
            ).action == .repeatSession
        )
    }

    @Test("أولوية عنصر مراجعة وش تلعب تأتي من المحرك")
    func reviewPriorityMetricsClassifyReason() {
        #expect(
            WhatToPlayReviewPriorityMetrics.classify(
                expectedImpact: -1,
                lostExpectedPoints: 10,
                lostProjectedTeamPoints: 10
            ).category == .negativeImpact
        )
        #expect(
            WhatToPlayReviewPriorityMetrics.classify(
                expectedImpact: 0,
                lostExpectedPoints: 6,
                lostProjectedTeamPoints: 12
            ).category == .valueOpportunity
        )
        #expect(
            WhatToPlayReviewPriorityMetrics.classify(
                expectedImpact: 0,
                lostExpectedPoints: 2,
                lostProjectedTeamPoints: 6
            ).category == .simulationLoss
        )
        #expect(
            WhatToPlayReviewPriorityMetrics.classify(
                expectedImpact: 0,
                lostExpectedPoints: 2,
                lostProjectedTeamPoints: 0,
                lostProjectedAgainstSecondBestPoints: 8
            ).category == .simulationLoss
        )
        #expect(
            WhatToPlayReviewPriorityMetrics.classify(
                expectedImpact: 1,
                lostExpectedPoints: 2,
                lostProjectedTeamPoints: 0
            ).category == .closeTacticalGap
        )
    }

    @Test("ترتيب قائمة مراجعة وش تلعب يأتي من المحرك")
    func reviewQueueRankMetricsSortsReviewItems() {
        let now = Date(timeIntervalSince1970: 1_000)
        let projectedLoss = reviewQueueRank(
            lostExpectedPoints: 4,
            lostProjectedTeamPoints: 8,
            expectedImpact: 1,
            createdAt: now
        )
        let valueLoss = reviewQueueRank(
            lostExpectedPoints: 7,
            lostProjectedTeamPoints: 0,
            expectedImpact: 0,
            createdAt: now.addingTimeInterval(10)
        )
        let tacticalLoss = reviewQueueRank(
            lostExpectedPoints: 4,
            lostProjectedTeamPoints: 0,
            expectedImpact: -3,
            createdAt: now.addingTimeInterval(20)
        )
        let olderTie = reviewQueueRank(
            lostExpectedPoints: 4,
            lostProjectedTeamPoints: 0,
            expectedImpact: -3,
            createdAt: now
        )

        #expect(WhatToPlayReviewQueueRankMetrics.ranksBefore(projectedLoss, valueLoss))
        #expect(WhatToPlayReviewQueueRankMetrics.ranksBefore(valueLoss, tacticalLoss))
        #expect(WhatToPlayReviewQueueRankMetrics.ranksBefore(tacticalLoss, olderTie))
    }

    @Test("فاقد ثاني المحاكاة يرفع أولوية مراجعة وش تلعب")
    func reviewQueueRankMetricsPrioritizesSecondSimulationLoss() {
        let now = Date(timeIntervalSince1970: 1_000)
        let secondSimulationLoss = reviewQueueRank(
            lostExpectedPoints: 2,
            lostProjectedTeamPoints: 2,
            lostProjectedAgainstSecondBestPoints: 9,
            expectedImpact: 4,
            createdAt: now
        )
        let valueLoss = reviewQueueRank(
            lostExpectedPoints: 7,
            lostProjectedTeamPoints: 0,
            expectedImpact: -1,
            createdAt: now.addingTimeInterval(10)
        )

        #expect(WhatToPlayReviewQueueRankMetrics.ranksBefore(secondSimulationLoss, valueLoss))
    }

    @Test("تصنيف بطاقة مراجعة وش تلعب يأتي من المحرك")
    func reviewCardMetricsClassifyCardType() {
        #expect(
            WhatToPlayReviewCardMetrics.classify(
                expectedImpact: -1,
                lostExpectedPoints: 10
            ).category == .costlyChoice
        )
        #expect(
            WhatToPlayReviewCardMetrics.classify(
                expectedImpact: 0,
                lostExpectedPoints: 6
            ).category == .missedOpportunity
        )
        #expect(
            WhatToPlayReviewCardMetrics.classify(
                expectedImpact: 2,
                lostExpectedPoints: 5
            ).category == .closeComparison
        )
    }

    @Test("سبب مراجعة وش تلعب التكتيكي يأتي من المحرك")
    func tacticalReviewReasonMetricsClassifyReason() {
        #expect(
            WhatToPlayTacticalReviewReasonMetrics.classify(
                expectedImpact: -4,
                impactBreakdown: .opponentTrickClosure(points: 12)
            ).category == .opponentTrickClosure
        )
        #expect(
            WhatToPlayTacticalReviewReasonMetrics.classify(
                expectedImpact: -3,
                impactBreakdown: .unprotectedPointDump(points: 10)
            ).category == .unprotectedPointDump
        )
        #expect(
            WhatToPlayTacticalReviewReasonMetrics.classify(
                expectedImpact: -2,
                impactBreakdown: .costlyOpeningLead(points: 4)
            ).category == .costlyOpeningLead
        )
        #expect(
            WhatToPlayTacticalReviewReasonMetrics.classify(
                expectedImpact: 1,
                impactBreakdown: .costlyOpeningLead(points: 4)
            ).category == nil
        )
    }

    @Test("قياس التحسن المتوقع في وش تلعب يأتي من المحرك")
    func expectedImprovementMetricsSelectSource() {
        let projected = WhatToPlayExpectedImprovementMetrics.calculate(
            lostExpectedPoints: 4,
            lostProjectedTeamPoints: 9
        )
        #expect(projected.source == .projectedTeamPoints)
        #expect(projected.points == 9)

        let expected = WhatToPlayExpectedImprovementMetrics.calculate(
            lostExpectedPoints: 6,
            lostProjectedTeamPoints: 2
        )
        #expect(expected.source == .expectedPoints)
        #expect(expected.points == 6)

        let secondSimulation = WhatToPlayExpectedImprovementMetrics.calculate(
            lostExpectedPoints: 4,
            lostProjectedTeamPoints: 2,
            lostProjectedAgainstSecondBestPoints: 8
        )
        #expect(secondSimulation.source == .projectedSecondBestPoints)
        #expect(secondSimulation.points == 8)

        let largerSecondSimulation = WhatToPlayExpectedImprovementMetrics.calculate(
            lostExpectedPoints: 4,
            lostProjectedTeamPoints: 9,
            lostProjectedAgainstSecondBestPoints: 12
        )
        #expect(largerSecondSimulation.source == .projectedSecondBestPoints)
        #expect(largerSecondSimulation.points == 12)

        let none = WhatToPlayExpectedImprovementMetrics.calculate(
            lostExpectedPoints: -2,
            lostProjectedTeamPoints: -1
        )
        #expect(none.source == .projectedTeamPoints)
        #expect(none.points == 0)
    }

    @Test("ترتيب أفضل وأسوأ قرار في وش تلعب يأتي من المحرك")
    func decisionHighlightRankMetricsSortHighlights() {
        let now = Date(timeIntervalSince1970: 2_000)
        let strong = WhatToPlayBestDecisionHighlightRankMetrics(
            expectedImpact: 5,
            isCorrect: false,
            createdAt: now
        )
        let correctTie = WhatToPlayBestDecisionHighlightRankMetrics(
            expectedImpact: 5,
            isCorrect: true,
            createdAt: now.addingTimeInterval(-10)
        )
        let laterTie = WhatToPlayBestDecisionHighlightRankMetrics(
            expectedImpact: 5,
            isCorrect: true,
            createdAt: now.addingTimeInterval(10)
        )
        #expect(WhatToPlayBestDecisionHighlightRankMetrics.ranksBefore(strong, .init(expectedImpact: 3, isCorrect: true, createdAt: now)))
        #expect(WhatToPlayBestDecisionHighlightRankMetrics.ranksBefore(correctTie, strong))
        #expect(WhatToPlayBestDecisionHighlightRankMetrics.ranksBefore(laterTie, correctTie))

        let projectedLoss = WhatToPlayWorstDecisionHighlightRankMetrics(
            lostExpectedPoints: 2,
            lostProjectedTeamPoints: 9,
            expectedImpact: 0,
            createdAt: now
        )
        let expectedLoss = WhatToPlayWorstDecisionHighlightRankMetrics(
            lostExpectedPoints: 7,
            lostProjectedTeamPoints: 0,
            expectedImpact: -1,
            createdAt: now
        )
        let secondSimulationLoss = WhatToPlayWorstDecisionHighlightRankMetrics(
            lostExpectedPoints: 1,
            lostProjectedTeamPoints: 2,
            lostProjectedAgainstSecondBestPoints: 10,
            expectedImpact: 2,
            createdAt: now
        )
        let lowerImpactTie = WhatToPlayWorstDecisionHighlightRankMetrics(
            lostExpectedPoints: 7,
            lostProjectedTeamPoints: 0,
            expectedImpact: -3,
            createdAt: now.addingTimeInterval(-10)
        )
        let laterWorstTie = WhatToPlayWorstDecisionHighlightRankMetrics(
            lostExpectedPoints: 7,
            lostProjectedTeamPoints: 0,
            expectedImpact: -3,
            createdAt: now.addingTimeInterval(10)
        )
        #expect(WhatToPlayWorstDecisionHighlightRankMetrics.ranksBefore(projectedLoss, expectedLoss))
        #expect(WhatToPlayWorstDecisionHighlightRankMetrics.ranksBefore(secondSimulationLoss, projectedLoss))
        #expect(WhatToPlayWorstDecisionHighlightRankMetrics.ranksBefore(lowerImpactTie, expectedLoss))
        #expect(WhatToPlayWorstDecisionHighlightRankMetrics.ranksBefore(laterWorstTie, lowerImpactTie))
    }

    @Test("ترتيب أولويات تدريب وش تلعب يأتي من المحرك")
    func trainingPriorityRankMetricsSortPriorities() {
        let projectedLoss = trainingPriorityRank(
            lostExpectedPoints: 2,
            lostProjectedTeamPoints: 9,
            accuracyPercent: 90,
            averageExpectedImpact: 1,
            stableOrder: 2
        )
        let secondSimulationLoss = trainingPriorityRank(
            lostExpectedPoints: 1,
            lostProjectedTeamPoints: 2,
            lostProjectedAgainstSecondBestPoints: 12,
            accuracyPercent: 90,
            averageExpectedImpact: 1,
            stableOrder: 2
        )
        let expectedLoss = trainingPriorityRank(
            lostExpectedPoints: 7,
            lostProjectedTeamPoints: 1,
            accuracyPercent: 90,
            averageExpectedImpact: 1,
            stableOrder: 1
        )
        let lowerAccuracy = trainingPriorityRank(
            lostExpectedPoints: 2,
            lostProjectedTeamPoints: 1,
            accuracyPercent: 60,
            averageExpectedImpact: 1,
            stableOrder: 1
        )
        let lowerImpact = trainingPriorityRank(
            lostExpectedPoints: 2,
            lostProjectedTeamPoints: 1,
            accuracyPercent: 60,
            averageExpectedImpact: -1,
            stableOrder: 2
        )
        let clean = trainingPriorityRank(
            lostExpectedPoints: 0,
            lostProjectedTeamPoints: 0,
            accuracyPercent: 100,
            averageExpectedImpact: 4,
            stableOrder: 0
        )

        #expect(projectedLoss.needsTraining)
        #expect(clean.needsTraining == false)
        #expect(WhatToPlayTrainingPriorityRankMetrics.ranksBefore(secondSimulationLoss, projectedLoss, mode: .projectedLossFirst))
        #expect(WhatToPlayTrainingPriorityRankMetrics.ranksBefore(projectedLoss, expectedLoss, mode: .projectedLossFirst))
        #expect(WhatToPlayTrainingPriorityRankMetrics.ranksBefore(secondSimulationLoss, expectedLoss, mode: .expectedLossFirst) == false)
        #expect(WhatToPlayTrainingPriorityRankMetrics.ranksBefore(expectedLoss, projectedLoss, mode: .expectedLossFirst))
        #expect(WhatToPlayTrainingPriorityRankMetrics.ranksBefore(lowerAccuracy, .init(
            lostExpectedPoints: 2,
            lostProjectedTeamPoints: 1,
            accuracyPercent: 80,
            averageExpectedImpact: 1,
            stableOrder: 0
        ), mode: .projectedLossFirst))
        #expect(WhatToPlayTrainingPriorityRankMetrics.ranksBefore(lowerImpact, lowerAccuracy, mode: .projectedLossFirst))
    }

    @Test("ملخص أداء وش تلعب يأتي من المحرك ويحافظ على السلاسل وفاقد القيمة")
    func statsSummaryMetricsCalculateTrainingPerformance() {
        let metrics = WhatToPlayStatsSummaryMetrics.summarize(chronologicalSamples: [
            WhatToPlayStatsSample(isCorrect: true, expectedImpact: 4, bestExpectedImpact: 4),
            WhatToPlayStatsSample(
                isCorrect: true,
                expectedImpact: 6,
                bestExpectedImpact: 8,
                secondBestExpectedImpact: 6,
                projectedTeamPoints: 82,
                bestProjectedTeamPoints: 82,
                secondBestProjectedTeamPoints: 78
            ),
            WhatToPlayStatsSample(
                isCorrect: false,
                expectedImpact: -3,
                bestExpectedImpact: 5,
                secondBestExpectedImpact: 3,
                projectedTeamPoints: 64,
                bestProjectedTeamPoints: 76,
                secondBestProjectedTeamPoints: 70
            ),
            WhatToPlayStatsSample(isCorrect: true, expectedImpact: 2, bestExpectedImpact: 6, projectedTeamPoints: 70)
        ])

        #expect(metrics.attempts == 4)
        #expect(metrics.correct == 3)
        #expect(metrics.accuracyPercent == 75)
        #expect(metrics.currentStreak == 1)
        #expect(metrics.bestStreak == 2)
        #expect(metrics.averageExpectedImpact == 2)
        #expect(metrics.lostExpectedPoints == 14)
        #expect(metrics.averageLostExpectedPoints == 4)
        #expect(metrics.lostAgainstSecondBestPoints == 6)
        #expect(metrics.secondBestComparisonAttempts == 2)
        #expect(metrics.averageSecondBestGap == 3)
        #expect(metrics.valueCaptureAttempts == 4)
        #expect(metrics.valueCapturePercent == 52)
        #expect(metrics.projectedTeamPointAttempts == 3)
        #expect(metrics.averageProjectedTeamPoints == 72)
        #expect(metrics.lostProjectedTeamPoints == 12)
        #expect(metrics.averageLostProjectedTeamPoints == 6)
        #expect(metrics.projectedSecondBestComparisonAttempts == 2)
        #expect(metrics.lostProjectedAgainstSecondBestPoints == 6)
        #expect(metrics.averageProjectedSecondBestGap == 3)
    }

    @Test("ملخص أداء وش تلعب يتجاهل أفضلية غير موجبة في نسبة التقاط القيمة")
    func statsSummaryMetricsClampValueCapture() {
        let metrics = WhatToPlayStatsSummaryMetrics.summarize(chronologicalSamples: [
            WhatToPlayStatsSample(isCorrect: true, expectedImpact: 10, bestExpectedImpact: 6),
            WhatToPlayStatsSample(isCorrect: false, expectedImpact: 3, bestExpectedImpact: 0),
            WhatToPlayStatsSample(isCorrect: false, expectedImpact: -4, bestExpectedImpact: 4)
        ])

        #expect(metrics.valueCaptureAttempts == 2)
        #expect(metrics.valueCapturePercent == 60)
        #expect(metrics.currentStreak == 0)
        #expect(metrics.bestStreak == 1)
    }

    @Test("تطور التقاط قيمة وش تلعب يأتي من المحرك")
    func valueProgressMetricsClassifyCaptureTrend() {
        #expect(WhatToPlayValueProgressMetrics.classify(chronologicalSamples: [], window: 0) == nil)
        #expect(WhatToPlayValueProgressMetrics.classify(chronologicalSamples: [
            WhatToPlayStatsSample(isCorrect: true, expectedImpact: 5, bestExpectedImpact: 10)
        ], window: 1) == nil)

        let improving = WhatToPlayValueProgressMetrics.classify(
            chronologicalSamples: valueProgressSamples(earlySelected: 2, recentSelected: 8),
            window: 2
        )
        #expect(improving?.direction == .improving)
        #expect(improving?.earlyCapturePercent == 20)
        #expect(improving?.recentCapturePercent == 80)
        #expect(improving?.deltaPercent == 60)
        #expect(improving?.inspectedAttempts == 4)

        let declining = WhatToPlayValueProgressMetrics.classify(
            chronologicalSamples: valueProgressSamples(earlySelected: 8, recentSelected: 2),
            window: 2
        )
        #expect(declining?.direction == .declining)
        #expect(declining?.deltaPercent == -60)

        let stable = WhatToPlayValueProgressMetrics.classify(
            chronologicalSamples: valueProgressSamples(earlySelected: 5, recentSelected: 5),
            window: 2
        )
        #expect(stable?.direction == .stable)
        #expect(stable?.deltaPercent == 0)
    }

    @Test("بذرة جلسة تدريب وش تلعب تستخدم seedBase وتتجاوز المواقف المجابة")
    func trainingSessionSeedMetricsRespectSeedBase() {
        let metrics = WhatToPlayTrainingSessionSeedMetrics(
            seedBase: 9_010_000,
            difficultyOrder: 3,
            focusOrder: 2,
            gameModeOrder: 1,
            trumpSuitOrdinal: 0,
            scenarioCount: 4,
            targetAccuracyPercent: 75,
            targetAverageExpectedImpact: 1,
            matchingAttemptSeeds: [9_010_000, 9_010_001]
        )

        #expect(metrics.nextSeed == 9_010_002)
    }

    @Test("بذرة جلسة تدريب وش تلعب تشتق من أوامر ثابتة لا من hashValue")
    func trainingSessionSeedMetricsDeriveStableSeed() {
        let metrics = WhatToPlayTrainingSessionSeedMetrics(
            seedBase: nil,
            difficultyOrder: 2,
            focusOrder: 4,
            gameModeOrder: 1,
            trumpSuitOrdinal: 3,
            scenarioCount: 4,
            targetAccuracyPercent: 75,
            targetAverageExpectedImpact: 1,
            matchingAttemptSeeds: [11_415_151]
        )

        #expect(metrics.nextSeed == 11_415_152)
    }

    @Test("تصنيف خطة جلسة وش تلعب يأتي من المحرك بترتيب أولويات ثابت")
    func trainingSessionPlanMetricsClassifySessionPriority() {
        #expect(
            trainingSessionPlanCategory(style: .measuring, pulse: .reviewNeeded, costlyPercent: 80)
                == .foundation
        )
        #expect(
            trainingSessionPlanCategory(style: .inconsistent, pulse: .reviewNeeded, costlyPercent: 80)
                == .focusedReview
        )
        #expect(
            trainingSessionPlanCategory(style: .inconsistent, averageLostProjectedTeamPoints: 10, costlyPercent: 40)
                == .reduceCostlyDecisions
        )
        #expect(
            trainingSessionPlanCategory(style: .inconsistent, averageLostProjectedTeamPoints: 8)
                == .simulationReview
        )
        #expect(
            trainingSessionPlanCategory(style: .inconsistent, averageLostExpectedPoints: 5)
                == .valueReview
        )
        #expect(
            trainingSessionPlanCategory(style: .expertAligned)
                == .levelUp
        )
        #expect(
            trainingSessionPlanCategory(style: .cautious)
                == .reducePointLeak
        )
        #expect(
            trainingSessionPlanCategory(style: .inconsistent)
                == .stabilizeReading
        )
    }

    @Test("مخطط جلسة وش تلعب يثبت أهداف التدريب داخل المحرك")
    func trainingSessionPlanMetricsExposeBlueprintTargets() {
        let foundation = WhatToPlayTrainingSessionPlanMetrics.blueprint(for: .foundation)
        #expect(foundation.scenarioCount == 3)
        #expect(foundation.targetAccuracyPercent == 60)
        #expect(foundation.targetAverageExpectedImpact == 0)
        #expect(foundation.maxCostlyDecisions == nil)

        let costly = WhatToPlayTrainingSessionPlanMetrics.blueprint(for: .reduceCostlyDecisions)
        #expect(costly.scenarioCount == 3)
        #expect(costly.targetAccuracyPercent == 67)
        #expect(costly.targetAverageExpectedImpact == 1)
        #expect(costly.maxCostlyDecisions == 1)

        let levelUp = WhatToPlayTrainingSessionPlanMetrics.blueprint(for: .levelUp)
        #expect(levelUp.scenarioCount == 5)
        #expect(levelUp.targetAccuracyPercent == 80)
        #expect(levelUp.targetAverageExpectedImpact == 2)

        let stabilize = WhatToPlayTrainingSessionPlanMetrics.blueprint(for: .stabilizeReading)
        #expect(stabilize.scenarioCount == 4)
        #expect(stabilize.targetAccuracyPercent == 70)
        #expect(stabilize.targetAverageExpectedImpact == 1)
    }

    @Test("سبب خطة جلسة وش تلعب يصنف من المحرك بترتيب ثابت")
    func trainingSessionPlanRationaleMetricsClassifyPriorityOrder() {
        #expect(
            planRationale(
                trump: true,
                mode: true,
                focus: true,
                pulse: .reviewNeeded
            ).category == .trumpSuitPriority
        )
        #expect(planRationale(mode: true, focus: true).category == .gameModePriority)
        #expect(planRationale(focus: true).category == .focusPriority)
        #expect(planRationale(pulse: .reviewNeeded).category == .immediateReview)
        #expect(planRationale(style: .measuring, attempts: 4).category == .baseline)
        #expect(planRationale(attempts: 0, hasGameModeTarget: true).category == .baseline)
        #expect(planRationale(hasGameModeTarget: true, hasFocusTarget: true).category == .gameModeSampling)
        #expect(planRationale(hasFocusTarget: true).category == .focusSampling)
        #expect(planRationale().category == .stabilizeReading)
    }

    @Test("توصية الموقف القادم تختار مصدرها من المحرك")
    func nextScenarioRecommendationMetricsSelectSource() {
        #expect(
            WhatToPlayNextScenarioRecommendationMetrics.classify(hasFocusPriority: true).source
                == .focusPriority
        )
        #expect(
            WhatToPlayNextScenarioRecommendationMetrics.classify(hasFocusPriority: false).source
                == .sessionPlan
        )
    }

    @Test("ملخص نتائج قرارات وش تلعب يأتي من المحرك")
    func outcomeSummaryMetricsClassifyOutcomes() {
        #expect(WhatToPlayOutcomeSummaryMetrics.summarize(outcomes: []) == .empty)

        let metrics = WhatToPlayOutcomeSummaryMetrics.summarize(outcomes: [
            .winsTrick,
            .losesTrick,
            .leadsTrick,
            .developsTrick,
            .winsTrick
        ])

        #expect(metrics.trackedAttempts == 5)
        #expect(metrics.winningTrickAttempts == 2)
        #expect(metrics.losingTrickAttempts == 1)
        #expect(metrics.openTrickAttempts == 2)
        #expect(metrics.winningPercent == 40)
        #expect(metrics.losingPercent == 20)
    }

    @Test("ملخص رتب اختيارات وش تلعب يأتي من المحرك")
    func choiceRankSummaryMetricsClassifyRanks() {
        #expect(WhatToPlayChoiceRankSummaryMetrics.summarize(selectedRanks: []) == .empty)

        let metrics = WhatToPlayChoiceRankSummaryMetrics.summarize(selectedRanks: [1, 2, 4, 3, 1])

        #expect(metrics.trackedAttempts == 5)
        #expect(metrics.expertPicks == 2)
        #expect(metrics.secondBestPicks == 1)
        #expect(metrics.farPicks == 2)
        #expect(metrics.expertPickPercent == 40)
        #expect(metrics.nearMissPercent == 20)
        #expect(metrics.farPickPercent == 40)
    }

    @Test("ترتيب أضعف محور تدريب وش تلعب يأتي من المحرك")
    func weaknessFocusRankMetricsRankTrainingFocus() {
        let lowerAccuracy = WhatToPlayWeaknessFocusRankMetrics(
            accuracyPercent: 40,
            lostExpectedPoints: 0,
            averageExpectedImpact: 5,
            stableOrder: 2
        )
        let higherAccuracy = WhatToPlayWeaknessFocusRankMetrics(
            accuracyPercent: 60,
            lostExpectedPoints: 20,
            averageExpectedImpact: -5,
            stableOrder: 1
        )
        #expect(WhatToPlayWeaknessFocusRankMetrics.ranksBefore(lowerAccuracy, higherAccuracy))

        let higherLoss = WhatToPlayWeaknessFocusRankMetrics(
            accuracyPercent: 50,
            lostExpectedPoints: 12,
            averageExpectedImpact: 4,
            stableOrder: 2
        )
        let lowerLoss = WhatToPlayWeaknessFocusRankMetrics(
            accuracyPercent: 50,
            lostExpectedPoints: 4,
            averageExpectedImpact: -4,
            stableOrder: 1
        )
        #expect(WhatToPlayWeaknessFocusRankMetrics.ranksBefore(higherLoss, lowerLoss))

        let weakerImpact = WhatToPlayWeaknessFocusRankMetrics(
            accuracyPercent: 50,
            lostExpectedPoints: 4,
            averageExpectedImpact: -3,
            stableOrder: 2
        )
        let strongerImpact = WhatToPlayWeaknessFocusRankMetrics(
            accuracyPercent: 50,
            lostExpectedPoints: 4,
            averageExpectedImpact: 2,
            stableOrder: 1
        )
        #expect(WhatToPlayWeaknessFocusRankMetrics.ranksBefore(weakerImpact, strongerImpact))

        let earlierStableOrder = WhatToPlayWeaknessFocusRankMetrics(
            accuracyPercent: 50,
            lostExpectedPoints: 4,
            averageExpectedImpact: 2,
            stableOrder: 1
        )
        let laterStableOrder = WhatToPlayWeaknessFocusRankMetrics(
            accuracyPercent: 50,
            lostExpectedPoints: 4,
            averageExpectedImpact: 2,
            stableOrder: 2
        )
        #expect(WhatToPlayWeaknessFocusRankMetrics.ranksBefore(earlierStableOrder, laterStableOrder))
    }

    @Test("ترتيب نزيف الصعوبة في وش تلعب يأتي من المحرك")
    func difficultyImpactRankMetricsRankWorstDifficulty() {
        let lowerImpact = WhatToPlayDifficultyImpactRankMetrics(
            averageExpectedImpact: -4,
            difficultyOrder: 1
        )
        let higherImpact = WhatToPlayDifficultyImpactRankMetrics(
            averageExpectedImpact: 2,
            difficultyOrder: 4
        )
        #expect(WhatToPlayDifficultyImpactRankMetrics.ranksBefore(lowerImpact, higherImpact))

        let harderTie = WhatToPlayDifficultyImpactRankMetrics(
            averageExpectedImpact: -2,
            difficultyOrder: 4
        )
        let easierTie = WhatToPlayDifficultyImpactRankMetrics(
            averageExpectedImpact: -2,
            difficultyOrder: 2
        )
        #expect(WhatToPlayDifficultyImpactRankMetrics.ranksBefore(harderTie, easierTie))
    }

    @Test("اتجاه أداء وش تلعب يأتي من المحرك")
    func performanceTrendMetricsClassifyRecentWindow() {
        #expect(
            WhatToPlayPerformanceTrendMetrics.classify(
                chronologicalSamples: performanceTrendSamples(previousCorrect: 0, recentCorrect: 3),
                recentWindow: 3,
                minimumWindow: 4
            ) == nil
        )

        let improving = WhatToPlayPerformanceTrendMetrics.classify(
            chronologicalSamples: performanceTrendSamples(previousCorrect: 0, recentCorrect: 3),
            recentWindow: 3,
            minimumWindow: 3
        )
        #expect(improving?.direction == .improving)
        #expect(improving?.previousAccuracyPercent == 0)
        #expect(improving?.recentAccuracyPercent == 100)
        #expect(improving?.accuracyDelta == 100)

        let declining = WhatToPlayPerformanceTrendMetrics.classify(
            chronologicalSamples: performanceTrendSamples(previousCorrect: 3, recentCorrect: 0),
            recentWindow: 3,
            minimumWindow: 3
        )
        #expect(declining?.direction == .declining)
        #expect(declining?.accuracyDelta == -100)

        let stable = WhatToPlayPerformanceTrendMetrics.classify(
            chronologicalSamples: performanceTrendSamples(previousCorrect: 2, recentCorrect: 2),
            recentWindow: 3,
            minimumWindow: 3
        )
        #expect(stable?.direction == .stable)
        #expect(stable?.previousAccuracyPercent == 67)
        #expect(stable?.recentAccuracyPercent == 67)
    }

    @Test("ملخص جودة قرارات وش تلعب يأتي من المحرك")
    func decisionQualitySummaryMetricsClassifyQualities() {
        #expect(WhatToPlayDecisionQualitySummaryMetrics.summarize(qualities: []) == .empty)

        let metrics = WhatToPlayDecisionQualitySummaryMetrics.summarize(qualities: [
            .expertMatch,
            .close,
            .acceptable,
            .costly,
            .costly
        ])

        #expect(metrics.trackedAttempts == 5)
        #expect(metrics.expertMatches == 1)
        #expect(metrics.closeDecisions == 1)
        #expect(metrics.acceptableDecisions == 1)
        #expect(metrics.costlyDecisions == 2)
        #expect(metrics.strongPercent == 40)
        #expect(metrics.costlyPercent == 40)
    }

    @Test("رؤى جودة قرارات وش تلعب تأتي من المحرك")
    func decisionQualityInsightMetricsClassifySummaries() {
        let tooSmall = WhatToPlayDecisionQualitySummaryMetrics(
            trackedAttempts: 2,
            expertMatches: 2,
            closeDecisions: 0,
            acceptableDecisions: 0,
            costlyDecisions: 0
        )
        #expect(WhatToPlayDecisionQualityInsightMetrics.classify(summary: tooSmall) == nil)

        let costly = WhatToPlayDecisionQualitySummaryMetrics(
            trackedAttempts: 4,
            expertMatches: 1,
            closeDecisions: 0,
            acceptableDecisions: 1,
            costlyDecisions: 2
        )
        #expect(WhatToPlayDecisionQualityInsightMetrics.classify(summary: costly)?.category == .costly)

        let strong = WhatToPlayDecisionQualitySummaryMetrics(
            trackedAttempts: 4,
            expertMatches: 2,
            closeDecisions: 1,
            acceptableDecisions: 1,
            costlyDecisions: 0
        )
        #expect(WhatToPlayDecisionQualityInsightMetrics.classify(summary: strong)?.category == .strong)

        let mixed = WhatToPlayDecisionQualitySummaryMetrics(
            trackedAttempts: 4,
            expertMatches: 1,
            closeDecisions: 1,
            acceptableDecisions: 2,
            costlyDecisions: 0
        )
        #expect(WhatToPlayDecisionQualityInsightMetrics.classify(summary: mixed)?.category == .mixed)
    }

    @Test("رؤى رتبة اختيارات وش تلعب تأتي من المحرك")
    func choiceRankInsightMetricsClassifySummaries() {
        #expect(WhatToPlayChoiceRankInsightMetrics.classify(summary: .empty) == nil)

        let aligned = WhatToPlayChoiceRankSummaryMetrics(
            trackedAttempts: 4,
            expertPicks: 3,
            secondBestPicks: 0,
            farPicks: 1
        )
        #expect(WhatToPlayChoiceRankInsightMetrics.classify(summary: aligned)?.category == .expertAligned)

        let far = WhatToPlayChoiceRankSummaryMetrics(
            trackedAttempts: 5,
            expertPicks: 1,
            secondBestPicks: 1,
            farPicks: 3
        )
        #expect(WhatToPlayChoiceRankInsightMetrics.classify(summary: far)?.category == .farChoices)

        let near = WhatToPlayChoiceRankSummaryMetrics(
            trackedAttempts: 5,
            expertPicks: 2,
            secondBestPicks: 2,
            farPicks: 1
        )
        #expect(WhatToPlayChoiceRankInsightMetrics.classify(summary: near)?.category == .nearMisses)
    }

    @Test("نصيحة تدريب وش تلعب تختار السبب من المحرك")
    func coachingTipMetricsClassifyTrainingNeeds() {
        let noData = WhatToPlayCoachingTipMetrics.classify(
            summary: coachingSummary(attempts: 0),
            choiceRankSummary: .empty
        )
        #expect(noData.category == .startMeasuring)

        let lowAccuracy = WhatToPlayCoachingTipMetrics.classify(
            summary: coachingSummary(attempts: 4, accuracyPercent: 49, averageExpectedImpact: -3, currentStreak: 4),
            choiceRankSummary: WhatToPlayChoiceRankSummaryMetrics(trackedAttempts: 4, expertPicks: 0, secondBestPicks: 0, farPicks: 4)
        )
        #expect(lowAccuracy.category == .slowDown)

        let pointLeak = WhatToPlayCoachingTipMetrics.classify(
            summary: coachingSummary(attempts: 4, accuracyPercent: 80, averageExpectedImpact: -1, currentStreak: 4),
            choiceRankSummary: WhatToPlayChoiceRankSummaryMetrics(trackedAttempts: 4, expertPicks: 0, secondBestPicks: 0, farPicks: 4)
        )
        #expect(pointLeak.category == .reducePointLeak)

        let secondSimulation = WhatToPlayCoachingTipMetrics.classify(
            summary: coachingSummary(
                attempts: 5,
                accuracyPercent: 80,
                averageExpectedImpact: 2,
                currentStreak: 3,
                projectedSecondBestComparisonAttempts: 3,
                lostProjectedAgainstSecondBestPoints: 24,
                averageProjectedSecondBestGap: 8
            ),
            choiceRankSummary: WhatToPlayChoiceRankSummaryMetrics(trackedAttempts: 5, expertPicks: 4, secondBestPicks: 1, farPicks: 0)
        )
        #expect(secondSimulation.category == .secondSimulationReview)
        #expect(secondSimulation.averageProjectedSecondBestGap == 8)

        let narrowChoices = WhatToPlayCoachingTipMetrics.classify(
            summary: coachingSummary(attempts: 5, accuracyPercent: 80, averageExpectedImpact: 1, currentStreak: 4),
            choiceRankSummary: WhatToPlayChoiceRankSummaryMetrics(trackedAttempts: 5, expertPicks: 2, secondBestPicks: 1, farPicks: 2)
        )
        #expect(narrowChoices.category == .narrowChoices)
        #expect(narrowChoices.farPickPercent == 40)

        let strongStreak = WhatToPlayCoachingTipMetrics.classify(
            summary: coachingSummary(attempts: 5, accuracyPercent: 80, averageExpectedImpact: 1, currentStreak: 3),
            choiceRankSummary: WhatToPlayChoiceRankSummaryMetrics(trackedAttempts: 5, expertPicks: 4, secondBestPicks: 1, farPicks: 0)
        )
        #expect(strongStreak.category == .strongStreak)

        let compare = WhatToPlayCoachingTipMetrics.classify(
            summary: coachingSummary(attempts: 5, accuracyPercent: 80, averageExpectedImpact: 1, currentStreak: 1),
            choiceRankSummary: WhatToPlayChoiceRankSummaryMetrics(trackedAttempts: 5, expertPicks: 3, secondBestPicks: 1, farPicks: 1)
        )
        #expect(compare.category == .compareChoices)
    }

    @Test("توصية تدريب وش تلعب تختار المسار والصعوبة من المحرك")
    func practiceRecommendationMetricsClassifyNextTrainingStep() {
        #expect(practiceRecommendation().category == .startEasy)
        #expect(practiceRecommendation().difficulty == .easy)

        let declining = practiceRecommendation(
            attempts: 6,
            trend: .declining,
            focusDifficulty: .medium,
            highestAttemptedDifficulty: .hard
        )
        #expect(declining.category == .tacticalStepBack)
        #expect(declining.difficulty == .medium)

        let costly = practiceRecommendation(
            attempts: 5,
            averageLostProjectedTeamPoints: 8,
            costlyPercent: 40,
            focusDifficulty: .hard
        )
        #expect(costly.category == .reduceCostlyDecisions)
        #expect(costly.difficulty == .hard)

        let simulation = practiceRecommendation(
            attempts: 5,
            projectedAttempts: 3,
            averageLostProjectedTeamPoints: 8,
            highestAttemptedDifficulty: .hard
        )
        #expect(simulation.category == .simulationReview)
        #expect(simulation.difficulty == .hard)

        let weakness = practiceRecommendation(
            attempts: 5,
            focusDifficulty: .medium,
            focusAccuracyPercent: 60
        )
        #expect(weakness.category == .weaknessFocus)
        #expect(weakness.difficulty == .medium)

        let value = practiceRecommendation(
            attempts: 5,
            averageLostExpectedPoints: 5,
            highestAttemptedDifficulty: .hard
        )
        #expect(value.category == .valueReview)
        #expect(value.difficulty == .hard)

        let levelUp = practiceRecommendation(
            attempts: 5,
            accuracyPercent: 80,
            currentStreak: 3,
            highestAttemptedDifficulty: .hard
        )
        #expect(levelUp.category == .levelUp)
        #expect(levelUp.difficulty == .expert)

        let steady = practiceRecommendation(
            attempts: 5,
            accuracyPercent: 70,
            highestAttemptedDifficulty: .hard
        )
        #expect(steady.category == .steadyMedium)
        #expect(steady.difficulty == .medium)
    }

    @Test("رؤى نتيجة قرارات وش تلعب تأتي من المحرك")
    func outcomeInsightMetricsClassifySummaries() {
        #expect(WhatToPlayOutcomeInsightMetrics.classify(summary: .empty) == nil)

        let losing = WhatToPlayOutcomeSummaryMetrics(
            trackedAttempts: 4,
            winningTrickAttempts: 1,
            losingTrickAttempts: 2,
            openTrickAttempts: 1
        )
        #expect(WhatToPlayOutcomeInsightMetrics.classify(summary: losing)?.category == .losingOften)

        let winning = WhatToPlayOutcomeSummaryMetrics(
            trackedAttempts: 4,
            winningTrickAttempts: 2,
            losingTrickAttempts: 1,
            openTrickAttempts: 1
        )
        #expect(WhatToPlayOutcomeInsightMetrics.classify(summary: winning)?.category == .winningOften)

        let open = WhatToPlayOutcomeSummaryMetrics(
            trackedAttempts: 5,
            winningTrickAttempts: 1,
            losingTrickAttempts: 1,
            openTrickAttempts: 3
        )
        #expect(WhatToPlayOutcomeInsightMetrics.classify(summary: open)?.category == .openTrickPattern)

        let balanced = WhatToPlayOutcomeSummaryMetrics(
            trackedAttempts: 5,
            winningTrickAttempts: 2,
            losingTrickAttempts: 1,
            openTrickAttempts: 2
        )
        #expect(WhatToPlayOutcomeInsightMetrics.classify(summary: balanced)?.category == .balanced)
    }

    @Test("مراجعة اختيار وش تلعب تحسب الفوارق وجودة القرار من المحرك")
    func choiceReviewCalculatesLossesAndQuality() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2, difficulty: .hard)
        let best = try #require(scenario.bestOption)
        let bestProjected = try #require(scenario.bestProjectedOption)
        let secondBestProjected = try #require(scenario.secondBestProjectedOption)
        let selected = try #require(scenario.options.first {
            $0.projectedTeamPoints < bestProjected.projectedTeamPoints
        })

        let review = WhatToPlayTrainer.choiceReview(in: scenario, selectedCard: selected.card)

        #expect(review.bestOption?.card == best.card)
        #expect(review.secondBestOption?.card == scenario.secondBestOption?.card)
        #expect(review.bestProjectedOption?.card == bestProjected.card)
        #expect(review.secondBestProjectedOption?.card == secondBestProjected.card)
        #expect(review.selectedOption?.card == selected.card)
        #expect(review.selectedLostExpectedPoints == max(0, best.expectedImpact - selected.expectedImpact))
        #expect(review.selectedLostProjectedTeamPoints == max(0, bestProjected.projectedTeamPoints - selected.projectedTeamPoints))
        #expect(
            review.decisionQuality == WhatToPlayDecisionQuality.classify(
                isExpertChoice: selected.isExpertChoice,
                lostExpectedPoints: review.selectedLostExpectedPoints ?? 0,
                lostProjectedTeamPoints: review.selectedLostProjectedTeamPoints ?? 0
            )
        )
        #expect(review.bestMoveConfidence == WhatToPlayBestMoveConfidence.classify(bestToSecondGap: review.bestToSecondExpectedImpactGap))
    }

    @Test("مراجعة وش تلعب بدون اختيار تعرض أفضلية الموقف ولا تصطنع جودة قرار")
    func choiceReviewWithoutSelectionKeepsDecisionEmpty() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let review = WhatToPlayTrainer.choiceReview(in: scenario)

        #expect(review.bestOption?.card == scenario.bestOption?.card)
        #expect(review.secondBestOption?.card == scenario.secondBestOption?.card)
        #expect(review.bestProjectedOption?.card == scenario.bestProjectedOption?.card)
        #expect(review.secondBestProjectedOption?.card == scenario.secondBestProjectedOption?.card)
        #expect(review.selectedOption == nil)
        #expect(review.selectedLostExpectedPoints == nil)
        #expect(review.selectedLostProjectedTeamPoints == nil)
        #expect(review.decisionQuality == nil)
        #expect(review.bestMoveConfidence != nil)
    }

    @Test("وسم خيار وش تلعب التكتيكي يأتي من المحرك")
    func tacticalTagClassifiesOption() {
        let expert = projectedOption(
            card: PlayingCard(suit: .spades, rank: .ace),
            rank: 1,
            isExpertChoice: true,
            expectedImpact: 10
        )
        let close = projectedOption(card: PlayingCard(suit: .hearts, rank: .ace), rank: 2, expectedImpact: 8)
        let costly = projectedOption(card: PlayingCard(suit: .clubs, rank: .seven), rank: 3, expectedImpact: -1)
        let wins = projectedOption(
            card: PlayingCard(suit: .diamonds, rank: .ace),
            rank: 4,
            expectedImpact: 6,
            outcome: .winsTrick
        )
        let opens = projectedOption(
            card: PlayingCard(suit: .diamonds, rank: .king),
            rank: 5,
            expectedImpact: 4,
            outcome: .leadsTrick
        )
        let holds = projectedOption(
            card: PlayingCard(suit: .diamonds, rank: .queen),
            rank: 6,
            expectedImpact: 4,
            projectedTeamPoints: 40,
            outcome: .losesTrick
        )
        let secondProjectedLoss = projectedOption(
            card: PlayingCard(suit: .clubs, rank: .eight),
            rank: 7,
            expectedImpact: 4,
            projectedTeamPoints: 30,
            outcome: .losesTrick
        )

        #expect(WhatToPlayOptionTacticalTag.classify(option: expert, bestExpectedImpact: 10, bestProjectedTeamPoints: 40) == .expertPick)
        #expect(WhatToPlayOptionTacticalTag.classify(option: close, bestExpectedImpact: 10, bestProjectedTeamPoints: 40) == .closeAlternative)
        #expect(WhatToPlayOptionTacticalTag.classify(option: costly, bestExpectedImpact: 10, bestProjectedTeamPoints: 40) == .costly)
        #expect(WhatToPlayOptionTacticalTag.classify(option: wins, bestExpectedImpact: 10, bestProjectedTeamPoints: 40) == .winsNow)
        #expect(WhatToPlayOptionTacticalTag.classify(option: opens, bestExpectedImpact: 10, bestProjectedTeamPoints: 40) == .opensRisk)
        #expect(WhatToPlayOptionTacticalTag.classify(option: holds, bestExpectedImpact: 10, bestProjectedTeamPoints: 40) == .holdsPosition)
        #expect(
            WhatToPlayOptionTacticalTag.classify(
                option: secondProjectedLoss,
                bestExpectedImpact: 10,
                bestProjectedTeamPoints: 31,
                secondBestProjectedTeamPoints: 40
            ) == .costly
        )
    }

    @Test("ملخص خيار وش تلعب التكتيكي يصنف من المحرك")
    func tacticalSummaryMetricsClassifyOptionReview() {
        let expert = projectedOption(
            card: PlayingCard(suit: .spades, rank: .ace),
            rank: 1,
            isExpertChoice: true,
            expectedImpact: 10
        )
        let projectedLoss = projectedOption(card: PlayingCard(suit: .hearts, rank: .ace), rank: 2, expectedImpact: 9)
        let noLoss = projectedOption(card: PlayingCard(suit: .clubs, rank: .ace), rank: 3, expectedImpact: 10)
        let smallLoss = projectedOption(card: PlayingCard(suit: .diamonds, rank: .ace), rank: 4, expectedImpact: 8)
        let negative = projectedOption(card: PlayingCard(suit: .clubs, rank: .seven), rank: 5, expectedImpact: -1)
        let wins = projectedOption(
            card: PlayingCard(suit: .diamonds, rank: .king),
            rank: 6,
            expectedImpact: 6,
            outcome: .winsTrick
        )
        let open = projectedOption(
            card: PlayingCard(suit: .diamonds, rank: .queen),
            rank: 7,
            expectedImpact: 6,
            outcome: .developsTrick
        )

        #expect(summaryCategory(expert, lost: 0, projected: 0) == .expertPick)
        #expect(summaryCategory(projectedLoss, lost: 1, projected: 5) == .projectedLoss)
        #expect(summaryCategory(projectedLoss, lost: 1, projected: 0, secondProjected: 5) == .projectedLoss)
        #expect(summaryCategory(noLoss, lost: 0, projected: 0) == .noLossCloseAlternative)
        #expect(summaryCategory(smallLoss, lost: 2, projected: 0) == .smallLossAlternative)
        #expect(summaryCategory(negative, lost: 11, projected: 0) == .negativeExpectedImpact)
        #expect(summaryCategory(wins, lost: 4, projected: 0) == .winsNowWithLowerValue)
        #expect(summaryCategory(open, lost: 4, projected: 0) == .openTrickLoss)
    }

    @Test("مراجعات خيارات وش تلعب ترتب الصفوف وتحسب الفاقد من المحرك")
    func optionReviewsCalculateRowsFromEngine() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2, difficulty: .hard)
        let reviews = WhatToPlayTrainer.optionReviews(in: scenario)
        let best = try #require(scenario.bestOption)
        let bestProjected = try #require(scenario.bestProjectedOption)
        let secondBestProjected = try #require(scenario.secondBestProjectedOption)

        #expect(reviews.map(\.option.card) == scenario.options.sorted { lhs, rhs in
            if lhs.rank != rhs.rank { return lhs.rank < rhs.rank }
            if lhs.card.suit.ordinal != rhs.card.suit.ordinal {
                return lhs.card.suit.ordinal < rhs.card.suit.ordinal
            }
            return lhs.card.rank.ordinal < rhs.card.rank.ordinal
        }.map(\.card))
        #expect(reviews.first?.option.card == best.card)
        #expect(reviews.contains { $0.isBestProjectedResult && $0.option.card == bestProjected.card })

        for review in reviews {
            #expect(review.lostExpectedPoints == max(0, best.expectedImpact - review.option.expectedImpact))
            #expect(review.lostProjectedTeamPoints == max(0, bestProjected.projectedTeamPoints - review.option.projectedTeamPoints))
            #expect(
                review.lostProjectedAgainstSecondBestPoints
                    == max(0, secondBestProjected.projectedTeamPoints - review.option.projectedTeamPoints)
            )
            #expect(
                review.tacticalTag == WhatToPlayOptionTacticalTag.classify(
                    option: review.option,
                    bestExpectedImpact: best.expectedImpact,
                    bestProjectedTeamPoints: bestProjected.projectedTeamPoints,
                    secondBestProjectedTeamPoints: secondBestProjected.projectedTeamPoints
                )
            )
            #expect(
                review.tacticalSummaryMetrics
                    == WhatToPlayOptionTacticalSummaryMetrics.classify(
                        option: review.option,
                        lostExpectedPoints: review.lostExpectedPoints,
                        lostProjectedTeamPoints: review.lostProjectedTeamPoints,
                        lostProjectedAgainstSecondBestPoints: review.lostProjectedAgainstSecondBestPoints
                    )
            )
        }
    }

    @Test("توصية الإجراء التالي بعد وش تلعب تأتي من المحرك")
    func nextActionRecommendationClassifiesDecision() throws {
        let expertScenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let expert = try #require(expertScenario.bestOption)
        let expertRecommendation = try #require(
            WhatToPlayTrainer.nextActionRecommendation(in: expertScenario, selectedCard: expert.card)
        )
        let expectedExpertKind: WhatToPlayNextActionKind = expertRecommendation.lostProjectedTeamPoints >= 9
            ? .reviewExpertSimulation
            : .reinforceRead
        #expect(expertRecommendation.kind == expectedExpertKind)
        #expect(expertRecommendation.selectedOption.card == expert.card)

        let simulationScenario = try WhatToPlayTrainer.generateScenario(seed: 2, difficulty: .hard)
        let best = try #require(simulationScenario.bestOption)
        let bestProjected = try #require(simulationScenario.bestProjectedOption)
        let simulationLoss = try #require(simulationScenario.options.first {
            !$0.isExpertChoice
                && max(0, bestProjected.projectedTeamPoints - $0.projectedTeamPoints) > max(0, best.expectedImpact - $0.expectedImpact)
        })
        let simulationRecommendation = try #require(
            WhatToPlayTrainer.nextActionRecommendation(in: simulationScenario, selectedCard: simulationLoss.card)
        )

        #expect(simulationRecommendation.kind == .reviewSimulation)
        #expect(simulationRecommendation.bestProjectedOption.card == bestProjected.card)
        #expect(simulationRecommendation.lostProjectedTeamPoints > simulationRecommendation.lostExpectedPoints)
        #expect(simulationRecommendation.recommendedCard == bestProjected.card)
        #expect(
            simulationRecommendation.expectedImprovement
                == max(simulationRecommendation.lostExpectedPoints, simulationRecommendation.lostProjectedTeamPoints)
        )

        let selectedOption = projectedOption(card: .init(suit: .clubs, rank: .seven), rank: 2, expectedImpact: 7, projectedTeamPoints: 52)
        let bestOption = projectedOption(card: .init(suit: .hearts, rank: .ace), rank: 1, expectedImpact: 8, projectedTeamPoints: 54)
        let bestProjectedOption = projectedOption(card: .init(suit: .spades, rank: .ace), rank: 3, expectedImpact: 6, projectedTeamPoints: 70)
        let secondBestProjectedOption = projectedOption(card: .init(suit: .diamonds, rank: .jack), rank: 4, expectedImpact: 5, projectedTeamPoints: 68)
        let secondProjectionReview = WhatToPlayChoiceReview(
            bestOption: bestOption,
            secondBestOption: selectedOption,
            bestProjectedOption: bestProjectedOption,
            secondBestProjectedOption: secondBestProjectedOption,
            selectedOption: selectedOption,
            bestToSecondExpectedImpactGap: 1,
            expertToBestProjectedTeamPointsGap: 16,
            selectedLostExpectedPoints: 1,
            selectedLostProjectedTeamPoints: 2,
            selectedLostProjectedAgainstSecondBestPoints: 16,
            decisionQuality: .costly,
            bestMoveConfidence: .narrow
        )
        let secondProjectionRecommendation: WhatToPlayNextActionRecommendation = try #require(
            WhatToPlayTrainer.nextActionRecommendation(from: secondProjectionReview)
        )

        #expect(secondProjectionRecommendation.kind == WhatToPlayNextActionKind.reviewSimulation)
        #expect(secondProjectionRecommendation.secondBestProjectedOption?.card == secondBestProjectedOption.card)
        #expect(secondProjectionRecommendation.lostProjectedTeamPoints == 2)
        #expect(secondProjectionRecommendation.lostProjectedAgainstSecondBestPoints == 16)
        #expect(secondProjectionRecommendation.expectedImprovement == 16)
        #expect(secondProjectionRecommendation.recommendedCard == secondBestProjectedOption.card)
    }

    @Test("توصية الإجراء التالي ترجح ثاني أفضل محاكاة عندما تكون أعلى فاقد")
    func nextActionRecommendationRecommendedCardUsesSecondProjectionLoss() {
        let selected = projectedOption(card: .init(suit: .clubs, rank: .seven), rank: 4, expectedImpact: 4, projectedTeamPoints: 50)
        let best = projectedOption(card: .init(suit: .hearts, rank: .ace), rank: 1, expectedImpact: 7, projectedTeamPoints: 54)
        let bestProjected = projectedOption(card: .init(suit: .spades, rank: .ace), rank: 2, expectedImpact: 6, projectedTeamPoints: 57)
        let secondBestProjected = projectedOption(card: .init(suit: .diamonds, rank: .jack), rank: 3, expectedImpact: 5, projectedTeamPoints: 68)
        let recommendation = WhatToPlayNextActionRecommendation(
            kind: .reviewSimulation,
            selectedOption: selected,
            bestOption: best,
            bestProjectedOption: bestProjected,
            secondBestOption: bestProjected,
            secondBestProjectedOption: secondBestProjected,
            lostExpectedPoints: 3,
            lostProjectedTeamPoints: 7,
            lostProjectedAgainstSecondBestPoints: 18
        )

        #expect(recommendation.expectedImprovement == 18)
        #expect(recommendation.recommendedCard == secondBestProjected.card)
    }

    @Test("أرقام Replay لقرار وش تلعب تأتي من مراجعة خيارات المحرك")
    func replayMetricsUseEngineOptionReview() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2, difficulty: .hard)
        let selected = try #require(scenario.options.last)
        let optionReview = try #require(WhatToPlayTrainer.optionReviews(in: scenario).first { $0.option.card == selected.card })

        let metrics = try #require(WhatToPlayTrainer.replayMetrics(in: scenario, selectedCard: selected.card))

        #expect(metrics.selectedOption.card == selected.card)
        #expect(metrics.lostProjectedTeamPoints == optionReview.lostProjectedTeamPoints)
        #expect(metrics.lostProjectedAgainstSecondBestPoints == optionReview.lostProjectedAgainstSecondBestPoints)
        #expect(metrics.isExpertChoice == selected.isExpertChoice)
        #expect(
            metrics.contextCategory
                == (max(metrics.lostProjectedTeamPoints, metrics.lostProjectedAgainstSecondBestPoints) > 0
                    ? .projectedLoss
                    : .selectedChoice)
        )

        let expertScenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let expert = try #require(expertScenario.bestOption)
        let expertMetrics = try #require(WhatToPlayTrainer.replayMetrics(in: expertScenario, selectedCard: expert.card))
        if expertMetrics.lostProjectedTeamPoints == 0 {
            #expect(expertMetrics.contextCategory == .expertChoice)
        }
    }

    @Test("تصنيف رؤية قرار وش تلعب الخام يأتي من المحرك")
    func decisionInsightMetricsClassifyDecision() {
        let expert = WhatToPlayDecisionInsightMetrics.classify(
            selectedRank: 1,
            selectedImpact: 8,
            bestImpact: 8,
            secondBestImpact: 5
        )
        #expect(expert.category == .expertMatch)
        #expect(expert.valueLossSeverity == .none)

        let close = WhatToPlayDecisionInsightMetrics.classify(
            selectedRank: 2,
            selectedImpact: 6,
            bestImpact: 8,
            secondBestImpact: 6
        )
        #expect(close.category == .closeAlternative)
        #expect(close.lostExpectedPoints == 2)
        #expect(close.valueLossSeverity == .low)

        let projectedLeak = WhatToPlayDecisionInsightMetrics.classify(
            selectedRank: 2,
            selectedImpact: 7,
            bestImpact: 8,
            secondBestImpact: 7,
            selectedProjectedTeamPoints: 52,
            bestProjectedTeamPoints: 68
        )
        #expect(projectedLeak.category == .pointLeak)
        #expect(projectedLeak.lostProjectedTeamPoints == 16)
        #expect(projectedLeak.valueLossSeverity == .high)

        let secondProjectedLeak = WhatToPlayDecisionInsightMetrics.classify(
            selectedRank: 2,
            selectedImpact: 7,
            bestImpact: 8,
            secondBestImpact: 7,
            selectedProjectedTeamPoints: 52,
            bestProjectedTeamPoints: 54,
            secondBestProjectedTeamPoints: 68
        )
        #expect(secondProjectedLeak.category == .pointLeak)
        #expect(secondProjectedLeak.lostProjectedTeamPoints == 2)
        #expect(secondProjectedLeak.lostProjectedAgainstSecondBestPoints == 16)
        #expect(secondProjectedLeak.valueLossSeverity == .high)

        let missedWin = WhatToPlayDecisionInsightMetrics.classify(
            selectedRank: 4,
            selectedImpact: -3,
            bestImpact: 7,
            secondBestImpact: 2
        )
        #expect(missedWin.category == .missedWinningChance)
        #expect(missedWin.secondBestGap == 5)
    }

    @Test("شدة خسارة قيمة وش تلعب تستخدم حدود المحرك")
    func valueLossSeverityCategoryClassifyThresholds() {
        #expect(WhatToPlayValueLossSeverityCategory.classify(decisiveLoss: 0) == .none)
        #expect(WhatToPlayValueLossSeverityCategory.classify(decisiveLoss: 2) == .low)
        #expect(WhatToPlayValueLossSeverityCategory.classify(decisiveLoss: 3) == .medium)
        #expect(WhatToPlayValueLossSeverityCategory.classify(decisiveLoss: 5) == .medium)
        #expect(WhatToPlayValueLossSeverityCategory.classify(decisiveLoss: 6) == .high)
    }

    @Test("خطوة مراجعة قرار وش تلعب حسب محور الموقف تأتي من المحرك")
    func decisionReviewFocusStepMetricsClassifyFocus() {
        #expect(reviewFocus(.openingLead).category == .openingLead)
        #expect(reviewFocus(.followSuit).category == .followSuit)
        #expect(reviewFocus(.trumpPressure).category == .trumpPressure)
        #expect(reviewFocus(.narrowChoice).category == .narrowChoice)
    }

    @Test("خطوة مراجعة قرار وش تلعب حسب نتيجة التحليل تأتي من المحرك")
    func decisionReviewInsightStepMetricsClassifyInsight() {
        #expect(reviewInsight(.expertMatch).category == .reinforceSuccess)
        #expect(reviewInsight(.closeAlternative).category == .compareAlternative)
        #expect(reviewInsight(.missedWinningChance).category == .findWinningCard)
        #expect(reviewInsight(.pointLeak).category == .identifyPointLeak)
    }

    @Test("رسالة تثبيت قراءة وش تلعب حسب محور الموقف تأتي من المحرك")
    func focusSuccessActionMetricsClassifyFocus() {
        #expect(successFocus(.openingLead).category == .openingLead)
        #expect(successFocus(.followSuit).category == .followSuit)
        #expect(successFocus(.trumpPressure).category == .trumpPressure)
        #expect(successFocus(.narrowChoice).category == .narrowChoice)
    }

    @Test("نوع إعادة موقف وش تلعب يصنف من المحرك")
    func retryRecommendationKindClassifiesExpectedImprovement() {
        #expect(WhatToPlayRetryRecommendationKind.classify(expectedImprovement: 0) == nil)
        #expect(WhatToPlayRetryRecommendationKind.classify(expectedImprovement: 1) == .smallGapPractice)
        #expect(WhatToPlayRetryRecommendationKind.classify(expectedImprovement: 2) == .smallGapPractice)
        #expect(WhatToPlayRetryRecommendationKind.classify(expectedImprovement: 3) == .replayUncounted)
    }

    @Test("توصية إعادة موقف وش تلعب تأتي من المحرك")
    func retryRecommendationComesFromEngine() throws {
        let expertScenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let expert = try #require(expertScenario.bestOption)
        #expect(WhatToPlayTrainer.retryRecommendation(in: expertScenario, selectedCard: expert.card) == nil)

        let simulationScenario = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)
        let best = try #require(simulationScenario.bestOption)
        let bestProjected = try #require(simulationScenario.bestProjectedOption)
        let selected = try #require(
            simulationScenario.options.first {
                !$0.isExpertChoice
                    && max(0, bestProjected.projectedTeamPoints - $0.projectedTeamPoints)
                        > max(0, best.expectedImpact - $0.expectedImpact)
            }
        )

        let recommendation = try #require(
            WhatToPlayTrainer.retryRecommendation(in: simulationScenario, selectedCard: selected.card)
        )

        #expect(recommendation.kind == .replayUncounted)
        #expect(
            recommendation.kind
                == WhatToPlayRetryRecommendationKind.classify(expectedImprovement: recommendation.expectedImprovement)
        )
        #expect(recommendation.recommendedCard == bestProjected.card)
        #expect(recommendation.expectedImprovement == max(
            max(0, best.expectedImpact - selected.expectedImpact),
            max(0, bestProjected.projectedTeamPoints - selected.projectedTeamPoints)
        ))
    }

    @Test("توصية الإعادة تستخدم فاقد ثاني محاكاة عند كونه الأعلى")
    func retryRecommendationUsesSecondProjectedLossWhenItIsHighest() throws {
        let selected = projectedOption(
            card: PlayingCard(suit: .spades, rank: .seven),
            rank: 4,
            expectedImpact: 8,
            projectedTeamPoints: 52
        )
        let best = projectedOption(
            card: PlayingCard(suit: .hearts, rank: .ace),
            rank: 1,
            isExpertChoice: true,
            expectedImpact: 10,
            projectedTeamPoints: 54
        )
        let bestProjected = projectedOption(
            card: PlayingCard(suit: .clubs, rank: .ace),
            rank: 2,
            expectedImpact: 9,
            projectedTeamPoints: 55
        )
        let secondBestProjected = projectedOption(
            card: PlayingCard(suit: .diamonds, rank: .ace),
            rank: 3,
            expectedImpact: 7,
            projectedTeamPoints: 70
        )
        let review = WhatToPlayChoiceReview(
            bestOption: best,
            secondBestOption: bestProjected,
            bestProjectedOption: bestProjected,
            secondBestProjectedOption: secondBestProjected,
            selectedOption: selected,
            bestToSecondExpectedImpactGap: 1,
            expertToBestProjectedTeamPointsGap: 1,
            selectedLostExpectedPoints: 2,
            selectedLostProjectedTeamPoints: 3,
            selectedLostProjectedAgainstSecondBestPoints: 18,
            decisionQuality: .costly,
            bestMoveConfidence: .clear
        )

        let recommendation = try #require(WhatToPlayTrainer.retryRecommendation(from: review))

        #expect(recommendation.improvementSource == WhatToPlayExpectedImprovementSource.projectedSecondBestPoints)
        #expect(recommendation.lostExpectedPoints == 2)
        #expect(recommendation.lostProjectedTeamPoints == 3)
        #expect(recommendation.lostProjectedAgainstSecondBestPoints == 18)
        #expect(recommendation.expectedImprovement == 18)
        #expect(recommendation.recommendedCard == secondBestProjected.card)
    }

    @Test("مستوى الخبير يولد موقفًا حقيقيًا قابلًا للتقييم")
    func expertDifficultyGeneratesPlayableScenario() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .expert)

        #expect(scenario.difficulty == .expert)
        #expect(scenario.state.phase == .playing)
        #expect(!scenario.options.isEmpty)
        #expect(scenario.options.contains { $0.isExpertChoice })
    }

    @Test("توليد الموقف يعطي دور لاعب بشري وخيارات قانونية")
    func generatedScenarioStopsAtHumanTurn() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .easy)

        #expect(scenario.state.phase == .playing)
        #expect(scenario.state.currentTurnPlayerID == scenario.playerID)
        #expect(!scenario.options.isEmpty)

        let legal = Set(GameEngine.legalCards(for: scenario.playerID, state: scenario.state))
        #expect(Set(scenario.options.map(\.card)).isSubset(of: legal))
        #expect(scenario.options.contains { $0.isExpertChoice })
    }

    @Test("الموقف الافتراضي يأتي من مزايدة بلوت كاملة لا من اختيار مبسط")
    func generatedScenarioUsesFullBiddingByDefault() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .easy)

        #expect(scenario.state.rules.biddingStyle == .full)
        #expect(scenario.state.actionHistory.contains {
            if case .placeBid = $0 { return true }
            return false
        })
        #expect(!scenario.state.actionHistory.contains {
            if case .chooseMode = $0 { return true }
            return false
        })
        #expect(scenario.state.bidding.declarerID != nil)
        #expect(scenario.state.mode != nil)
    }

    @Test("كل مزايدة في موقف التدريب قانونية لصاحب الدور عند إعادة التشغيل")
    func generatedScenarioBidsAreLegalForActingPlayer() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        var replay = scenario.initialState

        for action in scenario.state.actionHistory {
            if case .placeBid(let playerID, let bid) = action {
                #expect(replay.currentTurnPlayerID == playerID)
                #expect(GameEngine.legalBids(for: playerID, state: replay).contains(bid))
            }
            replay = try GameEngine.apply(action, to: replay)
        }
    }

    @Test("سيناريو التدريب يحمل لقطة البداية الأصلية لإعادة التشغيل")
    func generatedScenarioCarriesOriginalInitialStateForReplay() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)

        #expect(scenario.initialState.phase == .setup)
        #expect(scenario.initialState.actionHistory.isEmpty)
        #expect(scenario.initialState.players == scenario.state.players)
        #expect(scenario.initialState.teams == scenario.state.teams)
        #expect(scenario.initialState.rules == scenario.state.rules)

        let replayed = try GameEngine.replay(
            initialState: scenario.initialState,
            actions: scenario.state.actionHistory
        )

        #expect(replayed.phase == scenario.state.phase)
        #expect(replayed.currentTurnPlayerID == scenario.state.currentTurnPlayerID)
        #expect(replayed.hands == scenario.state.hands)
        #expect(trickSnapshot(replayed.currentTrick) == trickSnapshot(scenario.state.currentTrick))
        #expect(trickSnapshots(replayed.completedTricks) == trickSnapshots(scenario.state.completedTricks))
    }

    @Test("نفس البذرة والصعوبة تعطيان نفس الموقف والترتيب")
    func generationIsDeterministic() throws {
        let first = try WhatToPlayTrainer.generateScenario(seed: 99, difficulty: .medium)
        let second = try WhatToPlayTrainer.generateScenario(seed: 99, difficulty: .medium)

        #expect(first.seed == second.seed)
        #expect(first.state.phase == second.state.phase)
        #expect(first.state.mode == second.state.mode)
        #expect(first.state.trumpSuit == second.state.trumpSuit)
        #expect(first.state.hands[first.playerID] == second.state.hands[second.playerID])
        #expect(first.options.map(\.card) == second.options.map(\.card))
        #expect(first.blockedCards == second.blockedCards)
        #expect(first.bestOption?.card == second.bestOption?.card)
        #expect(first.context == second.context)
    }

    @Test("أفضل خيار بمحاكاة الجولة يأتي من المحرك وبترتيب حتمي")
    func projectedBestOptionIsDeterministic() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .hard)
        let repeated = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .hard)

        #expect(scenario.bestProjectedOption?.card == repeated.bestProjectedOption?.card)
        #expect(scenario.secondBestProjectedOption?.card == repeated.secondBestProjectedOption?.card)

        let projectedPoints = scenario.options.map(\.projectedTeamPoints).max()
        #expect(scenario.bestProjectedOption?.projectedTeamPoints == projectedPoints)
        #expect(WhatToPlayTrainer.projectedOptions(in: scenario.options).first?.card == scenario.bestProjectedOption?.card)
    }

    @Test("تعادل محاكاة وش تلعب يُحسم بترتيب أوراق ثابت")
    func projectedBestOptionTieBreaksWithStableCardOrder() {
        let options = [
            projectedOption(card: PlayingCard(suit: .hearts, rank: .ace), rank: 3),
            projectedOption(card: PlayingCard(suit: .clubs, rank: .seven), rank: 3),
            projectedOption(card: PlayingCard(suit: .clubs, rank: .eight), rank: 3)
        ]

        #expect(WhatToPlayTrainer.bestProjectedOption(in: options)?.card == PlayingCard(suit: .hearts, rank: .ace))
        #expect(WhatToPlayTrainer.secondBestProjectedOption(in: options)?.card == PlayingCard(suit: .clubs, rank: .seven))
        #expect(WhatToPlayTrainer.projectedOptions(in: options).map(\.card) == [
            PlayingCard(suit: .hearts, rank: .ace),
            PlayingCard(suit: .clubs, rank: .seven),
            PlayingCard(suit: .clubs, rank: .eight)
        ])
    }

    @Test("طلب تركيز محدد يولد موقفًا مطابقًا له بشكل حتمي")
    func generationHonorsPreferredFocusDeterministically() throws {
        for focusKind in WhatToPlayScenarioFocusKind.allCases {
            let first = try WhatToPlayTrainer.generateScenario(
                seed: 2_026,
                difficulty: .easy,
                preferredFocus: focusKind
            )
            let second = try WhatToPlayTrainer.generateScenario(
                seed: 2_026,
                difficulty: .easy,
                preferredFocus: focusKind
            )

            #expect(first.context.focusKind == focusKind)
            #expect(second.context.focusKind == focusKind)
            #expect(first.seed == second.seed)
            #expect(first.options.map(\.card) == second.options.map(\.card))
            #expect(first.bestOption?.card == second.bestOption?.card)
        }
    }

    @Test("طلب نمط محدد يولد موقف صن أو حكم من نفس دورة البلوت")
    func generationHonorsPreferredModeDeterministically() throws {
        for mode in GameMode.allCases {
            let first = try WhatToPlayTrainer.generateScenario(
                seed: 2_026,
                difficulty: .easy,
                preferredMode: mode
            )
            let second = try WhatToPlayTrainer.generateScenario(
                seed: 2_026,
                difficulty: .easy,
                preferredMode: mode
            )

            #expect(first.state.mode == mode)
            #expect(second.state.mode == mode)
            #expect(first.seed == second.seed)
            #expect(first.options.map(\.card) == second.options.map(\.card))
            #expect(first.state.actionHistory.contains {
                if case .placeBid = $0 { return true }
                return false
            })
        }
    }

    @Test("طلب صن مع لون حكم عالق يتجاهل اللون ولا يعطل التوليد")
    func generationIgnoresTrumpSuitWhenSunIsRequested() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(
            seed: 2_026,
            difficulty: .easy,
            preferredMode: .sun,
            preferredTrumpSuit: .spades
        )

        #expect(scenario.state.mode == .sun)
        #expect(scenario.state.trumpSuit == nil)
        #expect(scenario.context.mode == .sun)
        #expect(scenario.context.trumpSuit == nil)
        #expect(!scenario.options.isEmpty)
    }

    @Test("الوضع التلقائي يتجاهل لون حكم عالق ولا يضيّق توليد الصن والحكم")
    func generationIgnoresTrumpSuitWhenModeIsAutomatic() throws {
        let automatic = try WhatToPlayTrainer.generateScenario(
            seed: 2_026,
            difficulty: .easy
        )
        let withStaleTrumpSuit = try WhatToPlayTrainer.generateScenario(
            seed: 2_026,
            difficulty: .easy,
            preferredTrumpSuit: .spades
        )

        #expect(withStaleTrumpSuit.seed == automatic.seed)
        #expect(withStaleTrumpSuit.state.mode == automatic.state.mode)
        #expect(withStaleTrumpSuit.state.trumpSuit == automatic.state.trumpSuit)
        #expect(withStaleTrumpSuit.options.map(\.card) == automatic.options.map(\.card))
        #expect(withStaleTrumpSuit.bestOption?.card == automatic.bestOption?.card)
    }

    @Test("طلب لون حكم محدد يولد موقف حكم مطابقًا بشكل حتمي")
    func generationHonorsPreferredTrumpSuitDeterministically() throws {
        for suit in Suit.allCases {
            let first = try WhatToPlayTrainer.generateScenario(
                seed: 2_026,
                difficulty: .easy,
                preferredMode: .hokum,
                preferredTrumpSuit: suit
            )
            let second = try WhatToPlayTrainer.generateScenario(
                seed: 2_026,
                difficulty: .easy,
                preferredMode: .hokum,
                preferredTrumpSuit: suit
            )

            #expect(first.state.mode == .hokum)
            #expect(second.state.mode == .hokum)
            #expect(first.state.trumpSuit == suit)
            #expect(second.state.trumpSuit == suit)
            #expect(first.context.trumpSuit == suit)
            #expect(second.context.trumpSuit == suit)
            #expect(first.seed == second.seed)
            #expect(first.options.map(\.card) == second.options.map(\.card))
            #expect(first.bestOption?.card == second.bestOption?.card)
        }
    }

    @Test("تقييم اختيار المستخدم يعيد خيارًا معروفًا من نفس الموقف")
    func evaluatesUserChoiceAgainstScenarioOptions() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)
        let card = try #require(scenario.options.last?.card)

        let result = WhatToPlayTrainer.evaluateChoice(card: card, in: scenario)

        #expect(result?.card == card)
        #expect(result?.rank == scenario.options.count)
    }

    @Test("Replay قرار التدريب يعيد الجولة حتى الورقة المختارة")
    func decisionReplayRebuildsScenarioAndSelectedCard() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)
        let selected = try #require(scenario.options.last?.card)
        let replay = try #require(WhatToPlayTrainer.decisionReplay(for: selected, in: scenario))

        #expect(replay.initialState.actionHistory.isEmpty)
        #expect(replay.initialState.players == scenario.initialState.players)
        #expect(replay.initialState.teams == scenario.initialState.teams)
        #expect(replay.initialState.dealerSeat == scenario.initialState.dealerSeat)
        #expect(replay.initialState.roundNumber == scenario.initialState.roundNumber)

        let replayedScenario = try GameEngine.replay(
            initialState: replay.initialState,
            actions: Array(replay.actions.dropLast())
        )
        let replayedDecision = try GameEngine.replay(
            initialState: replay.initialState,
            actions: replay.actions
        )
        let directDecision = try GameEngine.apply(
            .playCard(playerID: scenario.playerID, card: selected),
            to: scenario.state
        )

        #expect(replay.selectedCard == selected)
        #expect(replay.playerID == scenario.playerID)
        #expect(replayedScenario.phase == scenario.state.phase)
        #expect(replayedScenario.currentTurnPlayerID == scenario.state.currentTurnPlayerID)
        #expect(replayedScenario.hands[scenario.playerID] == scenario.state.hands[scenario.playerID])
        #expect(trickSnapshot(replayedScenario.currentTrick) == trickSnapshot(scenario.state.currentTrick))
        #expect(trickSnapshots(replayedScenario.completedTricks) == trickSnapshots(scenario.state.completedTricks))
        #expect(replayedDecision.currentTurnPlayerID == directDecision.currentTurnPlayerID)
        #expect(replayedDecision.hands[scenario.playerID] == directDecision.hands[scenario.playerID])
        #expect(trickSnapshot(replayedDecision.currentTrick) == trickSnapshot(directDecision.currentTrick))
        #expect(trickSnapshots(replayedDecision.completedTricks) == trickSnapshots(directDecision.completedTricks))
        #expect(replayedDecision.actionHistory == directDecision.actionHistory)
    }

    @Test("الأوراق غير القانونية في الموقف تأتي من سبب رفض المحرك نفسه")
    func blockedCardsUseEngineInvalidMoveReasons() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(
            seed: 2026,
            difficulty: .easy,
            preferredFocus: .followSuit
        )
        let hand = try #require(scenario.state.hands[scenario.playerID])
        let legalCards = Set(scenario.options.map(\.card))
        let blockedCards = Set(scenario.blockedCards.map(\.card))

        #expect(!scenario.blockedCards.isEmpty)
        #expect(blockedCards.isDisjoint(with: legalCards))
        #expect(blockedCards.count + legalCards.count == hand.count)

        for blocked in scenario.blockedCards {
            #expect(GameEngine.invalidMoveReason(playerID: scenario.playerID, card: blocked.card, state: scenario.state) == blocked.reason)
        }
    }

    @Test("نتيجة كل خيار تطابق تطبيق الورقة على المحرك")
    func optionOutcomeMatchesEngineResult() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)
        let player = try #require(scenario.state.player(id: scenario.playerID))
        let wasLeading = scenario.state.currentTrick?.playedCards.isEmpty ?? true

        for option in scenario.options {
            let after = try GameEngine.apply(.playCard(playerID: scenario.playerID, card: option.card), to: scenario.state)
            let expected: WhatToPlayOptionOutcome
            if let last = after.completedTricks.last,
               let winnerID = last.winnerPlayerID,
               let winner = after.player(id: winnerID) {
                expected = winner.teamID == player.teamID ? .winsTrick : .losesTrick
            } else {
                expected = wasLeading ? .leadsTrick : .developsTrick
            }

            #expect(option.outcome == expected)
        }
    }

    @Test("محاكاة كل خيار تطابق الحالة الناتجة من تطبيق الورقة على المحرك")
    func optionSimulationMatchesEngineResult() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)

        for option in scenario.options {
            let after = try GameEngine.apply(.playCard(playerID: scenario.playerID, card: option.card), to: scenario.state)
            let completedTrick = after.completedTricks.last
            let winnerID = completedTrick?.winnerPlayerID
            let winnerTeamID = winnerID.flatMap { after.player(id: $0)?.teamID }
            let playerTeamID = try #require(scenario.state.player(id: scenario.playerID)?.teamID)
            let completedTrickPoints = completedTrick?.playedCards.reduce(0) {
                $0 + $1.card.points(mode: scenario.state.mode ?? .sun, trumpSuit: scenario.state.trumpSuit)
            } ?? 0

            #expect(option.simulation.phaseAfterPlay == after.phase)
            #expect(option.simulation.currentTrickCardCount == (after.currentTrick?.playedCards.count ?? 0))
            #expect(option.simulation.completedTrickWinnerID == winnerID)
            #expect(option.simulation.completedTrickWinnerTeamID == winnerTeamID)
            #expect(option.simulation.completedTrickWonByPlayerTeam == winnerTeamID.map { $0 == playerTeamID })
            #expect(option.simulation.completedTrickPoints == completedTrickPoints)
            #expect(option.simulation.nextTurnPlayerID == after.currentTurnPlayerID)
            #expect(option.simulation.playerRemainingCards == (after.hands[scenario.playerID]?.count ?? 0))
            #expect(option.simulation.actionHistoryCount == after.actionHistory.count)
        }
    }

    @Test("تفكيك أثر الخيار هو مصدر expectedImpact نفسه")
    func optionImpactBreakdownDrivesExpectedImpact() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)

        for option in scenario.options {
            #expect(option.expectedImpact == option.impactBreakdown.signedImpact)
            #expect(
                WhatToPlayTrainer.impactBreakdown(
                    of: option.card,
                    by: scenario.playerID,
                    in: scenario.state
                ) == option.impactBreakdown
            )
        }
    }

    @Test("تصنيف تفصيل أثر خيار وش تلعب يأتي من المحرك")
    func optionImpactDetailMetricsClassifyBreakdown() {
        let completed = WhatToPlayOptionImpactBreakdown(
            playedCardPoints: 10,
            immediateImpact: 0,
            trickPointsSwing: 18,
            completesTrick: true,
            winsForPlayerTeam: true,
            preservesLead: true
        )
        let preservedLead = WhatToPlayOptionImpactBreakdown(
            playedCardPoints: 4,
            immediateImpact: 2,
            trickPointsSwing: 0,
            completesTrick: false,
            winsForPlayerTeam: nil,
            preservesLead: true
        )
        let open = WhatToPlayOptionImpactBreakdown(
            playedCardPoints: 3,
            immediateImpact: -3,
            trickPointsSwing: 0,
            completesTrick: false,
            winsForPlayerTeam: nil,
            preservesLead: false
        )

        #expect(WhatToPlayOptionImpactDetailMetrics.classify(breakdown: completed).category == .completedTrick)
        #expect(WhatToPlayOptionImpactDetailMetrics.classify(breakdown: preservedLead).category == .preservedLead)
        #expect(WhatToPlayOptionImpactDetailMetrics.classify(breakdown: open).category == .openTrick)
    }

    @Test("توقع نقاط الفريق لكل خيار حتمي مع نفس البذرة")
    func optionProjectedTeamPointsAreDeterministic() throws {
        let first = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)
        let second = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)

        #expect(first.options.map(\.projectedTeamPoints) == second.options.map(\.projectedTeamPoints))
    }

    @Test("توقع نقاط الفريق يطابق استكمال الجولة من المحرك بعد فرض الورقة")
    func optionProjectedTeamPointsMatchesEnginePlayout() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)
        let player = try #require(scenario.state.player(id: scenario.playerID))

        for option in scenario.options {
            #expect(
                option.projectedTeamPoints == projectedTeamPoints(
                    afterPlaying: option.card,
                    by: player,
                    in: scenario.state
                )
            )
        }
    }

    @Test("تفكيك الأكلة المكتملة يحدد لمن تذهب نقاط الطاولة")
    func completedTrickBreakdownTracksTeamSwing() throws {
        var state = GameState.newLocalHumanMatch(rules: .simpleBidding)
        let south = try #require(state.player(at: .south))
        let west = try #require(state.player(at: .west))
        let north = try #require(state.player(at: .north))
        let east = try #require(state.player(at: .east))
        let winningCard = PlayingCard(suit: .hearts, rank: .ace)

        state.phase = .playing
        state.mode = .sun
        state.currentTurnPlayerID = south.id
        state.hands[south.id] = [winningCard]
        state.currentTrick = Trick(
            playedCards: [
                PlayedCard(playerID: west.id, card: PlayingCard(suit: .hearts, rank: .seven)),
                PlayedCard(playerID: north.id, card: PlayingCard(suit: .hearts, rank: .king)),
                PlayedCard(playerID: east.id, card: PlayingCard(suit: .hearts, rank: .ten))
            ],
            leaderSeat: .west
        )

        let option = try #require(try WhatToPlayTrainer.analyzeOptions(state: state, playerID: south.id).first)

        #expect(option.card == winningCard)
        #expect(option.impactBreakdown.completesTrick)
        #expect(option.impactBreakdown.winsForPlayerTeam == true)
        #expect(option.impactBreakdown.playedCardPoints == 11)
        #expect(option.impactBreakdown.trickPointsSwing == 25)
        #expect(option.expectedImpact == 25)
    }

    @Test("تفكيك الأثر لا يقبل ورقة غير قانونية")
    func impactBreakdownRejectsIllegalCard() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(
            seed: 2026,
            difficulty: .easy,
            preferredFocus: .followSuit
        )
        let blocked = try #require(scenario.blockedCards.first?.card)

        #expect(
            WhatToPlayTrainer.impactBreakdown(
                of: blocked,
                by: scenario.playerID,
                in: scenario.state
            ) == nil
        )
    }

    @Test("سبب نتيجة الخيار يشرح نوع الأثر التكتيكي")
    func optionOutcomeReasonExplainsOutcome() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)

        for option in scenario.options {
            #expect(!option.outcomeReason.isEmpty)
            switch option.outcome {
            case .leadsTrick:
                #expect(option.outcomeReason.contains("تبدأ الأكلة"))
            case .developsTrick:
                #expect(option.outcomeReason.contains("لا تحسم الأكلة"))
            case .winsTrick:
                #expect(option.outcomeReason.contains("لفريقك"))
            case .losesTrick:
                #expect(option.outcomeReason.contains("لصالح الخصم"))
            }
        }
    }

    @Test("شرح الخيار يذكر ترتيب الخبير والفارق العددي عن الأفضل")
    func optionExplanationIncludesRankAndBestGap() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 45, difficulty: .hard)
        let best = try #require(scenario.bestOption)
        let alternative = try #require(scenario.options.first { !$0.isExpertChoice })
        let expectedProjectionGap = max(0, best.projectedTeamPoints - alternative.projectedTeamPoints)

        #expect(best.explanation.contains("رقم 1"))
        #expect(best.explanation.contains("أعلى تقييم"))
        #expect(alternative.explanation.contains("فارق"))
        #expect(alternative.explanation.contains("\(expectedProjectionGap)"))
        #expect(alternative.explanation.contains("المحاكاة"))
    }

    @Test("شرح الخيار يعطي أولوية لخسارة المحاكاة العالية")
    func optionExplanationPrioritizesHighSimulationLoss() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2, difficulty: .hard)
        let best = try #require(scenario.bestOption)
        let option = try #require(scenario.options.first {
            !$0.isExpertChoice
                && max(0, best.projectedTeamPoints - $0.projectedTeamPoints) > max(2, abs($0.expectedImpact))
        })
        #expect(option.explanation.contains("يخسر بعد استكمال الجولة"))
        #expect(option.explanation.contains("نقاط المحاكاة"))
        #expect(!option.explanation.contains("خيار جيد"))
    }

    @Test("سياق الموقف يطابق حالة الأكلة الحالية")
    func scenarioContextMatchesCurrentTrickState() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let trick = scenario.state.currentTrick

        #expect(scenario.context.trickNumber == scenario.state.completedTricks.count + 1)
        #expect(scenario.context.isLeading == (trick?.playedCards.isEmpty ?? true))
        #expect(scenario.context.requiredSuit == trick?.requiredSuit)
        #expect(scenario.context.playedCardCount == (trick?.playedCards.count ?? 0))
        #expect(scenario.context.legalOptionCount == scenario.options.count)
        #expect(scenario.context.mode == scenario.state.mode)
        #expect(scenario.context.trumpSuit == scenario.state.trumpSuit)
        let player = try #require(scenario.state.player(id: scenario.playerID))
        let playerPoints = scenario.state.teamTrickPoints[player.teamID] ?? 0
        let opponentPoints = scenario.state.teams
            .filter { $0.id != player.teamID }
            .reduce(0) { $0 + (scenario.state.teamTrickPoints[$1.id] ?? 0) }
        #expect(scenario.context.playerTeamTrickPoints == playerPoints)
        #expect(scenario.context.opponentTeamTrickPoints == opponentPoints)
        #expect(scenario.context.playerTeamPointMargin == playerPoints - opponentPoints)
        #expect(
            scenario.context.focusKind == WhatToPlayTrainer.scenarioFocusKind(
                isLeading: scenario.context.isLeading,
                requiredSuit: scenario.context.requiredSuit,
                hasTrumpInCurrentTrick: scenario.context.hasTrumpInCurrentTrick,
                legalOptionCount: scenario.context.legalOptionCount
            )
        )
    }

    @Test("سياق الموقف يكتشف وجود الحكم على الطاولة في حكم فقط")
    func scenarioContextDetectsTrumpOnTableOnlyInHokum() throws {
        let scenario = try WhatToPlayTrainer.generateScenario(seed: 2026, difficulty: .medium)
        let hasTrump: Bool
        if scenario.state.mode == .hokum, let trumpSuit = scenario.state.trumpSuit {
            hasTrump = scenario.state.currentTrick?.playedCards.contains { $0.card.suit == trumpSuit } ?? false
        } else {
            hasTrump = false
        }

        #expect(scenario.context.hasTrumpInCurrentTrick == hasTrump)
    }

    @Test("تركيز الموقف يعطي أولوية لضغط الحكم ثم اللون المطلوب ثم ضيق الخيارات")
    func scenarioFocusPrioritizesActionablePressure() {
        #expect(
            WhatToPlayTrainer.scenarioFocusKind(
                isLeading: false,
                requiredSuit: .clubs,
                hasTrumpInCurrentTrick: true,
                legalOptionCount: 2
            ) == .trumpPressure
        )
        #expect(
            WhatToPlayTrainer.scenarioFocusKind(
                isLeading: false,
                requiredSuit: .clubs,
                hasTrumpInCurrentTrick: false,
                legalOptionCount: 2
            ) == .followSuit
        )
        #expect(
            WhatToPlayTrainer.scenarioFocusKind(
                isLeading: true,
                requiredSuit: nil,
                hasTrumpInCurrentTrick: false,
                legalOptionCount: 2
            ) == .narrowChoice
        )
        #expect(
            WhatToPlayTrainer.scenarioFocusKind(
                isLeading: true,
                requiredSuit: nil,
                hasTrumpInCurrentTrick: false,
                legalOptionCount: 4
            ) == .openingLead
        )
    }

    @Test("عوامل قرار الموقف تأتي من المحرك بترتيب ثابت")
    func decisionFactorsDescribeScenarioInStableOrder() {
        let context = WhatToPlayScenarioContext(
            trickNumber: 3,
            isLeading: false,
            requiredSuit: .clubs,
            playedCardCount: 2,
            legalOptionCount: 2,
            mode: .hokum,
            trumpSuit: .hearts,
            hasTrumpInCurrentTrick: true,
            focusKind: .trumpPressure
        )

        #expect(WhatToPlayTrainer.decisionFactors(context: context) == [
            WhatToPlayDecisionFactor(kind: .requiredSuit, suit: .clubs),
            WhatToPlayDecisionFactor(kind: .trumpOnTable, suit: .hearts),
            WhatToPlayDecisionFactor(kind: .trickProgress, count: 2),
            WhatToPlayDecisionFactor(kind: .narrowChoice, count: 2)
        ])
    }

    @Test("موجز موقف وش تلعب يصنف من المحرك")
    func scenarioBriefMetricsClassifyContext() {
        #expect(scenarioBrief(focus: .openingLead).category == .openingLead)
        #expect(
            scenarioBrief(focus: .followSuit, requiredSuit: .clubs).category == .followSuit
        )
        #expect(
            scenarioBrief(focus: .followSuit).category == .followSuitMissingRequiredSuit
        )
        #expect(
            scenarioBrief(
                focus: .trumpPressure,
                trumpSuit: .hearts,
                hasTrumpInCurrentTrick: true
            ).category == .trumpPressureWithTrumpOnTable
        )
        #expect(
            scenarioBrief(
                focus: .trumpPressure,
                trumpSuit: .hearts,
                hasTrumpInCurrentTrick: false
            ).category == .trumpPressureWithoutTrumpOnTable
        )
        #expect(scenarioBrief(focus: .narrowChoice, legalOptionCount: 2).category == .narrowChoice)
    }

    @Test("عوامل القرار تفرق بين افتتاح الصن والحكم المحفوظ")
    func decisionFactorsSeparateSunOpeningFromAvailableTrump() {
        let sunContext = WhatToPlayScenarioContext(
            trickNumber: 1,
            isLeading: true,
            requiredSuit: nil,
            playedCardCount: 0,
            legalOptionCount: 5,
            mode: .sun,
            trumpSuit: nil,
            hasTrumpInCurrentTrick: false,
            focusKind: .openingLead
        )
        let hokumContext = WhatToPlayScenarioContext(
            trickNumber: 1,
            isLeading: true,
            requiredSuit: nil,
            playedCardCount: 0,
            legalOptionCount: 5,
            mode: .hokum,
            trumpSuit: .spades,
            hasTrumpInCurrentTrick: false,
            focusKind: .openingLead
        )

        #expect(WhatToPlayTrainer.decisionFactors(context: sunContext).map(\.kind) == [
            .openingLead,
            .sunMode,
            .trickProgress,
            .flexibleChoice
        ])
        #expect(WhatToPlayTrainer.decisionFactors(context: hokumContext).map(\.kind) == [
            .openingLead,
            .trumpAvailable,
            .trickProgress,
            .flexibleChoice
        ])
        #expect(WhatToPlayTrainer.decisionFactors(context: hokumContext)[1].suit == .spades)
    }

    private func trickSnapshots(_ tricks: [Trick]) -> [[String]] {
        tricks.map { trickSnapshot($0) }
    }

    private func trickSnapshot(_ trick: Trick?) -> [String] {
        guard let trick else { return [] }
        return trick.playedCards.map { "\($0.playerID.uuidString):\($0.card.suit.rawValue):\($0.card.rank.rawValue)" }
            + ["leader:\(trick.leaderSeat.rawValue)", "winner:\(trick.winnerPlayerID?.uuidString ?? "nil")"]
    }

    private func projectedTeamPoints(afterPlaying card: PlayingCard, by player: Player, in state: GameState) -> Int {
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
}

private func trainingSessionPlanCategory(
    style: WhatToPlayPlayStyleCategory,
    pulse: WhatToPlaySessionPulseState = .focused,
    attempts: Int = 4,
    currentStreak: Int = 0,
    averageExpectedImpact: Int = 1,
    averageLostExpectedPoints: Int = 0,
    projectedAttempts: Int = 3,
    averageLostProjectedTeamPoints: Int = 0,
    costlyPercent: Int = 0
) -> WhatToPlayTrainingSessionPlanCategory {
    let costlyDecisions = costlyPercent >= 30 ? 2 : 0
    let qualityAttempts = costlyPercent >= 30 ? 5 : 0
    return WhatToPlayTrainingSessionPlanMetrics.classify(
        styleCategory: style,
        pulseState: pulse,
        summary: WhatToPlayStatsSummaryMetrics(
            attempts: attempts,
            correct: 2,
            accuracyPercent: 50,
            currentStreak: currentStreak,
            bestStreak: 2,
            averageExpectedImpact: averageExpectedImpact,
            lostExpectedPoints: averageLostExpectedPoints * max(1, attempts),
            averageLostExpectedPoints: averageLostExpectedPoints,
            lostAgainstSecondBestPoints: 0,
            secondBestComparisonAttempts: 0,
            averageSecondBestGap: 0,
            valueCapturePercent: 50,
            valueCaptureAttempts: attempts,
            projectedTeamPointAttempts: projectedAttempts,
            averageProjectedTeamPoints: 70,
            lostProjectedTeamPoints: averageLostProjectedTeamPoints * max(1, projectedAttempts),
            averageLostProjectedTeamPoints: averageLostProjectedTeamPoints,
            projectedSecondBestComparisonAttempts: 0,
            lostProjectedAgainstSecondBestPoints: 0,
            averageProjectedSecondBestGap: 0
        ),
        decisionQualitySummary: WhatToPlayDecisionQualitySummaryMetrics(
            trackedAttempts: qualityAttempts,
            expertMatches: qualityAttempts - costlyDecisions,
            closeDecisions: 0,
            acceptableDecisions: 0,
            costlyDecisions: costlyDecisions
        )
    ).category
}

private func planRationale(
    trump: Bool = false,
    mode: Bool = false,
    focus: Bool = false,
    pulse: WhatToPlaySessionPulseState = .focused,
    style: WhatToPlayPlayStyleCategory = .inconsistent,
    attempts: Int = 4,
    hasGameModeTarget: Bool = false,
    hasFocusTarget: Bool = false
) -> WhatToPlayTrainingSessionPlanRationaleMetrics {
    WhatToPlayTrainingSessionPlanRationaleMetrics.classify(
        hasTrumpSuitPriority: trump,
        hasGameModePriority: mode,
        hasFocusPriority: focus,
        pulseState: pulse,
        styleCategory: style,
        attempts: attempts,
        hasGameModeTarget: hasGameModeTarget,
        hasFocusTarget: hasFocusTarget
    )
}

private func valueProgressSamples(earlySelected: Int, recentSelected: Int) -> [WhatToPlayStatsSample] {
    [
        WhatToPlayStatsSample(isCorrect: false, expectedImpact: earlySelected, bestExpectedImpact: 10),
        WhatToPlayStatsSample(isCorrect: false, expectedImpact: earlySelected, bestExpectedImpact: 10),
        WhatToPlayStatsSample(isCorrect: false, expectedImpact: recentSelected, bestExpectedImpact: 10),
        WhatToPlayStatsSample(isCorrect: false, expectedImpact: recentSelected, bestExpectedImpact: 10)
    ]
}

private func practiceRecommendation(
    attempts: Int = 0,
    accuracyPercent: Int = 50,
    currentStreak: Int = 0,
    averageLostExpectedPoints: Int = 0,
    projectedAttempts: Int = 0,
    averageLostProjectedTeamPoints: Int = 0,
    costlyPercent: Int = 0,
    trend: WhatToPlayTrendDirectionCategory? = nil,
    focusDifficulty: WhatToPlayDifficulty? = nil,
    focusAccuracyPercent: Int? = nil,
    focusAverageExpectedImpact: Int? = nil,
    highestAttemptedDifficulty: WhatToPlayDifficulty? = nil
) -> WhatToPlayPracticeRecommendationMetrics {
    let costlyDecisions = costlyPercent >= 30 ? 2 : 0
    let qualityAttempts = costlyPercent >= 30 ? 5 : 0
    return WhatToPlayPracticeRecommendationMetrics.classify(
        summary: WhatToPlayStatsSummaryMetrics(
            attempts: attempts,
            correct: 0,
            accuracyPercent: accuracyPercent,
            currentStreak: currentStreak,
            bestStreak: currentStreak,
            averageExpectedImpact: 1,
            lostExpectedPoints: averageLostExpectedPoints * max(1, attempts),
            averageLostExpectedPoints: averageLostExpectedPoints,
            lostAgainstSecondBestPoints: 0,
            secondBestComparisonAttempts: 0,
            averageSecondBestGap: 0,
            valueCapturePercent: 50,
            valueCaptureAttempts: attempts,
            projectedTeamPointAttempts: projectedAttempts,
            averageProjectedTeamPoints: 70,
            lostProjectedTeamPoints: averageLostProjectedTeamPoints * max(1, projectedAttempts),
            averageLostProjectedTeamPoints: averageLostProjectedTeamPoints,
            projectedSecondBestComparisonAttempts: 0,
            lostProjectedAgainstSecondBestPoints: 0,
            averageProjectedSecondBestGap: 0
        ),
        decisionQualitySummary: WhatToPlayDecisionQualitySummaryMetrics(
            trackedAttempts: qualityAttempts,
            expertMatches: qualityAttempts - costlyDecisions,
            closeDecisions: 0,
            acceptableDecisions: 0,
            costlyDecisions: costlyDecisions
        ),
        trendDirection: trend,
        focusDifficulty: focusDifficulty,
        focusAccuracyPercent: focusAccuracyPercent,
        focusAverageExpectedImpact: focusAverageExpectedImpact,
        highestAttemptedDifficulty: highestAttemptedDifficulty
    )
}

private func projectedOption(
    card: PlayingCard,
    rank: Int,
    isExpertChoice: Bool = false,
    expectedImpact: Int = 4,
    projectedTeamPoints: Int = 40,
    outcome: WhatToPlayOptionOutcome = .developsTrick
) -> WhatToPlayOption {
    WhatToPlayOption(
        card: card,
        rank: rank,
        score: 0,
        isExpertChoice: isExpertChoice,
        expectedImpact: expectedImpact,
        projectedTeamPoints: projectedTeamPoints,
        impactBreakdown: WhatToPlayOptionImpactBreakdown(
            playedCardPoints: 0,
            immediateImpact: 0,
            trickPointsSwing: 0,
            completesTrick: false,
            winsForPlayerTeam: nil,
            preservesLead: false
        ),
        simulation: WhatToPlayOptionSimulation(
            phaseAfterPlay: .playing,
            currentTrickCardCount: 1,
            completedTrickWinnerID: nil,
            completedTrickWinnerTeamID: nil,
            completedTrickWonByPlayerTeam: nil,
            completedTrickPoints: 0,
            nextTurnPlayerID: nil,
            playerRemainingCards: 7,
            actionHistoryCount: 1
        ),
        outcome: outcome,
        outcomeReason: "",
        explanation: ""
    )
}

private func summaryCategory(
    _ option: WhatToPlayOption,
    lost: Int,
    projected: Int,
    secondProjected: Int = 0
) -> WhatToPlayOptionTacticalSummaryCategory {
    WhatToPlayOptionTacticalSummaryMetrics.classify(
        option: option,
        lostExpectedPoints: lost,
        lostProjectedTeamPoints: projected,
        lostProjectedAgainstSecondBestPoints: secondProjected
    ).category
}

private func decisionPatternSample(
    correct: Bool,
    impact: Int,
    rank: Int? = nil,
    breakdown: WhatToPlayOptionImpactBreakdown? = nil
) -> WhatToPlayDecisionPatternSample {
    WhatToPlayDecisionPatternSample(
        isCorrect: correct,
        selectedRank: rank,
        expectedImpact: impact,
        impactBreakdown: breakdown
    )
}

private func reviewQueueRank(
    lostExpectedPoints: Int,
    lostProjectedTeamPoints: Int,
    lostProjectedAgainstSecondBestPoints: Int = 0,
    expectedImpact: Int,
    createdAt: Date
) -> WhatToPlayReviewQueueRankMetrics {
    WhatToPlayReviewQueueRankMetrics(
        lostExpectedPoints: lostExpectedPoints,
        lostProjectedTeamPoints: lostProjectedTeamPoints,
        lostProjectedAgainstSecondBestPoints: lostProjectedAgainstSecondBestPoints,
        expectedImpact: expectedImpact,
        createdAt: createdAt
    )
}

private func trainingPriorityRank(
    lostExpectedPoints: Int,
    lostProjectedTeamPoints: Int,
    lostProjectedAgainstSecondBestPoints: Int = 0,
    accuracyPercent: Int,
    averageExpectedImpact: Int,
    stableOrder: Int
) -> WhatToPlayTrainingPriorityRankMetrics {
    WhatToPlayTrainingPriorityRankMetrics(
        lostExpectedPoints: lostExpectedPoints,
        lostProjectedTeamPoints: lostProjectedTeamPoints,
        lostProjectedAgainstSecondBestPoints: lostProjectedAgainstSecondBestPoints,
        accuracyPercent: accuracyPercent,
        averageExpectedImpact: averageExpectedImpact,
        stableOrder: stableOrder
    )
}

private func nextStep(
    progress: WhatToPlayTrainingSessionProgressCategory,
    remainingAttempts: Int = 0,
    correctNeeded: Int = 0,
    accuracyMet: Bool = false,
    impactMet: Bool = false,
    costlyMet: Bool = true,
    averageLostExpectedPoints: Int = 0,
    averageLostProjectedTeamPoints: Int = 0,
    averageProjectedSecondBestGap: Int = 0
) -> WhatToPlayTrainingSessionNextStepMetrics {
    WhatToPlayTrainingSessionNextStepMetrics.classify(
        progressCategory: progress,
        remainingAttempts: remainingAttempts,
        correctAttemptsNeededForTarget: correctNeeded,
        accuracyTargetMet: accuracyMet,
        impactTargetMet: impactMet,
        costlyDecisionTargetMet: costlyMet,
        averageLostExpectedPoints: averageLostExpectedPoints,
        averageLostProjectedTeamPoints: averageLostProjectedTeamPoints,
        averageProjectedSecondBestGap: averageProjectedSecondBestGap
    )
}

private func microDrill(
    pulse: WhatToPlaySessionPulseState = .focused,
    hasSimulationReview: Bool = false,
    hasHighValueReview: Bool = false,
    trackedDecisionQualityAttempts: Int = 0,
    costlyDecisionPercent: Int = 0,
    isDifficultyCoverageBalanced: Bool = true,
    isFocusCoverageBalanced: Bool = true,
    isGameModeCoverageBalanced: Bool = true,
    hasTrumpSuitSamples: Bool = false,
    isTrumpSuitCoverageBalanced: Bool = true,
    isMasterySharp: Bool = false
) -> WhatToPlayMicroDrillMetrics {
    WhatToPlayMicroDrillMetrics.classify(
        pulseState: pulse,
        hasSimulationReview: hasSimulationReview,
        hasHighValueReview: hasHighValueReview,
        trackedDecisionQualityAttempts: trackedDecisionQualityAttempts,
        costlyDecisionPercent: costlyDecisionPercent,
        isDifficultyCoverageBalanced: isDifficultyCoverageBalanced,
        isFocusCoverageBalanced: isFocusCoverageBalanced,
        isGameModeCoverageBalanced: isGameModeCoverageBalanced,
        hasTrumpSuitSamples: hasTrumpSuitSamples,
        isTrumpSuitCoverageBalanced: isTrumpSuitCoverageBalanced,
        isMasterySharp: isMasterySharp
    )
}

private func scenarioBrief(
    focus: WhatToPlayScenarioFocusKind,
    requiredSuit: Suit? = nil,
    trumpSuit: Suit? = nil,
    hasTrumpInCurrentTrick: Bool = false,
    legalOptionCount: Int = 4
) -> WhatToPlayScenarioBriefMetrics {
    WhatToPlayScenarioBriefMetrics.classify(
        context: WhatToPlayScenarioContext(
            trickNumber: 1,
            isLeading: focus == .openingLead,
            requiredSuit: requiredSuit,
            playedCardCount: requiredSuit == nil ? 0 : 1,
            legalOptionCount: legalOptionCount,
            mode: trumpSuit == nil ? .sun : .hokum,
            trumpSuit: trumpSuit,
            hasTrumpInCurrentTrick: hasTrumpInCurrentTrick,
            focusKind: focus
        )
    )
}

private func reviewFocus(
    _ focus: WhatToPlayScenarioFocusKind
) -> WhatToPlayDecisionReviewFocusStepMetrics {
    WhatToPlayDecisionReviewFocusStepMetrics.classify(focusKind: focus)
}

private func reviewInsight(
    _ insight: WhatToPlayDecisionInsightCategory
) -> WhatToPlayDecisionReviewInsightStepMetrics {
    WhatToPlayDecisionReviewInsightStepMetrics.classify(insightCategory: insight)
}

private func successFocus(
    _ focus: WhatToPlayScenarioFocusKind
) -> WhatToPlayFocusSuccessActionMetrics {
    WhatToPlayFocusSuccessActionMetrics.classify(focusKind: focus)
}

private func performanceTrendSamples(
    previousCorrect: Int,
    recentCorrect: Int
) -> [WhatToPlayStatsSample] {
    let previous = (0..<3).map { index in
        WhatToPlayStatsSample(
            isCorrect: index < previousCorrect,
            expectedImpact: index < previousCorrect ? 3 : -3
        )
    }
    let recent = (0..<3).map { index in
        WhatToPlayStatsSample(
            isCorrect: index < recentCorrect,
            expectedImpact: index < recentCorrect ? 3 : -3
        )
    }
    return previous + recent
}

private func coachingSummary(
    attempts: Int,
    accuracyPercent: Int = 0,
    averageExpectedImpact: Int = 0,
    currentStreak: Int = 0,
    projectedSecondBestComparisonAttempts: Int = 0,
    lostProjectedAgainstSecondBestPoints: Int = 0,
    averageProjectedSecondBestGap: Int = 0
) -> WhatToPlayStatsSummaryMetrics {
    WhatToPlayStatsSummaryMetrics(
        attempts: attempts,
        correct: 0,
        accuracyPercent: accuracyPercent,
        currentStreak: currentStreak,
        bestStreak: currentStreak,
        averageExpectedImpact: averageExpectedImpact,
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
        projectedSecondBestComparisonAttempts: projectedSecondBestComparisonAttempts,
        lostProjectedAgainstSecondBestPoints: lostProjectedAgainstSecondBestPoints,
        averageProjectedSecondBestGap: averageProjectedSecondBestGap
    )
}

private extension WhatToPlayOptionImpactBreakdown {
    static func opponentTrickClosure(points: Int) -> WhatToPlayOptionImpactBreakdown {
        WhatToPlayOptionImpactBreakdown(
            playedCardPoints: points,
            immediateImpact: -points,
            trickPointsSwing: -points,
            completesTrick: true,
            winsForPlayerTeam: false,
            preservesLead: false
        )
    }

    static func unprotectedPointDump(points: Int) -> WhatToPlayOptionImpactBreakdown {
        WhatToPlayOptionImpactBreakdown(
            playedCardPoints: points,
            immediateImpact: -points,
            trickPointsSwing: 0,
            completesTrick: false,
            winsForPlayerTeam: nil,
            preservesLead: false
        )
    }

    static func costlyOpeningLead(points: Int) -> WhatToPlayOptionImpactBreakdown {
        WhatToPlayOptionImpactBreakdown(
            playedCardPoints: points,
            immediateImpact: -max(1, points),
            trickPointsSwing: 0,
            completesTrick: false,
            winsForPlayerTeam: nil,
            preservesLead: true
        )
    }
}
