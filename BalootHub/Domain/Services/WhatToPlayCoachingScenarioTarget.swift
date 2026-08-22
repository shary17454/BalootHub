import BalootEngine
import Foundation

struct WhatToPlayCoachingScenarioTarget: Equatable {
    let seed: UInt64
    let difficulty: WhatToPlayDifficulty
    let focusKind: WhatToPlayScenarioFocusKind?
    let gameMode: GameMode?
    let trumpSuit: Suit?

    var focusRawValue: String {
        focusKind?.rawValue ?? "auto"
    }

    var gameModeRawValue: String {
        gameMode?.rawValue ?? "auto"
    }

    static func make(
        from tip: WhatToPlayCoachingTip,
        after currentSeed: UInt64,
        fallbackDifficulty: WhatToPlayDifficulty,
        attempts: [WhatToPlayAttempt]
    ) -> WhatToPlayCoachingScenarioTarget? {
        guard tip.hasActionableTarget else { return nil }

        let difficulty = tip.targetDifficulty ?? fallbackDifficulty
        let focusKind = tip.targetFocusKind
        let gameMode = tip.targetGameMode
        let trumpSuit = tip.targetTrumpSuit
        let seed = WhatToPlayScenarioLoader.nextUnattemptedSeed(
            after: currentSeed,
            difficulty: difficulty,
            preferredFocus: focusKind,
            preferredMode: gameMode,
            preferredTrumpSuit: trumpSuit,
            attempts: attempts
        )

        return WhatToPlayCoachingScenarioTarget(
            seed: seed,
            difficulty: difficulty,
            focusKind: focusKind,
            gameMode: gameMode,
            trumpSuit: trumpSuit
        )
    }

    static func make(
        from pattern: WhatToPlayDecisionPattern,
        after currentSeed: UInt64,
        fallbackDifficulty: WhatToPlayDifficulty,
        attempts: [WhatToPlayAttempt]
    ) -> WhatToPlayCoachingScenarioTarget? {
        guard pattern.hasActionableTarget else { return nil }

        let difficulty = pattern.targetDifficulty ?? fallbackDifficulty
        let focusKind = pattern.targetFocusKind
        let gameMode = pattern.targetGameMode
        let trumpSuit = pattern.targetTrumpSuit
        let seed = WhatToPlayScenarioLoader.nextUnattemptedSeed(
            after: currentSeed,
            difficulty: difficulty,
            preferredFocus: focusKind,
            preferredMode: gameMode,
            preferredTrumpSuit: trumpSuit,
            attempts: attempts
        )

        return WhatToPlayCoachingScenarioTarget(
            seed: seed,
            difficulty: difficulty,
            focusKind: focusKind,
            gameMode: gameMode,
            trumpSuit: trumpSuit
        )
    }
}
