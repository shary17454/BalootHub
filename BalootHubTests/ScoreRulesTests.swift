import XCTest
@testable import BalootHub

final class ScoreRulesTests: XCTestCase {
    func testOverflowingPersistedScoresRemainReadable() {
        XCTAssertEqual(ScoreRules.standard.finalScore(baseScore: Int.max, projects: 1, multiplier: .none), Int.max)
        XCTAssertEqual(ScoreRules.standard.finalScore(baseScore: Int.max, projects: 0, multiplier: .double), Int.max)
    }

    func testNewScoresRejectOverflowAndKeepExactBoundary() {
        XCTAssertNil(ScoreRules.standard.checkedFinalScore(baseScore: Int.max, projects: 1, multiplier: .none))
        XCTAssertNil(ScoreRules.standard.checkedFinalScore(baseScore: Int.max, projects: 0, multiplier: .double))
        XCTAssertEqual(ScoreRules.standard.checkedFinalScore(baseScore: Int.max - 1, projects: 1, multiplier: .none), Int.max)
    }

    func testScoreInputAcceptsArabicAndPersianDecimalDigits() {
        XCTAssertEqual(ScoreRoundInput.points("١٢٣"), 123)
        XCTAssertEqual(ScoreRoundInput.points("۱۲۳"), 123)
        XCTAssertEqual(ScoreRoundInput.points(" 123 "), 123)
        XCTAssertEqual(ScoreRoundInput.points(String(Int.max)), Int.max)
    }

    func testScoreInputRejectsInvalidOrOverflowingProjectsInsteadOfUsingZero() {
        for input in ["abc", "12.5", "-1", "١٢x", "9999999999999999999999999"] {
            XCTAssertNil(ScoreRoundInput.points(input, allowsEmpty: true), input)
        }
        XCTAssertEqual(ScoreRoundInput.points("", allowsEmpty: true), 0)
        XCTAssertNil(ScoreRoundInput.points(""))
    }

    func testNoMultiplierReturnsBaseScorePlusProjects() {
        let rules = ScoreRules.standard
        XCTAssertEqual(rules.finalScore(baseScore: 100, projects: 20, multiplier: .none), 120)
    }

    func testDoubleMultiplierDoublesTotal() {
        let rules = ScoreRules.standard
        XCTAssertEqual(rules.finalScore(baseScore: 100, projects: 0, multiplier: .double), 200)
    }

    func testTripleAndQuadrupleFactorsMatchStandardPreset() {
        let rules = ScoreRules.from(preset: .standard, coffeeEnabled: false)
        XCTAssertEqual(rules.finalScore(baseScore: 10, projects: 0, multiplier: .triple), 30)
        XCTAssertEqual(rules.finalScore(baseScore: 10, projects: 0, multiplier: .quadruple), 40)
    }

    func testCoffeeMultiplierDisabledFallsBackToNoMultiplier() {
        let rules = ScoreRules.from(preset: .standard, coffeeEnabled: false)
        XCTAssertEqual(rules.finalScore(baseScore: 50, projects: 0, multiplier: .coffee), 50)
    }

    func testCoffeeMultiplierEnabledAppliesConfiguredFactor() {
        let rules = ScoreRules.from(preset: .standard, coffeeEnabled: true)
        XCTAssertEqual(rules.finalScore(baseScore: 50, projects: 0, multiplier: .coffee), 200)
    }

    func testHighStakesPresetUsesDifferentFactors() {
        let rules = ScoreRules.from(preset: .highStakes, coffeeEnabled: false)
        XCTAssertEqual(rules.finalScore(baseScore: 10, projects: 0, multiplier: .triple), 40)
        XCTAssertEqual(rules.finalScore(baseScore: 10, projects: 0, multiplier: .quadruple), 60)
    }

    func testNegativeInputsAreClampedToZero() {
        let rules = ScoreRules.standard
        XCTAssertEqual(rules.finalScore(baseScore: -10, projects: -5, multiplier: .none), 0)
    }

    func testRoundAutofillUsesHokumBaseTotal() {
        XCTAssertEqual(ScoreRoundAutofill.basePointTotal(for: .hokum), 162)
        XCTAssertEqual(ScoreRoundAutofill.complementaryScore(for: 100, mode: .hokum), 62)
    }

    func testRoundAutofillUsesSunBaseTotal() {
        XCTAssertEqual(ScoreRoundAutofill.basePointTotal(for: .sun), 130)
        XCTAssertEqual(ScoreRoundAutofill.complementaryScore(for: 14, mode: .sun), 116)
    }

    func testRoundAutofillDoesNotReturnNegativeComplement() {
        XCTAssertEqual(ScoreRoundAutofill.complementaryScore(for: 200, mode: .hokum), 0)
    }
}
