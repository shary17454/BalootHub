import XCTest
import BalootEngine
@testable import BalootHub

final class WhatToPlayScenarioLoaderTests: XCTestCase {
    func testUnattemptedSeedKeepsCurrentSeedWhenItWasNotSolvedForFilter() {
        let attempts = [
            attempt(seed: 2027, difficulty: .medium, focusKind: .openingLead)
        ]

        let seed = WhatToPlayScenarioLoader.unattemptedSeed(
            startingAt: 2026,
            difficulty: .medium,
            preferredFocus: .openingLead,
            attempts: attempts
        )

        XCTAssertEqual(seed, 2026)
    }

    func testUnattemptedSeedSkipsCurrentSeedWhenAlreadySolvedForFilter() {
        let attempts = [
            attempt(seed: 2026, difficulty: .medium, focusKind: .followSuit),
            attempt(seed: 2027, difficulty: .medium, focusKind: .followSuit)
        ]

        let seed = WhatToPlayScenarioLoader.unattemptedSeed(
            startingAt: 2026,
            difficulty: .medium,
            preferredFocus: .followSuit,
            attempts: attempts
        )

        XCTAssertEqual(seed, 2028)
    }

    func testNextUnattemptedSeedSkipsSolvedSeedsForDifficultyAndAutoFocus() {
        let attempts = [
            attempt(seed: 2027, difficulty: .medium, focusKind: .openingLead),
            attempt(seed: 2028, difficulty: .medium, focusKind: .followSuit),
            attempt(seed: 2029, difficulty: .hard, focusKind: .openingLead)
        ]

        let seed = WhatToPlayScenarioLoader.nextUnattemptedSeed(
            after: 2026,
            difficulty: .medium,
            preferredFocus: nil,
            attempts: attempts
        )

        XCTAssertEqual(seed, 2029)
    }

    func testNextUnattemptedSeedOnlySkipsMatchingFocusWhenFocusIsSelected() {
        let attempts = [
            attempt(seed: 2027, difficulty: .medium, focusKind: .openingLead),
            attempt(seed: 2028, difficulty: .medium, focusKind: .followSuit)
        ]

        let seed = WhatToPlayScenarioLoader.nextUnattemptedSeed(
            after: 2026,
            difficulty: .medium,
            preferredFocus: .followSuit,
            attempts: attempts
        )

        XCTAssertEqual(seed, 2027)
    }

    func testNextUnattemptedSeedIgnoresOtherDifficulties() {
        let attempts = [
            attempt(seed: 2027, difficulty: .hard, focusKind: .openingLead),
            attempt(seed: 2028, difficulty: .hard, focusKind: .openingLead)
        ]

        let seed = WhatToPlayScenarioLoader.nextUnattemptedSeed(
            after: 2026,
            difficulty: .medium,
            preferredFocus: .openingLead,
            attempts: attempts
        )

        XCTAssertEqual(seed, 2027)
    }

    func testUnattemptedSeedSeparatesAttemptsByPreferredMode() {
        let attempts = [
            attempt(seed: 2026, difficulty: .medium, focusKind: .openingLead, gameMode: .sun),
            attempt(seed: 2027, difficulty: .medium, focusKind: .openingLead, gameMode: .hokum)
        ]

        let hokumSeed = WhatToPlayScenarioLoader.unattemptedSeed(
            startingAt: 2026,
            difficulty: .medium,
            preferredFocus: .openingLead,
            preferredMode: .hokum,
            attempts: attempts
        )
        let sunSeed = WhatToPlayScenarioLoader.unattemptedSeed(
            startingAt: 2026,
            difficulty: .medium,
            preferredFocus: .openingLead,
            preferredMode: .sun,
            attempts: attempts
        )

        XCTAssertEqual(hokumSeed, 2026)
        XCTAssertEqual(sunSeed, 2027)
    }

    func testUnattemptedSeedSeparatesHokumAttemptsByPreferredTrumpSuit() {
        let attempts = [
            attempt(seed: 2026, difficulty: .medium, focusKind: .trumpPressure, gameMode: .hokum, trumpSuit: .hearts),
            attempt(seed: 2027, difficulty: .medium, focusKind: .trumpPressure, gameMode: .hokum, trumpSuit: .spades)
        ]

        let heartsSeed = WhatToPlayScenarioLoader.unattemptedSeed(
            startingAt: 2026,
            difficulty: .medium,
            preferredFocus: .trumpPressure,
            preferredMode: .hokum,
            preferredTrumpSuit: .hearts,
            attempts: attempts
        )
        let spadesSeed = WhatToPlayScenarioLoader.unattemptedSeed(
            startingAt: 2026,
            difficulty: .medium,
            preferredFocus: .trumpPressure,
            preferredMode: .hokum,
            preferredTrumpSuit: .spades,
            attempts: attempts
        )

        XCTAssertEqual(heartsSeed, 2027)
        XCTAssertEqual(spadesSeed, 2026)
    }

    func testUnattemptedSeedIgnoresTrumpSuitWhenPreferredModeIsSun() {
        let attempts = [
            attempt(seed: 2026, difficulty: .medium, focusKind: .openingLead, gameMode: .sun),
            attempt(seed: 2027, difficulty: .medium, focusKind: .openingLead, gameMode: .hokum, trumpSuit: .spades)
        ]

        let seed = WhatToPlayScenarioLoader.unattemptedSeed(
            startingAt: 2026,
            difficulty: .medium,
            preferredFocus: .openingLead,
            preferredMode: .sun,
            preferredTrumpSuit: .spades,
            attempts: attempts
        )

        XCTAssertEqual(seed, 2027)
    }

