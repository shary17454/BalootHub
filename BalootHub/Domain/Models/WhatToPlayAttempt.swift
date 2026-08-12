import Foundation
import SwiftData
import BalootEngine

@Model
final class WhatToPlayAttempt {
    var id: UUID
    var createdAt: Date
    var difficultyRaw: String
    var seedValue: Int64
    var seedRaw: String?
    var selectedSuitRaw: String
    var selectedRankRaw: String
    var bestSuitRaw: String
    var bestRankRaw: String
    var secondBestSuitRaw: String?
    var secondBestRankRaw: String?
    var isCorrect: Bool
    var selectedRank: Int?
    var expectedImpact: Int
    var bestExpectedImpact: Int?
    var secondBestExpectedImpact: Int?
    var focusKindRaw: String?
    var outcomeRaw: String?
    var selectedCardPoints: Int?
    var selectedImmediateImpact: Int?
    var selectedTrickPointsSwing: Int?
    var selectedCompletesTrick: Bool?
    var selectedWinsForPlayerTeam: Bool?
    var selectedPreservesLead: Bool?
    var simulationPhaseAfterPlayRaw: String?
    var simulationCurrentTrickCardCount: Int?
    var simulationCompletedTrickWonByPlayerTeam: Bool?
    var simulationCompletedTrickPoints: Int?
    var simulationNextTurnPlayerIDRaw: String?
    var simulationPlayerRemainingCards: Int?
    var simulationActionHistoryCount: Int?

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        difficulty: WhatToPlayDifficulty,
        seed: UInt64,
        selectedCard: PlayingCard,
        bestCard: PlayingCard,
        secondBestCard: PlayingCard? = nil,
        isCorrect: Bool,
        selectedRank: Int? = nil,
        expectedImpact: Int,
        bestExpectedImpact: Int? = nil,
        secondBestExpectedImpact: Int? = nil,
        focusKind: WhatToPlayScenarioFocusKind? = nil,
        outcome: WhatToPlayOptionOutcome? = nil,
        impactBreakdown: WhatToPlayOptionImpactBreakdown? = nil,
        simulation: WhatToPlayOptionSimulation? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.difficultyRaw = difficulty.rawValue
        self.seedValue = Int64(clamping: seed)
        self.seedRaw = String(seed)
        self.selectedSuitRaw = selectedCard.suit.rawValue
        self.selectedRankRaw = selectedCard.rank.rawValue
        self.bestSuitRaw = bestCard.suit.rawValue
        self.bestRankRaw = bestCard.rank.rawValue
        self.secondBestSuitRaw = secondBestCard?.suit.rawValue
        self.secondBestRankRaw = secondBestCard?.rank.rawValue
        self.isCorrect = isCorrect
        self.selectedRank = selectedRank
        self.expectedImpact = expectedImpact
        self.bestExpectedImpact = bestExpectedImpact
        self.secondBestExpectedImpact = secondBestExpectedImpact
        self.focusKindRaw = focusKind?.rawValue
        self.outcomeRaw = outcome?.rawValue
        self.selectedCardPoints = impactBreakdown?.playedCardPoints
        self.selectedImmediateImpact = impactBreakdown?.immediateImpact
        self.selectedTrickPointsSwing = impactBreakdown?.trickPointsSwing
        self.selectedCompletesTrick = impactBreakdown?.completesTrick
        self.selectedWinsForPlayerTeam = impactBreakdown?.winsForPlayerTeam
        self.selectedPreservesLead = impactBreakdown?.preservesLead
        self.simulationPhaseAfterPlayRaw = simulation?.phaseAfterPlay.rawValue
        self.simulationCurrentTrickCardCount = simulation?.currentTrickCardCount
        self.simulationCompletedTrickWonByPlayerTeam = simulation?.completedTrickWonByPlayerTeam
        self.simulationCompletedTrickPoints = simulation?.completedTrickWinnerID == nil
            ? nil
            : simulation?.completedTrickPoints
        self.simulationNextTurnPlayerIDRaw = simulation?.nextTurnPlayerID?.uuidString
        self.simulationPlayerRemainingCards = simulation?.playerRemainingCards
        self.simulationActionHistoryCount = simulation?.actionHistoryCount
    }

    var difficulty: WhatToPlayDifficulty {
        WhatToPlayDifficulty(rawValue: difficultyRaw) ?? .medium
    }

    /// البذرة الأصلية لإعادة توليد الموقف.
    ///
    /// `seedValue` بقي للتوافق مع المحاولات المحفوظة سابقًا، لكنه `Int64` وكان يضغط
    /// أي `UInt64` كبير عبر `clamping`. الحقل النصي يحفظ البذرة كاملة بلا فقدان.
    var replaySeed: UInt64 {
        if let seedRaw, let seed = UInt64(seedRaw) {
            return seed
        }
        return UInt64(clamping: seedValue)
    }

    var selectedCard: PlayingCard? {
        guard let suit = Suit(rawValue: selectedSuitRaw),
              let rank = Rank(rawValue: selectedRankRaw)
        else { return nil }
        return PlayingCard(suit: suit, rank: rank)
    }

    var bestCard: PlayingCard? {
        guard let suit = Suit(rawValue: bestSuitRaw),
              let rank = Rank(rawValue: bestRankRaw)
        else { return nil }
        return PlayingCard(suit: suit, rank: rank)
    }

    var secondBestCard: PlayingCard? {
        guard let secondBestSuitRaw,
              let secondBestRankRaw,
              let suit = Suit(rawValue: secondBestSuitRaw),
              let rank = Rank(rawValue: secondBestRankRaw)
        else { return nil }
        return PlayingCard(suit: suit, rank: rank)
    }

    var lostExpectedPoints: Int {
        guard let bestExpectedImpact else { return 0 }
        return max(0, bestExpectedImpact - expectedImpact)
    }

    var lostAgainstSecondBestPoints: Int {
        guard let secondBestExpectedImpact else { return 0 }
        return max(0, secondBestExpectedImpact - expectedImpact)
    }

    var decisionQuality: WhatToPlayDecisionQuality? {
        guard bestExpectedImpact != nil else { return nil }
        return WhatToPlayDecisionQuality.classify(
            isExpertChoice: isCorrect,
            lostExpectedPoints: lostExpectedPoints
        )
    }

    var focusKind: WhatToPlayScenarioFocusKind? {
        guard let focusKindRaw else { return nil }
        return WhatToPlayScenarioFocusKind(rawValue: focusKindRaw)
    }

    var outcome: WhatToPlayOptionOutcome? {
        guard let outcomeRaw else { return nil }
        return WhatToPlayOptionOutcome(rawValue: outcomeRaw)
    }

    var impactBreakdown: WhatToPlayOptionImpactBreakdown? {
        guard let selectedCardPoints,
              let selectedImmediateImpact,
              let selectedTrickPointsSwing,
              let selectedCompletesTrick,
              let selectedPreservesLead
        else { return nil }

        return WhatToPlayOptionImpactBreakdown(
            playedCardPoints: selectedCardPoints,
            immediateImpact: selectedImmediateImpact,
            trickPointsSwing: selectedTrickPointsSwing,
            completesTrick: selectedCompletesTrick,
            winsForPlayerTeam: selectedWinsForPlayerTeam,
            preservesLead: selectedPreservesLead
        )
    }

    var simulationPhaseAfterPlay: GamePhase? {
        guard let simulationPhaseAfterPlayRaw else { return nil }
        return GamePhase(rawValue: simulationPhaseAfterPlayRaw)
    }
}
