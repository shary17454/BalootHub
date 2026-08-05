import XCTest
@testable import BalootHub

final class ScoreRulesTests: XCTestCase {
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
}
