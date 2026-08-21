import Foundation
import BalootEngine

enum WhatToPlayScenarioLoader {
    enum ScenarioCodeError: Error, Equatable {
        case invalidCode
    }

    static func unattemptedSeed(
        startingAt seed: UInt64,
        difficulty: WhatToPlayDifficulty,
        preferredFocus: WhatToPlayScenarioFocusKind?,
        preferredMode: GameMode? = nil,
        preferredTrumpSuit: Suit? = nil,
        attempts: [WhatToPlayAttempt]
    ) -> UInt64 {
        let normalizedTrumpSuit = preferredMode == .hokum ? preferredTrumpSuit : nil
        let attemptedSeeds = attemptedScenarioSeeds(
            difficulty: difficulty,
            preferredFocus: preferredFocus,
            preferredMode: preferredMode,
            preferredTrumpSuit: normalizedTrumpSuit,
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
        preferredTrumpSuit: Suit? = nil,
        attempts: [WhatToPlayAttempt]
    ) -> UInt64 {
        unattemptedSeed(
            startingAt: seed &+ 1,
            difficulty: difficulty,
            preferredFocus: preferredFocus,
            preferredMode: preferredMode,
            preferredTrumpSuit: preferredTrumpSuit,
            attempts: attempts
        )
    }

    private static func attemptedScenarioSeeds(
        difficulty: WhatToPlayDifficulty,
        preferredFocus: WhatToPlayScenarioFocusKind?,
        preferredMode: GameMode?,
        preferredTrumpSuit: Suit?,
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
                .filter { attempt in
                    guard let preferredTrumpSuit else { return true }
                    return attempt.contextTrumpSuit == preferredTrumpSuit
                }
                .map(\.replaySeed)
        )
        return attemptedSeeds
    }

    static func generate(
        seed: UInt64,
        difficulty: WhatToPlayDifficulty,
        preferredFocus: WhatToPlayScenarioFocusKind? = nil,
        preferredMode: GameMode? = nil,
        preferredTrumpSuit: Suit? = nil
    ) async throws -> WhatToPlayScenario {
        let normalizedTrumpSuit = preferredMode == .hokum ? preferredTrumpSuit : nil
        return try await Task.detached(priority: .userInitiated) {
            try WhatToPlayTrainer.generateScenario(
                seed: seed,
                difficulty: difficulty,
                preferredFocus: preferredFocus,
                preferredMode: preferredMode,
                preferredTrumpSuit: normalizedTrumpSuit
            )
        }.value
    }

    static func generate(code: String) async throws -> WhatToPlayScenario {
        guard let extractedCode = WhatToPlayScenarioCode.extractCode(from: code),
              let parsed = WhatToPlayScenarioCode.parse(extractedCode)
        else {
            throw ScenarioCodeError.invalidCode
        }

        return try await generate(
            seed: parsed.seed,
            difficulty: parsed.difficulty,
            preferredFocus: parsed.focusKind,
            preferredMode: parsed.gameMode,
            preferredTrumpSuit: parsed.trumpSuit
        )
    }
}
