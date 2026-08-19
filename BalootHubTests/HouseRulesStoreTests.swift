import XCTest
import BalootEngine
@testable import BalootHub

final class HouseRulesStoreTests: XCTestCase {
    func testSaveAndLoadRoundTripsCustomRules() {
        let defaults = UserDefaults(suiteName: "HouseRulesStoreTests.roundTrip")!
        defaults.removePersistentDomain(forName: "HouseRulesStoreTests.roundTrip")
        var rules = BalootRulesConfiguration.standard
        rules.mustOvertrump = true
        rules.projectsEnabled = false
        rules.matchTargetScore = 301
        let preset = HouseRulesPreset(name: "قواعد استراحتنا", rules: rules)

        HouseRulesStore.save(preset, to: defaults)
        let loaded = HouseRulesStore.load(from: defaults)

        XCTAssertEqual(loaded, preset)
    }

    func testCorruptSavedDataFallsBackToStandard() {
        let defaults = UserDefaults(suiteName: "HouseRulesStoreTests.corrupt")!
        defaults.removePersistentDomain(forName: "HouseRulesStoreTests.corrupt")
        defaults.set(Data("bad-json".utf8), forKey: HouseRulesStore.storageKey)

        XCTAssertEqual(HouseRulesStore.load(from: defaults), .standard)
    }

    func testBlankPresetNameFallsBackToMajlisName() {
        let preset = HouseRulesStore.preset(named: "   ", basedOn: .tournament)

        XCTAssertEqual(preset.name, "قواعد مجلسي")
        XCTAssertEqual(preset.rules, .tournament)
    }

    func testLoadNormalizesOutOfRangeSavedRules() {
        let defaults = UserDefaults(suiteName: "HouseRulesStoreTests.normalizedLoad")!
        defaults.removePersistentDomain(forName: "HouseRulesStoreTests.normalizedLoad")
        var rules = BalootRulesConfiguration.standard
        rules.hokumRoundTotal = -1
        rules.sunRoundBaseTotal = 999
        rules.lastTrickBonus = 99
        rules.matchTargetScore = 10_000
        rules.cardsBeforeBidding = 0
        let preset = HouseRulesPreset(name: "  قواعدنا  ", rules: rules)
        do {
            defaults.set(try JSONEncoder().encode(preset), forKey: HouseRulesStore.storageKey)
        } catch {
            XCTFail("Failed to encode house rules preset: \(error)")
        }

        let loaded = HouseRulesStore.load(from: defaults)

        XCTAssertEqual(loaded.name, "قواعدنا")
        XCTAssertEqual(loaded.rules.hokumRoundTotal, 100)
        XCTAssertEqual(loaded.rules.sunRoundBaseTotal, 300)
        XCTAssertEqual(loaded.rules.lastTrickBonus, 50)
        XCTAssertEqual(loaded.rules.matchTargetScore, 1000)
        XCTAssertEqual(loaded.rules.cardsBeforeBidding, 1)
    }

    func testSaveNormalizesMultiplierFactorsInAscendingOrder() {
        let defaults = UserDefaults(suiteName: "HouseRulesStoreTests.normalizedSave")!
        defaults.removePersistentDomain(forName: "HouseRulesStoreTests.normalizedSave")
        var rules = BalootRulesConfiguration.standard
        rules.doubleFactor = 9
        rules.tripleFactor = 3
        rules.quadrupleFactor = 4
        rules.gahwaFactor = 5

        HouseRulesStore.save(HouseRulesPreset(name: "", rules: rules), to: defaults)
        let loaded = HouseRulesStore.load(from: defaults)

        XCTAssertEqual(loaded.name, "قواعد مجلسي")
        XCTAssertEqual(loaded.rules.doubleFactor, 9)
        XCTAssertEqual(loaded.rules.tripleFactor, 9)
        XCTAssertEqual(loaded.rules.quadrupleFactor, 9)
        XCTAssertEqual(loaded.rules.gahwaFactor, 9)
    }
}
