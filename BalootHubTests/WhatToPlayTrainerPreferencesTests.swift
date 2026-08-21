import XCTest
import BalootEngine
@testable import BalootHub

final class WhatToPlayTrainerPreferencesTests: XCTestCase {
    func testPreferencesRoundTrip() {
        let defaults = UserDefaults(suiteName: "WhatToPlayTrainerPreferencesTests.roundTrip")!
        WhatToPlayTrainerPreferences.clear(from: defaults)

        WhatToPlayTrainerPreferences.save(
            difficulty: .expert,
            preferredFocus: .trumpPressure,
            preferredMode: .hokum,
            to: defaults
        )

        XCTAssertEqual(
            WhatToPlayTrainerPreferences.load(from: defaults),
            WhatToPlayTrainerPreferences(
                difficulty: .expert,
                preferredFocus: .trumpPressure,
                preferredMode: .hokum,
                preferredTrumpSuit: nil
            )
        )

        WhatToPlayTrainerPreferences.clear(from: defaults)
    }

    func testPreferencesRoundTripHokumTrumpSuit() {
        let defaults = UserDefaults(suiteName: "WhatToPlayTrainerPreferencesTests.trumpSuitRoundTrip")!
        WhatToPlayTrainerPreferences.clear(from: defaults)

        WhatToPlayTrainerPreferences.save(
            difficulty: .hard,
            preferredFocus: .trumpPressure,
            preferredMode: .hokum,
            preferredTrumpSuit: .spades,
            to: defaults
        )

        XCTAssertEqual(
            WhatToPlayTrainerPreferences.load(from: defaults),
            WhatToPlayTrainerPreferences(
                difficulty: .hard,
                preferredFocus: .trumpPressure,
                preferredMode: .hokum,
                preferredTrumpSuit: .spades
            )
        )

        WhatToPlayTrainerPreferences.clear(from: defaults)
    }

    func testPreferencesRemoveAutomaticFocus() {
        let defaults = UserDefaults(suiteName: "WhatToPlayTrainerPreferencesTests.autoFocus")!
        WhatToPlayTrainerPreferences.clear(from: defaults)

        WhatToPlayTrainerPreferences.save(
            difficulty: .easy,
            preferredFocus: .followSuit,
            preferredMode: .hokum,
            preferredTrumpSuit: .hearts,
            to: defaults
        )
        WhatToPlayTrainerPreferences.save(
            difficulty: .medium,
            preferredFocus: nil,
            preferredMode: nil,
            preferredTrumpSuit: .hearts,
            to: defaults
        )

        XCTAssertEqual(
            WhatToPlayTrainerPreferences.load(from: defaults),
            WhatToPlayTrainerPreferences(
                difficulty: .medium,
                preferredFocus: nil,
                preferredMode: nil,
                preferredTrumpSuit: nil
            )
        )

        WhatToPlayTrainerPreferences.clear(from: defaults)
    }

    func testPreferencesIgnoreTrumpSuitOutsideHokumMode() {
        let defaults = UserDefaults(suiteName: "WhatToPlayTrainerPreferencesTests.sunTrumpSuit")!
        WhatToPlayTrainerPreferences.clear(from: defaults)

        WhatToPlayTrainerPreferences.save(
            difficulty: .medium,
            preferredFocus: nil,
            preferredMode: .sun,
            preferredTrumpSuit: .clubs,
            to: defaults
        )

        XCTAssertEqual(
            WhatToPlayTrainerPreferences.load(from: defaults),
            WhatToPlayTrainerPreferences(
                difficulty: .medium,
                preferredFocus: nil,
                preferredMode: .sun,
                preferredTrumpSuit: nil
            )
        )

        WhatToPlayTrainerPreferences.clear(from: defaults)
    }

    func testPreferencesIgnoreInvalidStoredValues() {
        let defaults = UserDefaults(suiteName: "WhatToPlayTrainerPreferencesTests.invalid")!
        WhatToPlayTrainerPreferences.clear(from: defaults)
        defaults.set("legendary", forKey: "whatToPlayTrainerDifficulty")
        defaults.set("unknownFocus", forKey: "whatToPlayTrainerFocus")
        defaults.set("unknownMode", forKey: "whatToPlayTrainerMode")
        defaults.set("99", forKey: "whatToPlayTrainerTrumpSuit")

        XCTAssertEqual(WhatToPlayTrainerPreferences.load(from: defaults), .defaults)

        WhatToPlayTrainerPreferences.clear(from: defaults)
    }
}
