import Foundation
import BalootEngine

struct WhatToPlayTrainerPreferences: Equatable {
    private static let difficultyKey = "whatToPlayTrainerDifficulty"
    private static let focusKey = "whatToPlayTrainerFocus"
    private static let modeKey = "whatToPlayTrainerMode"
    private static let trumpSuitKey = "whatToPlayTrainerTrumpSuit"

    let difficulty: WhatToPlayDifficulty
    let preferredFocus: WhatToPlayScenarioFocusKind?
    let preferredMode: GameMode?
    let preferredTrumpSuit: Suit?

    static let defaults = WhatToPlayTrainerPreferences(
        difficulty: .medium,
        preferredFocus: nil,
        preferredMode: nil,
        preferredTrumpSuit: nil
    )

    static func load(from defaults: UserDefaults = .standard) -> WhatToPlayTrainerPreferences {
        let difficulty = defaults.string(forKey: difficultyKey)
            .flatMap(WhatToPlayDifficulty.init(rawValue:)) ?? Self.defaults.difficulty
        let preferredFocus = defaults.string(forKey: focusKey)
            .flatMap(WhatToPlayScenarioFocusKind.init(rawValue:))
        let preferredMode = defaults.string(forKey: modeKey)
            .flatMap(GameMode.init(rawValue:))
        let preferredTrumpSuit = defaults.string(forKey: trumpSuitKey)
            .flatMap { Int($0) }
            .flatMap { ordinal in Suit.allCases.first { $0.ordinal == ordinal } }

        return WhatToPlayTrainerPreferences(
            difficulty: difficulty,
            preferredFocus: preferredFocus,
            preferredMode: preferredMode,
            preferredTrumpSuit: preferredMode == .hokum ? preferredTrumpSuit : nil
        )
    }

    static func save(
        difficulty: WhatToPlayDifficulty,
        preferredFocus: WhatToPlayScenarioFocusKind?,
        preferredMode: GameMode?,
        preferredTrumpSuit: Suit? = nil,
        to defaults: UserDefaults = .standard
    ) {
        defaults.set(difficulty.rawValue, forKey: difficultyKey)
        if let preferredFocus {
            defaults.set(preferredFocus.rawValue, forKey: focusKey)
        } else {
            defaults.removeObject(forKey: focusKey)
        }
        if let preferredMode {
            defaults.set(preferredMode.rawValue, forKey: modeKey)
        } else {
            defaults.removeObject(forKey: modeKey)
        }
        if preferredMode == .hokum, let preferredTrumpSuit {
            defaults.set(String(preferredTrumpSuit.ordinal), forKey: trumpSuitKey)
        } else {
            defaults.removeObject(forKey: trumpSuitKey)
        }
    }

    static func clear(from defaults: UserDefaults) {
        defaults.removeObject(forKey: difficultyKey)
        defaults.removeObject(forKey: focusKey)
        defaults.removeObject(forKey: modeKey)
        defaults.removeObject(forKey: trumpSuitKey)
    }
}
