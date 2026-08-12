import Foundation
import BalootEngine

struct WhatToPlayTrainerPreferences: Equatable {
    private static let difficultyKey = "whatToPlayTrainerDifficulty"
    private static let focusKey = "whatToPlayTrainerFocus"

    let difficulty: WhatToPlayDifficulty
    let preferredFocus: WhatToPlayScenarioFocusKind?

    static let defaults = WhatToPlayTrainerPreferences(difficulty: .medium, preferredFocus: nil)

    static func load(from defaults: UserDefaults = .standard) -> WhatToPlayTrainerPreferences {
        let difficulty = defaults.string(forKey: difficultyKey)
            .flatMap(WhatToPlayDifficulty.init(rawValue:)) ?? Self.defaults.difficulty
        let preferredFocus = defaults.string(forKey: focusKey)
            .flatMap(WhatToPlayScenarioFocusKind.init(rawValue:))

        return WhatToPlayTrainerPreferences(difficulty: difficulty, preferredFocus: preferredFocus)
    }

    static func save(
        difficulty: WhatToPlayDifficulty,
        preferredFocus: WhatToPlayScenarioFocusKind?,
        to defaults: UserDefaults = .standard
    ) {
        defaults.set(difficulty.rawValue, forKey: difficultyKey)
        if let preferredFocus {
            defaults.set(preferredFocus.rawValue, forKey: focusKey)
        } else {
            defaults.removeObject(forKey: focusKey)
        }
    }

    static func clear(from defaults: UserDefaults) {
        defaults.removeObject(forKey: difficultyKey)
        defaults.removeObject(forKey: focusKey)
    }
}