    func testLoaderGeneratesScenarioWithRequestedSeedAndDifficulty() async throws {
        let scenario = try await WhatToPlayScenarioLoader.generate(seed: 2026, difficulty: .medium)
        let repeated = try await WhatToPlayScenarioLoader.generate(seed: 2026, difficulty: .medium)

        XCTAssertGreaterThanOrEqual(scenario.seed, 2026)
        XCTAssertEqual(scenario.seed, repeated.seed)
        XCTAssertEqual(scenario.difficulty, .medium)
        XCTAssertFalse(scenario.options.isEmpty)
        XCTAssertNotNil(scenario.bestOption)
    }

    func testLoaderGeneratesScenarioWithRequestedFocus() async throws {
        let scenario = try await WhatToPlayScenarioLoader.generate(
            seed: 2026,
            difficulty: .easy,
            preferredFocus: .followSuit
        )

        XCTAssertEqual(scenario.difficulty, .easy)
        XCTAssertEqual(scenario.context.focusKind, .followSuit)
        XCTAssertFalse(scenario.options.isEmpty)
    }

    func testLoaderGeneratesScenarioWithRequestedMode() async throws {
        let sun = try await WhatToPlayScenarioLoader.generate(seed: 2026, difficulty: .easy, preferredMode: .sun)
        let hokum = try await WhatToPlayScenarioLoader.generate(seed: 2026, difficulty: .easy, preferredMode: .hokum)

        XCTAssertEqual(sun.state.mode, .sun)
        XCTAssertEqual(hokum.state.mode, .hokum)
        XCTAssertFalse(sun.options.isEmpty)
        XCTAssertFalse(hokum.options.isEmpty)
    }

    func testLoaderGeneratesScenarioWithRequestedTrumpSuit() async throws {
        let scenario = try await WhatToPlayScenarioLoader.generate(
            seed: 2026,
            difficulty: .easy,
            preferredMode: .hokum,
            preferredTrumpSuit: .spades
        )

        XCTAssertEqual(scenario.state.mode, .hokum)
        XCTAssertEqual(scenario.state.trumpSuit, .spades)
        XCTAssertEqual(scenario.context.trumpSuit, .spades)
        XCTAssertFalse(scenario.options.isEmpty)
    }

    func testLoaderGeneratesScenarioFromShareCode() async throws {
        let original = try await WhatToPlayScenarioLoader.generate(
            seed: 2026,
            difficulty: .easy,
            preferredFocus: .followSuit
        )
        let code = WhatToPlayShareCard.content(for: original).scenarioCode

        let replayed = try await WhatToPlayScenarioLoader.generate(code: code)

        XCTAssertEqual(replayed.seed, original.seed)
        XCTAssertEqual(replayed.difficulty, original.difficulty)
        XCTAssertEqual(replayed.context.focusKind, original.context.focusKind)
        XCTAssertEqual(replayed.options.map(\.card), original.options.map(\.card))
        XCTAssertEqual(replayed.bestOption?.card, original.bestOption?.card)
    }

    func testLoaderGeneratesScenarioFromShareCodeWithRequestedModeAndTrumpSuit() async throws {
        let original = try await WhatToPlayScenarioLoader.generate(
            seed: 2026,
            difficulty: .easy,
            preferredFocus: .trumpPressure,
            preferredMode: .hokum,
            preferredTrumpSuit: .spades
        )
        let code = WhatToPlayShareCard.content(for: original).scenarioCode

        let replayed = try await WhatToPlayScenarioLoader.generate(code: code)

        XCTAssertEqual(replayed.seed, original.seed)
        XCTAssertEqual(replayed.state.mode, .hokum)
        XCTAssertEqual(replayed.state.trumpSuit, .spades)
        XCTAssertEqual(replayed.context.focusKind, original.context.focusKind)
        XCTAssertEqual(replayed.options.map(\.card), original.options.map(\.card))
        XCTAssertEqual(replayed.bestOption?.card, original.bestOption?.card)
    }

    func testLoaderRejectsMalformedScenarioCode() async {
        do {
            _ = try await WhatToPlayScenarioLoader.generate(code: "WTP-invalid")
            XCTFail("كان يجب رفض رمز الموقف غير الصالح")
        } catch let error as WhatToPlayScenarioLoader.ScenarioCodeError {
            XCTAssertEqual(error, .invalidCode)
        } catch {
            XCTFail("خطأ غير متوقع: \(error)")
        }
    }

    private func attempt(
        seed: UInt64,
        difficulty: WhatToPlayDifficulty,
        focusKind: WhatToPlayScenarioFocusKind,
        gameMode: GameMode? = nil,
        trumpSuit: Suit? = nil
    ) -> WhatToPlayAttempt {
        let scenarioContext = trumpSuit.map {
            WhatToPlayScenarioContext(
                trickNumber: 3,
                isLeading: false,
                requiredSuit: .hearts,
                playedCardCount: 2,
                legalOptionCount: 3,
                mode: .hokum,
                trumpSuit: $0,
                hasTrumpInCurrentTrick: false,
                playerTeamTrickPoints: 24,
                opponentTeamTrickPoints: 18,
                playerTeamPointMargin: 6,
                focusKind: focusKind
            )
        }

        return WhatToPlayAttempt(
            difficulty: difficulty,
            seed: seed,
            selectedCard: PlayingCard(suit: .clubs, rank: .seven),
            bestCard: PlayingCard(suit: .clubs, rank: .seven),
            isCorrect: true,
            selectedRank: 1,
            expectedImpact: 1,
            bestExpectedImpact: 1,
            focusKind: focusKind,
            gameMode: gameMode,
            outcome: .winsTrick,
            scenarioContext: scenarioContext
        )
    }
}
