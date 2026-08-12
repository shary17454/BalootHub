import Foundation
import BalootEngine

enum WhatToPlayScenarioLoader {
    static func unattemptedSeed(
        startingAt seed: UInt64,
        difficulty: WhatToPlayDifficulty,
        preferredFocus: WhatToPlayScenarioFocusKind?,
        attempts: [WhatToPlayAttempt]
    ) -> UInt64 {
        let attemptedSeeds = attemptedScenarioSeeds(
            difficulty: difficulty,
            preferredFocus: preferredFocus,
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
        attempts: [WhatToPlayAttempt]
    ) -> UInt64 {
        unattemptedSeed(
            startingAt: seed &+ 1,
            difficulty: difficulty,
            preferredFocus: preferredFocus,
            attempts: attempts
        )
    }

    private static func attemptedScenarioSeeds(
        difficulty: WhatToPlayDifficulty,
        preferredFocus: WhatToPlayScenarioFocusKind?,
        attempts: [WhatToPlayAttempt]
    ) -> Set<UInt64> {
        let attemptedSeeds = Set(
            attempts
                .filter { $0.difficulty == difficulty }
                .filter { attempt in
                    guard let preferredFocus else { return true }
                    return attempt.focusKind == preferredFocus
                }
                .map(\.replaySeed)
        )
        return attemptedSeeds
    }

    static func generate(
        seed: UInt64,
        difficulty: WhatToPlayDifficulty,
        preferredFocus: WhatToPlayScenarioFocusKind? = nil
    ) async throws -> WhatToPlayScenario {
        try await Task.detached(priority: .userInitiated) {
            try WhatToPlayTrainer.generateScenario(
                seed: seed,
                difficulty: difficulty,
                preferredFocus: preferredFocus
            )
        }.value
    }
}
