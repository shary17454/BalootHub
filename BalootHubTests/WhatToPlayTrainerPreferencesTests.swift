import XCTest
import BalootEngine
@testable import BalootHub

final class WhatToPlayTrainerPreferencesTests: XCTestCase {
    func testPreferencesRoundTrip() {
        let defaults = UserDefaults(suiteName: "WhatToPlayTrainerPreferencesTests.roundTrip")!
        WhatToPlayTrainerPreferences.clear(from: defaults)

        WhatToPlayTrainerPreferences.save(
            difficulty: .hard,
            preferredFocus: .trumpPressure,
            to: defaults
        )

        XCTAssertEqual(
            WhatToPlayTrainerPreferences.load(from: defaults),
            WhatToPlayTrainerPreferences(difficulty: .hard, preferredFocus: .trumpPressure)
        )

        WhatToPlayTrainerPreferences.clear(from: defaults)
    }

    func testPreferencesRemoveAutomaticFocus() {
        let defaults = UserDefaults(suiteName: "WhatToPlayTrainerPreferencesTests.autoFocus")!
        WhatToPlayTrainerPreferences.clear(from: defaults)

        WhatToPlayTrainerPreferences.save(difficulty: .easy, preferredFocus: .followSuit, to: defaults)
        WhatToPlayTrainerPreferences.save(difficulty: .medium, preferredFocus: nil, to: defaults)

        XCTAssertEqual(
            WhatToPlayTrainerPreferences.load(from: defaults),
            WhatToPlayTrainerPreferences(difficulty: .medium, preferredFocus: nil)
        )

        WhatToPlayTrainerPreferences.clear(from: defaults)
    }

    func testPreferencesIgnoreInvalidStoredValues() {
        let defaults = UserDefaults(suiteName: "WhatToPlayTrainerPreferencesTests.invalid")!
        WhatToPlayTrainerPreferences.clear(from: defaults)
        defaults.set("legendary", forKey: "whatToPlayTrainerDifficulty")
        defaults.set("unknownFocus", forKey: "whatToPlayTrainerFocus")

        XCTAssertEqual(WhatToPlayTrainerPreferences.load(from: defaults), .defaults)

        WhatToPlayTrainerPreferences.clear(from: defaults)
    }
}
