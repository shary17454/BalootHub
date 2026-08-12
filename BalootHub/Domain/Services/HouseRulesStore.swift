import Foundation
import BalootEngine

struct HouseRulesPreset: Codable, Equatable {
    var name: String
    var rules: BalootRulesConfiguration

    static let standard = HouseRulesPreset(name: "القواعد القياسية", rules: .standard)
    static let tournament = HouseRulesPreset(name: "قواعد بطولة", rules: .tournament)
    static let majlis = HouseRulesPreset(name: "قواعد مجلسي", rules: .standard)
}

enum HouseRulesStore {
    static let storageKey = "balootHouseRulesPresetJSON"

    static func load(from defaults: UserDefaults = .standard) -> HouseRulesPreset {
        guard let data = defaults.data(forKey: storageKey) else { return .standard }
        guard let preset = try? JSONDecoder().decode(HouseRulesPreset.self, from: data) else {
            return .standard
        }
        return normalized(preset)
    }

    static func save(_ preset: HouseRulesPreset, to defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(normalized(preset)) else { return }
        defaults.set(data, forKey: storageKey)
    }

    static func currentRules(from defaults: UserDefaults = .standard) -> BalootRulesConfiguration {
        load(from: defaults).rules
    }

    static func preset(named name: String, basedOn base: BalootRulesConfiguration) -> HouseRulesPreset {
        normalized(HouseRulesPreset(name: name, rules: base))
    }

    static func normalized(_ preset: HouseRulesPreset) -> HouseRulesPreset {
        var rules = preset.rules
        rules.hokumRoundTotal = clamp(rules.hokumRoundTotal, 100...300)
        rules.sunRoundBaseTotal = clamp(rules.sunRoundBaseTotal, 100...300)
        rules.sunScoreMultiplier = clamp(rules.sunScoreMultiplier, 1...4)
        rules.lastTrickBonus = clamp(rules.lastTrickBonus, 0...50)
        rules.cardsBeforeBidding = clamp(rules.cardsBeforeBidding, 1...8)
        rules.doubleFactor = clamp(rules.doubleFactor, 2...10)
        rules.tripleFactor = max(rules.doubleFactor, clamp(rules.tripleFactor, 2...12))
        rules.quadrupleFactor = max(rules.tripleFactor, clamp(rules.quadrupleFactor, 2...16))
        rules.gahwaFactor = max(rules.quadrupleFactor, clamp(rules.gahwaFactor, 2...24))
        rules.siraPoints = clamp(rules.siraPoints, 0...100)
        rules.fiftyPoints = clamp(rules.fiftyPoints, 0...150)
        rules.hundredPoints = clamp(rules.hundredPoints, 0...250)
        rules.fourHundredPoints = clamp(rules.fourHundredPoints, 0...500)
        rules.belotPoints = clamp(rules.belotPoints, 0...100)
        rules.kabootBonusHokum = clamp(rules.kabootBonusHokum, 0...300)
        rules.kabootBonusSun = clamp(rules.kabootBonusSun, 0...300)
        rules.matchTargetScore = clamp(rules.matchTargetScore, 50...1000)

        let name = preset.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return HouseRulesPreset(
            name: name.isEmpty ? "قواعد مجلسي" : name,
            rules: rules
        )
    }

    private static func clamp(_ value: Int, _ range: ClosedRange<Int>) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
