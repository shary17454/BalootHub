import Foundation
import BalootEngine

struct WhatToPlayTrainerPreferences: Equatable {
    private static let difficultyKey = "whatToPlayTrainerDifficulty"
    private static let focusKey = "whatToPlayTrainerFocus"
    private static let modeKey = "whatToPlayTrainerMode"

    let difficulty: WhatToPlayDifficulty
    let preferredFocus: WhatToPlayScenarioFocusKind?
    let preferredMode: GameMode?

    static let defaults = WhatToPlayTrainerPreferences(difficulty: .medium, preferredFocus: nil, preferredMode: nil)

    static func load(from defaults: UserDefaults = .standard) -> WhatToPlayTrainerPreferences {
        let difficulty = defaults.string(forKey: difficultyKey)
            .flatMap(WhatToPlayDifficulty.init(rawValue:)) ?? Self.defaults.difficulty
        let preferredFocus = defaults.string(forKey: focusKey)
            .flatMap(WhatToPlayScenarioFocusKind.init(rawValue:))
        let preferredMode = defaults.string(forKey: modeKey)
            .flatMap(GameMode.init(rawValue:))

        return WhatToPlayTrainerPreferences(difficulty: difficulty, preferredFocus: preferredFocus, preferredMode: preferredMode)
    }

    static func save(
        difficulty: WhatToPlayDifficulty,
        preferredFocus: WhatToPlayScenarioFocusKind?,
        preferredMode: GameMode?,
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
    }

    static func clear(from defaults: UserDefaults) {
        defaults.removeObject(forKey: difficultyKey)
        defaults.removeObject(forKey: focusKey)
        defaults.removeObject(forKey: modeKey)
    }
}
