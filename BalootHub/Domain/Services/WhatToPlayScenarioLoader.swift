import Foundation
import BalootEngine

enum WhatToPlayScenarioLoader {
    static func nextUnattemptedSeed(
        after seed: UInt64,
        difficulty: WhatToPlayDifficulty,
        preferredFocus: WhatToPlayScenarioFocusKind?,
        attempts: [WhatToPlayAttempt]
    ) -> UInt64 {
        let attemptedSeeds = Set(
            attempts
                .filter { $0.difficulty == difficulty }
                .filter { attempt in
                    guard let preferredFocus else { return true }
                    return attempt.focusKind == preferredFocus
                }
                .map(\.replaySeed)
        )

        var candidate = seed &+ 1
        while attemptedSeeds.contains(candidate) {
            candidate &+= 1
        }
        return candidate
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
