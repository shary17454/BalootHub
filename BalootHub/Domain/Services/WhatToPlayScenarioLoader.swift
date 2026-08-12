import Foundation
import BalootEngine

enum WhatToPlayScenarioLoader {
    static func unattemptedSeed(
        startingAt seed: UInt64,
        difficulty: WhatToPlayDifficulty,
        preferredFocus: WhatToPlayScenarioFocusKind?,
        preferredMode: GameMode? = nil,
        attempts: [WhatToPlayAttempt]
    ) -> UInt64 {
        let attemptedSeeds = attemptedScenarioSeeds(
            difficulty: difficulty,
            preferredFocus: preferredFocus,
            preferredMode: preferredMode,
            attempts: attempts
        )

        var candidate = seed
        while attemptedSeeds.contains(candidate) {
            candidate &+= 1
        }
        return candidate
    }

    static func nextUnattemptedSeed(
        after seed: UInt64,
        difficulty: WhatToPlayDifficulty,
        preferredFocus: WhatToPlayScenarioFocusKind?,
        preferredMode: GameMode? = nil,
        attempts: [WhatToPlayAttempt]
    ) -> UInt64 {
        unattemptedSeed(
            startingAt: seed &+ 1,
            difficulty: difficulty,
            preferredFocus: preferredFocus,
            preferredMode: preferredMode,
            attempts: attempts
        )
    }

    private static func attemptedScenarioSeeds(
        difficulty: WhatToPlayDifficulty,
        preferredFocus: WhatToPlayScenarioFocusKind?,
        preferredMode: GameMode?,
        attempts: [WhatToPlayAttempt]
    ) -> Set<UInt64> {
        let attemptedSeeds = Set(
            attempts
                .filter { $0.difficulty == difficulty }
                .filter { attempt in
                    guard let preferredFocus else { return true }
                    return attempt.focusKind == preferredFocus
                }
                .filter { attempt in
                    guard let preferredMode else { return true }
                    return attempt.gameMode == preferredMode
                }
                .map(\.replaySeed)
        )
        return attemptedSeeds
    }

    static func generate(
        seed: UInt64,
        difficulty: WhatToPlayDifficulty,
        preferredFocus: WhatToPlayScenarioFocusKind? = nil,
        preferredMode: GameMode? = nil
    ) async throws -> WhatToPlayScenario {
        try await Task.detached(priority: .userInitiated) {
            try WhatToPlayTrainer.generateScenario(
                seed: seed,
                difficulty: difficulty,
                preferredFocus: preferredFocus,
                preferredMode: preferredMode
            )
        }.value
    }
}
