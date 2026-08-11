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
}
